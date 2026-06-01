#ifndef CSR_MASKS_H
#define CSR_MASKS_H

//  RISC-V MACHINE-MODE INTERRUPT REGISTERS REFERENCE
//
//  mstatus (Machine Status) - Global control and state storage
//    - mstatus.MIE  [Bit 3]          : Global Interrupt Enable (1 = ON, 0 = OFF)
//    - mstatus.MPIE [Bit 7]          : Previous MIE value (saved here on trap)
//    - mstatus.MPP  [Bits 12:11]     : Previous Privilege Mode (saved here on trap)
//
//  mie (Machine Interrupt Enable) - Fine-grained interrupt masking
//    - mie.MSIE     [Bit 3]          : Machine Software Interrupt Enable
//    - mie.MTIE     [Bit 7]          : Machine Timer Interrupt Enable
//    - mie.MEIE     [Bit 11]         : Machine External Interrupt Enable (Peripherals)
//
//  mip (Machine Interrupt Pending) - Status flags of raised interrupts
//    - mip.MSIP     [Bit 3]          : Machine Software Interrupt Pending status
//    - mip.MTIP     [Bit 7]          : Machine Timer Interrupt Pending status
//    - mip.MEIP     [Bit 11]         : Machine External Interrupt Pending status
//
//  mcause (Machine Cause) - Reflects the reason for entering the trap
//    - mcause.EXCCODE   [Bits 30:0]  : Event code ID (e.g., 0xB for External Interrupt)
//    - mcause.INTERRUPT [Bit 31]     : 1 = Asynchronous Interrupt, 0 = Synchronous Exception
//
//  mtvec (Machine Trap Vector) - Configures trap handler entry addresses
//    - mtvec.MODE   [Bits 1:0]       : 00 = Direct Mode (single address for all traps)
//                                      01 = Vectored Mode (BASE + 4 * EXCCODE)
//    - mtvec.BASE   [Bits 31:2]      : Base address of the trap handler
//
//  mepc (Machine Exception Program Counter)
//    - Holds the PC value of the interrupted instruction. Used by 'mret' to return.
//
//  mscratch (Machine Scratch)
//    - Dedicated context register used to temporarily swap and save CPU registers.

#define MSTATUS_MIE_BIT          3
#define MSTATUS_MPIE_BIT         7
#define MSTATUS_MPP_BIT_LO      11
#define MSTATUS_MPP_BIT_HI      12

#define MIE_MEIE_BIT            11
#define MIE_MTIE_BIT             7
#define MIE_MSIE_BIT             3

//  mie (Machine Interrupt Enable) - Fine-grained interrupt masking
//    - mie.MEIE     [Bit 11] : Machine External Interrupt Enable (Peripherals)
//    - mie.MTIE     [Bit 7]  : Machine Timer Interrupt Enable
//    - mie.MSIE     [Bit 3]  : Machine Software Interrupt Enable
//
//  mip (Machine Interrupt Pending) - Status flags of raised interrupts
//    - mip.MEIP     [Bit 11] : Machine External Interrupt Pending status
//    - mip.MTIP     [Bit 7]  : Machine Timer Interrupt Pending status
//    - mip.MSIP     [Bit 3]  : Machine Software Interrupt Pending status
//
//  mcause (Machine Cause) - Reflects the reason for entering the trap
//    - mcause.INTERRUPT [Bit 31]  : 1 = Asynchronous Interrupt, 0 = Synchronous Exception
//    - mcause.EXCCODE   [Bits 30:0]: Event code ID (e.g., 0xB for External Interrupt)
//
//  mtvec (Machine Trap Vector) - Configures trap handler entry addresses
//    - mtvec.BASE   [Bits 31:2] : Base address of the trap handler
//    - mtvec.MODE   [Bits 1:0]  : 00 = Direct Mode (single address for all traps)
//                                 01 = Vectored Mode (BASE + 4 * EXCCODE)
//
//  mepc (Machine Exception Program Counter)
//    - Holds the PC value of the interrupted instruction. Used by 'mret' to return.
//
//  mscratch (Machine Scratch)
//    - Dedicated context register used to temporarily swap and save CPU registers.

#define MASK_FROM_BIT(b)             (1 << (b))
#define MASK_FROM_HI_LO_BIT(hi, lo)  ((~ 0u >> (31 - (hi))) & (~ 0 << (lo)))

#define MSTATUS_MIE   MASK_FROM_BIT        ( MSTATUS_MIE_BIT                          )
#define MSTATUS_MPIE  MASK_FROM_BIT        ( MSTATUS_MPIE_BIT                         )
#define MSTATUS_MPP   MASK_FROM_HI_LO_BIT  ( MSTATUS_MPP_BIT_HI  , MSTATUS_MPP_BIT_LO )

#define MIE_MEIE      MASK_FROM_BIT        ( MIE_MEIE_BIT                             )
#define MIE_MTIE      MASK_FROM_BIT        ( MIE_MTIE_BIT                             )
#define MIE_MSIE      MASK_FROM_BIT        ( MIE_MSIE_BIT                             )

#endif  // ifdef CSR_MASKS_H
