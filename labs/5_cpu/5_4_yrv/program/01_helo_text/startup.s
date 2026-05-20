.equ  mie,    0x304
.equ  mtvec,  0x305
.equ  mcause, 0x342
.equ  iobase, 0xffff0     # i/o at 0xffff0000

# ==============================================================================
# SECTION: DEAFULT SCRATCH for interrupt
# ==============================================================================
# Here is DEFAULT mscratch place
# See book : mscratch_reg <= `MSCR_RST;

.section .text.default_mscratch
.global _default_mscratch
_default_mscratch:
    .zero


# ==============================================================================
# SECTION: DEAFULT TRAP HANDLER  0x040
# ==============================================================================

.section .text.trap_ack
.global trap_ack

# Template for common trap handler

trap_ack:
    csrr  t2, mcause           
    bltz  t2, handle_exception 

    srli  t2, t2, 1            
    li    t1, 0x16             
    bne   t1, t2, check_other  

    j common_return           

check_other:
    li    t1, 0x20             
    bltu  t2, t1, unknown      

    
common_return:
    mret                      

handle_exception:
    mret                   

unknown:
    mret

# ==============================================================================
# SECTION: NMI HANDLER 0x100
# ==============================================================================
# NMI Trap handler

.section .text.nmi_vec
.global nmi_vec

nmi_vec:
    mret       


# ==============================================================================
# SECTION: DBG HANDLER 0x140
# ==============================================================================
.section .text.dbg_vec
.global dbg_vec

dbg_vec:  
    dret


# ==============================================================================
# SECTION: DEX HANDLER 0x1c0
# ==============================================================================
.section .text.dex_vec
.global dex_vec
dex_vec:  
    dret


# ==============================================================================
# SECTION: RESET (main) 0x200
# ==============================================================================

.section .text.init
.global _start

_start:
loop:


# ------------------------------------------------------------------------------
# Sub-section: mscratch initialization
# ------------------------------------------------------------------------------
# used trapframe scetion with 128 bytes lenght

    la t0, _trapframe_start
    csrw mscratch, t0

# Inform the debugger that this is the root of the call stack and there are no callers above.
# https://sourceware.org/binutils/docs/as/CFI-directives.html


# ------------------------------------------------------------------------------
# Sub-section: startproc
# ------------------------------------------------------------------------------

.cfi_startproc
.cfi_undefined ra


# .option push     - Save the current assembler options configuration.
# .option norelax  - Disable linker relaxation to prevent relaxation of the GP initialization.
# .option pop      - Restore the previously saved assembler options configuration.
# https://sourceware.org/binutils/docs/as/RISC_002dV_002dDirectives.html
# https://github.com/riscvarchive/riscv-newlib/blob/riscv-newlib-3.2.0/libgloss/riscv/crt0.S


# https://twilco.github.io/riscv-from-scratch/2019/04/27/riscv-from-scratch-2.html
.option push
.option norelax
	la gp, __global_pointer$
.option pop

	la sp, __stack_top
	add s0, sp, zero     #Frame pointer is initialized to the top of the stack.

	jal zero, main
.cfi_endproc

    beq   zero, zero, loop

# ==============================================================================
# END OF PROGRAM
# ==============================================================================
