#include "bgm_femto_threads.h"
#include "memory_mapped_registers.h"

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

void thread_3 ()
{
    // Output to LED

    mmio_led_t led;

    led.w = 0;

    led.b.l0 = (counter_1 & 1) != 0;
    led.b.l1 = (counter_1 & 2) != 0;
    led.b.l2 = (counter_1 & 4) != 0;
    led.b.l3 = (counter_1 & 8) != 0;

    led.b.l4 = (counter_2 & 1) != 0;
    led.b.l5 = (counter_2 & 2) != 0;
    led.b.l6 = (counter_2 & 4) != 0;
    led.b.l7 = (counter_2 & 8) != 0;

    mmio.led = led;

    led.f.l24_0 = ((counter_1 & 0xf) << 4) | (counter_2 & 0xf);
    mmio.led = led;
}

void main ()
{
    define_thread (thread_1);
    define_thread (thread_2);
    define_thread (thread_3);

    start_running_threads ();
    for (;;);
}
