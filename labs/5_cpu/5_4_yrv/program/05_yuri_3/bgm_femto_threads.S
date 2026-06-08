#include "bgm_femto_threads.h"
#include "csr_masks.h"

#-----------------------------------------------------------------------------

        .bss
        .align      2

thread_contexts:
        .space      MAX_THREADS * THREAD_CONTEXT_SIZE

after_thread_contexts:

#-----------------------------------------------------------------------------

# For whatever reason GCC version we use does not recognize ".sdata"
# and requires writing ".section .sdata".

        .section    .sdata
        .align      2

threads_end_pointer:
        .word       thread_contexts

#-----------------------------------------------------------------------------

        .text

        .align      2
        .globl      define_thread

define_thread:

        lw          t0, thread_end_pointer (gp)
        la          t1, after_thread_contexts

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

        la          tp, thread_contexts   // Assign thread pointer

        li          t1,      MIP_MTIP     // Enable timer interrupt
        csrw        mip,     t1

        csrwi       mstatus, MSTATUS_MIE  // Enable interrupts

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

        # Save t0
        # Instead of using mscratch and trapframe
        # we use thread context to save registers.

        sw          t0, thread_context_offset_t0 (tp)  # save t0

        # Check if interrupt

        csrr        t0, mcause         # read exception cause
        bgez        t0, not_interrupt

        # Check if a timer interrupt

        sw          t1, thread_context_offset_t1 (tp)  # save t1
        li          t1, MCAUSE_EXCCODE_MASK
        and         t0, t0, t1         # isolate interrupt cause
        li          t1, MCAUSE_EXCCODE_MACHINE_TIMER_INTERRUPT
        bne         t0, t1, not_timer_interrupt

        # Timer interrupt

        sw          a3,  8 (a0)       # save a3
        sw          a4, 12 (a0)       # save a4

        lw          t0, thread_end_pointer (gp)
        la          t1, thread_contexts
        beq         t0, t1, no_thread_defined

        lw          a3, current_thread_pointer (gp)
        addi        a4, a3, THREAD_CONTEXT_SIZE

        beq         a4, t0, next_thread_0
        mv          t1, a4

        // TODO: check case of num_threads=1

next_thread_0:

        # Now a3 is the current thread and t1 is the next thread

        beq         t1, a3, one_thread_defined

        // TODO: take care of saving proper t0-a4

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

        lw          t1,  8 (a0)       # restore t1
        lw          a4, 12 (a0)       # restore a4

no_thread_defined:
not_timer_interrupt:

        lw          t1, 4 (a0)        # restore t1

not_interrupt:

        lw          t0, 0 (a0)        # restore t0
        csrrw       a0, mscratch, a0  # restore a0; mscratch = &temp storage

        // TODO: return to the proper address
        // restored from the next thread context.
        // The current return from interrupt register
        // should be saved in the context.

        mret
