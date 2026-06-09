#include "bgm_femto_threads.h"
#include "csr_masks.h"

//----------------------------------------------------------------------------

        .bss
        .align      2

thread_contexts:
        .space      MAX_THREADS * THREAD_CONTEXT_SIZE

after_thread_contexts:

//----------------------------------------------------------------------------

// For whatever reason GCC version we use does not recognize ".sdata"
// and requires writing ".section .sdata".

        .section    .sdata
        .align      2

threads_end_pointer:
        .word       thread_contexts

//----------------------------------------------------------------------------

        .text

        .align      2
        .globl      define_thread

define_thread:

        lw          t0, %lo (threads_end_pointer) (gp)
        la          t1, after_thread_contexts

        blt         t0, t1, enough_space_for_new_thread
        li          a0, 0  // Error return
        ret

enough_space_for_new_thread:

        sw          a0, (t0)
        addi        t2, t0, THREAD_CONTEXT_SIZE
        sw          t2, %lo (threads_end_pointer) (gp)
        sw          a0, %lo (THREAD_CONTEXT_OFFSET_PC) (t0) 
        li          a0, 1
        ret

//----------------------------------------------------------------------------

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

//        wfi                               // Wait for interrupts Bad for debug
        j           eternal_loop

//----------------------------------------------------------------------------

        .section    .text.trap_ack
        .global     trap_ack

trap_ack:

        // Save t0
        // Instead of using mscratch and trapframe
        // we use thread context to save registers.

        sw          t0, THREAD_CONTEXT_OFFSET_T0 (tp)  // save t0

        //--------------------------------------------------------------------
        // Check if interrupt

        csrr        t0, mcause         // read exception cause
        bgez        t0, not_interrupt

        //--------------------------------------------------------------------
        // Check if a timer interrupt

        sw          t1, THREAD_CONTEXT_OFFSET_T1 (tp)           // save t1
        li          t1, MCAUSE_EXCCODE_MASK
        and         t0, t0, t1                                  // isolate interrupt cause Problem MCAUSE_EXCCODE_MASK 0xffffffff
        li          t1, MCAUSE_EXCCODE_MACHINE_TIMER_INTERRUPT
        bne         t0, t1, not_timer_interrupt

        //--------------------------------------------------------------------
        // Check if there is more than one thread

        sw          t2, THREAD_CONTEXT_OFFSET_T2 (tp)  // save t2
        lw          t0, %lo (threads_end_pointer) (gp)
        la          t1, thread_contexts
        addi        t2, t1, 2 * THREAD_CONTEXT_SIZE
        blt         t0, t2, less_than_two_threads_defined
        j           switch_the_contexts

        //--------------------------------------------------------------------
        // Recovery from no-switching situations.

less_than_two_threads_defined:
        lw          t2, THREAD_CONTEXT_OFFSET_T2 (tp)  // restore t2
not_timer_interrupt:
        lw          t1, THREAD_CONTEXT_OFFSET_T1 (tp)  // restore t1
not_interrupt:
        lw          t0, THREAD_CONTEXT_OFFSET_T0 (tp)  // restore t0
        mret

//----------------------------------------------------------------------------

        .text

switch_the_contexts:

        //--------------------------------------------------------------------
        // Advance the thread pointer

        mv          t2, tp
        addi        tp, tp, THREAD_CONTEXT_SIZE
        bne         tp, t0, tp_is_advanced
        mv          tp, t1

