#include "bgm_femto_threads.h"
#include "memory_mapped_registers.h"
#include "seg7.h"

  static  uint32_t half=0;

uint8_t inline char_to_hex(uint32_t c) {
    switch(c) {
        case 0: return HEX_0;
        case 1: return HEX_1;
        case 2: return HEX_2;
        case 3: return HEX_3;
        case 4: return HEX_4;
        case 5: return HEX_5;
        case 6: return HEX_6;
        case 7: return HEX_7;
        case 8: return HEX_8;
        case 9: return HEX_9;
        default: return HEX_MINUS;
    }
}

//Hacker's Delight (need review)
static inline uint32_t div10(uint32_t in) {
    register uint32_t triple = (in << 1) + in;                
    register  uint32_t fifty_one = (triple << 4) + triple;     
    register  uint32_t two_hundred_five = (fifty_one << 2) + in; 
    return two_hundred_five >> 11;                   
}

static inline uint32_t mul10(uint32_t in) {
    return (in << 3) + (in << 1);
}

int counter_1 = 0;

void thread_1 ()
{
    counter_1 = counter_1 <100? counter_1+1 : 0;
}

int counter_2 = 0;

void thread_2 ()
{
    counter_2  = counter_2 <100? counter_2+1 : 0;
}

void thread_3 ()
{
    half = half?0:1;
    register uint32_t counter = div10(half?counter_2:counter_1);
    register uint8_t hex_code = char_to_hex(counter);
    MMIO_LED = half?LED_3:LED_1;
    MMIO_7SEG = hex_code;
    for(register uint32_t delay = 0; delay < 100; delay++);
    MMIO_LED = 0x00;
    MMIO_7SEG = 0x00;

    counter = (half?counter_2:counter_1) - mul10(counter);
    hex_code = char_to_hex(counter);
    MMIO_LED = half?LED_2:LED_0;
    MMIO_7SEG = hex_code;
    for(register uint32_t delay = 0; delay < 100; delay++);
    MMIO_LED = 0x00;
    MMIO_7SEG = 0x00;
    
    
}


void main ()
{
    define_thread (thread_1);
    define_thread (thread_2);
    define_thread (thread_3);

    start_running_threads ();
    for (;;);
}
