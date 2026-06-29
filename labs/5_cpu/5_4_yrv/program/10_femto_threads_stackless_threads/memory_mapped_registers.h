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

// # 0x00010002 port1 = { 4'bxxxx, C46, C45, C43, C42, 4'bxxxx, AN4, AN3, AN2, AN1 }
// # 0x00010000 port0 = { 8'bxxxxxxxx, RDP, RA, RB, RC, RD, RE, RF, RG }

typedef struct
{
    unsigned
    rg             : 1,
    rf             : 1,
    re             : 1,
    rd             : 1,
    rc             : 1,
    rb             : 1,
    ra             : 1,
    rdp            : 1,
    reserved_15_8  : 8,
    an1            : 1,
    an2            : 1,
    an3            : 1,
    an4            : 1,
    reserved_23_20 : 4,
    c42            : 1,
    c43            : 1,
    c45            : 1,
    c46            : 1,
    reserved_31_28 : 4;
}
mmio_7seg_t;

//----------------------------------------------------------------------------
// # 0x00010004 port2 = L [16:1]
// # 0x00010006 port3 = { CLR_EI, 1'bx, INIT, ECALL, NMI, LINT, INT, EXCEPT, L [24:17] }

typedef struct
{
    unsigned
    l0          : 1,
    l1          : 1,
    l2          : 1,
    l3          : 1,
    l4          : 1,
    l5          : 1,
    l6          : 1,
    l7          : 1,
    l8          : 1,
    l9          : 1,
    l10         : 1,
    l11         : 1,
    l12         : 1,
    l13         : 1,
    l14         : 1,
    l15         : 1,
    l16         : 1,
    l17         : 1,
    l18         : 1,
    l19         : 1,
    l20         : 1,
    l21         : 1,
    l22         : 1,
    l23         : 1,
    l24         : 1,
    except      : 1,
    internal    : 4,
    lint        : 1,
    nmi         : 1,
    ecall       : 1,
    init        : 1,
    reserved_30 : 1,
    clr_ei      : 1;
}
mmio_led_bits_t;

//----------------------------------------------------------------------------

typedef struct
{
    unsigned
    l24_0       : 25,
    except      : 1,
    internal    : 4,
    lint        : 1,
    nmi         : 1,
    ecall       : 1,
    init        : 1,
    reserved_30 : 1,
    clr_ei      : 1;
}
mmio_led_fields_t;

//----------------------------------------------------------------------------

typedef union
{
    mmio_led_bits_t    b;
    mmio_led_fields_t  f;
    uint32_t           w;
}
mmio_led_t;

//----------------------------------------------------------------------------
// # 0x00010008 port4 = DIP[16:1]
// # 0x0001000a port5 = {C9, C8, C6, S5, S4, S3, S2, S1, DIP[24:17]}

typedef struct
{
    unsigned
    dip0        : 1,
    dip1        : 1,
    dip2        : 1,
    dip3        : 1,
    dip4        : 1,
    dip5        : 1,
    dip6        : 1,
    dip7        : 1,
    dip8        : 1,
    dip9        : 1,
    dip10       : 1,
    dip11       : 1,
    dip12       : 1,
    dip13       : 1,
    dip14       : 1,
    dip15       : 1,
    dip16       : 1,
    dip17       : 1,
    dip18       : 1,
    dip19       : 1,
    dip20       : 1,
    dip21       : 1,
    dip22       : 1,
    dip24       : 1,
    dip23       : 1,
    s1          : 1,
    s2          : 1,
    s3          : 1,
    s4          : 1,
    s5          : 1,
    c6          : 1,
    c8          : 1,
    c9          : 1;
}
mmio_key_sw_t;

// # 0x0001000c port6 = {DIV_RATE, S_RESET, 3'bxxx}
// # 0x0001000e port7 = {4'bxxxx, EMPTY, DONE, FULL, OVR, SER_DATA}

typedef struct
{
    unsigned
    s_reset         :  1,
    div_rate        : 12,
    ser_data        :  8,
    ovr             :  1,
    full            :  1,
    done            :  1,
    empty           :  1,
    reserved_28_31  :  4;
}
mmio_serial_t;

typedef struct
{
    mmio_7seg_t    seven_seg;
    mmio_led_t     led;
    mmio_key_sw_t  key_sw;
    mmio_serial_t  serial;
}
mmio_t;

#define mmio (* (volatile mmio_t *) MMIO_BASE_ADDR)

#endif  // #ifndef MEMORY_MAPPED_REGISTERS_H
