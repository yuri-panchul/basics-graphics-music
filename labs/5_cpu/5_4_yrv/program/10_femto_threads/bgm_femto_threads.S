#include "risc_v_cpu_config.h"
#include "csr_masks.h"
#include "bgm_femto_threads.h"

//----------------------------------------------------------------------------

        .bss
        .balign     4

thread_contexts:
        .space      MAX_THREADS * THREAD_CONTEXT_SIZE

after_thread_contexts:

//----------------------------------------------------------------------------


// For whatever reason GCC version we use does not recognize ".sdata"
// and requires writing ".section .sdata".
// It also does not assume allocatable "a" by default.

        .section    .sdata, "a"
        .balign 4

threads_end_pointer:
        .word       thread_contexts

next_thread_stack_bottom:
        .word       __stack_bottom

//----------------------------------------------------------------------------

        .text

        .balign     4
        .global     define_thread

define_thread:

        lw          t0, %lo (threads_end_pointer) (gp)
        la          t1, after_thread_contexts

        blt         t0, t1, enough_space_for_the_new_thread

define_thread_error_return:

        li          a0, 0  // Error return code
        ret

enough_space_for_the_new_thread:

        // Check we have enough memory for the thread's stack

        lw          t2, %lo (next_thread_stack_bottom) (gp)
        addi        t3, t2, THREAD_STACK_SIZE  // Thread stack top
        la          t4, __stack_top - MAIN_STACK_SIZE
        bgt         t3, t4, define_thread_error_return

        sw          a0, THREAD_CONTEXT_OFFSET_PC (t0)

        // By saving a0 into RA of the context we guarantee
        // that if the thread finishes it loops
        // to the beginning of the thread

        sw          a0, THREAD_CONTEXT_OFFSET_RA (t0)

        sw          t3, THREAD_CONTEXT_OFFSET_SP (t0)

        addi        t5, t0, THREAD_CONTEXT_SIZE
        sw          t5, %lo (threads_end_pointer) (gp)

        li          a0, 1
        ret

//----------------------------------------------------------------------------

        .global     start_running_threads

start_running_threads:

        // Initialize the thread pointer to 0.
        // tp will be changed to thread_contexts after the first interrupt.

        li          tp, 0
//        li          t1,      MIE_MTIE     // Enable timer interrupt
        li          t1, -1
        csrw        mie,     t1

        li      t0, 0x8
        csrs    mstatus, t0 
        ret

//----------------------------------------------------------------------------

        .section    .text.trap_ack
        .global     trap_ack

trap_ack:

        // TODO: Can we guarantee that all exceptions are disabled
        // at this point?
        csrci   mstatus, 0x8 
        
        csrrw       t6, mscratch, t6   // Get trap frame pointer, save t6
        sw          t0, (t6)           // Save t0

        //--------------------------------------------------------------------
        // Check if interrupt

        csrr        t0, mcause         // Read exception cause
        bgez        t0, not_interrupt

        //--------------------------------------------------------------------
        // Check if an external interrupt

        sw          t1, 1 * WORD_SIZE (t6)     
        li          t1, 0x7FFFFFFF
        and         t0, t0, t1                 
        li          t1, 11 
        
        bne         t0, t1, not_timer_interrupt

        //--------------------------------------------------------------------
        // Check if there is more than one thread

        sw          t2, 2 * WORD_SIZE (t6)     // Save t2
        lw          t0, %lo (threads_end_pointer) (gp)
        la          t1, thread_contexts
        addi        t2, t1, 2 * THREAD_CONTEXT_SIZE

        // TODO: consider one thread as a special case

        blt         t0, t2, less_than_two_threads_defined
        j           switch_the_contexts

        //--------------------------------------------------------------------
        // Recovery from no-switching situations.

less_than_two_threads_defined:
        lw          t2, 2 * WORD_SIZE (t6)    // Restore t2
not_timer_interrupt:
        lw          t1, 1 * WORD_SIZE (t6)    // Restore t1
not_interrupt:
        lw          t0, (t6)                  // Restore t0

        csrrw       t6, mscratch, t6          // Put trap frame pointer
                                              // back to mscratch, restore t6
        mret

//----------------------------------------------------------------------------

        .text

switch_the_contexts:

        // Checking if this context switch is not the first one.
        // Before the first context switch the thread pointer is set to 0.

        bne         tp, zero, advance_tp

        // The first context switch, no need to save the context.
        // We have to initialize the thread pointer
        // and restore the program counter
        // which contains the address of the function
        // with the body of the first thread.
        // The program counter is restored in restore_context.

        la          tp, thread_contexts
        j           restore_context

        //--------------------------------------------------------------------
        // Advance the thread pointer,
        // wrapping to thread_contexts
        // once it reaches threads_end_pointer

advance_tp:

        mv          t2, tp
        addi        tp, tp, THREAD_CONTEXT_SIZE
        bne         tp, t0, tp_is_advanced
        mv          tp, t1  // t1 contains thread_contexts

