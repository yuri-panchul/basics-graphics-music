// Use this example to get
// experience with HEX on differents boards

#include "memory_mapped_registers.h"

void main ()
{
//    mmio.seven_seg.ra = 1;
//    MMIO_7SEG         = 123;

//    mmio.seven_seg.free1 = 12;
    mmio.seven_seg.rdp      = 0;
/*
    mmio.seven_seg.ra       = 1;
    mmio.seven_seg.rb       = 0;
    mmio.seven_seg.rc       = 1;
    mmio.seven_seg.rd       = 1;
    mmio.seven_seg.re       = 0;
    mmio.seven_seg.rf       = 0;
    mmio.seven_seg.rg       = 1;

    mmio_7seg_t seg;

//    seg.free1 = 12;
    seg.rdp      = 0;
    seg.ra       = 1;
    seg.rb       = 0;
    seg.rc       = 1;
    seg.rd       = 1;
    seg.re       = 0;
    seg.rf       = 0;
    seg.rg       = 1;

    mmio.seven_seg = seg;
*/
}

