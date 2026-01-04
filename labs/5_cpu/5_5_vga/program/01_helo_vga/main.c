// Use this example to get 
// experience with HEX on differents boards
#include "memory_mapped_registers.h"
#include "seg7.h"
#include <stdint.h>
#include <coremark.h>

#define LED_0   0x1
#define LED_1   0x2
#define LED_2   0x4
#define LED_3   0x8

#define digit_deleay 5000
#define letter_delay 5000

void delay_nop(volatile int count) {
    while (count--) {
        asm("nop");
    }
}

void clean() {
    
    port1 = 0x00;
    port0 = 0x00;

}

void display_char(uint8_t led, uint8_t hex_code) {

    //To avoid blinking and shifting
    // First select HEX
    port1 = led;
    // Second put letter
    port0 = hex_code;
    
    // For boards DE0, DE0-CV with static hexs
    #ifdef STATIC
        clean();
    #endif
}

void H() {
    display_char(LED_3, HEX_H);
    delay_nop(digit_deleay);
}

void E() {
    display_char(LED_2, HEX_E);
    delay_nop(digit_deleay);
}

void L() {
    display_char(LED_1, HEX_L);
    delay_nop(digit_deleay);
}

void O() {
    display_char(LED_0, HEX_O);
    delay_nop(digit_deleay);
}

extern  void cls();

extern  void cls1();

extern  void putc(int x, int y, char c);

void main() {
    cls();
    // VGA[0] = 0x41;
    // VGA[1] = 0x42;
    // VGA[2] = 0x43;
    // VGA[3] = 0x44;
    ee_printf("\n\n\n\n\n\n\n\n\n\n\n\n                              Hello world!!!\n");
    ee_printf("\n\n\n                                  RISC-V\n");
    ee_printf("\n\n\n                             Tang Nano 9k YRV\n");
    ee_printf("\n\n\n\n\n\n\n\n\n \n\n\n\n\n\n\n\n\n\n \n\n\n\n\n\n\n\n\n\n \n\n\n\n\n\n\n\n\n 2026");


    while (1) {
        
        H();
         delay_nop(20000);
        E();
         delay_nop(20000);
        L();
         delay_nop(20000);
        O();
         delay_nop(20000);
    }
}