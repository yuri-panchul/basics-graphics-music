#ifndef BGM_FEMTO_THREADS_H
#define BGM_FEMTO_THREADS_H

//----------------------------------------------------------------------------
// Limits and sizes

#define WORD_SIZE          4
#define MAX_THREADS        8
#define MAIN_STACK_SIZE    128
#define THREAD_STACK_SIZE  128

//----------------------------------------------------------------------------
// The thread context words.
// Most words are used to store registers,
// however we do not need to store x0 (zero), x3 (gp) and x4 (tp),
// so we use the corresponding words for something else.
// Or we don't use them at all to prevent confusing unrelated data
// with the saved registers.

#define THREAD_CONTEXT_WORD_RESERVED_0   0  // We do not to store x0
#define THREAD_CONTEXT_WORD_RA           1
#define THREAD_CONTEXT_WORD_SP           2
#define THREAD_CONTEXT_WORD_RESERVED_3   3  // We do not need to store gp
#define THREAD_CONTEXT_WORD_RESERVED_4   4  // We do not need to store tp
#define THREAD_CONTEXT_WORD_T0           5
#define THREAD_CONTEXT_WORD_T1           6
#define THREAD_CONTEXT_WORD_T2           7
#define THREAD_CONTEXT_WORD_S0_FP        8
#define THREAD_CONTEXT_WORD_S1           9
#define THREAD_CONTEXT_WORD_A0          10
#define THREAD_CONTEXT_WORD_A1          11
#define THREAD_CONTEXT_WORD_A2          12
#define THREAD_CONTEXT_WORD_A3          13
#define THREAD_CONTEXT_WORD_A4          14
#define THREAD_CONTEXT_WORD_A5          15
#define THREAD_CONTEXT_WORD_A6          16
#define THREAD_CONTEXT_WORD_A7          17
#define THREAD_CONTEXT_WORD_S2          18
#define THREAD_CONTEXT_WORD_S3          19
#define THREAD_CONTEXT_WORD_S4          20
#define THREAD_CONTEXT_WORD_S5          21
#define THREAD_CONTEXT_WORD_S6          22
#define THREAD_CONTEXT_WORD_S7          23
#define THREAD_CONTEXT_WORD_S8          24
#define THREAD_CONTEXT_WORD_S9          25
#define THREAD_CONTEXT_WORD_S10         26
#define THREAD_CONTEXT_WORD_S11         27
#define THREAD_CONTEXT_WORD_T3          28
#define THREAD_CONTEXT_WORD_T4          29
#define THREAD_CONTEXT_WORD_T5          30
#define THREAD_CONTEXT_WORD_T6          31
#define THREAD_CONTEXT_WORD_PC          32

#define NUM_THREAD_CONTEXT_WORDS        (THREAD_CONTEXT_WORD_PC + 1)

//----------------------------------------------------------------------------