tp_is_advanced:

        //--------------------------------------------------------------------
        // Now t2 is the previous/current thread and tp is the next thread.
        // Let's save all the registers in the previous thread context.

        sw            ra  , THREAD_CONTEXT_OFFSET_RA     (t2)
        sw            sp  , THREAD_CONTEXT_OFFSET_SP     (t2)
        sw            gp  , THREAD_CONTEXT_OFFSET_GP     (t2)

        // Registers t0, t1 and t2 are already saved

        sw            s0  , THREAD_CONTEXT_OFFSET_S0_FP  (t2)
        sw            s1  , THREAD_CONTEXT_OFFSET_S1     (t2)
        sw            a0  , THREAD_CONTEXT_OFFSET_A0     (t2)
        sw            a1  , THREAD_CONTEXT_OFFSET_A1     (t2)
        sw            a2  , THREAD_CONTEXT_OFFSET_A2     (t2)
        sw            a3  , THREAD_CONTEXT_OFFSET_A3     (t2)
        sw            a4  , THREAD_CONTEXT_OFFSET_A4     (t2)
        sw            a5  , THREAD_CONTEXT_OFFSET_A5     (t2)
        sw            a6  , THREAD_CONTEXT_OFFSET_A6     (t2)
        sw            a7  , THREAD_CONTEXT_OFFSET_A7     (t2)
        sw            s2  , THREAD_CONTEXT_OFFSET_S2     (t2)
        sw            s3  , THREAD_CONTEXT_OFFSET_S3     (t2)
        sw            s4  , THREAD_CONTEXT_OFFSET_S4     (t2)
        sw            s5  , THREAD_CONTEXT_OFFSET_S5     (t2)
        sw            s6  , THREAD_CONTEXT_OFFSET_S6     (t2)
        sw            s7  , THREAD_CONTEXT_OFFSET_S7     (t2)
        sw            s8  , THREAD_CONTEXT_OFFSET_S8     (t2)
        sw            s9  , THREAD_CONTEXT_OFFSET_S9     (t2)
        sw            s10 , THREAD_CONTEXT_OFFSET_S10    (t2)
        sw            s11 , THREAD_CONTEXT_OFFSET_S11    (t2)
        sw            t3  , THREAD_CONTEXT_OFFSET_T3     (t2)
        sw            t4  , THREAD_CONTEXT_OFFSET_T4     (t2)
        sw            t5  , THREAD_CONTEXT_OFFSET_T5     (t2)
        sw            t6  , THREAD_CONTEXT_OFFSET_T6     (t2)

        //--------------------------------------------------------------------
        // Save the program counter of the previous/current thread
        // and schedule the restoration of the program counter
        // for the next thread.

        csrr          t0,   mepc  // Program counter before the interrupt  
        sw            t0,   THREAD_CONTEXT_OFFSET_PC     (t2)

        lw            t0,   THREAD_CONTEXT_OFFSET_PC     (tp) //zero ?!  First start context is null
        csrw          mepc, t0    // Program counter after mret

        //--------------------------------------------------------------------
        // Restore all the registers for the next thread
        // from the next thread context.

        lw            ra  , THREAD_CONTEXT_OFFSET_RA     (tp)
        lw            sp  , THREAD_CONTEXT_OFFSET_SP     (tp)
        lw            gp  , THREAD_CONTEXT_OFFSET_GP     (tp)
        lw            t0  , THREAD_CONTEXT_OFFSET_T0     (tp)
        lw            t1  , THREAD_CONTEXT_OFFSET_T1     (tp)
        lw            t2  , THREAD_CONTEXT_OFFSET_T2     (tp)
        lw            s0  , THREAD_CONTEXT_OFFSET_S0_FP  (tp)
        lw            s1  , THREAD_CONTEXT_OFFSET_S1     (tp)
        lw            a0  , THREAD_CONTEXT_OFFSET_A0     (tp)
        lw            a1  , THREAD_CONTEXT_OFFSET_A1     (tp)
        lw            a2  , THREAD_CONTEXT_OFFSET_A2     (tp)
        lw            a3  , THREAD_CONTEXT_OFFSET_A3     (tp)
        lw            a4  , THREAD_CONTEXT_OFFSET_A4     (tp)
        lw            a5  , THREAD_CONTEXT_OFFSET_A5     (tp)
        lw            a6  , THREAD_CONTEXT_OFFSET_A6     (tp)
        lw            a7  , THREAD_CONTEXT_OFFSET_A7     (tp)
        lw            s2  , THREAD_CONTEXT_OFFSET_S2     (tp)
        lw            s3  , THREAD_CONTEXT_OFFSET_S3     (tp)
        lw            s4  , THREAD_CONTEXT_OFFSET_S4     (tp)
        lw            s5  , THREAD_CONTEXT_OFFSET_S5     (tp)
        lw            s6  , THREAD_CONTEXT_OFFSET_S6     (tp)
        lw            s7  , THREAD_CONTEXT_OFFSET_S7     (tp)
        lw            s8  , THREAD_CONTEXT_OFFSET_S8     (tp)
        lw            s9  , THREAD_CONTEXT_OFFSET_S9     (tp)
        lw            s10 , THREAD_CONTEXT_OFFSET_S10    (tp)
        lw            s11 , THREAD_CONTEXT_OFFSET_S11    (tp)
        lw            t3  , THREAD_CONTEXT_OFFSET_T3     (tp)
        lw            t4  , THREAD_CONTEXT_OFFSET_T4     (tp)
        lw            t5  , THREAD_CONTEXT_OFFSET_T5     (tp)
        lw            t6  , THREAD_CONTEXT_OFFSET_T6     (tp)

        mret
