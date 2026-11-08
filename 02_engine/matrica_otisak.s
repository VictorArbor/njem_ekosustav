.global _start
.text

_start:
    // Inicijalizacija stoga r10
    sub sp, sp, #512
    add x10, sp, #0

    mov x0, #0                    // Uredan završetak
    mov x8, #93                   // SYS_exit
    svc #0
