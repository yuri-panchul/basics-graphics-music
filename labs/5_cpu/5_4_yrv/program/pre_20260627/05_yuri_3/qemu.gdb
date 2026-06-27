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


# Automatically print mtvec value (to verify it changes to 0x040)
display /x $mtvec

# Automatically print mcause value (useful if you trigger an exception)
display /x $mcause

# Print PC, MEPC , TP
display /i $pc
display /x $mepc
display /x $tp
display /x $t0
display /x $t1

set $pc = 0x200

### GDB Timer Interrupt Simulation Macro

define tick
  set $mepc = $pc
  set $mcause = 0x80000007
  set $pc = $mtvec
  stepi
end

### GDB Custom Context Macro

define context
 printf "\n--- [ CONTEXT WINDOW: -2 / +3 ] ---\n"
 x/6i ($pc - 8)
end

# For uart
#watch *(char *)0x100000
#commands
#  silent
#  printf "[PORT STATE CHANGED] Current value is: %d\n", *(char *)0x100000
#  continue
#end
#continue

define loop
 set $pc=eternal_loop
end


# Show current thread context
define th
 x/32xw $tp
end

# Show sawed contexts
define tc
  x/96xw &thread_contexts 
end
