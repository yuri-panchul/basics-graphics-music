#include "bgm_femto_threads.h"
#include "csr_masks.h"


.macro SAVE_TO_SCRATCH_T0
        csrrw       t6, mscratch, t6
        sw          t0, 0(t6)   
        sw          t1, 4(t6)   
        sw          t2, 8(t6)   
        csrr        t0, mscratch  
        sw          t0, 4(t6)
        csrw        mscratch, t6 
.endm

.macro RESTORE_FROM_SCRATCH_T0
        lw          t1, 4(t6)   
        lw          t2, 8(t6)           
        lw          t0, 0(t6)   
        lw          t6, 4(t6)    
        csrw        mscratch, t6 
        csrrw       t6, mscratch, t6
.endm


//----------------------------------------------------------------------------

        .bss
        .balign     4

thread_contexts:
        .space      MAX_THREADS * THREAD_CONTEXT_SIZE

after_thread_contexts:

//----------------------------------------------------------------------------

// For whatever reason GCC version we use does not recognize ".sdata"
// and requires writing ".section .sdata".

        .section    .sdata
        .balign     4

threads_end_pointer:
        .word       thread_contexts

//----------------------------------------------------------------------------

        .text

        .balign     4
        .global     define_thread

define_thread:

        bne         tp, zero, tp_defined
        la          tp, thread_contexts

tp_defined:

        lw          t0, %lo (threads_end_pointer) (gp)
        la          t1, after_thread_contexts

        blt         t0, t1, enough_space_for_new_thread
        li          a0, 0  // Error return
        ret

enough_space_for_new_thread:

        sw          a0, THREAD_CONTEXT_OFFSET_PC (t0)
        la          t3, __IDLE
        sw          t3, THREAD_CONTEXT_OFFSET_RA     (t0)
        addi        t2, t0, THREAD_CONTEXT_SIZE
        sw          t2, %lo (threads_end_pointer) (gp)

        li          a0, 1
        ret

//----------------------------------------------------------------------------

        .global     start_running_threads

start_running_threads:

        // Initialize the thread pointer to 0.
        // tp will be changed to thread_contexts after the first interrupt.
        mv          tp, zero
        
        li          t1,      MIP_MTIP     // Enable timer interrupt
        csrw        mip,     t1

        csrwi       mstatus, MSTATUS_MIE  // Enable interrupts
        ret

//----------------------------------------------------------------------------

        .section    .text.trap_ack
        .global     trap_ack

trap_ack:

        // Это код прерываний и мы не знаем откуда пришел вызов
        // Поэтому для временного хранения используем mscratch
        // mscratch ВСЕГДА содержит адрес __trapframe кроме коротких промежутков

        SAVE_TO_SCRATCH_T0
        
        //--------------------------------------------------------------------
        // Check if interrupt

        csrr        t0, mcause         // read exception cause
        bgez        t0, not_interrupt

        //--------------------------------------------------------------------
        // Check if a timer interrupt

        li          t1, MCAUSE_EXCCODE_MASK
        and         t0, t0, t1         // isolate interrupt cause
        li          t1, MCAUSE_EXCCODE_MACHINE_TIMER_INTERRUPT
        bne         t0, t1, not_timer_interrupt

        //--------------------------------------------------------------------
        // Check if there is more than one thread
        // TODO
        la          t1, switch_the_contexts
        jalr        zero, 0(t1)
        //--------------------------------------------------------------------
        // Recovery from no-switching situations.

less_than_two_threads_defined:
not_timer_interrupt:
not_interrupt:
        
        RESTORE_FROM_SCRATCH_T0
        mret

//----------------------------------------------------------------------------

        .text

switch_the_contexts:

        // Checking if this context switch is not the first one.
        // Before the first context switch the thread pointer is set to 0.
      
        bne         tp, zero, already_started
        la          tp, thread_contexts
        j tp_round_robin
 
 
 already_started:        
        
        //--------------------------------------------------------------------
        // Advance the thread pointer,
        // wrapping to thread_contexts
        // once it reaches threads_end_pointer

        mv          t2, tp
        addi        tp, tp, THREAD_CONTEXT_SIZE        
        lw          t1, %lo (threads_end_pointer) (gp)
        blt         tp, t1, tp_round_robin
        la          tp, thread_contexts 
 
 tp_round_robin:   

        lw          t0, THREAD_CONTEXT_OFFSET_TS (t2)  //Статус текущего потока 0 неактивен 1 активен
        bne         t0, zero, save_context // Если поток активен статус отличается от 0 

        // The first context switch, no need to save the context.
        // We have to initialize the thread pointer
        // and restore the program counter
        // which contains the address of the function
        // with the body of the first thread.
        // The program counter is restored in restore_context.       
        // Set thread state running
        

        j           restore_context



save_context:

        //--------------------------------------------------------------------
        // Now t2 is the previous/current thread and tp is the next thread.
        // Let's save all the registers in the previous thread context.

        sw            ra  , THREAD_CONTEXT_OFFSET_RA     (t2)
        sw            sp  , THREAD_CONTEXT_OFFSET_SP     (t2)
        sw            gp  , THREAD_CONTEXT_OFFSET_GP     (t2)

        // In interrupt mode t6 hold mscratch
        lw            t1  , 0(t6)                        // saved t0
        sw            t1  , THREAD_CONTEXT_OFFSET_T0     (t2)

        lw            t1  , 4(t6)                        // saved t1
        sw            t1  , THREAD_CONTEXT_OFFSET_T1     (t2)

        lw            t1  , 8(t6)                        // saved t2
        sw            t1  , THREAD_CONTEXT_OFFSET_T2     (t2)

        lw            t1  , 12(t6)                       // saved t6
        sw            t1  , THREAD_CONTEXT_OFFSET_T6     (t2)

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

        //--------------------------------------------------------------------
        // Save the program counter of the previous/current thread
        // and schedule the restoration of the program counter
        // for the next thread.

        csrr          t0,   mepc  // Program counter before the interrupt
        sw            t0,   THREAD_CONTEXT_OFFSET_PC     (t2)

        li            t0,   2
        sw            t0,   THREAD_CONTEXT_OFFSET_TS     (t2)

restore_context:

        // Будим поток 
        li            t0  , 1
        sw            t0  , THREAD_CONTEXT_OFFSET_TS     (tp)

        lw            t0,   THREAD_CONTEXT_OFFSET_PC     (tp)
        csrw          mepc, t0    // Program counter after mret

        //--------------------------------------------------------------------
        // Restore all the registers for the next thread
        // from the next thread context.

        lw            ra  , THREAD_CONTEXT_OFFSET_RA     (tp)
        lw            sp  , THREAD_CONTEXT_OFFSET_SP     (tp)
        lw            gp  , THREAD_CONTEXT_OFFSET_GP     (tp)
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
        
        // NEDD REVIEW
        li          t0, MSTATUS_MIE
        csrs        mie, t0
        csrs        mstatus, t0
        lw          t0  , THREAD_CONTEXT_OFFSET_T0     (tp)

        mret
