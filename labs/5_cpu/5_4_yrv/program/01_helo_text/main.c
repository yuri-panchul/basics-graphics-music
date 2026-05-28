// Use this example to get
// experience with HEX on differents boards

#include "memory_mapped_registers.h"

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

