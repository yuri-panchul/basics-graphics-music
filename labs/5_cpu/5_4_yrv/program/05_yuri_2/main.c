#include "bgm_pico_threads.h"
#include "memory_mapped_registers.h"

void f ()
{
    for (;;);
}

int counter_1 = 0;

void thread_1 ()
{
    counter_1 ++;
}

int counter_2 = 0;

void thread_2 ()
{
    counter_2 ++;
}

int counter_3 = 0;

void thread_3 ()
{
    counter_3 ++;
}

void main ()
{
    define_thread (thread_1);
    define_thread (thread_2);
    define_thread (thread_3);

    start_running_threads ();
}
