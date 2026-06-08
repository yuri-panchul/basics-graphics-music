#ifndef BGM_FEMTO_THREADS_H
#define BGM_FEMTO_THREADS_H

//----------------------------------------------------------------------------
//  Limits and sizes

#define max_threads  8
#define word_size    4

//----------------------------------------------------------------------------
//  The context words.
//  Most words are used to store registers,
//  however we do not need to store x0 (zero) and x4 (tp),
//  so we use the corresponding words for something else.

#define context_word_reserved_0   0  // We do not to store x0
#define context_word_ra           1
#define context_word_sp           2
#define context_word_gp           3
#define context_word_reserved_4   4  // We do not need to store tp
#define context_word_t0           5
#define context_word_t1           6
#define context_word_t2           7
#define context_word_s0_fp        8
#define context_word_s1           9
#define context_word_a0          10
#define context_word_a1          11
#define context_word_a2          12
#define context_word_a3          13
#define context_word_a4          14
#define context_word_a5          15
#define context_word_a6          16
#define context_word_a7          17
#define context_word_s2          18
#define context_word_s3          19
#define context_word_s4          20
#define context_word_s5          21
#define context_word_s6          22
#define context_word_s7          23
#define context_word_s8          24
#define context_word_s9          25
#define context_word_s10         26
#define context_word_s11         27
#define context_word_t3          28
#define context_word_t4          29
#define context_word_t5          30
#define context_word_t6          31
#define context_word_pc          32

#define num_context_words        (context_word_pc + 1)

//----------------------------------------------------------------------------

#define context_offset_reserved_0  ( word_size * context_word_reserved_0 )  // We do not to store x0
#define context_offset_ra          ( word_size * context_word_ra         )
#define context_offset_sp          ( word_size * context_word_sp         )
#define context_offset_gp          ( word_size * context_word_gp         )
#define context_offset_reserved_4  ( word_size * context_word_reserved_4 )  // We do not need to store tp
#define context_offset_t0          ( word_size * context_word_t0         )
#define context_offset_t1          ( word_size * context_word_t1         )
#define context_offset_t2          ( word_size * context_word_t2         )
#define context_offset_s0_fp       ( word_size * context_word_s0_fp      )
#define context_offset_s1          ( word_size * context_word_s1         )
#define context_offset_a0          ( word_size * context_word_a0         )
#define context_offset_a1          ( word_size * context_word_a1         )
#define context_offset_a2          ( word_size * context_word_a2         )
#define context_offset_a3          ( word_size * context_word_a3         )
#define context_offset_a4          ( word_size * context_word_a4         )
#define context_offset_a5          ( word_size * context_word_a5         )
#define context_offset_a6          ( word_size * context_word_a6         )
#define context_offset_a7          ( word_size * context_word_a7         )
#define context_offset_s2          ( word_size * context_word_s2         )
#define context_offset_s3          ( word_size * context_word_s3         )
#define context_offset_s4          ( word_size * context_word_s4         )
#define context_offset_s5          ( word_size * context_word_s5         )
#define context_offset_s6          ( word_size * context_word_s6         )
#define context_offset_s7          ( word_size * context_word_s7         )
#define context_offset_s8          ( word_size * context_word_s8         )
#define context_offset_s9          ( word_size * context_word_s9         )
#define context_offset_s10         ( word_size * context_word_s10        )
#define context_offset_s11         ( word_size * context_word_s11        )
#define context_offset_t3          ( word_size * context_word_t3         )
#define context_offset_t4          ( word_size * context_word_t4         )
#define context_offset_t5          ( word_size * context_word_t5         )
#define context_offset_t6          ( word_size * context_word_t6         )
#define context_offset_pc          ( word_size * context_word_pc         )

#define context_size               ( word_size * num_context_words       )

//----------------------------------------------------------------------------

#ifndef __ASSEMBLER__

typedef void (* pointer_to_void_function_no_arguments) ();

extern bool define_thread (void (* func) ());
extern bool define_thread (pointer_to_void_function_no_arguments func);

extern void start_running_threads ();

#endif  // #ifndef __ASSEMBLER__

#endif  // #ifndef BGM_FEMTO_THREADS_H
