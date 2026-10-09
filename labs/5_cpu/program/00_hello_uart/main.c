#include <stdint.h>

/* ======================================================================
 * UART (YRV Port 7/6 @ 0xFFFF000C)
 * ====================================================================== */
#define UART_BASE_ADDR          0xFFFF000CUL
#define UART_STATUS_BUFR_EMPTY  (1U << 11)

#define CLK_FREQ_MHZ            27
#define UART_BAUD_RATE          9600
#define UART_OVERSAMPLE         16
#define UART_DIV_RATE           ((CLK_FREQ_MHZ * 1000000UL) / (UART_BAUD_RATE * UART_OVERSAMPLE))

static void uart_init(void)
{
    volatile uint32_t *reg = (volatile uint32_t *)UART_BASE_ADDR;
    uint32_t val = *reg;
    val &= 0xFFFF0000U;
    val |= (UART_DIV_RATE << 4);  /* div_rate, s_reset=0, cks_mode=0 */
    *reg = val;
}

static void send_uart(char c)
{
    volatile uint32_t *reg = (volatile uint32_t *)UART_BASE_ADDR;
    while (!(*reg & UART_STATUS_BUFR_EMPTY))
        ;
    uint32_t val = *reg;
    val &= 0x0000FFFFU;
    val |= ((uint32_t)(uint8_t)c << 16);
    *reg = val;
}

static void uart_puts(const char *s)
{
    while (*s)
        send_uart(*s++);
}

/* ======================================================================
 * Main
 * ====================================================================== */
int main()
{
    uart_init();

    uart_puts("Hello from YRV!\r\n");
    uart_puts("Simulation UART test passed.\r\n");

    __asm__ volatile ("wfi");
    for (;;)
        __asm__ volatile ("wfi");

    return 0;
}