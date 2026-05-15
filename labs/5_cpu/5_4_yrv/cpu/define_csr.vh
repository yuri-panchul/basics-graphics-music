/*******************************************************************************************/
/**                                                                                       **/
/** Copyright 2021 Monte J. Dalrymple                                                     **/
/**                                                                                       **/
/** SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1                                      **/
/**                                                                                       **/
/** Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may not use  **/
/** this file except in compliance with the License, or, at your option, the Apache       **/
/** License version 2.0. You may obtain a copy of the License at                          **/
/**                                                                                       **/
/** https://solderpad.org/licenses/SHL-2.1/                                               **/
/**                                                                                       **/
/** Unless required by applicable law or agreed to in writing, any work distributed under **/
/** the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF   **/
/** ANY KIND, either express or implied. See the License for the specific language        **/
/** governing permissions and limitations under the License.                              **/
/**                                                                                       **/
/** YRV CSR defines                                                   Rev 0.0  03/29/2021 **/
/**                                                                                       **/
/*******************************************************************************************/

/*******************************************************************************************/
/* User Trap Setup                                                                         */
/*******************************************************************************************/
`define USTATUS        12'h000
`define UIE            12'h004
`define UTVEC          12'h005

/*******************************************************************************************/
/* User Trap Handling                                                                      */
/*******************************************************************************************/
`define USCRATCH       12'h040
`define UEPC           12'h041
`define UCAUSE         12'h042
`define UTVAL          12'h043
`define UIP            12'h044

/*******************************************************************************************/
/* User Floating-Point CSRs                                                                */
/*******************************************************************************************/
`define FFLAGS         12'h001
`define FRM            12'h002
`define FCSR           12'h003

/*******************************************************************************************/
/* User Counter/Timers                                                                     */
/*******************************************************************************************/
`define CYCLE          12'hc00                             /* mcycle_reg                   */
`define TIME           12'hc01                             /* timer_rdata                  */
`define INSTRET        12'hc02                             /* minstret_reg                 */
`define HPMCOUNTER3    12'hc03
`define HPMCOUNTER4    12'hc04
`define HPMCOUNTER5    12'hc05
`define HPMCOUNTER6    12'hc06
`define HPMCOUNTER7    12'hc07
`define HPMCOUNTER8    12'hc08
`define HPMCOUNTER9    12'hc09
`define HPMCOUNTER10   12'hc0a
`define HPMCOUNTER11   12'hc0b
`define HPMCOUNTER12   12'hc0c
`define HPMCOUNTER13   12'hc0d
`define HPMCOUNTER14   12'hc0e
`define HPMCOUNTER15   12'hc0f
`define HPMCOUNTER16   12'hc10
`define HPMCOUNTER17   12'hc11
`define HPMCOUNTER18   12'hc12
`define HPMCOUNTER19   12'hc13
`define HPMCOUNTER20   12'hc14
`define HPMCOUNTER21   12'hc15
`define HPMCOUNTER22   12'hc16
`define HPMCOUNTER23   12'hc17
`define HPMCOUNTER24   12'hc18
`define HPMCOUNTER25   12'hc19
`define HPMCOUNTER26   12'hc1a
`define HPMCOUNTER27   12'hc1b
`define HPMCOUNTER28   12'hc1c
`define HPMCOUNTER29   12'hc1d
`define HPMCOUNTER30   12'hc1e
`define HPMCOUNTER31   12'hc1f
`define CYCLEH         12'hc80                             /* mcycleh_reg                  */
`define TIMEH          12'hc81                             /* timer_rdata                  */
`define INSTRETH       12'hc82                             /* minstreth_reg                */
`define HPMCOUNTER3H   12'hc83
`define HPMCOUNTER4H   12'hc84
`define HPMCOUNTER5H   12'hc85
`define HPMCOUNTER6H   12'hc86
`define HPMCOUNTER7H   12'hc87
`define HPMCOUNTER8H   12'hc88
`define HPMCOUNTER9H   12'hc89
`define HPMCOUNTER10H  12'hc8a
`define HPMCOUNTER11H  12'hc8b
`define HPMCOUNTER12H  12'hc8c
`define HPMCOUNTER13H  12'hc8d
`define HPMCOUNTER14H  12'hc8e
`define HPMCOUNTER15H  12'hc8f
`define HPMCOUNTER16H  12'hc90
`define HPMCOUNTER17H  12'hc91
`define HPMCOUNTER18H  12'hc92
`define HPMCOUNTER19H  12'hc93
`define HPMCOUNTER20H  12'hc94
`define HPMCOUNTER21H  12'hc95
`define HPMCOUNTER22H  12'hc96
`define HPMCOUNTER23H  12'hc97
`define HPMCOUNTER24H  12'hc98
`define HPMCOUNTER25H  12'hc99
`define HPMCOUNTER26H  12'hc9a
`define HPMCOUNTER27H  12'hc9b
`define HPMCOUNTER28H  12'hc9c
`define HPMCOUNTER29H  12'hc9d
`define HPMCOUNTER30H  12'hc9e
`define HPMCOUNTER31H  12'hc9f

/*******************************************************************************************/
/* Supervisor Trap Setup                                                                   */
/*******************************************************************************************/
`define SSTATUS        12'h100
`define SEDELEG        12'h102
`define SIDELEG        12'h103
`define SIE            12'h104
`define STVEC          12'h105
`define SCOUNTEREN     12'h106

/*******************************************************************************************/
/* Supervisor Trap Handling                                                                */
/*******************************************************************************************/
`define SSCRATCH       12'h140
`define SEPC           12'h141
`define SCAUSE         12'h142
`define STVAL          12'h143
`define SIP            12'h144

