#include "memory_mapped_registers.h"
#include "seg7.h"
#include <stdint.h>

#define LED_0   0x1
#define LED_1   0x2
#define LED_2   0x4
#define LED_3   0x8



uint8_t char_to_hex(char c);
/**
 * Отображает первые 4 символа строки на 7-сегментных индикаторах
 * @param str Указатель на строку (минимум 4 символа)
 */
void display_string(const char* str) {
    uint8_t anodes[4] = {LED_3, LED_2, LED_1, LED_0}; 
    
    // Отображаем каждый из первых 4 символов
    for(int i = 0; i < 4; i++) {
        char c = str[i];
        uint8_t hex_code = char_to_hex(c);
        
        // Включаем соответствующий индикатор
        port0 = hex_code;
        port1 = anodes[i];
        
        // Задержка для визуализации (можно убрать при использовании динамической индикации)
        for(volatile int delay = 0; delay < 100; delay++);
        
        // Очистка после отображения (если нужно мультиплексирование)
        port0 = 0x00;
        port1 = 0x00;
    }
}

/**
 * Вспомогательная функция: преобразует символ в 7-сегментный код
 */
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
    const char message[] = "HELO"; // Строка из 4 символов
    
    while(1) {
        display_string(message);
    }
}