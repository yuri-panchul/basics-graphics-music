#include "memory_mapped_registers.h"
#include <stdint.h>

#define LED_0   0x1
#define LED_1   0x2
#define LED_2   0x4
#define LED_3   0x8

 //------------------------------------------------------------------------

#ifndef SEG7_H
#define SEG7_H

// Сегменты индикатора (7-сегментный + точка)
//     a
//    ---
//  f|   |b
//   | g |
//    ---
//  e|   |c
//   |   |
//    ---
//     d     h (точка)

// Коды для символов (активный сегмент = 1)
#define HEX_0         0b01111110  // abcdef
#define HEX_1         0b00001100  // bc
#define HEX_2         0b01011011  // abged
#define HEX_3         0b01001111  // abgcd
#define HEX_4         0b00101101  // fgbc
#define HEX_5         0b01101101  // afgcd
#define HEX_6         0b01111101  // afgcde
#define HEX_7         0b00001110  // abc
#define HEX_8         0b01111111  // abcdefg
#define HEX_9         0b01101111  // abcdfg

#define HEX_A         0b01110111  // abcefg
#define HEX_B         0b01111100  // cdefg
#define HEX_C         0b01001110  // afed
#define HEX_D         0b00111101  // bcdeg
#define HEX_E         0b01001111  // afged
#define HEX_F         0b01000111  // afge

#define HEX_H         0b00110111  // bcdef  
#define HEX_L         0b00001110  // fed
#define HEX_O         0b01111110  // abcdef
#define HEX_P         0b01100111  // abefg
#define HEX_R         0b00100101  // efg
#define HEX_S         0b01101101  // afcdg
#define HEX_U         0b00111110  // bcdef
#define HEX_Y         0b00101101  // bcfg

#define HEX_SPACE     0b00000000
#define HEX_MINUS     0b00000100  // g


#define HEX_a         0b01011101  // abcdeg
#define HEX_b         0b01111100  // cdefg
#define HEX_c         0b01011000  // deg
#define HEX_d         0b01111001  // bcdeg
#define HEX_e         0b01011011  // abged
#define HEX_f         0b01000111  // afge
#define HEX_g         0b01101101  // afcdg
#define HEX_h         0b00110101  // cefg
#define HEX_i         0b00001000  // c
#define HEX_j         0b00001001  // c
#define HEX_l         0b00001100  // cd
#define HEX_n         0b00110100  // cef
#define HEX_o         0b01111000  // cdeg
#define HEX_p         0b01100111  // abefg
#define HEX_q         0b01101110  // abcfg
#define HEX_r         0b00100100  // ef
#define HEX_t         0b01001100  // fged
#define HEX_u         0b00111000  // cde
#define HEX_y         0b00101101  // bcfg


#define HEX_DOT       0b10000000

#define HEX_0_DOT     (HEX_0 | HEX_DOT)
#define HEX_1_DOT     (HEX_1 | HEX_DOT)
#define HEX_2_DOT     (HEX_2 | HEX_DOT)
#define HEX_3_DOT     (HEX_3 | HEX_DOT)
#define HEX_4_DOT     (HEX_4 | HEX_DOT)
#define HEX_5_DOT     (HEX_5 | HEX_DOT)
#define HEX_6_DOT     (HEX_6 | HEX_DOT)
#define HEX_7_DOT     (HEX_7 | HEX_DOT)
#define HEX_8_DOT     (HEX_8 | HEX_DOT)
#define HEX_9_DOT     (HEX_9 | HEX_DOT)
#define HEX_A_DOT     (HEX_A | HEX_DOT)
#define HEX_H_DOT     (HEX_H | HEX_DOT)
#define HEX_L_DOT     (HEX_L | HEX_DOT)
#define HEX_O_DOT     (HEX_O | HEX_DOT)

#endif

// #define HEX_H   0b11001000
// #define HEX_E   0b10110000
// #define HEX_L   0b11110001
// #define HEX_O   0b10000001

/*
0x00010000 port0 = {8'bxxxxxxxx, RDP, RA, RB, RC, RD, RE, RF, RG}
0x00010002 port1 = {4'bxxxx, C46, C45, C43, C42, 4'bxxxx, AN4, AN3, AN2, AN1}
0x00010004 port2 = L[16:1]
0x00010006 port3 = {CLR_EI, 1'bx, INIT, ECALL, NMI, LINT, INT, EXCEPT, L[24:17]}
0x00010008 port4 = DIP[16:1]
0x0001000a port5 = {C9, C8, C6, S5, S4, S3, S2, S1, DIP[24:17]}
0x0001000c port6 = {DIV_RATE, S_RESET, 3'bxxx}
0x0001000e port7 = {4'bxxxx, EMPTY, DONE, FULL, OVR, SER_DATA}
*/




uint32_t clock;

void sleep();

void long_sleep();

void very_long_sleep();


void clean();

void H();

void E();

void L();

void O();

void HELO(int state);

int next(int prev, int step);


short time();

void main() {
    clean();
    int state = 0;
    int step = 3;

    while (1) {
         HELO(state);
         state = next(state, step);
    }
}


void sleep() {
    for (int i = 0; i < 100; i++) {
        clock++;
    }
}

void long_sleep() {
    for (int i = 0; i < 2000; i++) {
        clock++;
    }
}

void very_long_sleep() {
    for (int i = 0; i < 60000; i++) {
        asm("nop");
    }
}


void clean() {
     port0 = 0x00;
     port1 = 0x0;

}

void H() {
    port1 = LED_3;
    port0 = HEX_H;
    sleep();
    clean();
}

void E() {
    port1 = LED_2;
    port0 = HEX_E;
    sleep();
    clean();
}

void L() {
    port1 = LED_1;
    port0 = HEX_L;
    sleep();
    clean();
}

void O() {
    port1 = LED_0;
    port0 = HEX_O;
    sleep();
    clean();
}

void HELO(int state) {
    if (state > 50000) H();
    if (state > 40000) E();
    if (state > 30000) L();
    if (state > 20000) O();
}

int next(int prev, int step) {
    if (prev > 60000) prev = 0;
    return prev + step;
}

short time() {
    return port5;
}