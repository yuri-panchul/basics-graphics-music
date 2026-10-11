OUTPUT_ARCH ( riscv  )
ENTRY       ( _start )

/* PicoRV32 resets at address 0, and instruction + data share one RAM,
 * so a single region starting at 0 is enough. The end-of-memory check is
 * done with ASSERT at the bottom of the script.
 *
 * Unlike the YRV linker script there are no trap / NMI / debug vectors and
 * no __RST_BASE: PicoRV32 has no RISC-V CSRs, so _start simply sits at 0. */

PROVIDE (MEMORY_SIZE    = 16K);   /* must match data_ram.sv SIZE (4096 words) */
PROVIDE (HEAP_SIZE      = 0x100);
PROVIDE (MIN_STACK_SIZE = 0x100);

SECTIONS
{
    .text 0x0 :
    {
        KEEP (* (.text.reset))   /* _start -> placed at the reset address 0 */

        * (.text.startup)
        * (.text)
        * (.text*)
    }

    /* Fill address 0 and any gaps with zeros. 0 is an illegal instruction
     * in RISC-V, so a runaway fetch traps instead of executing garbage. */

    = 0

    .rodata : ALIGN (4)
    {
        * (.rodata)
        * (.rodata*)
        * (.srodata)
        * (.srodata*)
    }

    .data : ALIGN (4)
    {
        * (.data)
        * (.data*)
    }

    /* .sdata and .sbss must be contiguous for linker relaxation of gp. */

    .sdata : ALIGN (4)
    {
        __sdata_start = .;
        PROVIDE (__global_pointer$ = . + 0x800);
        * (.sdata)
        * (.sdata*)
    }

    .sbss : ALIGN (4)
    {
        __sbss_start = .;
        * (.sbss)
        * (.sbss*)
        __sbss_end = .;
    }

    .bss : ALIGN (4)
    {
        * (.bss)
        * (.bss*)
        * (COMMON)
        __bss_end = .;
    }

    ASSERT (__sbss_end - __sdata_start <= 0x1000,
       ".sdata + .sbss exceed 4 KB gp range")

    /* Heap is aligned by 16 because of a typical malloc implementation. */

    .heap (NOLOAD) : ALIGN (16)
    {
        __heap_start = .;
        . += HEAP_SIZE;
        __heap_end = .;
    }

    .stack (NOLOAD) : ALIGN (16)
    {
        __stack_bottom = .;
        . = ABSOLUTE (MEMORY_SIZE);
        __stack_top = .;
    }

    ASSERT ((__stack_top - __stack_bottom) >= MIN_STACK_SIZE,
        "Not enough space for the stack: increase MEMORY_SIZE or decrease MIN_STACK_SIZE")

    /DISCARD/ :
    {
        * (.note.gnu.build-id)
        * (.note.GNU-stack)
        * (.riscv.attributes)
        * (.comment)
        * (.eh_frame)
        * (.eh_frame*)
    }
}
