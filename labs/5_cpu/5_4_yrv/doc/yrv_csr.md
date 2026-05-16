| CSR           | Read Only | Writable | Reset in hardware? | Init in software? | Updated on backround?  | Comment                                                                                                       |
| ------------- | --------- |--------- | --------------- | ------------ | ------------ | ------------------------------------------------------------------------------------------------------------- |
| CYCLE         |           | Writable | Not guaranteed  | Should       | Yes          | The counter registers have an arbitrary value after the hart is reset, and can be written with a given value  |
| CYCLEH        |           | Writable | Not guaranteed  | Should       | Yes          | The counter registers have an arbitrary value after the hart is reset, and can be written with a given value  |
| DCSR          |           |          |                 |              |              |                                                                                                               |
| DPC           |           |          |                 |              |              |                                                                                                               |
| DSCRATCH0     |           | Writable |                 |              |              |                                                                                                               |
| DSCRATCH1     |           | Writable |                 |              |              |                                                                                                               |
| INSTRET       |           |          |                 |              |              |                                                                                                               |
| INSTRETH      |           |          |                 |              |              |                                                                                                               |
| MARCHID       | Read Only |          |                 |              |              |                                                                                                               |
| MCAUSE        |           |          |                 |              |              |                                                                                                               |
| MCOUNTINHIBIT |           |          |                 |              |              |                                                                                                               |
| MCYCLE        |           |          |                 |              |              |                                                                                                               |
| MCYCLEH       |           |          |                 |              |              |                                                                                                               |
| MEPC          |           |          |                 |              |              |                                                                                                               |
| MHARTID       |           |          |                 |              |              |                                                                                                               |
| MIE           |           |          |                 |              |              |                                                                                                               |
| MIMPID        | Read Only |          |                 |              |              |                                                                                                               |
| MINSTRET      |           | Writable |                 |              |              |                                                                                                               |
| MINSTRETH     |           | Writable |                 |              |              |                                                                                                               |
| MIP           |           |          |                 |              |              |                                                                                                               |
| MISA          | Read Only |          |                 |              |              |                                                                                                               |
| MSCRATCH      |           | Writable |                 |              |              |                                                                                                               |
| MSTATUS       |           |          |                 |              |              |                                                                                                               |
| MTVAL         |           |          |                 |              |              |                                                                                                               |
| MTVEC         |           |          |                 |              |              |                                                                                                               |
| MVENDORID     | Read Only |          |                 |              |              |                                                                                                               |
| TIME          | Read Only |          | Current time    |              |  Yes         |                                                                                                               |
| TIMEH         | Read Only |          | Current time    |              |  Yes         |                                                                                                               |

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
