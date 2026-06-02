#ifndef BGM_PICO_THREADS_H
#define BGM_PICO_THREADS_H

#define MAX_THREADS  8

#ifndef __ASSEMBLER__

typedef void (* pointer_to_void_function_no_arguments) ();

extern bool define_thread (void (* func) ());
extern bool define_thread (pointer_to_void_function_no_arguments func);

extern void start_running_threads ();

#endif  // #ifndef __ASSEMBLER__
#endif  // #ifndef BGM_PICO_THREADS_H
