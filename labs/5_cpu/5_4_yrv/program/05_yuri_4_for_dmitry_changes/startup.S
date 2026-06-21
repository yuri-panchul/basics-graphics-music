#include "csr_masks.h"

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

        csrc    mstatus, MSTATUS_MIE  // Disable all interrupts globally

        // Init the stack for the interrupt handler.
        // Such a stack is called a "trap frame"
        // and mentioned in the code as "trapframe".
        //
        // Note that BGM Femto Threads does not use trapframe.
        // However other examples may use trapframe to store the registers
        // in the example's interrupt handlers.

        la          t0, __trapframe_start
        csrw        mscratch, t0

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

        // Inform the debugger that this is the root of the call stack
        // and there are no callers above.
        // See https://sourceware.org/binutils/docs/as/CFI-directives.html

        .cfi_startproc
        .cfi_undefined ra

        // .option push     - Save the current assembler options configuration.
        // .option norelax  - Disable linker relaxation to prevent relaxation of the GP initialization.
        // .option pop      - Restore the previously saved assembler options configuration.
        //
        // https://sourceware.org/binutils/docs/as/RISC_002dV_002dDirectives.html
        // https://github.com/riscvarchive/riscv-newlib/blob/riscv-newlib-3.2.0/libgloss/riscv/crt0.S
        // https://twilco.github.io/riscv-from-scratch/2019/04/27/riscv-from-scratch-2.html

        .option push
        .option norelax

        la          gp, __global_pointer$

        .option pop

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
