#include "memory_mapped_registers.h"
#include "seg7.h"
#include <stdint.h>

#define LED_0   0x1
#define LED_1   0x2
#define LED_2   0x4
#define LED_3   0x8

void delay_nop(volatile int count) {
    while (count--) {
        asm("nop");
    }
}

void clean() {
    port0 = 0x00;
    port1 = 0x00;
}

void display_char(uint8_t led, uint8_t hex_code) {
    port0 = hex_code;
    port1 = led;
}

void H() {
    display_char(LED_3, HEX_H);
    delay_nop(50000);
    clean();
}

void E() {
    display_char(LED_2, HEX_E);
    delay_nop(50000);
    clean();
}

void L() {
    display_char(LED_1, HEX_L);
    delay_nop(50000);
    clean();
}

void O() {
    display_char(LED_0, HEX_O);
    delay_nop(50000);
    clean();
}

void main() {
    while (1) {
        H();
        delay_nop(20000);
        E();
        delay_nop(20000);
        L();
        delay_nop(20000);
        O();
        delay_nop(20000);
        L();
        delay_nop(20000);
        O();
        delay_nop(80000);  