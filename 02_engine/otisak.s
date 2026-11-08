.global _start
.text

_start:
    // Očitavanje početnog stanja AArch64 brojača ciklusa (CNTVCT_EL0)
    mrs x19, cntvct_el0

    // mkm r10 (Alokacija stoga)
    sub sp, sp, #512
    add x10, sp, #0
    mov x1, 0x5B28
    mov x2, 0x07FF
    orr x3, x1, x2  // uis (Unija)
    eor x4, x1, x2  // srs (Simetrična razlika)
    // Očitavanje završnog stanja AArch64 brojača
    mrs x20, cntvct_el0
    sub x0, x20, x19  // Razlika taktova predaje se u exit code
    mov x8, #93       // SYS_exit
    svc #0
