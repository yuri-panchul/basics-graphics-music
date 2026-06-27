#include "csr_masks.h"

//----------------------------------------------------------------------------
// The section at the beginning of the address space
// is needed to accommodate QEMU
// and some cores that have reset at address 0.
//
// "__" is needed if a user wants to implement reset
// as a C function "_RST_BASE".

        .section text.zero

        j           __RST_BASE

//----------------------------------------------------------------------------
// Handlers for NMI trap, DBG and DEX

        .section    .text.nmi_vec
        mret

        .section    .text.dbg_vec
        dret

        .section    .text.dex_vec
        dret

//----------------------------------------------------------------------------
// Reset handler

        .section    .text.reset
        .global     _start
_start:

        //--------------------------------------------------------------------
        // Disable all interrupts globally

        csrc    mstatus, MSTATUS_MIE

        //--------------------------------------------------------------------
        // Setup global pointer. See:
        //
        // https://sourceware.org/binutils/docs/as/RISC_002dV_002dDirectives.html
        // https://github.com/riscvarchive/riscv-newlib/blob/riscv-newlib-3.2.0/libgloss/riscv/crt0.S
        // https://twilco.github.io/riscv-from-scratch/2019/04/27/riscv-from-scratch-2.html

        // TODO: Check what happen if we remove .option
        .option push     // Save the current assembler options configuration.
        .option norelax  // Disable linker relaxation to prevent relaxation of the GP initialization.

        la          gp, __global_pointer$


        //--------------------------------------------------------------------
        // __TRAP_ACK as an interrupt service routive

        la          t0, __TRAP_ACK
        csrw        mtvec, t0

        //--------------------------------------------------------------------
        // Initialize the stack for the interrupt handler.
        // Such a stack is called a "trap frame"
        // and mentioned in the code as "trapframe".

        la          t0, __trapframe_start
        csrw        mscratch, t0

        .option pop      // Restore the previously saved assembler options configuration.

        //--------------------------------------------------------------------
        // Fill sbss and bss sections with zeros. See:
        //
        // https://eseo-tech.github.io/emulsiV/doc/
        // https://github.com/riscv-mcu/GD32VF103_Firmware_Library/blob/master/Firmware/RISCV/env_Eclipse/start.S

        // The symbols __sbss_start are __bss_end are assumed to be defined
        // in the linker script

        la          t0, __sbss_start
        la          t1, __bss_end

        // Check if the bss sections are empty (if t0 >= t1, skip the loop entirely)
        bgeu        t0, t1, bss_clr_done

bss_clr:

        sw          zero, (t0)
        addi        t0, t0, 4
        bltu        t0, t1, bss_clr

bss_clr_done:

        //--------------------------------------------------------------------
        // Setup the stack.
        //
        // Inform the debugger that this is the root of the call stack
        // and there are no callers above.
        // See https://sourceware.org/binutils/docs/as/CFI-directives.html

        .cfi_startproc
        .cfi_undefined ra

        la          sp, __stack_top

        // Frame pointer fp/s0 is initialized to the top of the stack.
        // Frame pointer is usually not needed by the programs written in C,
        // unless a debugger is used.
        //
        // See the options in GCC documentation:
        // -g -O2/3 -fomit-frame-pointer -fno-omit-frame-pointer

        mv          fp, sp

        jal         main

        .cfi_endproc

        j           _start
