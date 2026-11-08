.global _start
.text

_start:
    sub sp, sp, #512
    add x10, sp, #0

    mov x0, #1
    ldr x1, =str_hdr
    ldr x2, =len_hdr
    mov x8, #64
    svc #0

    // -------------------------------------------------------------------------
    // LALATOR UZORAK: 'ja' (2 fonema)
    // -------------------------------------------------------------------------
    // 1. ENKODIRANJE (Riječ -> MID)
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_ENC_2_2:
    ldr x1, =0x000000000029
    ldr x2, =0x1001
    lsl x0, x2, #48
    orr x0, x0, x1                // Spojeni 64-bitni MID
    subs x12, x12, #1
    b.ne PETLJA_ENC_2_2
    mrs x20, cntvct_el0
    sub x22, x20, x19              // Total ciklusa za ENC

    // 2. DEKODIRANJE (MID -> Riječ) sa 1-taktnim UBFX dohvatom
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_DEC_2_2:
    ubfx x5, x0, #48, #16         // 1-TAKTNI TOPOLOŠKI CTRL DOHVAT
    lsr x3, x5, #11               // m.p razdvojen
    and x4, x5, #0x7FF            // f.u razdvojen
    subs x12, x12, #1
    b.ne PETLJA_DEC_2_2
    mrs x20, cntvct_el0
    sub x23, x20, x19              // Total ciklusa za DEC

    // Ispis naziva uzorka
    mov x0, #1
    ldr x1, =lbl_2_2
    ldr x2, =len_lbl_2_2
    mov x8, #64
    svc #0

    // Formatirani izračun taktova
    mov x0, x22
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_razmak
    mov x2, #3
    mov x8, #64
    svc #0

    mov x0, x23
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_novired
    mov x2, #1
    mov x8, #64
    svc #0
    // -------------------------------------------------------------------------
    // LALATOR UZORAK: 'oko' (3 fonema)
    // -------------------------------------------------------------------------
    // 1. ENKODIRANJE (Riječ -> MID)
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_ENC_3_3:
    ldr x1, =0x00000000045C
    ldr x2, =0x1802
    lsl x0, x2, #48
    orr x0, x0, x1                // Spojeni 64-bitni MID
    subs x12, x12, #1
    b.ne PETLJA_ENC_3_3
    mrs x20, cntvct_el0
    sub x22, x20, x19              // Total ciklusa za ENC

    // 2. DEKODIRANJE (MID -> Riječ) sa 1-taktnim UBFX dohvatom
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_DEC_3_3:
    ubfx x5, x0, #48, #16         // 1-TAKTNI TOPOLOŠKI CTRL DOHVAT
    lsr x3, x5, #11               // m.p razdvojen
    and x4, x5, #0x7FF            // f.u razdvojen
    subs x12, x12, #1
    b.ne PETLJA_DEC_3_3
    mrs x20, cntvct_el0
    sub x23, x20, x19              // Total ciklusa za DEC

    // Ispis naziva uzorka
    mov x0, #1
    ldr x1, =lbl_3_3
    ldr x2, =len_lbl_3_3
    mov x8, #64
    svc #0

    // Formatirani izračun taktova
    mov x0, x22
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_razmak
    mov x2, #3
    mov x8, #64
    svc #0

    mov x0, x23
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_novired
    mov x2, #1
    mov x8, #64
    svc #0
    // -------------------------------------------------------------------------
    // LALATOR UZORAK: 'voda' (4 fonema)
    // -------------------------------------------------------------------------
    // 1. ENKODIRANJE (Riječ -> MID)
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_ENC_4_4:
    ldr x1, =0x000000002393
    ldr x2, =0x2005
    lsl x0, x2, #48
    orr x0, x0, x1                // Spojeni 64-bitni MID
    subs x12, x12, #1
    b.ne PETLJA_ENC_4_4
    mrs x20, cntvct_el0
    sub x22, x20, x19              // Total ciklusa za ENC

    // 2. DEKODIRANJE (MID -> Riječ) sa 1-taktnim UBFX dohvatom
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_DEC_4_4:
    ubfx x5, x0, #48, #16         // 1-TAKTNI TOPOLOŠKI CTRL DOHVAT
    lsr x3, x5, #11               // m.p razdvojen
    and x4, x5, #0x7FF            // f.u razdvojen
    subs x12, x12, #1
    b.ne PETLJA_DEC_4_4
    mrs x20, cntvct_el0
    sub x23, x20, x19              // Total ciklusa za DEC

    // Ispis naziva uzorka
    mov x0, #1
    ldr x1, =lbl_4_4
    ldr x2, =len_lbl_4_4
    mov x8, #64
    svc #0

    // Formatirani izračun taktova
    mov x0, x22
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_razmak
    mov x2, #3
    mov x8, #64
    svc #0

    mov x0, x23
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_novired
    mov x2, #1
    mov x8, #64
    svc #0
    // -------------------------------------------------------------------------
    // LALATOR UZORAK: 'trava' (5 fonema)
    // -------------------------------------------------------------------------
    // 1. ENKODIRANJE (Riječ -> MID)
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_ENC_5_5:
    ldr x1, =0x000000066612
    ldr x2, =0x280B
    lsl x0, x2, #48
    orr x0, x0, x1                // Spojeni 64-bitni MID
    subs x12, x12, #1
    b.ne PETLJA_ENC_5_5
    mrs x20, cntvct_el0
    sub x22, x20, x19              // Total ciklusa za ENC

    // 2. DEKODIRANJE (MID -> Riječ) sa 1-taktnim UBFX dohvatom
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_DEC_5_5:
    ubfx x5, x0, #48, #16         // 1-TAKTNI TOPOLOŠKI CTRL DOHVAT
    lsr x3, x5, #11               // m.p razdvojen
    and x4, x5, #0x7FF            // f.u razdvojen
    subs x12, x12, #1
    b.ne PETLJA_DEC_5_5
    mrs x20, cntvct_el0
    sub x23, x20, x19              // Total ciklusa za DEC

    // Ispis naziva uzorka
    mov x0, #1
    ldr x1, =lbl_5_5
    ldr x2, =len_lbl_5_5
    mov x8, #64
    svc #0

    // Formatirani izračun taktova
    mov x0, x22
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_razmak
    mov x2, #3
    mov x8, #64
    svc #0

    mov x0, x23
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_novired
    mov x2, #1
    mov x8, #64
    svc #0
    // -------------------------------------------------------------------------
    // LALATOR UZORAK: 'zemlja' (5 fonema)
    // -------------------------------------------------------------------------
    // 1. ENKODIRANJE (Riječ -> MID)
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_ENC_5_6:
    ldr x1, =0x000000074D54
    ldr x2, =0x280D
    lsl x0, x2, #48
    orr x0, x0, x1                // Spojeni 64-bitni MID
    subs x12, x12, #1
    b.ne PETLJA_ENC_5_6
    mrs x20, cntvct_el0
    sub x22, x20, x19              // Total ciklusa za ENC

    // 2. DEKODIRANJE (MID -> Riječ) sa 1-taktnim UBFX dohvatom
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_DEC_5_6:
    ubfx x5, x0, #48, #16         // 1-TAKTNI TOPOLOŠKI CTRL DOHVAT
    lsr x3, x5, #11               // m.p razdvojen
    and x4, x5, #0x7FF            // f.u razdvojen
    subs x12, x12, #1
    b.ne PETLJA_DEC_5_6
    mrs x20, cntvct_el0
    sub x23, x20, x19              // Total ciklusa za DEC

    // Ispis naziva uzorka
    mov x0, #1
    ldr x1, =lbl_5_6
    ldr x2, =len_lbl_5_6
    mov x8, #64
    svc #0

    // Formatirani izračun taktova
    mov x0, x22
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_razmak
    mov x2, #3
    mov x8, #64
    svc #0

    mov x0, x23
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_novired
    mov x2, #1
    mov x8, #64
    svc #0
    // -------------------------------------------------------------------------
    // LALATOR UZORAK: 'svjetlo' (7 fonema)
    // -------------------------------------------------------------------------
    // 1. ENKODIRANJE (Riječ -> MID)
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_ENC_7_7:
    ldr x1, =0x000046492671
    ldr x2, =0x3837
    lsl x0, x2, #48
    orr x0, x0, x1                // Spojeni 64-bitni MID
    subs x12, x12, #1
    b.ne PETLJA_ENC_7_7
    mrs x20, cntvct_el0
    sub x22, x20, x19              // Total ciklusa za ENC

    // 2. DEKODIRANJE (MID -> Riječ) sa 1-taktnim UBFX dohvatom
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_DEC_7_7:
    ubfx x5, x0, #48, #16         // 1-TAKTNI TOPOLOŠKI CTRL DOHVAT
    lsr x3, x5, #11               // m.p razdvojen
    and x4, x5, #0x7FF            // f.u razdvojen
    subs x12, x12, #1
    b.ne PETLJA_DEC_7_7
    mrs x20, cntvct_el0
    sub x23, x20, x19              // Total ciklusa za DEC

    // Ispis naziva uzorka
    mov x0, #1
    ldr x1, =lbl_7_7
    ldr x2, =len_lbl_7_7
    mov x8, #64
    svc #0

    // Formatirani izračun taktova
    mov x0, x22
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_razmak
    mov x2, #3
    mov x8, #64
    svc #0

    mov x0, x23
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_novired
    mov x2, #1
    mov x8, #64
    svc #0
    // -------------------------------------------------------------------------
    // LALATOR UZORAK: 'kretanje' (7 fonema)
    // -------------------------------------------------------------------------
    // 1. ENKODIRANJE (Riječ -> MID)
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_ENC_7_8:
    ldr x1, =0x00000B664A0B
    ldr x2, =0x382B
    lsl x0, x2, #48
    orr x0, x0, x1                // Spojeni 64-bitni MID
    subs x12, x12, #1
    b.ne PETLJA_ENC_7_8
    mrs x20, cntvct_el0
    sub x22, x20, x19              // Total ciklusa za ENC

    // 2. DEKODIRANJE (MID -> Riječ) sa 1-taktnim UBFX dohvatom
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_DEC_7_8:
    ubfx x5, x0, #48, #16         // 1-TAKTNI TOPOLOŠKI CTRL DOHVAT
    lsr x3, x5, #11               // m.p razdvojen
    and x4, x5, #0x7FF            // f.u razdvojen
    subs x12, x12, #1
    b.ne PETLJA_DEC_7_8
    mrs x20, cntvct_el0
    sub x23, x20, x19              // Total ciklusa za DEC

    // Ispis naziva uzorka
    mov x0, #1
    ldr x1, =lbl_7_8
    ldr x2, =len_lbl_7_8
    mov x8, #64
    svc #0

    // Formatirani izračun taktova
    mov x0, x22
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_razmak
    mov x2, #3
    mov x8, #64
    svc #0

    mov x0, x23
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_novired
    mov x2, #1
    mov x8, #64
    svc #0
    // -------------------------------------------------------------------------
    // LALATOR UZORAK: 'prijatelj' (8 fonema)
    // -------------------------------------------------------------------------
    // 1. ENKODIRANJE (Riječ -> MID)
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_ENC_8_9:
    ldr x1, =0x00034A452E0F
    ldr x2, =0x40AB
    lsl x0, x2, #48
    orr x0, x0, x1                // Spojeni 64-bitni MID
    subs x12, x12, #1
    b.ne PETLJA_ENC_8_9
    mrs x20, cntvct_el0
    sub x22, x20, x19              // Total ciklusa za ENC

    // 2. DEKODIRANJE (MID -> Riječ) sa 1-taktnim UBFX dohvatom
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_DEC_8_9:
    ubfx x5, x0, #48, #16         // 1-TAKTNI TOPOLOŠKI CTRL DOHVAT
    lsr x3, x5, #11               // m.p razdvojen
    and x4, x5, #0x7FF            // f.u razdvojen
    subs x12, x12, #1
    b.ne PETLJA_DEC_8_9
    mrs x20, cntvct_el0
    sub x23, x20, x19              // Total ciklusa za DEC

    // Ispis naziva uzorka
    mov x0, #1
    ldr x1, =lbl_8_9
    ldr x2, =len_lbl_8_9
    mov x8, #64
    svc #0

    // Formatirani izračun taktova
    mov x0, x22
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_razmak
    mov x2, #3
    mov x8, #64
    svc #0

    mov x0, x23
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_novired
    mov x2, #1
    mov x8, #64
    svc #0
    // -------------------------------------------------------------------------
    // LALATOR UZORAK: 'inteligencija' (13 fonema)
    // -------------------------------------------------------------------------
    // 1. ENKODIRANJE (Riječ -> MID)
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_ENC_13_13:
    ldr x1, =0x52C4E456C5273
    ldr x2, =0x6B56
    lsl x0, x2, #48
    orr x0, x0, x1                // Spojeni 64-bitni MID
    subs x12, x12, #1
    b.ne PETLJA_ENC_13_13
    mrs x20, cntvct_el0
    sub x22, x20, x19              // Total ciklusa za ENC

    // 2. DEKODIRANJE (MID -> Riječ) sa 1-taktnim UBFX dohvatom
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_DEC_13_13:
    ubfx x5, x0, #48, #16         // 1-TAKTNI TOPOLOŠKI CTRL DOHVAT
    lsr x3, x5, #11               // m.p razdvojen
    and x4, x5, #0x7FF            // f.u razdvojen
    subs x12, x12, #1
    b.ne PETLJA_DEC_13_13
    mrs x20, cntvct_el0
    sub x23, x20, x19              // Total ciklusa za DEC

    // Ispis naziva uzorka
    mov x0, #1
    ldr x1, =lbl_13_13
    ldr x2, =len_lbl_13_13
    mov x8, #64
    svc #0

    // Formatirani izračun taktova
    mov x0, x22
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_razmak
    mov x2, #3
    mov x8, #64
    svc #0

    mov x0, x23
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_novired
    mov x2, #1
    mov x8, #64
    svc #0
    // -------------------------------------------------------------------------
    // LALATOR UZORAK: 'morfologija' (11 fonema)
    // -------------------------------------------------------------------------
    // 1. ENKODIRANJE (Riječ -> MID)
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_ENC_11_11:
    ldr x1, =0x052CB190908D
    ldr x2, =0x5AAD
    lsl x0, x2, #48
    orr x0, x0, x1                // Spojeni 64-bitni MID
    subs x12, x12, #1
    b.ne PETLJA_ENC_11_11
    mrs x20, cntvct_el0
    sub x22, x20, x19              // Total ciklusa za ENC

    // 2. DEKODIRANJE (MID -> Riječ) sa 1-taktnim UBFX dohvatom
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_DEC_11_11:
    ubfx x5, x0, #48, #16         // 1-TAKTNI TOPOLOŠKI CTRL DOHVAT
    lsr x3, x5, #11               // m.p razdvojen
    and x4, x5, #0x7FF            // f.u razdvojen
    subs x12, x12, #1
    b.ne PETLJA_DEC_11_11
    mrs x20, cntvct_el0
    sub x23, x20, x19              // Total ciklusa za DEC

    // Ispis naziva uzorka
    mov x0, #1
    ldr x1, =lbl_11_11
    ldr x2, =len_lbl_11_11
    mov x8, #64
    svc #0

    // Formatirani izračun taktova
    mov x0, x22
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_razmak
    mov x2, #3
    mov x8, #64
    svc #0

    mov x0, x23
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_novired
    mov x2, #1
    mov x8, #64
    svc #0
    // -------------------------------------------------------------------------
    // LALATOR UZORAK: 'transpilerija' (13 fonema)
    // -------------------------------------------------------------------------
    // 1. ENKODIRANJE (Riječ -> MID)
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_ENC_13_13:
    ldr x1, =0x14B82637C5C612
    ldr x2, =0x6ABB
    lsl x0, x2, #48
    orr x0, x0, x1                // Spojeni 64-bitni MID
    subs x12, x12, #1
    b.ne PETLJA_ENC_13_13
    mrs x20, cntvct_el0
    sub x22, x20, x19              // Total ciklusa za ENC

    // 2. DEKODIRANJE (MID -> Riječ) sa 1-taktnim UBFX dohvatom
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_DEC_13_13:
    ubfx x5, x0, #48, #16         // 1-TAKTNI TOPOLOŠKI CTRL DOHVAT
    lsr x3, x5, #11               // m.p razdvojen
    and x4, x5, #0x7FF            // f.u razdvojen
    subs x12, x12, #1
    b.ne PETLJA_DEC_13_13
    mrs x20, cntvct_el0
    sub x23, x20, x19              // Total ciklusa za DEC

    // Ispis naziva uzorka
    mov x0, #1
    ldr x1, =lbl_13_13
    ldr x2, =len_lbl_13_13
    mov x8, #64
    svc #0

    // Formatirani izračun taktova
    mov x0, x22
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_razmak
    mov x2, #3
    mov x8, #64
    svc #0

    mov x0, x23
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_novired
    mov x2, #1
    mov x8, #64
    svc #0
    // -------------------------------------------------------------------------
    // LALATOR UZORAK: 'reverzibilnost' (14 fonema)
    // -------------------------------------------------------------------------
    // 1. ENKODIRANJE (Riječ -> MID)
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_ENC_14_14:
    ldr x1, =0x946398C2E905350
    ldr x2, =0x76B5
    lsl x0, x2, #48
    orr x0, x0, x1                // Spojeni 64-bitni MID
    subs x12, x12, #1
    b.ne PETLJA_ENC_14_14
    mrs x20, cntvct_el0
    sub x22, x20, x19              // Total ciklusa za ENC

    // 2. DEKODIRANJE (MID -> Riječ) sa 1-taktnim UBFX dohvatom
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_DEC_14_14:
    ubfx x5, x0, #48, #16         // 1-TAKTNI TOPOLOŠKI CTRL DOHVAT
    lsr x3, x5, #11               // m.p razdvojen
    and x4, x5, #0x7FF            // f.u razdvojen
    subs x12, x12, #1
    b.ne PETLJA_DEC_14_14
    mrs x20, cntvct_el0
    sub x23, x20, x19              // Total ciklusa za DEC

    // Ispis naziva uzorka
    mov x0, #1
    ldr x1, =lbl_14_14
    ldr x2, =len_lbl_14_14
    mov x8, #64
    svc #0

    // Formatirani izračun taktova
    mov x0, x22
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_razmak
    mov x2, #3
    mov x8, #64
    svc #0

    mov x0, x23
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_novired
    mov x2, #1
    mov x8, #64
    svc #0
    // -------------------------------------------------------------------------
    // LALATOR UZORAK: 'metabolizacija' (14 fonema)
    // -------------------------------------------------------------------------
    // 1. ENKODIRANJE (Riječ -> MID)
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_ENC_14_14:
    ldr x1, =0x2962346C81324D
    ldr x2, =0x7555
    lsl x0, x2, #48
    orr x0, x0, x1                // Spojeni 64-bitni MID
    subs x12, x12, #1
    b.ne PETLJA_ENC_14_14
    mrs x20, cntvct_el0
    sub x22, x20, x19              // Total ciklusa za ENC

    // 2. DEKODIRANJE (MID -> Riječ) sa 1-taktnim UBFX dohvatom
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_DEC_14_14:
    ubfx x5, x0, #48, #16         // 1-TAKTNI TOPOLOŠKI CTRL DOHVAT
    lsr x3, x5, #11               // m.p razdvojen
    and x4, x5, #0x7FF            // f.u razdvojen
    subs x12, x12, #1
    b.ne PETLJA_DEC_14_14
    mrs x20, cntvct_el0
    sub x23, x20, x19              // Total ciklusa za DEC

    // Ispis naziva uzorka
    mov x0, #1
    ldr x1, =lbl_14_14
    ldr x2, =len_lbl_14_14
    mov x8, #64
    svc #0

    // Formatirani izračun taktova
    mov x0, x22
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_razmak
    mov x2, #3
    mov x8, #64
    svc #0

    mov x0, x23
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_novired
    mov x2, #1
    mov x8, #64
    svc #0
    // -------------------------------------------------------------------------
    // LALATOR UZORAK: 'samoreprodukcija' (16 fonema)
    // -------------------------------------------------------------------------
    // 1. ENKODIRANJE (Riječ -> MID)
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_ENC_16_16:
    ldr x1, =0xA58974720F508D31
    ldr x2, =0x82D5
    lsl x0, x2, #48
    orr x0, x0, x1                // Spojeni 64-bitni MID
    subs x12, x12, #1
    b.ne PETLJA_ENC_16_16
    mrs x20, cntvct_el0
    sub x22, x20, x19              // Total ciklusa za ENC

    // 2. DEKODIRANJE (MID -> Riječ) sa 1-taktnim UBFX dohvatom
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_DEC_16_16:
    ubfx x5, x0, #48, #16         // 1-TAKTNI TOPOLOŠKI CTRL DOHVAT
    lsr x3, x5, #11               // m.p razdvojen
    and x4, x5, #0x7FF            // f.u razdvojen
    subs x12, x12, #1
    b.ne PETLJA_DEC_16_16
    mrs x20, cntvct_el0
    sub x23, x20, x19              // Total ciklusa za DEC

    // Ispis naziva uzorka
    mov x0, #1
    ldr x1, =lbl_16_16
    ldr x2, =len_lbl_16_16
    mov x8, #64
    svc #0

    // Formatirani izračun taktova
    mov x0, x22
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_razmak
    mov x2, #3
    mov x8, #64
    svc #0

    mov x0, x23
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_novired
    mov x2, #1
    mov x8, #64
    svc #0
    // -------------------------------------------------------------------------
    // LALATOR UZORAK: 'kautarhičnostika' (16 fonema)
    // -------------------------------------------------------------------------
    // 1. ENKODIRANJE (Riječ -> MID)
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_ENC_16_16:
    ldr x1, =0xADCA31C66881952B
    ldr x2, =0x8369
    lsl x0, x2, #48
    orr x0, x0, x1                // Spojeni 64-bitni MID
    subs x12, x12, #1
    b.ne PETLJA_ENC_16_16
    mrs x20, cntvct_el0
    sub x22, x20, x19              // Total ciklusa za ENC

    // 2. DEKODIRANJE (MID -> Riječ) sa 1-taktnim UBFX dohvatom
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_DEC_16_16:
    ubfx x5, x0, #48, #16         // 1-TAKTNI TOPOLOŠKI CTRL DOHVAT
    lsr x3, x5, #11               // m.p razdvojen
    and x4, x5, #0x7FF            // f.u razdvojen
    subs x12, x12, #1
    b.ne PETLJA_DEC_16_16
    mrs x20, cntvct_el0
    sub x23, x20, x19              // Total ciklusa za DEC

    // Ispis naziva uzorka
    mov x0, #1
    ldr x1, =lbl_16_16
    ldr x2, =len_lbl_16_16
    mov x8, #64
    svc #0

    // Formatirani izračun taktova
    mov x0, x22
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_razmak
    mov x2, #3
    mov x8, #64
    svc #0

    mov x0, x23
    bl ispisi_broj_ciklusa

    mov x0, #1
    ldr x1, =str_novired
    mov x2, #1
    mov x8, #64
    svc #0
    mov x0, #0
    mov x8, #93                   // SYS_exit
    svc #0

