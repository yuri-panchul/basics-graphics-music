#include <stdint.h>
#include "yrv_mcu_passthrough.h"

#define YRV_MCU_PASSTHROUGH_BASE (0xFFFF0000UL) // yrv_mcu.vh

volatile yrv_mcu_passthrough_t * const YRV_MCU = (volatile yrv_mcu_passthrough_t *)YRV_MCU_PASSTHROUGH_BASE;

void delay(uint32_t n)
{
    for (uint32_t i = 0; i < n; i++)
        __asm__ volatile ("nop");
}

int main(void) 
{
    while (1) {
        YRV_MCU->YRV_MCU_LED_CTRL ^= (YRV_MCU_PASSTHROUGH__YRV_MCU_LED_CTRL__CTRL_bm);
        delay (500000);
    }

    return 0;
}