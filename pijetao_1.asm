// ═════════════════════════════════════════════════════════════════════
// NJM-OS :: PIJETAO v5.1 — NATIVNI HRVATSKI LSBU JIT EMITTER (FIXED)
// ─────────────────────────────────────────────────────────────────────
// Potpuna poravnatost stoga (16-byte alignment), stabilan JIT i ABI
// ═════════════════════════════════════════════════════════════════════

.arch armv8-a
.text
.align 4

.set SYS_read,     63
.set SYS_write,    64
.set SYS_exit,     93
.set SYS_mmap,     222

.set ULAZ_VELICINA,   8192
.set JIT_VELICINA,    65536
.set TOKEN_MAX,       32
.set BROJ_TOKENA,     8

// ─── PORAVNATE BSS VARIJABLE (64-BIT ALIGNED) ──────────────────────
.bss
.align 4
ulaz_buffer:    .skip ULAZ_VELICINA
.align 4
izlaz_buffer:   .skip 256
.align 4
jit_mem:        .skip 8
.align 4
jit_pc:         .skip 8
.align 4
ulaz_len:       .skip 8
.align 4
ulaz_idx:       .skip 8
.align 4
linija_pc:      .skip 8
.align 4
tablica_oznaka: .skip 4096
.align 4
broj_oznaka:    .skip 8
.align 4
tokeni:         .skip TOKEN_MAX * BROJ_TOKENA
.align 4
broj_tokena:    .skip 8

.text
.align 4
.global _start

_start:
    // ─── 1. INICIJALIZACIJA JIT MEMORIJE (mmap RWX) ──────────────────
    mov     x0, #0
    mov     x1, #JIT_VELICINA
    mov     x2, #7                       // PROT_READ|WRITE|EXEC
    mov     x3, #0x22                    // MAP_PRIVATE|ANON
    mov     x4, #-1
    mov     x5, #0
    mov     x8, #SYS_mmap
    svc     #0
    
    // Provjera valjanosti alocirane memorije
    cmp     x0, #0
    b.le    kraj_greska

    adr     x1, jit_mem
    str     x0, [x1]

    // ─── 2. RESETIRANJE INDEKSA ──────────────────────────────────────
    adr     x1, jit_pc
    str     xzr, [x1]
    adr     x1, linija_pc
    str     xzr, [x1]
    adr     x1, broj_oznaka
    str     xzr, [x1]

    // ─── 3. ČITANJE ULAVNOG LSBU SKRIPTA S STDIN-A ───────────────────
    mov     x0, #0
    adr     x1, ulaz_buffer
    mov     x2, #ULAZ_VELICINA
    mov     x8, #SYS_read
    svc     #0
    
    cmp     x0, #0
    b.le    kraj

    adr     x1, ulaz_len
    str     x0, [x1]

    // ─── 4. PROLAZ 1: PRIKUPLJANJE OZNAKA ───────────────────────────
    bl      skupi_oznake

    // ─── 5. PROLAZ 2: KODIRANJE I EMITIRANJE U RAM ────────────────────
    adr     x1, ulaz_idx
    str     xzr, [x1]
    adr     x1, jit_pc
    str     xzr, [x1]
    adr     x1, linija_pc
    str     xzr, [x1]

    bl      kodiraj_petlja

    // OSIGURANJE ZAVRŠETKA JIT BLOKA S PIR (RET)
    movz    x0, #0xD65F, lsl #16
    movk    x0, #0x03C0
    bl      emit_op

    // ─── 6. IZVRŠAVANJE GENERIRANOG JIT SKLOPA IZ RAM-A ──────────────
    adr     x1, jit_pc
    ldr     x1, [x1]
    cbz     x1, kraj

    adr     x1, jit_mem
    ldr     x1, [x1]
    blr     x1

kraj:
    mov     x0, #0
    mov     x8, #SYS_exit
    svc     #0

