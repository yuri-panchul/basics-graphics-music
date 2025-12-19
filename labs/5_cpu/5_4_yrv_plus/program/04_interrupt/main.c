#include "memory_mapped_registers.h"
#include "seg7.h"
#include <stdint.h>
#include <string.h>

// Регистры индикаторов
#define LED_0   0x1
#define LED_1   0x2
#define LED_2   0x4
#define LED_3   0x8

// Интервал смены положений строки
#define FRAME_LIMIT 1000  // Цифра с расчетом не сошлась на порядок

//Буфер
const char message[] = "HELLO ALL PPL";

// Длина буфера
size_t message_len = sizeof(message)-1; // Длина строки минус завершающий ноль

// Глобальные переменные состояния
static int call_count = 0;   // Счётчик вызовов
static int pos = 0;          // Текущая позиция строки

// Массив адресов индикаторов
const uint8_t anodes[4] = {LED_3, LED_2, LED_1, LED_0};

// Преобразует символ в значение индикатора
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

// Функция обновления позиции строки
void shift_message() {
    if (call_count >= FRAME_LIMIT) {
        pos++;                           // Просто двигаем строку дальше
        if (pos > message_len + 3) {     // Если прошло всю строку
            pos = 0;                     // Возвратимся к самому началу
        }
        call_count = 0;                   // Сбрасываем счётчик
    }
    call_count++;                          // Увеличение счётчика
}

// Функция отображения текущих символов на индикаторах
void display_current_chars() {
    for (int digit = 0; digit < 4; ++digit) { // Проходим по всем индикаторам
        char c;
        int char_pos = pos + digit;
        if (char_pos < 0 || char_pos >= message_len) {
            c = ' ';
        } else {
            c = message[char_pos];
        }

        // Выводим симво на соответствующий индикатор
        port0 = char_to_hex(c);    // Устанавливаем значение сегмента
        port1 = anodes[digit];    // Включаем индикатор

        // Яркость
        for (volatile int delay = 0; delay < 100; delay++);

        // Выключаем индикатор, для того чтобы враппер коректно отработал
        port0 = 0x00;
        port1 = 0x00;
    }
}

// Функция, вызывающая обновление и отображение
void run_display() {
    port3 = 0;  // Блокировка NMI
    display_current_chars();  // Сначала отображаем текущие символы
    shift_message(); // Потом обновляем позицию строки
    port3 = 1; // Разрешение NMI          
}

// Главная функция
void main() {
    // Зануляем для коректного сброса
    pos = 0;
    call_count = 0;
 
    // Разрешаем NMI
    port3=1;
    while (1) {
        asm("wfi");         // Главный цикл вызова обеих функций
    }
}