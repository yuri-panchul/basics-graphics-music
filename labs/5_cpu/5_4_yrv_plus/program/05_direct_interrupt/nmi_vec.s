.section .text.nmi_vec
.global nmi_vec
.global run_display

# NMI Trap handler
nmi_vec:

    csrrw a0, mscratch, a0        
    sw ra, 0(a0)                   
    sw s0, 4(a0)                   
    sw s1, 8(a0)                   
    addi sp, sp, -16               

    jal ra, run_display            

    lw ra, 0(a0)                   
    lw s0, 4(a0)                 
    lw s1, 8(a0)                  
    addi sp, sp, 16               
    csrrw a0, mscratch, a0        
    mret                           
