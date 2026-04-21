#include "memory_mapped_registers.h"
#include "seg7.h"
#include <stdint.h>
#include <string.h>

// Hex numbers
#define LED_0   0x1
#define LED_1   0x2
#define LED_2   0x4
#define LED_3   0x8
#define LED_4   0x10
#define LED_5   0x20
#define LED_6   0x40
#define LED_7   0x80



// Shift delay
#define FRAME_LIMIT 1000 

// Message
 char message[] = "HELLO ALL PPL";

// String legth 
size_t message_len = sizeof(message)-1;

// Global vars
static int call_count = 0;  
static int pos = 0;          

// HEXs
const uint8_t anodes[8] = {LED_7,LED_6,LED_5,LED_4,LED_3, LED_2, LED_1, LED_0};

// DIRECT INTERRUPT HANDLER
//Change two first letter when interrupt
void __attribute__ ((interrupt )) trap_function_handler()  {
    message[0]='E';
    message[1]='H';
}

// Convert to HEX
uint8_t char_to_hex(char c) {
    switch (c) {
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

// Shift string
void shift_message() {
    if (call_count >= FRAME_LIMIT) {
        pos++;                         
        if (pos > message_len + 7) {     
            pos = 0;                    
        }
        call_count = 0;                 
    }
    call_count++;                         
}

//Show string
void display_current_chars() {
    for (int digit = 0; digit < 8; ++digit) { 
        char c;
        int char_pos = pos + digit;
        if (char_pos < 0 || char_pos >= message_len) {
            c = ' ';
        } else {
            c = message[char_pos];
        }

        // Show digit
        port1 = anodes[digit];    
        port0 = char_to_hex(c);    

        // Wailtin for light
        for (volatile int delay = 0; delay < 100; delay++);

        // Turn off HEX (sticky)
        port1 = 0x00;
        port0 = 0x00;
        for (volatile int delay = 0; delay < 10; delay++);
    }
}

// Display and shift
void run_display() {
    display_current_chars();  // Сначала отображаем текущие символы
    shift_message();          // Потом обновляем позицию строки
}



void main() {
    pos = 0;
    int mstatus;
    // The Machine Interrupt-Enable bit (MIE, bit 3) First bit - 0
    asm("csrr %0, mstatus" : "=r"(mstatus));
    asm("csrw mstatus, %0" ::"r"(mstatus | 0x8));
    
    // The Machine External Interrupt-Enable bit (MEIE, bit 11) enables the External interrupt.
    // This is the only general-purpose interrupt source specified in the RISC-V Instruction Set
    // Manual.
    // Press KEY[6] to external interrupt
    asm("li    a5, 0x1");
    asm("slli  a5, a5, 11"); //RV32I style
    
    // The Machine Local Interrupt-Enable bits (MLIE, bits 31-16) enable the individual Local
    // interrupts that are custom additions for this design.
    // Press KEY[3] to local interrupt
    asm("bset a5,a5, 16"); // Bit manip extention style   
    
    // Enable External and local Interrupts
    asm("csrw mie, a5");

    //Save  handler to mtvec
    //Run 08_show_dump.sh  to see assembler code
    asm("csrw mtvec, %0" ::"r"(&trap_function_handler)); 
    while (1) {
        run_display();         // Main loop
    }
}