#ifndef MFP_MEMORY_MAPPED_REGISTERS_H
#define MFP_MEMORY_MAPPED_REGISTERS_H


/*
define IO_PORT10 14 h0000                                  lsword of port 1/0 address   
define IO_PORT32 14 h0001                                  lsword of port 3/2 address   
define IO_PORT54 14 h0002                                  lsword of port 5/4 address   
define IO_PORT76 14 h0003                                  lsword of port 7/6 address   


*/

#define IO_PORT00_ADDR     0xFFFF0000
#define IO_PORT16_ADDR     0xFFFF0002
#define IO_PORT32_ADDR     0xFFFF0004
#define IO_PORT48_ADDR     0xFFFF0006
#define IO_PORT54_ADDR     0xFFFF0008
#define IO_PORT60_ADDR     0xFFFF000A
#define IO_PORT76_ADDR     0xFFFF000C


#define port0 (* (volatile unsigned short*) IO_PORT00_ADDR )
#define port1 (* (volatile unsigned short*) IO_PORT16_ADDR )
#define port2 (* (volatile unsigned short*) IO_PORT32_ADDR )
#define port3 (* (volatile unsigned short*) IO_PORT48_ADDR )
#define port4 (* (volatile unsigned short*) IO_PORT54_ADDR )
#define port5 (* (volatile unsigned short*) IO_PORT60_ADDR )
#define port6 (* (volatile unsigned short*) IO_PORT76_ADDR )

#endif
