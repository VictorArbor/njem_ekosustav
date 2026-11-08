.global _start
.text

_start:
    // Inicijalizacija i očitavanje početnog stanja AArch64 brojača (CNTVCT_EL0)
    mrs x19, cntvct_el0

    sub sp, sp, #512
    add x10, sp, #0
    ldr x1, =0x0000000000D8F349
    ldr x2, =11
    // --- ENKODIRANJE (Spajanje u CTRL) ---
    lsl x0, x2, #11         // Pomak m.p na poziciju
    orr x0, x0, x1        // CTRL = m.p || f.u
    lsl x0, x0, #49           // Topološko poravnanje na bit 63..49
    // --- DEKODIRANJE (1-Taktni UBFX CTRL Dohvat) ---
    ubfx x5, x0, #49, #15    // 1 TAKT: Učitavanje cijelog CTRL bloka
    lsr x3, x5, #11           // LSR razdvaja m.p (4 bita)
    and x4, x5, #0x7FF        // AND maskira f.u (11 bita)
    // Očitavanje završnog stanja AArch64 brojača
    mrs x20, cntvct_el0
    sub x0, x20, x19              // Izračunata razlika predaje se u status code
    mov x8, #93                   // SYS_exit
    svc #0
