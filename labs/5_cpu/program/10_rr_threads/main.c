#include "memory_mapped_registers.h"
#include "bgm_rr_threads.h"

int counter_1 = 1;

void thread_1 ()
{
    // mmio.led.f.l24_0 = 1;
    MMIO_LED = 1;
    counter_1 ++;
}

int counter_2 = 2;

void thread_2 ()
{
    MMIO_LED = 2;
    counter_2 ++;
}

void thread_3 ()
{
    MMIO_LED = 3;

    /*
    mmio.led.f.l24_0
      =   (((counter_1 >> 15) & 0xf) << 4)
        |  ((counter_2 >> 15) & 0xf);
    */
}

void main ()
{
    rr_thread_define (thread_1);
    rr_thread_define (thread_2);
    rr_thread_define (thread_3);

    rr_threads_start_running_all ();

    for (;;);
}
