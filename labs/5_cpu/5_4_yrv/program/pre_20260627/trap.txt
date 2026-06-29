# ==============================================================================
# SECTION: DEAFULT TRAP HANDLER  0x040
# ==============================================================================

        .section    .text.trap_ack
        .global     trap_ack

trap_ack:

        # Save a0 and a1 registers

        csrrw       a0, mscratch, a0  # save a0; set a0 = & temp storage
        sw          a1, 0 (a0)        # save a1

        # Check if interrupt

        csrr        a1, mcause        # read exception cause
        bgez        a1, not_interrupt

        # Check if a timer interrupt

        sw          a2, 4 (a0)        # save a2
        andi        a1, a1, 0x3f      # isolate interrupt cause
        li          a2, 7             # a2 = machine timer interrupt cause
        bne         a1, a2, not_timer_interrupt

        # Timer interrupt


not_timer_interrupt:

        lw          a2, 4 (a0)        # restore a2

not_interrupt:

        lw          a1, 0 (a0)        # restore a1
        csrrw       a0, mscratch, a0  # restore a0; mscratch = &temp storage
        mret



        sw          a1, 0  (a0)       # save a1
        sw          a2, 4  (a0)       # save a2
        sw          a3, 8  (a0)       # save a3
        sw          a4, 12 (a0)       # save a4

        # decode interrupt cause

        csrr        a1, mcause        # read exception cause
        bgez        a1, exception     # branch if not an interrupt
        andi        a1, a1, 0x3f      # isolate interrupt cause
        li          a2, 7             # a2 = timer interrupt cause

        bne a1, a2, otherInt # branch if not a timer interrupt

        # handle timer interrupt by incrementing time comparator
        la a1, mtimecmp # a1 = &time comparator
        lw a2, 0(a1) # load lower 32 bits of comparator
        lw a3, 4(a1) # load upper 32 bits of comparator
        addi a4, a2, 1000 # increment lower bits by 1000 cycles
        sltu a2, a4, a2 # generate carry-out
        add a3, a3, a2 # increment upper bits
        sw a3, 4(a1) # store upper 32 bits
        sw a4, 0(a1) # store lower 32 bits
        # restore registers and return
        lw a4, 12(a0) # restore a4
        lw a3, 4(a0) # restore a3
        lw a2, 4(a0) # restore a2
        lw a1, 0(a0) # restore a1
        csrrw a0, mscratch, a0 # restore a0; mscratch = &temp storage
        mret # return from handler


trap_ack:  .word 0x342023f3          # csrr t2, mcause
           blt   t2, x0, int_ack

           slli  t2, t2, 1           # discard msb
           li    t1, 0x16            # ecall
           bne   t1, t2, n_ecall

           li    t1, 0x20            # bit 12
           beq   zero, zero, set_led

n_ecall:   li    t1, 0x2             # bit 8
           beq   zero, zero, set_led

int_ack:   slli  t2, t2, 1           # discard msb
           li    t1, 0x16            # eint
           bne   t1, t2, n_eint

clr_int:   lui   a7, iobase          # i/o page
           lhu   t0, 6(a7)           # read port3
           .word 0x28f29293          # bseti t0, t0, 15
           sh    t0, 6(a7)           # write port3
           .word 0x48f29293          # bclri t0, t0, 15
           sh    t0, 6(a7)           # write port3
           .word 0x30200073          # mret

n_eint:    li    t1, 0x20            # li
           blt   t2, t1, n_li

           li    t1, 0x8             # bit 10
           beq   zero, zero, set_led

n_li:      li    t1, 0x4             # bit 9
           beq   zero, zero, set_led





# Template for common trap handler

trap_ack:
    csrr  t2, mcause
    bltz  t2, handle_exception

    srli  t2, t2, 1
    li    t1, 0x16
    bne   t1, t2, check_other

    j     common_return

check_other:
    li    t1, 0x20
    bltu  t2, t1, unknown


common_return:
    mret

handle_exception:
    mret

unknown:
    mret

# ==============================================================================
# SECTION: NMI HANDLER 0x100
# ==============================================================================
# NMI Trap handler

.section .text.nmi_vec
.global nmi_vec

nmi_vec:
    mret


# ==============================================================================
# SECTION: DBG HANDLER 0x140
# ==============================================================================
.section .text.dbg_vec
.global dbg_vec

dbg_vec:
    dret


# ==============================================================================
# SECTION: DEX HANDLER 0x1c0
# ==============================================================================
.section .text.dex_vec
.global dex_vec
dex_vec:
    dret


# ==============================================================================
# SECTION: RESET (main) 0x200
# ==============================================================================

.section .text.init
.global _start

_start:
loop:

# ------------------------------------------------------------------------------
# Sub-section: mscratch initialization
# ------------------------------------------------------------------------------
# used trapframe scetion with 128 bytes lenght

    csrc    mstatus, RISCV_MSTATUS_MIE     # Clear MIE bit to disable all interrupts globally
    la      t0, __trapframe_start
    csrw    mscratch, t0

# ------------------------------------------------------------------------------
# Sub-section: Zero BSSs
# ------------------------------------------------------------------------------
# https://eseo-tech.github.io/emulsiV/doc/
# https://github.com/riscv-mcu/GD32VF103_Firmware_Library/blob/master/Firmware/RISCV/env_Eclipse/start.S

# Load the memory boundaries generated by the linker script
    la      t0, __sbss_start    # Start address of memory to clear (from .sbss section)
    la      t1, __bss_end       # End address of memory to clear (from .bss section)

    # Check if the BSS sections are empty (if t0 >= t1, skip the loop entirely)
    bgeu    t0, t1, bss_clr_done

bss_clr:
    sw      zero, 0(t0)         # Store a 32-bit zero into the memory address held in t0
    addi    t0, t0, 4           # Advance the memory pointer by 4 bytes (1 word)
    bltu    t0, t1, bss_clr     # If t0 is still less than t1, continue clearing memory

bss_clr_done:


# Inform the debugger that this is the root of the call stack and there are no callers above.
# https://sourceware.org/binutils/docs/as/CFI-directives.html
# ------------------------------------------------------------------------------
# Sub-section: startproc
# ------------------------------------------------------------------------------

.cfi_startproc
.cfi_undefined ra

# .option push     - Save the current assembler options configuration.
# .option norelax  - Disable linker relaxation to prevent relaxation of the GP initialization.
# .option pop      - Restore the previously saved assembler options configuration.
# https://sourceware.org/binutils/docs/as/RISC_002dV_002dDirectives.html
# https://github.com/riscvarchive/riscv-newlib/blob/riscv-newlib-3.2.0/libgloss/riscv/crt0.S


# https://twilco.github.io/riscv-from-scratch/2019/04/27/riscv-from-scratch-2.html
.option push
.option norelax
	la gp, __global_pointer$
.option pop

	la sp, __stack_top
	add s0, sp, zero     #Frame pointer is initialized to the top of the stack.

	jal zero, main
.cfi_endproc

    beq   zero, zero, loop

# ==============================================================================
# END OF PROGRAM
# ==============================================================================
