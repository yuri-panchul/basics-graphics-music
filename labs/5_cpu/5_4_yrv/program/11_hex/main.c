#include "memory_mapped_registers.h"
#include "bgm_femto_threads.h"
#include "seg7.h"

static  uint32_t half=0;

uint8_t char_to_hex(uint32_t c) {
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

// Hacker's Delight 
// valid until in in 0 .. 255
uint32_t div10(uint32_t in) {
    uint32_t triple = (in << 1) + in;                
    uint32_t fifty_one = (triple << 4) + triple;     
    uint32_t two_hundred_five = (fifty_one << 2) + in; 
    return two_hundred_five >> 11;                   
}

static inline uint32_t mul10(uint32_t in) {
    return (in << 3) + (in << 1);
}

volatile int counter_1 = 0;
int counter_1_div = 0;

void thread_1 ()
{
    if(++counter_1_div == 1000000) {
        counter_1  = counter_1 < 99 ? counter_1 + 1 : 0;
        counter_1_div = 0;
    } 
}

volatile int counter_2 = 99;
int counter_2_div = 0;

void thread_2 ()
{
    if (++counter_2_div < 100000) return;
    counter_2_div = 0;
    counter_2 = (counter_2 > 0) ? counter_2 - 1 : 99;
}


void display_digit(uint8_t anode_mask, uint8_t digit_value) {
    uint8_t hex_code = char_to_hex(digit_value);
    mmio.seven_seg.h.anode = anode_mask;
    mmio.seven_seg.h.hex = hex_code;
    
    //For SPI delay or hex light
    for (volatile int delay = 0; delay < 100; delay++);
}

void thread_3() { 
    int c1_tens = div10(counter_1);
    int c1_ones = counter_1 - mul10(c1_tens);
    
    int c2_tens = div10(counter_2);
    int c2_ones = counter_2 - mul10(c2_tens);
    
    display_digit(0, 0);
    display_digit(1, c1_ones); 
    display_digit(2, c1_tens); 
    display_digit(4, c2_ones); 
    display_digit(8, c2_tens); 
}




void main ()
{
    define_thread (thread_1);
    define_thread (thread_2);
    define_thread (thread_3);

    start_running_threads ();

    for (;;);
}
