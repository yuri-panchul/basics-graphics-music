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
/** YRV Exception Code defines                                        Rev 0.0  03/29/2021 **/
/**                                                                                       **/
/*******************************************************************************************/

/*******************************************************************************************/
/* standard exception code: {mcause_reg[31], mcause_reg[5:0]}                              */
/*******************************************************************************************/
`define EC_NULL    7'h00                                   /* null value                   */
`define EC_NMI     7'h00                                   /* nmi value                    */
`define EC_RST     7'h00                                   /* reset value                  */

`define EC_IALIGN  7'h00                                   /* inst fetch addr misaligned   */
`define EC_IFAULT  7'h01                                   /* inst fetch access fault      */
`define EC_ILLEG   7'h02                                   /* illegal inst                 */
`define EC_BREAK   7'h03                                   /* breakpoint                   */
`define EC_LALIGN  7'h04                                   /* load addr misaligned         */
`define EC_LFAULT  7'h05                                   /* load access fault            */
`define EC_SALIGN  7'h06                                   /* store/amo addr misaligned    */
`define EC_SFAULT  7'h07                                   /* store/amo access fault       */
`define EC_UCALL   7'h08                                   /* ecall from U mode            */
`define EC_SCALL   7'h09                                   /* ecall from S mode            */
`define EC_MCALL   7'h0b                                   /* ecall from M mode            */
`define EC_IPFAULT 7'h0c                                   /* inst fetch page fault        */
`define EC_LPFAULT 7'h0d                                   /* load page fault              */
`define EC_SPFAULT 7'h0f                                   /* store/amo page fault         */

`define EC_USWI    7'h40                                   /* user sw interrupt            */
`define EC_SSWI    7'h41                                   /* supervisor sw interrupt      */
`define EC_MSWI    7'h43                                   /* machine sw interrupt         */
`define EC_UTMRI   7'h44                                   /* user tmr interrupt           */
`define EC_STMRI   7'h45                                   /* supervisor tmr interrupt     */
`define EC_MTMRI   7'h47                                   /* machine tmr interrupt        */
`define EC_UEXTI   7'h48                                   /* user ext interrupt           */
`define EC_SEXTI   7'h49                                   /* supervisor ext interrupt     */
`define EC_MEXTI   7'h4b                                   /* machine ext interrupt        */

/*******************************************************************************************/
/* custom exception code: {mcause_reg[31], mcause_reg[5:0]}                                */
/*******************************************************************************************/
`define EC_LI0     7'h60                                   /* li0 interrupt                */
`define EC_LI1     7'h61                                   /* li1 interrupt                */
`define EC_LI2     7'h62                                   /* li2 interrupt                */
`define EC_LI3     7'h63                                   /* li3 interrupt                */
`define EC_LI4     7'h64                                   /* li4 interrupt                */
`define EC_LI5     7'h65                                   /* li5 interrupt                */
`define EC_LI6     7'h66                                   /* li6 interrupt                */
`define EC_LI7     7'h67                                   /* li7 interrupt                */
`define EC_LI8     7'h68                                   /* li8 interrupt                */
`define EC_LI9     7'h69                                   /* li9 interrupt                */
`define EC_LI10    7'h6a                                   /* li10 interrupt               */
`define EC_LI11    7'h6b                                   /* li11 interrupt               */
`define EC_LI12    7'h6c                                   /* li12 interrupt               */
`define EC_LI13    7'h6d                                   /* li13 interrupt               */
`define EC_LI14    7'h6e                                   /* li14 interrupt               */
`define EC_LI15    7'h6f                                   /* li15 interrupt               */

/*******************************************************************************************/
/* debug mode cause                                                               priority */
/*******************************************************************************************/
`define DC_BRK     3'h2                                    /* brk_req                4     */
`define DC_SW      3'h1                                    /* ebreak inst            3     */
`define DC_HLT     3'h5                                    /* halt_reg               2     */
`define DC_DBG     3'h3                                    /* dbg_req                1     */
`define DC_STEP    3'h4                                    /* step_reg               0     */
