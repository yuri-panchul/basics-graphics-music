// Use this example to get
// experience with HEX on differents boards

#include "memory_mapped_registers.h"
#define MTIME_CLK_FREQ 27000000
#define TICKS_PER_MS   (MTIME_CLK_FREQ / 1000)

// Macros for reading and writing the control and status registers (CSRs)
// Form Digital Design and Computer Architecture, RISC-V Edition 542.e29
#define read_csr(reg) ({ unsigned long __tmp; \
asm volatile ("csrr %0, " #reg : "= r"(__tmp)); \
__tmp; })

#define write_csr(reg, val) ({ \
asm volatile ("csrw " #reg ", %0" :: "rK"(val)); })

void delay(int ms) {
    unsigned long start_time = read_csr(time);
    unsigned long wait_time = (unsigned long)ms * TICKS_PER_MS;
    while ((read_csr(time) - start_time) < wait_time); // Wait until time is reached. Unsigned help with overload
}


void main ()
{
//    mmio.seven_seg.ra = 1;
//    MMIO_7SEG         = 123;

    mmio.seven_seg.bits.free1 = 12;
    mmio.seven_seg.bits.rdp      = 0;
    mmio.seven_seg.bits.ra       = 1;
    mmio.seven_seg.bits.rb       = 0;
    mmio.seven_seg.bits.rc       = 1;
    mmio.seven_seg.bits.rd       = 1;
    mmio.seven_seg.bits.re       = 0;
    mmio.seven_seg.bits.rf       = 0;
    mmio.seven_seg.bits.rg       = 1;

    mmio_7seg_t seg;

    delay(10);
    seg.bits.free1 = 12;
    seg.bits.rdp      = 0;
    seg.bits.ra       = 1;
    seg.bits.rb       = 0;
    seg.bits.rc       = 1;
    seg.bits.rd       = 1;
    seg.bits.re       = 0;
    seg.bits.rf       = 0;
    seg.bits.rg       = 1;

    mmio.seven_seg = seg;

    
}

