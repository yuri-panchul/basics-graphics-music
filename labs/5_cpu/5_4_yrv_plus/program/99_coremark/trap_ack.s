.section .text.trap_ack
.global trap_ack

.equ  mie,    0x304
.equ  mtvec,  0x305
.equ  mcause, 0x342
.equ  iobase, 0xffff0     # i/o at 0xffff0000


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

