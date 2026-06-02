#include "bgm_pico_threads.h"
#include "csr_masks.h"

#-----------------------------------------------------------------------------

# For whatever reason GCC version we use does not recognize ".sdata"
# and requires writing ".section .sdata".

        .section    .sdata
        .align      2

num_threads:
        .word       0

cur_thread:
        .word       0

#-----------------------------------------------------------------------------

#define THREAD_CONTEXT_SIZE  32

        .bss
        .align      2

thread_contexts:
        .space      MAX_THREADS * THREAD_CONTEXT_SIZE

#-----------------------------------------------------------------------------

        .text

        .align      2
        .globl      define_thread

define_thread:

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

.1:     wfi                               // Wait for interrupts
        j           1

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


not_timer_interrupt:

        lw          a2, 4 (a0)        # restore a2

not_interrupt:

        lw          a1, 0 (a0)        # restore a1
        csrrw       a0, mscratch, a0  # restore a0; mscratch = &temp storage
        mret
