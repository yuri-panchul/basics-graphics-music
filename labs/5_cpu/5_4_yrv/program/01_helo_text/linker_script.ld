OUTPUT_ARCH ( riscv  )
ENTRY       ( _start )

# We don't need the MEMORY command in our script
# because we don't have separate ROM and RAM,
# the sections start at 0,
# and the memory overflow check is done using ASSERT
# at the end of the script.

# TODO: Make MEMORY_SIZE board-specific

PROVIDE (MEMORY_SIZE    = 0x2000);
PROVIDE (TRAPFRAME_SIZE = 0x100);
PROVIDE (HEAP_SIZE      = 0x100);
PROVIDE (MIN_STACK_SIZE = 0x100);

# TODO Check if this list is complete

_TRAP_ACK = 0x040;
_NMI_VECT = 0x100;
_DBG_VEC  = 0x140;
_DEX_VEC  = 0x1c0;
_RST_BASE = 0x200;

SECTIONS
{
    .text :
    {
        . = _TRAP_ACK;
        KEEP (* (.text.trap_ack))
        . = _NMI_VECT;
        KEEP (* (.text.nmi_vec))
        . = _DBG_VEC;
        KEEP (* (.text.dbg_vec))
        . = _DEX_VEC;
        KEEP (* (.text.dex_vec))
        . = _RST_BASE;
        KEEP (* (.text.init))
        * (.text)
    }

    .rodata : ALIGN (4)
    {
        * (.rodata)
    }

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
    }

    .sbss : ALIGN (4)
    {
        __sbss_start = .;
        * (.sbss)
        __sbss_end = .;
    }

    .bss : ALIGN (4)
    {
        * (.bss)
        __bss_end = .;
    }

    ASSERT (__sbss_end - __sdata_start <= 0x1000,
       ".sdata + .sbss exceed 4 KB gp range")

    # ALIGN (16) from https://docs.riscv.org/reference/abi/riscv-cc-c-cpp-type-details.html
    # https://riscv.org/wp-content/uploads/2024/12/riscv-calling.pdf similar stack

    .trapframe (NOLOAD) : ALIGN (16)  # inspired by xv6, a core from MIT
    {
        __trapframe_start = .;
        . = . + TRAPFRAME_SIZE;
        __trapframe_end = .;
    }

    .heap (NOLOAD) : ALIGN (16)
    {
        __heap_start = .;
        . = . + HEAP_SIZE;
        __heap_end = .;
    }

    .stack (NOLOAD) : ALIGN (4)
    {
        __stack_bottom = .;
        . = MEMORY_SIZE;
        __stack_top = .;
    }

    /DISCARD/ :
    {
        * (.note.gnu.build-id)
        * (.riscv.attributes)
        * (.comment)
    }

    ASSERT (__stack_top - __stack_bottom >= MIN_STACK_SIZE,
        "Not enough space for the stack: consider increasing MEMORY_SIZE or decreasing MIN_STACK_SIZE");
}
