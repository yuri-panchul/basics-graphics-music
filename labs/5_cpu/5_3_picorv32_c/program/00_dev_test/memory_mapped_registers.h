#ifndef MEMORY_MAPPED_REGISTERS_H
#define MEMORY_MAPPED_REGISTERS_H

#define MMIO_BASE_ADDR       0xffff0000

#define MMIO_7SEG_OFFSET     0x0
#define MMIO_LED_OFFSET      0x4
#define MMIO_KEY_SW_OFFSET   0x8
#define MMIO_SERIAL_OFFSET   0xc

#define MMIO_7SEG_ADDR       (MMIO_BASE_ADDR + MMIO_7SEG_OFFSET)
#define MMIO_LED_ADDR        (MMIO_BASE_ADDR + MMIO_LED_OFFSET)
#define MMIO_KEY_SW_ADDR     (MMIO_BASE_ADDR + MMIO_KEY_SW_OFFSET)
#define MMIO_SERIAL_ADDR     (MMIO_BASE_ADDR + MMIO_SERIAL_OFFSET)

//----------------------------------------------------------------------------

#ifndef __ASSEMBLER__

#include <stdint.h>

// TODO: Fill structs

#endif  // #ifndef __ASSEMBLER__

#endif  // #ifndef MEMORY_MAPPED_REGISTERS_H
