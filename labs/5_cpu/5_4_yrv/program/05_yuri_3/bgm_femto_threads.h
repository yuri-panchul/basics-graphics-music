#ifndef BGM_FEMTO_THREADS_H
#define BGM_FEMTO_THREADS_H

//----------------------------------------------------------------------------
//  The context words.
//  Most words are used to store registers,
//  however we do not need to store x0 (zero) and x4 (tp),
//  so we use the corresponding words for something else.

#define bft_context_word_reserved_0   0  // We do not to store x0
#define bft_context_word_reg_ra       1
#define bft_context_word_reg_sp       2
#define bft_context_word_reg_gp       3
#define bft_context_word_reserved_1   4  // We do not need to store tp
#define bft_context_word_reg_t0       5
#define bft_context_word_reg_t1       6
#define bft_context_word_reg_t2       7
#define bft_context_word_reg_s0_fp    8
#define bft_context_word_reg_s1       9
#define bft_context_word_reg_a0      10
#define bft_context_word_reg_a1      11
#define bft_context_word_reg_a2      12
#define bft_context_word_reg_a3      13
#define bft_context_word_reg_a4      14
#define bft_context_word_reg_a5      15
#define bft_context_word_reg_a6      16
#define bft_context_word_reg_a7      17
#define bft_context_word_reg_s2      18
#define bft_context_word_reg_s3      19
#define bft_context_word_reg_s4      20
#define bft_context_word_reg_s5      21
#define bft_context_word_reg_s6      22
#define bft_context_word_reg_s7      23
#define bft_context_word_reg_s8      24
#define bft_context_word_reg_s9      25
#define bft_context_word_reg_s10     26
#define bft_context_word_reg_s11     27
#define bft_context_word_reg_t3      28
#define bft_context_word_reg_t4      29
#define bft_context_word_reg_t5      30
#define bft_context_word_reg_t6      31
#define bft_context_word_reg_pc      32

#define bft_num_context_words        (bft_context_word_reg_pc + 1)

//----------------------------------------------------------------------------

#define bft_num_word_bytes  4

//----------------------------------------------------------------------------

#define bft_context_offset_reserved_0  ( bft_num_word_bytes * bft_context_word_reserved_0 )  // We do not to store x0
#define bft_context_offset_reg_ra      ( bft_num_word_bytes * bft_context_word_reg_ra     )
#define bft_context_offset_reg_sp      ( bft_num_word_bytes * bft_context_word_reg_sp     )
#define bft_context_offset_reg_gp      ( bft_num_word_bytes * bft_context_word_reg_gp     )
#define bft_context_offset_reserved_1  ( bft_num_word_bytes * bft_context_word_reserved_1 )  // We do not need to store tp
#define bft_context_offset_reg_t0      ( bft_num_word_bytes * bft_context_word_reg_t0     )
#define bft_context_offset_reg_t1      ( bft_num_word_bytes * bft_context_word_reg_t1     )
#define bft_context_offset_reg_t2      ( bft_num_word_bytes * bft_context_word_reg_t2     )
#define bft_context_offset_reg_s0_fp   ( bft_num_word_bytes * bft_context_word_reg_s0_fp  )
#define bft_context_offset_reg_s1      ( bft_num_word_bytes * bft_context_word_reg_s1     )
#define bft_context_offset_reg_a0      ( bft_num_word_bytes * bft_context_word_reg_a0     )
#define bft_context_offset_reg_a1      ( bft_num_word_bytes * bft_context_word_reg_a1     )
#define bft_context_offset_reg_a2      ( bft_num_word_bytes * bft_context_word_reg_a2     )
#define bft_context_offset_reg_a3      ( bft_num_word_bytes * bft_context_word_reg_a3     )
#define bft_context_offset_reg_a4      ( bft_num_word_bytes * bft_context_word_reg_a4     )
#define bft_context_offset_reg_a5      ( bft_num_word_bytes * bft_context_word_reg_a5     )
#define bft_context_offset_reg_a6      ( bft_num_word_bytes * bft_context_word_reg_a6     )
#define bft_context_offset_reg_a7      ( bft_num_word_bytes * bft_context_word_reg_a7     )
#define bft_context_offset_reg_s2      ( bft_num_word_bytes * bft_context_word_reg_s2     )
#define bft_context_offset_reg_s3      ( bft_num_word_bytes * bft_context_word_reg_s3     )
#define bft_context_offset_reg_s4      ( bft_num_word_bytes * bft_context_word_reg_s4     )
#define bft_context_offset_reg_s5      ( bft_num_word_bytes * bft_context_word_reg_s5     )
#define bft_context_offset_reg_s6      ( bft_num_word_bytes * bft_context_word_reg_s6     )
#define bft_context_offset_reg_s7      ( bft_num_word_bytes * bft_context_word_reg_s7     )
#define bft_context_offset_reg_s8      ( bft_num_word_bytes * bft_context_word_reg_s8     )
#define bft_context_offset_reg_s9      ( bft_num_word_bytes * bft_context_word_reg_s9     )
#define bft_context_offset_reg_s10     ( bft_num_word_bytes * bft_context_word_reg_s10    )
#define bft_context_offset_reg_s11     ( bft_num_word_bytes * bft_context_word_reg_s11    )
#define bft_context_offset_reg_t3      ( bft_num_word_bytes * bft_context_word_reg_t3     )
#define bft_context_offset_reg_t4      ( bft_num_word_bytes * bft_context_word_reg_t4     )
#define bft_context_offset_reg_t5      ( bft_num_word_bytes * bft_context_word_reg_t5     )
#define bft_context_offset_reg_t6      ( bft_num_word_bytes * bft_context_word_reg_t6     )
#define bft_context_offset_reg_pc      ( bft_num_word_bytes * bft_context_word_reg_pc     )

#define bft_context_size               ( bft_num_word_bytes * bft_num_context_words       )

//----------------------------------------------------------------------------

#ifndef __ASSEMBLER__

typedef void (* pointer_to_void_function_no_arguments) ();

extern bool define_thread (void (* func) ());
extern bool define_thread (pointer_to_void_function_no_arguments func);

extern void start_running_threads ();

#endif  // #ifndef __ASSEMBLER__

#endif  // #ifndef BGM_FEMTO_THREADS_H
