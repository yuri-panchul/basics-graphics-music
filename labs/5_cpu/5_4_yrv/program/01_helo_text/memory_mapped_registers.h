#ifndef MEMORY_MAPPED_REGISTERS_H
#define MEMORY_MAPPED_REGISTERS_H

#include <stdint.h>

#define MMIO_BASE_ADDR    0xffff0000

#define MMIO_7SEG_ADDR    0xffff0000
#define MMIO_LED_ADDR     0xffff0004
#define MMIO_KEY_SW_ADDR  0xffff0008
#define MMIO_SERIAL_ADDR  0xffff000c

#define MMIO(a) (* (volatile uint32_t *) (a))

#define MMIO_7SEG    MMIO ( MMIO_7SEG_ADDR   )
#define MMIO_LED     MMIO ( MMIO_LED_ADDR    )
#define MMIO_KEY_SW  MMIO ( MMIO_KEY_SW_ADDR )
#define MMIO_SERIAL  MMIO ( MMIO_SERIAL_ADDR )

typedef struct
{
    unsigned
    reserved : 8,
    rdp      : 1,
    ra       : 1,
    rb       : 1,
    rc       : 1,
    rd       : 1,
    re       : 1,
    rf       : 1,
    rg       : 1;
}
mmio_7seg_t;

typedef struct
{
    mmio_7seg_t seven_seg;
}
mmio_t;

#define mmio (* (volatile mmio_t *) MMIO_BASE_ADDR)

#endif