// Nativna potprogramska rutina za registarski ispis ciklusa
ispisi_broj_ciklusa:
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
    .ascii "=================================================================================\n"
    .ascii "⚡ NJM OS :: DETERMINISTIČKO MJERENJE LSBU UZORAKA (2 DO 16 FONEMA)\n"
    .ascii "   Generirano: Diskretni kalkulator & NJM Generator Uzoraka (V=3b / K=5b)\n"
    .ascii "=================================================================================\n\n"
    .ascii "Fonemi | Uzorak Riječi       | ENC Ciklusi (100k) | DEC Ciklusi (100k)\n"
    .ascii "---------------------------------------------------------------------------------\n"
len_hdr = . - str_hdr

str_razmak: .ascii " | "
str_novired: .ascii "\n"

lbl_2_2: .ascii " 2     | ja                 | "
len_lbl_2_2 = . - lbl_2_2
lbl_3_3: .ascii " 3     | oko                | "
len_lbl_3_3 = . - lbl_3_3
lbl_4_4: .ascii " 4     | voda               | "
len_lbl_4_4 = . - lbl_4_4
lbl_5_5: .ascii " 5     | trava              | "
len_lbl_5_5 = . - lbl_5_5
lbl_5_6: .ascii " 5     | zemlja             | "
len_lbl_5_6 = . - lbl_5_6
lbl_7_7: .ascii " 7     | svjetlo            | "
len_lbl_7_7 = . - lbl_7_7
lbl_7_8: .ascii " 7     | kretanje           | "
len_lbl_7_8 = . - lbl_7_8
lbl_8_9: .ascii " 8     | prijatelj          | "
len_lbl_8_9 = . - lbl_8_9
lbl_13_13: .ascii " 13    | inteligencija      | "
len_lbl_13_13 = . - lbl_13_13
lbl_11_11: .ascii " 11    | morfologija        | "
len_lbl_11_11 = . - lbl_11_11
lbl_13_13: .ascii " 13    | transpilerija      | "
len_lbl_13_13 = . - lbl_13_13
lbl_14_14: .ascii " 14    | reverzibilnost     | "
len_lbl_14_14 = . - lbl_14_14
lbl_14_14: .ascii " 14    | metabolizacija     | "
len_lbl_14_14 = . - lbl_14_14
lbl_16_16: .ascii " 16    | samoreprodukcija   | "
len_lbl_16_16 = . - lbl_16_16
lbl_16_16: .ascii " 16    | kautarhičnostika  | "
len_lbl_16_16 = . - lbl_16_16
