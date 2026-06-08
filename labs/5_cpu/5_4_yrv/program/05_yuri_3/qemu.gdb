# Set architecture
set architecture riscv:rv32

# Connect to the QEMU port
target remote localhost:1234

# Set breakpoints at entry and trap handler
b _start
b *0x040
b switch_the_contexts
b tp_is_advanced

# --- Automatic display block ---

# Automatically print current Program Counter (PC) in hex on every step
display /x $pc

# Automatically print mtvec value (to verify it changes to 0x040)
display /x $mtvec

# Automatically print mcause value (useful if you trigger an exception)
display /x $mcause

display/i $pc

display /x $mepc

set $pc = 0x200

### GDB Timer Interrupt Simulation Macro

define tick
  set $mepc = 0x2b4
  set $mcause = 0x80000007
  set $pc = $mtvec
  stepi
end

### GDB Custom Context Macro

define context
 printf "\n--- [ CONTEXT WINDOW: -2 / +3 ] ---\n"
 x/6i ($pc - 8)
end

#watch *(char *)0x100000
#commands
#  silent
#  printf "[PORT STATE CHANGED] Current value is: %d\n", *(char *)0x100000
#  continue
#end
#continue
