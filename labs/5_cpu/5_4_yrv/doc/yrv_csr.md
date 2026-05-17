| CSR           | Used in MIET APS | Read Only | Writable | Value in YRV      | Reset in hardware? | Init in software? | Updated on backround?  | Comments....................                                                      |
| ------------- | ----- | --------- |--------- | ---------         | --------------- | ------------- | ------------ | ------------------------------------------------------------------------------------------------------------- |
| CYCLE         |       | Read Only | Writable |                   | Not guaranteed  |               | Yes, if enabled | Alias to MCYCLE to use in user mode (no user mode in YRV)
| CYCLEH        |       | Read Only | Writable |                   | Not guaranteed  |               | Yes, if enabled | Alias to MCYCLEH to use in user mode (no user mode in YRV)
| DCSR          |       |           |          |                   |                 |               |              |                                                                                                               |
| DPC           |       |           |          |                   |                 |               |              |                                                                                                               |
| DSCRATCH0     |       |           | Writable |                   |                 |               |              |                                                                                                               |
| DSCRATCH1     |       |           | Writable |                   |                 |               |              |                                                                                                               |
| INSTRET       |       |           |          |                   |                 |               |              |                                                                                                               |
| INSTRETH      |       |           |          |                   |                 |               |              |                                                                                                               |
| MARCHID       |       | Read Only |          | 0 or define       |                 |               |              |                                                                                                               |
| MCAUSE        | Yes   |           |          |                   |                 |               |              |                                                                                                               |
| MCOUNTINHIBIT |       |           |          |                   |                 |               |              |                                                                                                               |
| MCYCLE        |       |           | Writable |                   | Not guaranteed  | Don't have to | Yes, if enabled | The counter registers have an arbitrary value after the hart is reset, and can be written with a given value  |
| MCYCLEH       |       |           | Writable |                   | Not guaranteed  | Don't have to | Yes, if enabled | Upper part of MCYCLE |
| MEPC          | Yes   |           |          |                   |                 |               |                 |                                                                                                               |
| MHARTID       |       | Read Only |          | 0, wire from MCU  |                 |               |                 |                                                                                                               |
| MIE           | Yes   |           | Writable |                   | Expected 0, not guaranteed | Generally required | | In YRV the same flop is used for all three IE bits in MIE, as well as MIE bit in MSTATUS                  |
| MIMPID        |       | Read Only |          | 0 or define       |                 |               |                 |                                                                                                               |
| MINSTRET      |       |           | Writable |                   |                 |               |                 |                                                                                                               |
| MINSTRETH     |       |           | Writable |                   |                 |               |                 |                                                                                                               |
| MIP           |       | Read Only in YRV |   |                   |                 |               |                 | Three bits MSIP (3), MTIP (7) and MEIP (11), plus user-defined MLIP [31:0]                                    |
| MISA          |       | Read Only |          | 0 or define       |                 |               |                 |                                                                                                               |
| MSCRATCH      | Yes   |           | Writable |                   |                 |               |                 |                                                                                                               |
| MSTATUS       |       | Except MIE (bit 3) and MPIE (bit 7) | bits 3 and 7 are writable | 0 except bits 3 and 7 | MPIE=1, MIE=0 | Yes (complicated) | Yes (complicated) | Changes on reset, interrupt, exception, mret or csr write. Read the doc carefully. |
| MTVAL         |       |           |          |                   |                 |               |                 |                                                                                                               |
| MTVEC         | Yes   |           | Writable |                   |                 | Must if interrupts are used |   | Machine Trap Handler Base-Adress OR-ed with Vectored bit                                       |
| MVENDORID     |       | Read Only |          | 0 or define       |                 |               |              |                                                                                                   |
| TIME          |       | Read Only |          |                   | Current time    |               |  Yes         |                                                                                                   |
| TIMEH         |       | Read Only |          |                   | Current time    |               |  Yes         |                                                                                                   |

        mcyinh_reg <= csr_wdata[0];
        mirinh_reg <= csr_wdata[2];
        mie_reg   <= (mstat_wr) ? csr_wdata[3] :
        mpie_reg  <= (mstat_wr) ? csr_wdata[7] :
        mlie_reg  <= csr_wdata[31:16];
        meie_reg  <= csr_wdata[11];   
        mtie_reg  <= csr_wdata[7];    
        msie_reg  <= csr_wdata[3]; 
      if (mscr_wr) mscratch_reg <= csr_wdata;
        mtvec_reg <= csr_wdata[31:2];
        vmode_reg <= csr_wdata[1:0]; 
        ebrkd_reg  <= csr_wdata[15]; 
        stopc_reg  <= csr_wdata[10];
        stopt_reg  <= csr_wdata[9]; 
        step_reg   <= csr_wdata[2]; 