/*******************************************************************************************/
/* Supervisor Protection and Translation                                                   */
/*******************************************************************************************/
`define SATP           12'h180

/*******************************************************************************************/
/* Hypervisor Trap Setup                                                                   */
/*******************************************************************************************/
`define HSTATUS        12'h600
`define HEDELEG        12'h602
`define HIDELEG        12'h603
`define HIE            12'h604
`define HCOUNTEREN     12'h606
`define HGEIE          12'h607

/*******************************************************************************************/
/* Hypervisor Trap Handling                                                                */
/*******************************************************************************************/
`define HTVAL          12'h643
`define HIP            12'h644
`define HVIP           12'h645
`define HTINST         12'h64A
`define HGEIP          12'he12

/*******************************************************************************************/
/* Hypervisor Protection and Translation                                                   */
/*******************************************************************************************/
`define HGATP          12'h680

/*******************************************************************************************/
/* Hypervisor Counter/Timer Virtualization Registers                                       */
/*******************************************************************************************/
`define HTIMEDELTA     12'h605
`define HTIMEDELTAH    12'h615

/*******************************************************************************************/
/* Virtual Supervisor Registers                                                            */
/*******************************************************************************************/
`define VSSTATUS       12'h200
`define VSIE           12'h204
`define VSTVEC         12'h205
`define VSSCRATCH      12'h240
`define VSEPC          12'h241
`define VSCAUSE        12'h242
`define VSTVAL         12'h243
`define VSIP           12'h244
`define VSATP          12'h280

/*******************************************************************************************/
/* Machine Information Registers                                                           */
/*******************************************************************************************/
`define MVENDORID      12'hf11                             /* `MVENDORID_DEF               */
`define MARCHID        12'hf12                             /* `MARCHID_DEF                 */
`define MIMPID         12'hf13                             /* `MIMPID_DEF                  */
`define MHARTID        12'hf14                             /* hw_id                        */

/*******************************************************************************************/
/* Machine Trap Setup                                                                      */
/*******************************************************************************************/
`define MSTATUS        12'h300                             /* various                      */
`define MISA           12'h301                             /* `MISA_DEF                    */
`define MEDELEG        12'h302
`define MIDELEG        12'h303
`define MIE            12'h304                             /* various m*ie_reg             */
`define MTVEC          12'h305                             /* mtvec_reg, vmode_reg         */
`define MCOUNTEREN     12'h306

/*******************************************************************************************/
/* Machine Trap Handling                                                                   */
/*******************************************************************************************/
`define MSCRATCH       12'h340                             /* mscratch_reg                 */
`define MEPC           12'h341                             /* mepc_reg                     */
`define MCAUSE         12'h342                             /* mcause_reg                   */
`define MTVAL          12'h343
`define MIP            12'h344                             /* various m*ip_reg             */
`define MTINST         12'h34a
`define MIVAL2         12'h34b

/*******************************************************************************************/
/* Machine Memory Protection                                                               */
/*******************************************************************************************/
`define PMPCFG0        12'h3a0
`define PMPCFG1        12'h3a1
`define PMPCFG2        12'h3a2
`define PMPCFG3        12'h3a3
`define PMPADDR0       12'h3b0
`define PMPADDR1       12'h3b1
`define PMPADDR2       12'h3b2
`define PMPADDR3       12'h3b3
`define PMPADDR4       12'h3b4
`define PMPADDR5       12'h3b5
`define PMPADDR6       12'h3b6
`define PMPADDR7       12'h3b7
`define PMPADDR8       12'h3b8
`define PMPADDR9       12'h3b9
`define PMPADDR10      12'h3ba
`define PMPADDR11      12'h3bb
`define PMPADDR12      12'h3bc
`define PMPADDR13      12'h3bd
`define PMPADDR14      12'h3be
`define PMPADDR15      12'h3bf

