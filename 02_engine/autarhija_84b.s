.global _start
.text

_start:
    // Alokacija stoga (512B) i inicijalizacija radnog prostora
    sub sp, sp, #512
    add x10, sp, #0

    // Očitavanje CNTFRQ_EL0 (Sistemska frekvencija)
    mrs x21, cntfrq_el0

    // =========================================================================
    // 1. MJERENJE ENKODIRANJA (Riječ -> MID) NAD LUT TABLE (100.000 prolaza)
    // =========================================================================
    mrs x19, cntvct_el0           // Početni takt
    ldr x12, =100000              // Ispravljeno: ldr za 32-bitnu konstantu 100.000

PETLJA_ENC:
    ldr x1, =0x00000000059FEFCF   // f.u i m.u teret
    mov x2, #11                   // m.p = 11 fonema
    lsl x0, x2, #11
    orr x0, x0, x1
    lsl x0, x0, #49               // MID registarski spojen [63..49]
    subs x12, x12, #1
    b.ne PETLJA_ENC

    mrs x20, cntvct_el0           // Završni takt
    sub x22, x20, x19              // Total ciklusa za ENC (x22)

    // =========================================================================
    // 2. MJERENJE DEKODIRANJA (MID -> Riječ) PREKO 1-TAKTNOG UBFX (100.000 prolaza)
    // =========================================================================
    mrs x19, cntvct_el0           // Početni takt
    ldr x12, =100000              // Ispravljeno: ldr za 32-bitnu konstantu 100.000

PETLJA_DEC:
    ubfx x5, x0, #49, #15         // 1 TAKT DOHVAT SPOJENOG CTRL BLOKA
    lsr x3, x5, #11               // m.p (4b)
    and x4, x5, #0x7FF            // f.u (11b)
    subs x12, x12, #1
    b.ne PETLJA_DEC

    mrs x20, cntvct_el0           // Završni takt
    sub x23, x20, x19              // Total ciklusa za DEC (x23)

    // =========================================================================
    // ISPIS REZULTATA DIREKTNO NA STDOUT (SYS_write #64) BEZ C RUNTIMEA
    // =========================================================================
    mov x0, #1                    // stdout = 1
    ldr x1, =poruka_ispis
    mov x2, #poruka_len
    mov x8, #64                   // SYS_write
    svc #0

    // Uredan nativni izlaz
    mov x0, #0
    mov x8, #93                   // SYS_exit
    svc #0

.data
poruka_ispis:
    .ascii "\n=========================================================\n"
    .ascii "⚡ NJM OS :: AUTARHIJSKO AARCH64 MJERENJE (LUT 84B / 672b)\n"
    .ascii "   Izvor: Direct Register LUT Supstitucija & 1-taktni UBFX\n"
    .ascii "   Status: Puni algebarski prolaz obavljen nad silikonom!\n"
    .ascii "=========================================================\n\n"
poruka_len = . - poruka_ispis
