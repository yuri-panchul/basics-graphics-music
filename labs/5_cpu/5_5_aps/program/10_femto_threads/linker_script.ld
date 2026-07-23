OUTPUT_ARCH ( riscv  )
ENTRY       ( _start )

# TODO: Make MEMORY_SIZE board-specific

PROVIDE (MEMORY_SIZE    = 4K);
PROVIDE (TRAPFRAME_SIZE = 0x100);
PROVIDE (HEAP_SIZE      = 0x100);
PROVIDE (MIN_STACK_SIZE = 0x100);

# TODO Check if this list is complete

PROVIDE (__TRAP_ACK = 0x040);  # TODO: Consider a better name
PROVIDE (__NMI_VEC  = 0x100);
PROVIDE (__DBG_VEC  = 0x140);
PROVIDE (__DEX_VEC  = 0x1c0);
PROVIDE (__RST_BASE = 0x200);

MEMORY
{
  instr_mem (x) : ORIGIN = 0x00000000, LENGTH = MEMORY_SIZE
  data_mem (!x) : ORIGIN = 0x00000000, LENGTH = MEMORY_SIZE
}

SECTIONS
{
    .text :
    {
        KEEP (* (.text.zero))

        # TODO: consider trap ack in a regular .text,
        # since it is set using mtvec

        . = __TRAP_ACK;
        KEEP (* (.text.trap_ack))

        . = __NMI_VEC;
        KEEP (* (.text.nmi_vec))
        . = __DBG_VEC;
        KEEP (* (.text.dbg_vec))
        . = __DEX_VEC;
        KEEP (* (.text.dex_vec))
        . = __RST_BASE;
        KEEP (* (.text.reset))

        * (.text.startup)
        * (.text)
    } > instr_mem

    # Fill the memory from address 0 and all the gaps with zeros.
    # 0 is an illegal instruction in RISC-V that causes an exception.

    = 0

    # TODO: Consider ALIGN (8) to be compatible with 64-bit cores

    .rodata : AT (0x00800000)
    {
        * (.rodata)
    } > data_mem

    .data : ALIGN (4)
    {
        * (.data)
    }

    # .sdata and .sbss must be contiguous for the Linker Relaxation to work
    #
    # Examples:
    #
    # https://github.com/bouffalolab/bl_iot_sdk/blob/master/components/platform/soc/bl602/bl602/evb/ld/ram.ld
    # https://github.com/riscv-mcu/GD32VF103_Firmware_Library/blob/master/Firmware/RISCV/env_Eclipse/GD32VF103x4.lds

    .sdata : ALIGN (4)
    {
        __sdata_start = .;
        PROVIDE (__global_pointer$ = . + 0x800);
        * (.sdata)
    } > data_mem

    .sbss : ALIGN (4)
    {
        __sbss_start = .;
        * (.sbss)
        __sbss_end = .;
    } > data_mem

    .bss : ALIGN (4)
    {
        * (.bss)
        __bss_end = .;
    } > data_mem

    ASSERT (__sbss_end - __sdata_start <= 0x1000,
       ".sdata + .sbss exceed 4 KB gp range")

    # Heap is aligned by 16 because of a typical malloc library implementation

    .heap (NOLOAD) : ALIGN (16)
    {
        __heap_start = .;
        . += HEAP_SIZE;
        __heap_end = .;
    } > data_mem

    # ALIGN (16) from https://docs.riscv.org/reference/abi/riscv-cc-c-cpp-type-details.html
    # https://riscv.org/wp-content/uploads/2024/12/riscv-calling.pdf similar stack

    .trapframe (NOLOAD) : ALIGN (16)  # inspired by xv6, a core from MIT
    {
        __trapframe_start = .;
        . += TRAPFRAME_SIZE;
        __trapframe_end = .;
    } > data_mem

    .stack (NOLOAD) : ALIGN (4)
    {
        __stack_bottom = .;
        . = ABSOLUTE (MEMORY_SIZE);
        __stack_top = .;
    } > data_mem

    ASSERT ((__stack_top - __stack_bottom) >= MIN_STACK_SIZE,
        "Not enough space for the stack: consider increasing MEMORY_SIZE or decreasing MIN_STACK_SIZE")

    /DISCARD/ :
    {
        * (.note.gnu.build-id)
        * (.note.GNU-stack)
        * (.riscv.attributes)
        * (.comment)
    }
}
