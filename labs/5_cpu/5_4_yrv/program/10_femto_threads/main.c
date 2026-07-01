#include "memory_mapped_registers.h"
#include "bgm_femto_threads.h"

int counter_1 = 1;

void thread_1 ()
{
    mmio.led.f.l24_0 = 1;
    counter_1 ++;
}

int counter_2 = 2;

void thread_2 ()
{
    mmio.led.f.l24_0 = 2;
    counter_2 ++;
}

void thread_3 ()
{
    mmio.led.f.l24_0 = 3;

    /*
    mmio.led.f.l24_0
      =   (((counter_1 >> 15) & 0xf) << 4)
        |  ((counter_2 >> 15) & 0xf);
    */
}

void main ()
{
    define_thread (thread_1);
    define_thread (thread_2);
    define_thread (thread_3);

    start_running_threads ();

    for (;;);
}
