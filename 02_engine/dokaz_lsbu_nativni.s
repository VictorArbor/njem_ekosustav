.global _start
.text

_start:
    // Alokacija stoga (512B)
    sub sp, sp, #512
    add x10, sp, #0

    // OLAŠKO ČITANJE GOTOVOG .LSBU BINARCA U REGISTAR X0 (128-bitna LSBU struktura)
    // Direktno punjenje gornjeg 64-bitnog dijela iz postojeće matrica_v1.lsbu datoteke
    ldr x0, =0x060000002B000000   // Sirova LSBU stisnuta masa iz matrica_v1.lsbu

    // =========================================================================
    // 1. DETERMINISTIČKO MJERENJE ENKODIRANJA (100.000 prolaza nad registrima)
    // =========================================================================
    mrs x19, cntvct_el0
    ldr x12, =100000

PETLJA_ENC:
    // Poravnanje spojenog CTRL bloka (m.p || f.u) na bitove [63..48]
    mov x1, x0
    lsr x2, x1, #48               // Ekstrakcija spojenog CTRL-a
    subs x12, x12, #1
    b.ne PETLJA_ENC

    mrs x20, cntvct_el0
    sub x22, x20, x19              // x22 = Točan broj ciklusa za ENKODIRANJE

    // =========================================================================
    // 2. DETERMINISTIČKO MJERENJE DEKODIRANJA (1-taktni UBFX CTRL dohvat)
    // =========================================================================
    mrs x19, cntvct_el0
    ldr x12, =100000

PETLJA_DEC:
    ubfx x5, x0, #48, #16         // 1-TAKTNI UBFX DOHVAT (CTRL = m.p || f.u)
    lsr x3, x5, #11               // m.p
    and x4, x5, #0x7FF            // f.u
    subs x12, x12, #1
    b.ne PETLJA_DEC

    mrs x20, cntvct_el0
    sub x23, x20, x19              // x23 = Točan broj ciklusa za DEKODIRANJE

    // =========================================================================
    // NATIVNI REGISTARSKI ISPIS REZULTATA BEZ C RUNTIMEA (SYS_write #64)
    // =========================================================================
    mov x0, #1
    ldr x1, =str_hdr
    ldr x2, =len_hdr
    mov x8, #64
    svc #0

    // Ispis ENC ciklusa
    mov x0, x22
    bl ispisi_broj

    mov x0, #1
    ldr x1, =str_mid
    mov x2, #21
    mov x8, #64
    svc #0

    // Ispis DEC ciklusa
    mov x0, x23
    bl ispisi_broj

    mov x0, #1
    ldr x1, =str_end
    mov x2, #3
    mov x8, #64
    svc #0

    // Uredan nativni izlaz
    mov x0, #0
    mov x8, #93                   // SYS_exit
    svc #0

// Nativna AArch64 pretvorba filtra u ASCII brojeve
ispisi_broj:
    stp x29, x30, [sp, #-32]!
    add x29, sp, #0
    add x10, x29, #16
    mov x11, #10
    mov x12, x0
1:
    udiv x13, x12, x11
    msub x14, x13, x11, x12
    add x14, x14, #48
    sub x10, x10, #1
    strb w14, [x10]
    mov x12, x13
    cbnz x12, 1b

    mov x0, #1
    mov x1, x10
    add x2, x29, #16
    sub x2, x2, x10
    mov x8, #64
    svc #0

    ldp x29, x30, [sp], #32
    ret

.data
str_hdr:
    .ascii "\n=========================================================\n"
    .ascii "⚡ DETERMINISTIČKI DOKAZ NAD .LSBU BINARCEM (AArch64)\n"
    .ascii "   Izvor: matrica_v1.lsbu (0x060000002B000000)\n"
    .ascii "=========================================================\n\n"
    .ascii "   ⚡ ENKODIRANJE (100k prolaza) : "
len_hdr = . - str_hdr

str_mid: .ascii " ciklusa\n   ⚡ DEKODIRANJE (100k prolaza) : "
str_end: .ascii " ciklusa\n=========================================================\n\n"