tp_is_advanced:

        //--------------------------------------------------------------------
        // Now t2 is the previous/current thread and tp is the next thread.
        // Let's save all the registers in the previous thread context.

        // Saving registers changed in the trap handler

        lw          t0  , (t6)                // Restore t0
        sw          t0  , THREAD_CONTEXT_OFFSET_T0     (t2)

        lw          t1  , 1 * WORD_SIZE (t6)  // Restore t1
        sw          t1  , THREAD_CONTEXT_OFFSET_T1     (t2)

        lw          t0  , 2 * WORD_SIZE (t6)  // Restore t2 into t0
        sw          t0  , THREAD_CONTEXT_OFFSET_T2     (t2)

        csrr        t1  , mscratch            // Restore t6 into t1
        sw          t1  , THREAD_CONTEXT_OFFSET_T6     (t2)

        // Saving registers not changed in the trap handler.
        // We don't need to save x0 (zero), x3 (gp) and x4 (tp).

        // TODO: use tp to save, change tp afterwards

        sw          ra  , THREAD_CONTEXT_OFFSET_RA     (t2)
        sw          sp  , THREAD_CONTEXT_OFFSET_SP     (t2)
        sw          s0  , THREAD_CONTEXT_OFFSET_S0_FP  (t2)
        sw          s1  , THREAD_CONTEXT_OFFSET_S1     (t2)
        sw          a0  , THREAD_CONTEXT_OFFSET_A0     (t2)
        sw          a1  , THREAD_CONTEXT_OFFSET_A1     (t2)
        sw          a2  , THREAD_CONTEXT_OFFSET_A2     (t2)
        sw          a3  , THREAD_CONTEXT_OFFSET_A3     (t2)
        sw          a4  , THREAD_CONTEXT_OFFSET_A4     (t2)
        sw          a5  , THREAD_CONTEXT_OFFSET_A5     (t2)
        sw          a6  , THREAD_CONTEXT_OFFSET_A6     (t2)
        sw          a7  , THREAD_CONTEXT_OFFSET_A7     (t2)
        sw          s2  , THREAD_CONTEXT_OFFSET_S2     (t2)
        sw          s3  , THREAD_CONTEXT_OFFSET_S3     (t2)
        sw          s4  , THREAD_CONTEXT_OFFSET_S4     (t2)
        sw          s5  , THREAD_CONTEXT_OFFSET_S5     (t2)
        sw          s6  , THREAD_CONTEXT_OFFSET_S6     (t2)
        sw          s7  , THREAD_CONTEXT_OFFSET_S7     (t2)
        sw          s8  , THREAD_CONTEXT_OFFSET_S8     (t2)
        sw          s9  , THREAD_CONTEXT_OFFSET_S9     (t2)
        sw          s10 , THREAD_CONTEXT_OFFSET_S10    (t2)
        sw          s11 , THREAD_CONTEXT_OFFSET_S11    (t2)
        sw          t3  , THREAD_CONTEXT_OFFSET_T3     (t2)
        sw          t4  , THREAD_CONTEXT_OFFSET_T4     (t2)
        sw          t5  , THREAD_CONTEXT_OFFSET_T5     (t2)

        //--------------------------------------------------------------------
        // Save the program counter of the previous/current thread
        // and schedule the restoration of the program counter
        // for the next thread.

        csrr        t0,   mepc    // Program counter before the interrupt
        sw          t0,   THREAD_CONTEXT_OFFSET_PC     (t2)

restore_context:

        csrw        mscratch, t6  // Put trap frame pointer back to mscratch

        lw          t0,   THREAD_CONTEXT_OFFSET_PC     (tp)
        csrw        mepc, t0      // Program counter after mret

        //--------------------------------------------------------------------
        // Restore all the registers for the next thread
        // from the next thread context.
        //
        // We don't need to restore x0 (zero), x3 (gp) and x4 (tp).

        lw          ra  , THREAD_CONTEXT_OFFSET_RA     (tp)
        lw          sp  , THREAD_CONTEXT_OFFSET_SP     (tp)
        lw          t1  , THREAD_CONTEXT_OFFSET_T1     (tp)
        lw          t2  , THREAD_CONTEXT_OFFSET_T2     (tp)
        lw          s0  , THREAD_CONTEXT_OFFSET_S0_FP  (tp)
        lw          s1  , THREAD_CONTEXT_OFFSET_S1     (tp)
        lw          a0  , THREAD_CONTEXT_OFFSET_A0     (tp)
        lw          a1  , THREAD_CONTEXT_OFFSET_A1     (tp)
        lw          a2  , THREAD_CONTEXT_OFFSET_A2     (tp)
        lw          a3  , THREAD_CONTEXT_OFFSET_A3     (tp)
        lw          a4  , THREAD_CONTEXT_OFFSET_A4     (tp)
        lw          a5  , THREAD_CONTEXT_OFFSET_A5     (tp)
        lw          a6  , THREAD_CONTEXT_OFFSET_A6     (tp)
        lw          a7  , THREAD_CONTEXT_OFFSET_A7     (tp)
        lw          s2  , THREAD_CONTEXT_OFFSET_S2     (tp)
        lw          s3  , THREAD_CONTEXT_OFFSET_S3     (tp)
        lw          s4  , THREAD_CONTEXT_OFFSET_S4     (tp)
        lw          s5  , THREAD_CONTEXT_OFFSET_S5     (tp)
        lw          s6  , THREAD_CONTEXT_OFFSET_S6     (tp)
        lw          s7  , THREAD_CONTEXT_OFFSET_S7     (tp)
        lw          s8  , THREAD_CONTEXT_OFFSET_S8     (tp)
        lw          s9  , THREAD_CONTEXT_OFFSET_S9     (tp)
        lw          s10 , THREAD_CONTEXT_OFFSET_S10    (tp)
        lw          s11 , THREAD_CONTEXT_OFFSET_S11    (tp)
        lw          t3  , THREAD_CONTEXT_OFFSET_T3     (tp)
        lw          t4  , THREAD_CONTEXT_OFFSET_T4     (tp)
        lw          t5  , THREAD_CONTEXT_OFFSET_T5     (tp)
        lw          t6  , THREAD_CONTEXT_OFFSET_T6     (tp)

        // TODO: Should we and can we enable the exceptions here?
        lw          t0  , THREAD_CONTEXT_OFFSET_T0     (tp)

        mret
