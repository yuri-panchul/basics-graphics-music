.section .text.nmi_vec
.global nmi_vec
.global run_display

# Обработчик NMI-вектора
nmi_vec:

    csrrw a0, mscratch, a0         # сохраняем регистр a0 и получаем указатель
    sw ra, 0(a0)                   # сохраняем RA
    sw s0, 4(a0)                   # сохраняем s0
    sw s1, 8(a0)                   # сохраняем s1
    addi sp, sp, -16               # резервируем пространство на стеке

    jal ra, run_display            # вызываем run_display()

    lw ra, 0(a0)                   # восстанавливаем RA
    lw s0, 4(a0)                   # восстанавливаем s0
    lw s1, 8(a0)                   # восстанавливаем s1
    addi sp, sp, 16                # освобождаем пространство на стеке
    csrrw a0, mscratch, a0         # восстанавливаем a0 и указатель
    ret                           # выход из обработчика прерывания
