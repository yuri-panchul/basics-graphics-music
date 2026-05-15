#include "memory_mapped_registers.h"
#include "seg7.h"
#include <stdint.h>

#define LED_0   0x1
#define LED_1   0x2
#define LED_2   0x4
#define LED_3   0x8
#define FRAME_LIMIT 1000  // SPEED OF STRING

uint8_t char_to_hex(char c);


void marquee_string(const char* str) {
    static int pos = 0;
    static int frame_counter = 0;
    static int digit = 0;

    uint8_t anodes[4] = {LED_3, LED_2, LED_1, LED_0};
    int len = 0;


    while(str[len] != '\0') len++;
    if(len < 4) len = 4;

    frame_counter++;
    if(frame_counter >= FRAME_LIMIT) {
        frame_counter = 0;
        pos++;
        if(pos > len) {
            for(int i = 0; i < 4; i++) {
        
                // IT NEED FOR ORRECT TM1638
                // AT FIRST SELECT HEX!
                port1 = anodes[i];
                port0 = HEX_SPACE;
                for(volatile int d = 0; d < 50; d++);
            
                port1 = 0x00;
                port0 = 0x00;
                for(volatile int d = 0; d < 10; d++);
            }
            pos = -3;
        }
    }

    char c;
    int char_pos = pos + digit;

    if(char_pos < 0 || char_pos >= len) {
        c = ' ';
    } else {
        c = str[char_pos];
    }

    port1 = anodes[digit];
    port0 = char_to_hex(c);
    

    for(volatile int delay = 0; delay < 500; delay++);

    port1 = 0x00;
    port0 = 0x00;

    digit = (digit + 1) & 0x3;
}

uint8_t char_to_hex(char c) {
    switch(c) {
        case ' ': return HEX_SPACE;
        case 'A': case 'a': return HEX_A;
        case 'B': case 'b': return HEX_B;
        case 'C': case 'c': return HEX_C;
        case 'D': case 'd': return HEX_D;
        case 'E': case 'e': return HEX_E;
        case 'F': case 'f': return HEX_F;
        case 'H': case 'h': return HEX_H;
        case 'L': case 'l': return HEX_L;
        case 'O': case 'o': return HEX_O;
        case 'P': case 'p': return HEX_P;
        case 'R': case 'r': return HEX_R;
        case 'S': case 's': return HEX_S;
        case 'U': case 'u': return HEX_U;
        case 'Y': case 'y': return HEX_Y;
        case '0': return HEX_0;
        case '1': return HEX_1;
        case '2': return HEX_2;
        case '3': return HEX_3;
        case '4': return HEX_4;
        case '5': return HEX_5;
        case '6': return HEX_6;
        case '7': return HEX_7;
        case '8': return HEX_8;
        case '9': return HEX_9;
        default: return HEX_MINUS;
    }
}

void main() {
    const char message[] = "HELLO ALL PPL";

    while(1) {
        marquee_string(message);
    }
}