
### Run Quemu
```bash
#!/usr/bin/env bash
export PATH=$PATH:"/c/Program Files/qemu"

qemu-system-riscv32 \
  -M none,memory-backend=ram0 \
  -object memory-backend-ram,id=ram0,size=8K \
  -cpu rv32,m=false,zawrs=false,zfa=false,a=false,f=false,d=false,c=false,zicsr=true,priv_spec=v1.12.0,mmu=false,pmp=false \
  -bios none \
  -device loader,file=run/final,force-raw=on\
  -nographic \
  -d in_asm,int,guest_errors \
  -D qemu.log \
  -s -S
```

### Run GDB
```bash
#!/usr/bin/env bash

/c/opt/riscv/bin/riscv-none-elf-gdb.exe run/a.out -x qemu.gdb
```
### GDB Quik reference
- info registers pc — Check the current Program Counter (it should be 0x200)si (stepi) — Step through exactly one assembly instruction. Type - si once, then simply press Enter to keep stepping forward
- info registers t0 sp — View the values written to the t0 and sp registers during initialization
- p /x $mtvec — Print the contents of the mtvec CSR register in hexadecimal to verify that the address 0x040 was successfully written
- b *0x040 — Set a breakpoint at the trap/interrupt handler address. If an error or exception occurs in your code, the CPU will jump there, and GDB will immediately halt execution
- c (continue) — Continue normal program execution until the first breakpoint is hit or the system hangs.

## GDB Configuration for RISC-V 32-bit Debugging

This script automates the initial setup, target connection, and debugging environment configuration for a 32-bit RISC-V system running on QEMU. It initializes the architecture, establishes a remote connection, sets up key breakpoints, configures automatic register tracking for every execution step, and sets the initial execution pointer.

# Set architecture
```tcl
set architecture riscv:rv32
```
# Connect to the QEMU port
```
target remote localhost:1234
```
# Set breakpoints at entry and trap handler
```
b _start
b *0x040
```
# --- Automatic display block ---

# Automatically print current Program Counter (PC) in hex on every step
```
display /x $pc
```
# Automatically print mtvec value (to verify it changes to 0x040)
```
display /x $mtvec
```
# Automatically print mcause value (useful if you trigger an exception)
```
display /x $mcause

display/i $pc

set $pc = 0x200
```

### GDB Timer Interrupt Simulation Macro

This script defines a custom GDB command named `tick` that forces the RISC-V processor to immediately jump into its Machine Timer Interrupt handler, simulating a hardware timer event (`MTI`).

#### Code Breakdown:

*   **`define tick ... end`**
    Creates a new custom user command in GDB named `tick` for timer interrupt simulatind. 
*   **`set $mepc = $pc`**
    Saves the current Program Counter (`$pc`) into the Machine Exception Program Counter (`$mepc`) CSR register. This allows the processor to know where to return after the interrupt service routine ends.
*   **`set $mcause = 0x80000007`**
    Sets the Machine Cause (`$mcause`) CSR register to `0x80000007`. In the RISC-V architecture, this specific bitmask represents a **Machine Timer Interrupt**.
*   **`set $pc = $mtvec`**
    Forces the Program Counter (`$pc`) to jump to the address stored in the Machine Trap-Vector Base-Address (`$mtvec`) CSR register, where your interrupt handler starts.
*   **`stepi`**
    Executes exactly one assembly instruction at the new address. This immediately triggers the entry into the interrupt handler and refreshes the GDB state.

```
define tick
  set $mepc = $pc
  set $mcause = 0x80000007
  set $pc = $mtvec
  stepi
end
```

### GDB Custom Context Macro

This script defines a custom GDB command (macro) named `context` that displays the current instruction pointer ($pc) along with a few preceding and following assembly instructions for better code debugging.

#### Code Breakdown:

*   **`define context ... end`**
    Creates a new custom user command in GDB named `context`. You can trigger it anytime during debugging by simply typing `context`.
*   **`printf "\n--- [ CONTEXT WINDOW: -2 / +3 ] ---\n"`**
    Prints a clean, formatted header in the terminal to visually separate the code context from other GDB outputs.
*   **`x/6i ($pc - 8)`**
    Examines (`x`) and disassembles (`i`) 6 consecutive instructions starting from 8 bytes before the current program counter (`$pc - 8`). 
    *   Since RISC-V instructions are typically 4 bytes long (or 2 bytes for compressed instructions), this effectively displays approximately **2 past instructions** and **3 future instructions**, placing the current instruction right in the middle of the window.

```
define context
 printf "\n--- [ CONTEXT WINDOW: -2 / +3 ] ---\n"
 x/6i ($pc - 8)
end
```
### GDB Global Stop Hook

This script uses GDB's built-in execution hook to automatically run the `context` macro every time the program halts.

#### Code Breakdown:

*   **`define hook-stop ... end`**
    Defines a special built-in GDB hook named `hook-stop`. GDB automatically triggers this block **every time the target application stops execution** for any reason.
*   **`context`**
    Invokes your custom instruction window macro inside the hook. 

#### Why this is useful:
Instead of manually binding commands to individual breakpoints, this hook guarantees that your context window will automatically display whenever the CPU hits a **breakpoint**, triggers a **watchpoint**, or completes a single-step (**`si`** / **`next`**) command. After printing the context, GDB returns full control to you so you can continue single-stepping.

```
define hook-stop
  printf "\n STOPPED AT: "
  frame 0
  context
end
```

### GDB Automated Watchpoint Script

This script automates GDB to monitor a specific memory address and log its changes in real-time without interrupting the execution of the program.

#### Code Breakdown:

*   **`watch *(char *)0x100000`**
    Sets a hardware watchpoint on a 1-byte (`char`) memory location at address `0x100000`. GDB will intercept any write operation to this address.
*   **`commands ... end`**
    Defines a block of commands that GDB executes automatically every time the watchpoint triggers, preventing the need for manual user input.
*   **`silent`**
    Suppresses standard GDB verbose outputs (like line numbers and old/new value details) to keep the console log clean.
*   **`printf "[PORT STATE CHANGED] ...", *(char *)0x100000`**
    Reads the current byte from the specified address and prints the formatted status message directly to the terminal.
*   **`continue`**
    Resumes the execution of the target program immediately after printing the log.

```
watch *(char *)0x100000
commands
  silent
  printf "[PORT STATE CHANGED] Current value is: %d\n", *(char *)0x100000
  continue
end
continue

```

```
define step_until_timer
    set $counter = 0
    while ($counter < 100)
        stepi
        set $counter = $counter + 1
    end
    echo \n[GDB] Timer ID 7...\n
    set $mepc = $pc
    set $mcause = 0x80000007
    set $pc = ($mtvec & ~3) + 28
end
```