kraj_greska:
    mov     x0, #1
    mov     x8, #SYS_exit
    svc     #0

// ═════════════════════════════════════════════════════════════════════
// skupi_oznake :: PROLAZ 1
// ═════════════════════════════════════════════════════════════════════
skupi_oznake:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]

    adr     x19, ulaz_idx
    str     xzr, [x19]

    adr     x20, linija_pc
    str     xzr, [x20]

skup_oznaka_petlja:
    bl      preskoci_ws

    adr     x0, ulaz_idx
    ldr     x0, [x0]
    adr     x1, ulaz_len
    ldr     x1, [x1]
    cmp     x0, x1
    b.ge    skup_oznaka_kraj

    adr     x2, ulaz_buffer
    ldrb    w3, [x2, x0]

    cmp     w3, #'#'
    b.eq    skup_preskoci_komentar

    cmp     w3, #'\n'
    b.eq    skup_sljedeci_red

    mov     x4, x0
skup_trazi_dvotocku:
    adr     x2, ulaz_buffer
    ldrb    w3, [x2, x4]
    cmp     w3, #'\n'
    b.eq    skup_nije_oznaka
    cmp     w3, #0
    b.eq    skup_nije_oznaka
    cmp     w3, #':'
    b.eq    skup_jest_oznaka
    add     x4, x4, #1
    b       skup_trazi_dvotocku

skup_jest_oznaka:
    adr     x5, broj_oznaka
    ldr     x6, [x5]
    lsl     x7, x6, #4
    adr     x8, tablica_oznaka
    add     x8, x8, x7

    mov     x9, #0
skup_kopiraj_ime:
    cmp     x9, #8
    b.ge    skup_ime_kraj
    add     x10, x0, x9
    cmp     x10, x4
    b.ge    skup_ime_kraj
    adr     x11, ulaz_buffer
    ldrb    w12, [x11, x10]
    strb    w12, [x8, x9]
    add     x9, x9, #1
    b       skup_kopiraj_ime

