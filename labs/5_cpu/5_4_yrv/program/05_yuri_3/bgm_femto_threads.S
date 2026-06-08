#include "bgm_femto_threads.h"
#include "csr_masks.h"

#-----------------------------------------------------------------------------

        .bss
        .align      2

thread_contexts:
        .space      max_threads * context_size

#-----------------------------------------------------------------------------

# For whatever reason GCC version we use does not recognize ".sdata"
# and requires writing ".section .sdata".

        .section    .sdata
        .align      2

threads_end_pointer:
        .word       thread_contexts

current_thread_pointer:
        .word       0

#-----------------------------------------------------------------------------

        .text

        .align      2
        .globl      define_thread

define_thread:

        lw          t0, thread_end_pointer (gp)
        la          t1, thread_contexts + MAX_THREADS * THREAD_CONTEXT_SIZE

        blt         t0, t1, enough_space_for_new_thread
        li          a0, 0  # Error return
        ret

enough_space_for_new_thread:

        sw          a0, (t0)
        addi        t2, t0, THREAD_CONTEXT_SIZE
        sw          t2, thread_end_pointer (gp)

        li          a0, 1
        ret

#-----------------------------------------------------------------------------

        .globl      start_running_threads

start_running_threads:

        csrwi       mstatus, MSTATUS_MIE  // Enable interrupts

        li          t0,      MIP_MTIP     // Enable timer interrupt
        csrw        mip,     t0

        // The eternal loop below is not necessary
        // if the only interrupts we have come from the timer.
        // Otherwise we do need the loop in order to continue
        // running after the interrupt processing.

eternal_loop:

        wfi                               // Wait for interrupts
        j           eternal_loop

#-----------------------------------------------------------------------------

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

        sw          a3,  8 (a0)       # save a3
        sw          a4, 12 (a0)       # save a4

        lw          a1, thread_end_pointer (gp)
        la          a2, thread_contexts
        beq         a1, a2, no_thread_defined

        lw          a3, current_thread_pointer (gp)
        addi        a4, a3, THREAD_CONTEXT_SIZE

        beq         a4, a1, next_thread_0
        mv          a2, a4

        // TODO: check case of num_threads=1

next_thread_0:

        # Now a3 is the current thread and a2 is the next thread

        beq         a2, a3, one_thread_defined

        // TODO: take care of saving proper a1-a4

        sw           x1,  1 * 4 (a3)
        sw           x2,  2 * 4 (a3)
        sw           x3,  3 * 4 (a3)
        sw           x4,  4 * 4 (a3)
        sw           x5,  5 * 4 (a3)
        sw           x6,  6 * 4 (a3)
        sw           x7,  7 * 4 (a3)
        sw           x8,  8 * 4 (a3)
        sw           x9,  9 * 4 (a3)
        sw          x10, 10 * 4 (a3)
        sw          x11, 11 * 4 (a3)
        sw          x12, 12 * 4 (a3)
        sw          x13, 13 * 4 (a3)
        sw          x14, 14 * 4 (a3)
        sw          x15, 15 * 4 (a3)
        sw          x16, 16 * 4 (a3)
        sw          x17, 17 * 4 (a3)
        sw          x18, 18 * 4 (a3)
        sw          x19, 19 * 4 (a3)
        sw          x20, 20 * 4 (a3)
        sw          x21, 21 * 4 (a3)
        sw          x22, 22 * 4 (a3)
        sw          x23, 23 * 4 (a3)
        sw          x24, 24 * 4 (a3)
        sw          x25, 25 * 4 (a3)
        sw          x26, 26 * 4 (a3)
        sw          x27, 27 * 4 (a3)
        sw          x28, 28 * 4 (a3)
        sw          x29, 29 * 4 (a3)
        sw          x30, 30 * 4 (a3)
        sw          x31, 31 * 4 (a3)

        lw           x1,  1 * 4 (a2)
        lw           x2,  2 * 4 (a2)
        lw           x3,  3 * 4 (a2)
        lw           x4,  4 * 4 (a2)
        lw           x5,  5 * 4 (a2)
        lw           x6,  6 * 4 (a2)
        lw           x7,  7 * 4 (a2)
        lw           x8,  8 * 4 (a2)
        lw           x9,  9 * 4 (a2)
        lw          x10, 10 * 4 (a2)
        lw          x11, 11 * 4 (a2)
        lw          x12, 12 * 4 (a2)
        lw          x13, 13 * 4 (a2)
        lw          x14, 14 * 4 (a2)
        lw          x15, 15 * 4 (a2)
        lw          x16, 16 * 4 (a2)
        lw          x17, 17 * 4 (a2)
        lw          x18, 18 * 4 (a2)
        lw          x19, 19 * 4 (a2)
        lw          x20, 20 * 4 (a2)
        lw          x21, 21 * 4 (a2)
        lw          x22, 22 * 4 (a2)
        lw          x23, 23 * 4 (a2)
        lw          x24, 24 * 4 (a2)
        lw          x25, 25 * 4 (a2)
        lw          x26, 26 * 4 (a2)
        lw          x27, 27 * 4 (a2)
        lw          x28, 28 * 4 (a2)
        lw          x29, 29 * 4 (a2)
        lw          x30, 30 * 4 (a2)
        lw          x31, 31 * 4 (a2)

one_thread_defined:

        lw          a2,  8 (a0)       # restore a2
        lw          a4, 12 (a0)       # restore a4

no_thread_defined:
not_timer_interrupt:

        lw          a2, 4 (a0)        # restore a2

not_interrupt:

        lw          a1, 0 (a0)        # restore a1
        csrrw       a0, mscratch, a0  # restore a0; mscratch = &temp storage

        // TODO: return to the proper address
        // restored from the next thread context.
        // The current return from interrupt register
        // should be saved in the context.

        mret
