#include "memory_mapped_registers.h"
#include "seg7.h"
#include <stdint.h>

#define LED_0   0x1
#define LED_1   0x2
#define LED_2   0x4
#define LED_3   0x8



extern void default_exception_handler();
extern void default_vector_handler();
extern void nmi_handler_function();
extern void software_interrupt_handler();
extern void timer_interrupt_handler();
extern void external_interrupt_handler();



void __attribute__((weak, interrupt)) __mtvec_clint_vector_table(void);

extern void exception_handler(void);
extern void vector_handler(void);
extern void software_interrupt_handler(void);
extern void timer_interrupt_handler(void);
extern void external_interrupt_handler(void);


extern char __irq_handlers[];
#define irq_handlers ((void**)__irq_handlers)

void __attribute__((naked)) nmi_handler() {
    asm volatile (
        ".org 0x40\n\t"                       
        "csrrs t0, mscratch, zero\n\t"         
        "call nmi_handler_function\n\t"         
        "mret\n\t"                              
    );
}


void set_mtvec_vectored_mode() {
    uintptr_t addr = (uintptr_t)irq_handlers | 0b1; 
    asm volatile ("csrw mtvec, %0\n\t" :: "r"(addr));
}

void init() {
    set_mtvec_vectored_mode(); 
}




/* Defines to access CSR registers within C code */
#define read_csr(reg) ({ unsigned long __tmp; \
  asm volatile ("csrr %0, " #reg : "=r"(__tmp)); \
  __tmp; })

#define write_csr(reg, val) ({ \
  asm volatile ("csrw " #reg ", %0" :: "rK"(val)); })

#define write_dword(addr, data)                 ((*(volatile uint64_t *)(addr)) = (uint64_t)data)
#define read_dword(addr)                        (*(volatile uint64_t *)(addr))
#define write_word(addr, data)                  ((*(volatile uint32_t *)(addr)) = data)
#define read_word(addr)                         (*(volatile uint32_t *)(addr))
#define write_byte(addr, data)                  ((*(volatile uint8_t *)(addr)) = data)
#define read_byte(addr)                         (*(volatile uint8_t *)(addr))

/* Globals */
void __attribute__((weak, interrupt)) __mtvec_clint_vector_table(void);
void __attribute__((weak, interrupt)) software_handler (void);
void __attribute__((weak, interrupt)) timer_handler (void);
void __attribute__((weak, interrupt)) external_handler (void);
void __attribute__((weak, interrupt)) default_vector_handler (void);
void __attribute__((weak)) default_exception_handler(void);


void interrupt_global_enable (void);
void interrupt_global_disable (void);
void interrupt_software_enable (void);
void interrupt_software_disable (void);
void interrupt_timer_enable (void);
void interrupt_timer_disable (void);
void interrupt_external_enable (void);
void interrupt_external_disable (void);
void interrupt_local_enable (int id);



char message[] = "HELO"; 

void __attribute__((weak, interrupt)) default_vector_handler (void) {
    message[0] = 'L';
    message[1] = 'O';
    message[2] = 'C';
    message[3] = 'L';
}

void __attribute__((weak, interrupt)) external_handler (void){
    message[0] = 'E';
}

void __attribute__((weak, interrupt)) software_handler (void) {
        message[0] = 'E';
}

void __attribute__((weak, interrupt)) timer_handler (void)
{
            message[0] = 'C';

}

void __attribute__((weak)) default_exception_handler(void) {
            message[0] = ' ';
}

void __attribute__((weak)) nmi_handler_function(void) {
            message[0] = 'N';
}



uint8_t char_to_hex(char c);

void display_string(const char* str) {
    uint8_t anodes[4] = {LED_3, LED_2, LED_1, LED_0};

    for(int i = 0; i < 4; i++) {
        char c = str[i];
        uint8_t hex_code = char_to_hex(c);

        port1 = anodes[i];
        port0 = hex_code;
       

        for(volatile int delay = 0; delay < 100; delay++);

        #ifdef STATIC
            port0 = 0x00;
            port1 = 0x00;
        #endif
    }
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

void delay(volatile uint32_t count) {
    while(count--) {
        asm("nop");
    }
}

void main() {
    uint32_t i, priority_thresh, mode;
    uintptr_t mtvec_base, my_hartid, boot_hart, plic_addr;



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
    asm("bset a5,a5, 17"); // Bit manip extention style   

    
    // Enable External and local Interrupts
    asm("csrw mie, a5");

    // mode = MTVEC_MODE_CLINT_VECTORED;
    // mtvec_base = (uintptr_t)&__mtvec_clint_vector_table;
    // write_csr (mtvec, (mtvec_base | mode));
    
    //Save  handler to mtvec
    //Run 08_show_dump.sh  to see assembler code


    
    while(1) {
        display_string(message);
    }
}


// void interrupt_global_enable (void) {
//     uintptr_t m;
//     __asm__ volatile ("csrrs %0, mstatus, %1" : "=r"(m) : "r"(METAL_MIE_INTERRUPT));
// }

// void interrupt_global_disable (void) {
//     uintptr_t m;
//     __asm__ volatile ("csrrc %0, mstatus, %1" : "=r"(m) : "r"(METAL_MIE_INTERRUPT));
// }

// void interrupt_software_enable (void) {
//     uintptr_t m;
//     __asm__ volatile ("csrrs %0, mie, %1" : "=r"(m) : "r"(METAL_LOCAL_INTERRUPT_SW));
// }

// void interrupt_software_disable (void) {
//     uintptr_t m;
//     __asm__ volatile ("csrrc %0, mie, %1" : "=r"(m) : "r"(METAL_LOCAL_INTERRUPT_SW));
// }

// void interrupt_timer_enable (void) {
//     uintptr_t m;
//     __asm__ volatile ("csrrs %0, mie, %1" : "=r"(m) : "r"(METAL_LOCAL_INTERRUPT_TMR));
// }

// void interrupt_timer_disable (void) {
//     uintptr_t m;
//     __asm__ volatile ("csrrc %0, mie, %1" : "=r"(m) : "r"(METAL_LOCAL_INTERRUPT_TMR));
// }

// void interrupt_external_enable (void) {
//     uintptr_t m;
//     __asm__ volatile ("csrrs %0, mie, %1" : "=r"(m) : "r"(METAL_LOCAL_INTERRUPT_EXT));
// }

// void interrupt_external_disable (void) {
//     unsigned long m;
//     __asm__ volatile ("csrrc %0, mie, %1" : "=r"(m) : "r"(METAL_LOCAL_INTERRUPT_EXT));
// }

void interrupt_local_enable (int id) {
    uintptr_t b = 1 << id;
    uintptr_t m;
    __asm__ volatile ("csrrs %0, mie, %1" : "=r"(m) : "r"(b));
}