skup_ime_kraj:
    adr     x5, linija_pc
    ldr     x6, [x5]
    str     x6, [x8, #8]

    adr     x5, broj_oznaka
    ldr     x6, [x5]
    add     x6, x6, #1
    str     x6, [x5]

    add     x0, x4, #1
    adr     x2, ulaz_idx
    str     x0, [x2]
    b       skup_sljedeci_red

skup_nije_oznaka:
    adr     x5, linija_pc
    ldr     x6, [x5]
    add     x6, x6, #1
    str     x6, [x5]

skup_sljedeci_red:
    bl      preskoci_do_kraja_reda
    b       skup_oznaka_petlja

skup_preskoci_komentar:
    bl      preskoci_do_kraja_reda
    b       skup_oznaka_petlja

skup_oznaka_kraj:
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

// ═════════════════════════════════════════════════════════════════════
// kodiraj_petlja :: PROLAZ 2
// ═════════════════════════════════════════════════════════════════════
kodiraj_petlja:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

kodiraj_provjeri:
    bl      preskoci_ws

    adr     x0, ulaz_idx
    ldr     x0, [x0]
    adr     x1, ulaz_len
    ldr     x1, [x1]
    cmp     x0, x1
    b.ge    kodiraj_kraj

    adr     x2, ulaz_buffer
    ldrb    w3, [x2, x0]

    cmp     w3, #'#'
    b.eq    kodiraj_preskoci
    cmp     w3, #'\n'
    b.eq    kodiraj_preskoci

    bl      tokeniziraj_liniju

    adr     x0, broj_tokena
    ldr     x0, [x0]
    cbz     x0, kodiraj_preskoci

    adr     x1, tokeni
    ldrb    w2, [x1]
    cmp     x0, #2
    b.lt    kodiraj_instrukciju
    add     x3, x1, #TOKEN_MAX
    ldrb    w4, [x3]
    cmp     w4, #':'
    b.eq    kodiraj_preskoci

kodiraj_instrukciju:
    bl      dispatch_mnemonik

kodiraj_preskoci:
    bl      preskoci_do_kraja_reda
    b       kodiraj_provjeri

kodiraj_kraj:
    ldp     x29, x30, [sp], #16
    ret

// ═════════════════════════════════════════════════════════════════════
// tokeniziraj_liniju
// ═════════════════════════════════════════════════════════════════════
tokeniziraj_liniju:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    str     x21, [sp, #24]

    adr     x19, broj_tokena
    str     xzr, [x19]

    adr     x20, tokeni

token_petlja:
    adr     x0, ulaz_idx
    ldr     x0, [x0]
token_preskoci:
    adr     x2, ulaz_buffer
    ldrb    w3, [x2, x0]
    cmp     w3, #' '
    b.eq    token_preskoci_inc
    cmp     w3, #'\t'
    b.eq    token_preskoci_inc
    cmp     w3, #','
    b.eq    token_preskoci_inc
    b       token_provjeri_kraj

token_preskoci_inc:
    add     x0, x0, #1
    b       token_preskoci

token_provjeri_kraj:
    cmp     w3, #'\n'
    b.eq    token_gotovo
    cmp     w3, #0
    b.eq    token_gotovo
    cmp     w3, #'#'
    b.eq    token_gotovo

    adr     x5, broj_tokena
    ldr     x6, [x5]
    cmp     x6, #BROJ_TOKENA
    b.ge    token_gotovo

    mov     x7, #TOKEN_MAX
    mul     x7, x6, x7
    add     x7, x20, x7

    mov     x9, #0

token_kopiraj:
    adr     x2, ulaz_buffer
    ldrb    w3, [x2, x0]

    cmp     w3, #' '
    b.eq    token_zavrsi
    cmp     w3, #'\t'
    b.eq    token_zavrsi
    cmp     w3, #','
    b.eq    token_zavrsi
    cmp     w3, #'\n'
    b.eq    token_zavrsi
    cmp     w3, #0
    b.eq    token_zavrsi
    cmp     w3, #'#'
    b.eq    token_zavrsi

    cmp     x9, #TOKEN_MAX
    b.ge    token_zavrsi
    strb    w3, [x7, x9]
    add     x9, x9, #1
    add     x0, x0, #1
    b       token_kopiraj

token_zavrsi:
    cmp     x9, #TOKEN_MAX
    b.ge    token_zavrsi_bez_null
    strb    wzr, [x7, x9]
token_zavrsi_bez_null:

    adr     x5, broj_tokena
    ldr     x6, [x5]
    add     x6, x6, #1
    str     x6, [x5]

    adr     x2, ulaz_idx
    str     x0, [x2]
    b       token_petlja

token_gotovo:
    adr     x2, ulaz_idx
    str     x0, [x2]
    ldr     x21, [sp, #24]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

preskoci_ws:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

preskoci_ws_petlja:
    adr     x0, ulaz_idx
    ldr     x0, [x0]
    adr     x1, ulaz_len
    ldr     x1, [x1]
    cmp     x0, x1
    b.ge    preskoci_ws_kraj

    adr     x2, ulaz_buffer
    ldrb    w3, [x2, x0]

    cmp     w3, #' '
    b.eq    preskoci_ws_inc
    cmp     w3, #'\t'
    b.eq    preskoci_ws_inc
    b       preskoci_ws_kraj

preskoci_ws_inc:
    add     x0, x0, #1
    adr     x2, ulaz_idx
    str     x0, [x2]
    b       preskoci_ws_petlja

preskoci_ws_kraj:
    ldp     x29, x30, [sp], #16
    ret

preskoci_do_kraja_reda:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

pdkr_petlja:
    adr     x0, ulaz_idx
    ldr     x0, [x0]
    adr     x1, ulaz_len
    ldr     x1, [x1]
    cmp     x0, x1
    b.ge    pdkr_kraj

    adr     x2, ulaz_buffer
    ldrb    w3, [x2, x0]

    cmp     w3, #'\n'
    b.eq    pdkr_naprijed
    add     x0, x0, #1
    adr     x2, ulaz_idx
    str     x0, [x2]
    b       pdkr_petlja

pdkr_naprijed:
    add     x0, x0, #1
    adr     x2, ulaz_idx
    str     x0, [x2]

pdkr_kraj:
    ldp     x29, x30, [sp], #16
    ret

// ═════════════════════════════════════════════════════════════════════
// dispatch_mnemonik
// ═════════════════════════════════════════════════════════════════════
dispatch_mnemonik:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]

    adr     x19, tokeni

    ldrb    w0, [x19]
    ldrb    w1, [x19, #1]
    ldrb    w2, [x19, #2]

    cmp     w0, #'p'
    b.ne    dm_nije_p

    cmp     w1, #'i'
    b.ne    dm_nije_pi

    cmp     w2, #'s'
    b.eq    handle_pis
    cmp     w2, #'r'
    b.eq    handle_pir
    cmp     w2, #'o'
    b.eq    handle_pio
    b       dm_kraj

dm_nije_pi:
    cmp     w1, #'j'
    b.ne    dm_nije_pj
    cmp     w2, #'e'
    b.eq    handle_pje
    b       dm_kraj

dm_nije_pj:
    cmp     w1, #'p'
    b.ne    dm_kraj
    cmp     w2, #'s'
    b.eq    handle_pps
    cmp     w2, #'o'
    b.eq    handle_ppo
    b       dm_kraj

dm_nije_p:
    cmp     w0, #'u'
    b.ne    dm_nije_u

    cmp     w1, #'i'
    b.ne    dm_nije_ui
    cmp     w2, #'s'
    b.eq    handle_uis
    b       dm_kraj

dm_nije_ui:
    cmp     w1, #'j'
    b.ne    dm_nije_uj
    cmp     w2, #'b'
    b.eq    handle_ujb
    b       dm_kraj

dm_nije_uj:
    cmp     w1, #'s'
    b.ne    dm_nije_us
    cmp     w2, #'b'
    b.eq    handle_usb
    b       dm_kraj

dm_nije_us:
    cmp     w1, #'m'
    b.ne    dm_kraj
    cmp     w2, #'e'
    b.eq    handle_ume
    b       dm_kraj

dm_nije_u:
    cmp     w0, #'r'
    b.ne    dm_nije_r
    cmp     w1, #'i'
    b.ne    dm_kraj
    cmp     w2, #'s'
    b.eq    handle_ris
    b       dm_kraj

dm_nije_r:
    cmp     w0, #'s'
    b.ne    dm_nije_s
    cmp     w1, #'r'
    b.ne    dm_nije_sr
    cmp     w2, #'s'
    b.eq    handle_srs
    b       dm_kraj

dm_nije_sr:
    cmp     w1, #'p'
    b.ne    dm_nije_sp
    cmp     w2, #'e'
    b.eq    handle_spe
    b       dm_kraj

dm_nije_sp:
    cmp     w1, #'s'
    b.ne    dm_kraj
    cmp     w2, #'b'
    b.eq    handle_ssb
    b       dm_kraj

dm_nije_s:
    cmp     w0, #'v'
    b.ne    dm_nije_v
    cmp     w1, #'p'
    b.eq    dm_vp
    cmp     w1, #'u'
    b.eq    dm_vu
    cmp     w1, #'r'
    b.eq    dm_vr
    cmp     w1, #'s'
    b.eq    dm_vs
    b       dm_kraj

dm_vp:
    cmp     w2, #'s'
    b.eq    handle_vps
    b       dm_kraj

dm_vu:
    cmp     w2, #'s'
    b.eq    handle_vus
    b       dm_kraj

dm_vr:
    cmp     w2, #'s'
    b.eq    handle_vrs
    b       dm_kraj

dm_vs:
    cmp     w2, #'s'
    b.eq    handle_vss
    b       dm_kraj

dm_nije_v:
    cmp     w0, #'n'
    b.ne    dm_nije_n
    cmp     w1, #'v'
    b.eq    dm_nv
    cmp     w1, #'n'
    b.eq    dm_nn
    b       dm_kraj

dm_nv:
    cmp     w2, #'e'
    b.eq    handle_nve
    b       dm_kraj

dm_nn:
    cmp     w2, #'o'
    b.eq    handle_nno
    b       dm_kraj

dm_nije_n:
    cmp     w0, #'l'
    b.eq    dm_l
    cmp     w0, #'d'
    b.eq    dm_d
    b       dm_kraj

dm_l:
    cmp     w1, #'p'
    b.ne    dm_kraj
    cmp     w2, #'o'
    b.eq    handle_lpo
    b       dm_kraj

dm_d:
    cmp     w1, #'p'
    b.ne    dm_kraj
    cmp     w2, #'o'
    b.eq    handle_dpo
    b       dm_kraj

dm_kraj:
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

// ═════════════════════════════════════════════════════════════════════
// HANDLERI — ISPRANJI STOG I SKOKOVI (PORAVNATO)
// ═════════════════════════════════════════════════════════════════════

handle_pis:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0x8A01, lsl #16
    movk    x0, #0x0002
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_uis:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0xAA01, lsl #16
    movk    x0, #0x0002
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_ris:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0x8A21, lsl #16
    movk    x0, #0x0002
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_srs:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0xCA01, lsl #16
    movk    x0, #0x0002
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_vps:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0x4E21, lsl #16
    movk    x0, #0x1C02
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_vus:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0x4EA1, lsl #16
    movk    x0, #0x1C02
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_vrs:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0x4E61, lsl #16
    movk    x0, #0x1C02
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_vss:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0x6E21, lsl #16
    movk    x0, #0x1C02
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_nve:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0xD280, lsl #16
    movk    x0, #0x0800
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_pje:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0xAA01, lsl #16
    movk    x0, #0x03E2
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_ujb:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0x3940, lsl #16
    movk    x0, #0x0001
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_udb:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0x3940, lsl #16
    movk    x0, #0x0402
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_usb:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0x3861, lsl #16
    movk    x0, #0x6801
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_ssb:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0x3900, lsl #16
    movk    x0, #0x0401
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_ume:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0xEB01, lsl #16
    movk    x0, #0x001F
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_gjn:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0xB400, lsl #16
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_gnn:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0xB500, lsl #16
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_guo:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0x5400, lsl #16
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_pio:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0x1400, lsl #16
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_ppo:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0x9400, lsl #16
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_lpo:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0xD37A, lsl #16
    movk    x0, #0xEC02
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_dpo:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0xD37A, lsl #16
    movk    x0, #0xFC02
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_nno:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0xD503, lsl #16
    movk    x0, #0x201F
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_bar:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0xD503, lsl #16
    movk    x0, #0x3BBF
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_ooi:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0xD63F, lsl #16
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_spe:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0xD400, lsl #16
    movk    x0, #0x0801
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

handle_pir:
handle_pps:
handle_pos:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    movz    x0, #0xD65F, lsl #16
    movk    x0, #0x03C0
    bl      emit_op
    ldp     x29, x30, [sp], #16
    ret

// ═════════════════════════════════════════════════════════════════════
// emit_op :: Emitiranje instrukcije u JIT RAM
// ═════════════════════════════════════════════════════════════════════
emit_op:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    adr     x1, jit_pc
    ldr     x2, [x1]
    adr     x3, jit_mem
    ldr     x4, [x3]

    lsl     x5, x2, #2
    add     x4, x4, x5
    str     w0, [x4]

    add     x2, x2, #1
    str     x2, [x1]

    ldp     x29, x30, [sp], #16
    ret
