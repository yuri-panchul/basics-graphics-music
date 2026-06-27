.section .text.nmi_vec
.global nmi_vec
.global run_display

# NMI Trap handler
nmi_vec:
    mret