/*******************************************************************************************/
/* Machine Counter/Timers                                                                  */
/*******************************************************************************************/
`define MCYCLE         12'hb00                             /* mcycle_reg                   */
`define MINSTRET       12'hb02                             /* minstret_reg                 */
`define MHPMCOUNTER3   12'hb03
`define MHPMCOUNTER4   12'hb04
`define MHPMCOUNTER5   12'hb05
`define MHPMCOUNTER6   12'hb06
`define MHPMCOUNTER7   12'hb07
`define MHPMCOUNTER8   12'hb08
`define MHPMCOUNTER9   12'hb09
`define MHPMCOUNTER10  12'hb0a
`define MHPMCOUNTER11  12'hb0b
`define MHPMCOUNTER12  12'hb0c
`define MHPMCOUNTER13  12'hb0d
`define MHPMCOUNTER14  12'hb0e
`define MHPMCOUNTER15  12'hb0f
`define MHPMCOUNTER16  12'hb10
`define MHPMCOUNTER17  12'hb11
`define MHPMCOUNTER18  12'hb12
`define MHPMCOUNTER19  12'hb13
`define MHPMCOUNTER20  12'hb14
`define MHPMCOUNTER21  12'hb15
`define MHPMCOUNTER22  12'hb16
`define MHPMCOUNTER23  12'hb17
`define MHPMCOUNTER24  12'hb18
`define MHPMCOUNTER25  12'hb19
`define MHPMCOUNTER26  12'hb1a
`define MHPMCOUNTER27  12'hb1b
`define MHPMCOUNTER28  12'hb1c
`define MHPMCOUNTER29  12'hb1d
`define MHPMCOUNTER30  12'hb1e
`define MHPMCOUNTER31  12'hb1f
`define MCYCLEH        12'hb80                             /* mcycleh_reg                  */
`define MINSTRETH      12'hb82                             /* minstreth_reg                */
`define MHPMCOUNTER3H  12'hb83
`define MHPMCOUNTER4H  12'hb84
`define MHPMCOUNTER5H  12'hb85
`define MHPMCOUNTER6H  12'hb86
`define MHPMCOUNTER7H  12'hb87
`define MHPMCOUNTER8H  12'hb88
`define MHPMCOUNTER9H  12'hb89
`define MHPMCOUNTER10H 12'hb8a
`define MHPMCOUNTER11H 12'hb8b
`define MHPMCOUNTER12H 12'hb8c
`define MHPMCOUNTER13H 12'hb8d
`define MHPMCOUNTER14H 12'hb8e
`define MHPMCOUNTER15H 12'hb8f
`define MHPMCOUNTER16H 12'hb90
`define MHPMCOUNTER17H 12'hb91
`define MHPMCOUNTER18H 12'hb92
`define MHPMCOUNTER19H 12'hb93
`define MHPMCOUNTER20H 12'hb94
`define MHPMCOUNTER21H 12'hb95
`define MHPMCOUNTER22H 12'hb96
`define MHPMCOUNTER23H 12'hb97
`define MHPMCOUNTER24H 12'hb98
`define MHPMCOUNTER25H 12'hb99
`define MHPMCOUNTER26H 12'hb9a
`define MHPMCOUNTER27H 12'hb9b
`define MHPMCOUNTER28H 12'hb9c
`define MHPMCOUNTER29H 12'hb9d
`define MHPMCOUNTER30H 12'hb9e
`define MHPMCOUNTER31H 12'hb9f

/*******************************************************************************************/
/* Machine Counter Setup                                                                   */
/*******************************************************************************************/
`define MCOUNTINHIBIT  12'h320                             /* various                      */
`define MHPMEVENT3     12'h323
`define MHPMEVENT4     12'h324
`define MHPMEVENT5     12'h325
`define MHPMEVENT6     12'h326
`define MHPMEVENT7     12'h327
`define MHPMEVENT8     12'h328
`define MHPMEVENT9     12'h329
`define MHPMEVENT10    12'h32a
`define MHPMEVENT11    12'h32b
`define MHPMEVENT12    12'h32c
`define MHPMEVENT13    12'h32d
`define MHPMEVENT14    12'h32e
`define MHPMEVENT15    12'h32f
`define MHPMEVENT16    12'h330
`define MHPMEVENT17    12'h331
`define MHPMEVENT18    12'h332
`define MHPMEVENT19    12'h333
`define MHPMEVENT20    12'h334
`define MHPMEVENT21    12'h335
`define MHPMEVENT22    12'h336
`define MHPMEVENT23    12'h337
`define MHPMEVENT24    12'h338
`define MHPMEVENT25    12'h339
`define MHPMEVENT26    12'h33a
`define MHPMEVENT27    12'h33b
`define MHPMEVENT28    12'h33c
`define MHPMEVENT29    12'h33d
`define MHPMEVENT30    12'h33e
`define MHPMEVENT31    12'h33f

/*******************************************************************************************/
/* Debug/Trace Registers                                                                   */
/*******************************************************************************************/
`define TSELECT        12'h7a0
`define TDATA1         12'h7a1
`define TDATA2         12'h7a2
`define TDATA3         12'h7a3

/*******************************************************************************************/
/* Debug Mode Registers                                                                    */
/*******************************************************************************************/
`define DCSR           12'h7b0                             /* various                      */
`define DPC            12'h7b1                             /* dpc_reg                      */
`define DSCRATCH0      12'h7b2                             /* dscratch0_reg                */
`define DSCRATCH1      12'h7b3                             /* dscratch1_reg                */
