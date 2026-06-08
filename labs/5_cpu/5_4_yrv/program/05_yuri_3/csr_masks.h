#ifndef CSR_MASKS_H
#define CSR_MASKS_H

//  RISC-V machine-mode interrupt registers reference
//
//  mstatus (Machine Status)        - Global control and state storage
//    - mstatus.MIE       [ 3]      : Global Interrupt Enable (1 = ON, 0 = OFF)
//    - mstatus.MPIE      [ 7]      : Previous MIE value (saved here on trap)
//    - mstatus.MPP       [12:11]   : Previous Privilege Mode (saved here on trap)
//
//  mie (Machine Interrupt Enable)  - Fine-grained interrupt masking
//    - mie.MSIE          [ 3]      : Machine Software Interrupt Enable
//    - mie.MTIE          [ 7]      : Machine Timer Interrupt Enable
//    - mie.MEIE          [11]      : Machine External Interrupt Enable (Peripherals)
//
//  mip (Machine Interrupt Pending) - Status flags of raised interrupts
//    - mip.MSIP          [ 3]      : Machine Software Interrupt Pending status
//    - mip.MTIP          [ 7]      : Machine Timer Interrupt Pending status
//    - mip.MEIP          [11]      : Machine External Interrupt Pending status
//
//  mcause (Machine Cause)          - Reflects the reason for entering the trap
//    - mcause.EXCCODE    [30: 0]   : Event code ID (e.g., 0xB for External Interrupt)
//    - mcause.INTERRUPT  [31]      : 1 = Asynchronous Interrupt, 0 = Synchronous Exception
//
//  mtvec (Machine Trap Vector)     - Configures trap handler entry addresses
//    - mtvec.MODE        [ 1: 0]   : 00 = Direct Mode (single address for all traps)
//                                    01 = Vectored Mode (BASE + 4 * EXCCODE)
//    - mtvec.BASE        [31: 2]   : Base address of the trap handler
//
//  mepc (Machine Exception Program Counter)
//    - Holds the PC value of the interrupted instruction. Used by 'mret' to return.
//
//  mscratch (Machine Scratch)
//    - Dedicated context register used to temporarily swap and save CPU registers.

#define MSTATUS_MIE_BIT         3
#define MSTATUS_MPIE_BIT        7

#define MSTATUS_MPP_BIT_LO     11
#define MSTATUS_MPP_BIT_HI     12

#define MIE_MSIE_BIT            3
#define MIE_MTIE_BIT            7
#define MIE_MEIE_BIT           11

#define MIP_MSIP_BIT            3
#define MIP_MTIP_BIT            7
#define MIP_MEIP_BIT           11

#define MCAUSE_EXCCODE_BIT_LO   0
#define MCAUSE_EXCCODE_BIT_HI  30

#define MCAUSE_INTERRUPT_BIT   31

#define MTVEC_MODE_BIT_LO       0
#define MTVEC_MODE_BIT_HI       1

#define MTVEC_BASE_BIT_LO       2
#define MTVEC_BASE_BIT_HI      31

//----------------------------------------------------------------------------

#define MASK_FROM_BIT(b)             (1 << (b))
#define MASK_FROM_HI_LO_BIT(hi, lo)  ((~ 0u >> (31 - (hi))) & (~ 0 << (lo)))

#define MSTATUS_MIE       MASK_FROM_BIT        ( MSTATUS_MIE_BIT                               )
#define MSTATUS_MPIE      MASK_FROM_BIT        ( MSTATUS_MPIE_BIT                              )
#define MSTATUS_MPP       MASK_FROM_HI_LO_BIT  ( MSTATUS_MPP_BIT_HI    , MSTATUS_MPP_BIT_LO    )

#define MIE_MSIE          MASK_FROM_BIT        ( MIE_MSIE_BIT                                  )
#define MIE_MTIE          MASK_FROM_BIT        ( MIE_MTIE_BIT                                  )
#define MIE_MEIE          MASK_FROM_BIT        ( MIE_MEIE_BIT                                  )

#define MIP_MSIP          MASK_FROM_BIT        ( MIP_MSIP_BIT                                  )
#define MIP_MTIP          MASK_FROM_BIT        ( MIP_MTIP_BIT                                  )
#define MIP_MEIP          MASK_FROM_BIT        ( MIP_MEIP_BIT                                  )

#define MCAUSE_EXCCODE    MASK_FROM_HI_LO_BIT  ( MCAUSE_EXCCODE_BIT_LO , MCAUSE_EXCCODE_BIT_HI )
#define MCAUSE_INTERRUPT  MASK_FROM_BIT        ( MCAUSE_INTERRUPT_BIT                          )

#define MTVEC_MODE        MASK_FROM_HI_LO_BIT  ( MTVEC_MODE_BIT_LO     , MTVEC_MODE_BIT_HI     )
#define MTVEC_BASE        MASK_FROM_HI_LO_BIT  ( MTVEC_BASE_BIT_LO     , MTVEC_BASE_BIT_HI     )

//----------------------------------------------------------------------------

#define MCAUSE_EXCCODE_MACHINE_TIMER_INTERRUPT  7

#endif  // ifdef CSR_MASKS_H