#define THREAD_CONTEXT_OFFSET_RESERVED_0  ( WORD_SIZE * THREAD_CONTEXT_WORD_RESERVED_0 )  // We do not to store x0
#define THREAD_CONTEXT_OFFSET_RA          ( WORD_SIZE * THREAD_CONTEXT_WORD_RA         )
#define THREAD_CONTEXT_OFFSET_SP          ( WORD_SIZE * THREAD_CONTEXT_WORD_SP         )
#define THREAD_CONTEXT_OFFSET_GP          ( WORD_SIZE * THREAD_CONTEXT_WORD_GP         )
#define THREAD_CONTEXT_OFFSET_RESERVED_4  ( WORD_SIZE * THREAD_CONTEXT_WORD_RESERVED_4 )  // We do not need to store tp
#define THREAD_CONTEXT_OFFSET_T0          ( WORD_SIZE * THREAD_CONTEXT_WORD_T0         )
#define THREAD_CONTEXT_OFFSET_T1          ( WORD_SIZE * THREAD_CONTEXT_WORD_T1         )
#define THREAD_CONTEXT_OFFSET_T2          ( WORD_SIZE * THREAD_CONTEXT_WORD_T2         )
#define THREAD_CONTEXT_OFFSET_S0_FP       ( WORD_SIZE * THREAD_CONTEXT_WORD_S0_FP      )
#define THREAD_CONTEXT_OFFSET_S1          ( WORD_SIZE * THREAD_CONTEXT_WORD_S1         )
#define THREAD_CONTEXT_OFFSET_A0          ( WORD_SIZE * THREAD_CONTEXT_WORD_A0         )
#define THREAD_CONTEXT_OFFSET_A1          ( WORD_SIZE * THREAD_CONTEXT_WORD_A1         )
#define THREAD_CONTEXT_OFFSET_A2          ( WORD_SIZE * THREAD_CONTEXT_WORD_A2         )
#define THREAD_CONTEXT_OFFSET_A3          ( WORD_SIZE * THREAD_CONTEXT_WORD_A3         )
#define THREAD_CONTEXT_OFFSET_A4          ( WORD_SIZE * THREAD_CONTEXT_WORD_A4         )
#define THREAD_CONTEXT_OFFSET_A5          ( WORD_SIZE * THREAD_CONTEXT_WORD_A5         )
#define THREAD_CONTEXT_OFFSET_A6          ( WORD_SIZE * THREAD_CONTEXT_WORD_A6         )
#define THREAD_CONTEXT_OFFSET_A7          ( WORD_SIZE * THREAD_CONTEXT_WORD_A7         )
#define THREAD_CONTEXT_OFFSET_S2          ( WORD_SIZE * THREAD_CONTEXT_WORD_S2         )
#define THREAD_CONTEXT_OFFSET_S3          ( WORD_SIZE * THREAD_CONTEXT_WORD_S3         )
#define THREAD_CONTEXT_OFFSET_S4          ( WORD_SIZE * THREAD_CONTEXT_WORD_S4         )
#define THREAD_CONTEXT_OFFSET_S5          ( WORD_SIZE * THREAD_CONTEXT_WORD_S5         )
#define THREAD_CONTEXT_OFFSET_S6          ( WORD_SIZE * THREAD_CONTEXT_WORD_S6         )
#define THREAD_CONTEXT_OFFSET_S7          ( WORD_SIZE * THREAD_CONTEXT_WORD_S7         )
#define THREAD_CONTEXT_OFFSET_S8          ( WORD_SIZE * THREAD_CONTEXT_WORD_S8         )
#define THREAD_CONTEXT_OFFSET_S9          ( WORD_SIZE * THREAD_CONTEXT_WORD_S9         )
#define THREAD_CONTEXT_OFFSET_S10         ( WORD_SIZE * THREAD_CONTEXT_WORD_S10        )
#define THREAD_CONTEXT_OFFSET_S11         ( WORD_SIZE * THREAD_CONTEXT_WORD_S11        )
#define THREAD_CONTEXT_OFFSET_T3          ( WORD_SIZE * THREAD_CONTEXT_WORD_T3         )
#define THREAD_CONTEXT_OFFSET_T4          ( WORD_SIZE * THREAD_CONTEXT_WORD_T4         )
#define THREAD_CONTEXT_OFFSET_T5          ( WORD_SIZE * THREAD_CONTEXT_WORD_T5         )
#define THREAD_CONTEXT_OFFSET_T6          ( WORD_SIZE * THREAD_CONTEXT_WORD_T6         )
#define THREAD_CONTEXT_OFFSET_PC          ( WORD_SIZE * THREAD_CONTEXT_WORD_PC         )

#define THREAD_CONTEXT_SIZE               ( WORD_SIZE * NUM_THREAD_CONTEXT_WORDS       )

//----------------------------------------------------------------------------

#ifndef __ASSEMBLER__

typedef void (* pointer_to_void_function_no_arguments) ();

extern bool define_thread (void (* func) ());
extern bool define_thread (pointer_to_void_function_no_arguments func);

extern void start_running_threads ();

#endif  // #ifndef __ASSEMBLER__

#endif  // #ifndef BGM_FEMTO_THREADS_H
