CSR           | Used in MIET APS | Read Only | Writable | Value in YRV | Reset in hardware? | Init in software? | Updated on backround?  | Comments....................
------------- | ---------------- | --------- |--------- | ------------ | ------------------ | ----------------- | ---------------------- | ----------------------------
CYCLE         |       | Read Only |          |                   | Not guaranteed  |               | Yes, if enabled | Alias to MCYCLE to use in user mode (no user mode in YRV)
CYCLEH        |       | Read Only |          |                   | Not guaranteed  |               | Yes, if enabled | Alias to MCYCLEH to use in user mode (no user mode in YRV)
DCSR          |       | Some bits |          |                   | Check           | Check         | Check           | Check usage
DPC           |       |           | Writable |                   | Yes, to 0       |               |                 | Check usage
DSCRATCH0     |       |           | Writable |                   | Yes, to 0       |               |                 | Check usage
DSCRATCH1     |       |           | Writable |                   |                 |               |                 | Check usage
INSTRET       |       | Read Only |          |                   | Not guaranteed  |               | Yes, if enabled | Alias to MINSTRET to use in user mode (no user mode in YRV)
INSTRETH      |       | Read Only |          |                   | Not guaranteed  |               | Yes, if enabled | Alias to MINSTRETH to use in user mode (no user mode in YRV)
MARCHID       |       | Read Only |          | 0 or define       |                 |               |                 |
MCAUSE        | Yes   |           |          |                   |                 |               |                 |
MCOUNTINHIBIT |       |           | Writable |                   | Yes, to 0       |               |                 | CY (bit 0) inhibits cycle counting, IR (2) instruction counting. Timer counting (1) is never inhibited.
MCYCLE        |       |           | Writable |                   | Not guaranteed  | Don't have to | Yes, if enabled | The counter registers have an arbitrary value after the hart is reset, and can be written with a given value
MCYCLEH       |       |           | Writable |                   | Not guaranteed  | Don't have to | Yes, if enabled | Upper part of MCYCLE
MEPC          | Yes   |           | Writable |                   |                 |               | Yes             | Is valid and relevant only after the first exception.
MHARTID       |       | Read Only |          | 0, wire from MCU  |                 |               |                 |
MIE           | Yes   |           | Writable |                   | Expected 0, not guaranteed | Generally required | | In YRV the same flop is used for all three IE bits in MIE, as well as MIE bit in MSTATUS
MIMPID        |       | Read Only |          | 0 or define       |                 |               |                 |
MINSTRET      |       |           | Writable |                   | Not guaranteed  | Don't have to | Yes, if enabled | Should be close to 0 but not sure
MINSTRETH     |       |           | Writable |                   | Not guaranteed  | Don't have to | Yes, if enabled | Upper part of MINSTRET
MIP           |       | Read Only in YRV |   |                   |                 |               |                 | Three bits MSIP (3), MTIP (7) and MEIP (11), plus user-defined MLIP [31:0]
MISA          |       | Read Only |          | 0 or define       |                 |               |                 |
MSCRATCH      | Yes   |           | Writable |                   |                 | Yes, for interrupt stack |      | Usage varied depending on internet service routine, see H&H testbook example where this csr is used as a stack pointer.
MSTATUS       |       | Except MIE (bit 3) and MPIE (bit 7) | bits 3 and 7 are writable | 0 except bits 3 and 7 | MPIE=1, MIE=0 | Yes (complicated) | Yes (complicated) | Changes on reset, interrupt, exception, mret or csr write. Read the doc carefully.
MTVAL         |       |           |          |                   |                 |               |                 |
MTVEC         | Yes   |           | Writable |                   |                 | Must if interrupts are used |   | Machine Trap Handler Base-Adress OR-ed with Vectored bit
MVENDORID     |       | Read Only |          | 0 or define       |                 |               |              |
TIME          |       | Read Only |          |                   | Current time    |               |  Yes         |
TIMEH         |       | Read Only |          |                   | Current time    |               |  Yes         |

What has to be initialized in software in the boot code:

* MTVEC - trap vector base OR-ed with vector bit
* MSTATUS - enable interrupts
* MIE - enable interrupts
* MSCRATCH - set the stack pointer for the ISR, interrupt service routine
* MCOUNTINHIBIT - turn on the counters
* MCYCLE/MINSTRET - optionally set the counters to 0
* DCSR и другие debug CSR - not sure, maybe set everything to 0
