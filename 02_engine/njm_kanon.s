.global _start
.text

_start:
    sub sp, sp, #512
    add x10, sp, #0
    mrs x19, cntvct_el0           // Početak mjerenja taktova

    mov x1, #12
    mov x2, #10
    mrs x20, cntvct_el0
    sub x0, x20, x19              // Razlika u ciklusu šalje se u exit code
    mov x8, #93                   // SYS_exit
    svc #0
