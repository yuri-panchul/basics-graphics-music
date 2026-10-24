#include "memory_mapped_registers.h"
#include "bgm_rr_threads.h"
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

int counter_1 = 1;

void thread_1 ()
{
    send_uart('A');
    counter_1 ++;
}

int counter_2 = 2;

void thread_2 ()
{
    send_uart('B');
    counter_2 ++;
}

void thread_3 ()
{
    send_uart('C');
}

void main ()
{
    uart_init();
    uart_puts("YRV round robiun threads demo.\r\n");
   
    define_thread (thread_1);
    uart_puts("Thread 1 defined...\r\n");

    define_thread (thread_2);
    uart_puts("Thread 2 defined...\r\n");

    define_thread (thread_3);
    uart_puts("Thread 3 defined...\r\n");

    uart_puts("All threads started!\r\n");
    start_running_threads ();
    
    for (;;);
}
