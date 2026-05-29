OUTPUT_ARCH ( riscv  )
ENTRY       ( _start )

MEMORY
{
    BRAM (rwx) : ORIGIN = 0x00000000, LENGTH = 8K
}

# TODO Check if this list is complete

_TRAP_ACK = 0x040;
_NMI_VECT = 0x100;
_DBG_VEC  = 0x140;
_DEX_VEC  = 0x1c0;
_RST_BASE = 0x200;

SECTIONS
{
    PROVIDE (__stack_top = ORIGIN (BRAM) + LENGTH (BRAM));

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
        * (.text.*)
    }
    > BRAM

    .rodata :
    {
        . = ALIGN (4);
        * (.rodata)
    }
    > BRAM

    .data :
    {
        * (.data)
    }
    > BRAM

    # .sdata and .sbss must be contiguous for the Linker Relaxation to work
    #
    # Examples:
    #
    # https://github.com/bouffalolab/bl_iot_sdk/blob/master/components/platform/soc/bl602/bl602/evb/ld/ram.ld
    # https://github.com/riscv-mcu/GD32VF103_Firmware_Library/blob/master/Firmware/RISCV/env_Eclipse/GD32VF103x4.lds

    .sdata :
    {
        . = ALIGN (4);
        __sdata_start = .;
        PROVIDE (__global_pointer$ = . + 0x800);
        * (.sdata)
    }
    > BRAM

    .sbss :
    {
        . = ALIGN (4);
        __sbss_start = .;
        * (.sbss)
        __sbss_end = .;
    }
    > BRAM

    .bss :
    {
        . = ALIGN(4);
        * (.bss)
        __bss_end = .;
    }
    > BRAM

    ASSERT ((__sbss_end - __sdata_start) <= 0x1000,
       ".sdata + .sbss exceed 4 KB gp range")

    .trapframe (NOLOAD) : ALIGN(16)  # inspired by xv6, a core from MIT

    # ALIGN (16) from https://docs.riscv.org/reference/abi/riscv-cc-c-cpp-type-details.html
    # https://riscv.org/wp-content/uploads/2024/12/riscv-calling.pdf similar stack

    {
        __trapframe_start = .;
        . = . + 128;
        __trapframe_end = .;
    }
    > BRAM

    .heap (NOLOAD) : ALIGN (16)
    {
        __heap_start = .;
       # TODO: increase the heap in the future C examples with malloc/free
        . = . + 256;
        __heap_end = .;
    }
    > BRAM

    /DISCARD/ :
    {
        * (.note.gnu.build-id)
        * (.riscv.attributes)
        * (.comment)
    }

    __end = .; # It can be used to cheсk for collision with SP
}
