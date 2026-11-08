#!/bin/bash
# =============================================================================
# NJM GLOSATOR ENGINE :: DISKRETNI KALKULATOR & GENERATOR LSBU UZORAKA
# =============================================================================

ULAZ=${1:-"03_leksik/matrica_hrvatski.njm"}
IZLAZ_S="02_engine/lsbu_pogon.s"
IZLAZ_BIN="02_engine/lsbu_pogon_bin"

echo "================================================================================="
echo "⚡ [NJM GLOSATOR] Aktivacija Generatora binarnih uzoraka i Diskretnog kalkulatora"
echo "================================================================================="

# MODUL: DISKRETNI KALKULATOR & LSBU GENERATOR (84B LUT Logika: V=3b, K=5b)
# Mapiranje s točnim prepoznavanjem dvoslova (lj, nj, dž) i dijakritika
generiraj_lsbu_teret() {
    local str="$1"
    local len=${#str}
    local idx=0
    local mp=0
    local fu=0
    local teret=0
    local shift=0

    while [ $idx -lt $len ]; do
        local sub2="${str:$idx:2}"
        local sub1="${str:$idx:1}"
        local kod=0
        local je_vokal=0

        # Dvoslovi
        if [[ "$sub2" == "lj" || "$sub2" == "nj" || "$sub2" == "dž" ]]; then
            case "$sub2" in
                "lj") kod=26 ;;
                "nj") kod=27 ;;
                "dž") kod=28 ;;
            esac
            idx=$((idx + 2))
        else
            case "$sub1" in
                a|A) kod=1; je_vokal=1 ;;
                e|E) kod=2; je_vokal=1 ;;
                i|I) kod=3; je_vokal=1 ;;
                o|O) kod=4; je_vokal=1 ;;
                u|U) kod=5; je_vokal=1 ;;
                b|B) kod=1 ;; c|C) kod=2 ;; d|D) kod=3 ;; f|F) kod=4 ;;
                g|G) kod=5 ;; č|Č) kod=6 ;; ć|Ć) kod=7 ;; h|H) kod=8 ;;
                j|J) kod=9 ;; đ|Đ) kod=10 ;; k|K) kod=11 ;; l|L) kod=12 ;;
                m|M) kod=13 ;; n|N) kod=14 ;; p|P) kod=15 ;; r|R) kod=16 ;;
                s|S) kod=17 ;; t|T) kod=18 ;; v|V) kod=19 ;; z|Z) kod=20 ;;
                š|Š) kod=23 ;; ž|Ž) kod=30 ;;
                *) kod=1 ;;
            esac
            idx=$((idx + 1))
        fi

        if [ $je_vokal -eq 1 ]; then
            teret=$(( teret | ((kod & 0x7) << shift) ))
            shift=$((shift + 3))
        else
            teret=$(( teret | ((kod & 0x1F) << shift) ))
            fu=$(( fu | (1 << mp) ))
            shift=$((shift + 5))
        fi
        mp=$((mp + 1))
    done

    # CTRL = m.p (5b) || f.u (11b)
    local ctrl=$(( ((mp & 0x1F) << 11) | (fu & 0x7FF) ))
    
    # MID poravnanje: CTRL [63..48] || Teret [47..0]
    printf "0x%04X 0x%012X %d" $ctrl $teret $mp
}

# POČETAK EMITIRANJA SILIKONSKOG OTISKA
cat << 'ASMELEM' > $IZLAZ_S
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

ASMELEM

while read -r linija || [ -n "$linija" ]; do
    [[ "$linija" =~ ^#.* ]] && continue
    [[ -z "$linija" ]] && continue

    # DISKRETNI KALKULATOR :: Prepoznavanje mnemonika test_uzorak
    if [[ "$linija" =~ ^test_uzorak\ \"([^\"]+)\" ]]; then
        rijec="${BASH_REMATCH[1]}"
        
        # Generator u hodu izračunava LSBU masene parametre
        read ctrl_hex teret_hex mp < <(generiraj_lsbu_teret "$rijec")

        cat << ASM_TEST >> $IZLAZ_S
    // -------------------------------------------------------------------------
    // LALATOR UZORAK: '$rijec' ($mp fonema)
    // -------------------------------------------------------------------------
    // 1. ENKODIRANJE (Riječ -> MID)
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_ENC_${mp}_${#rijec}:
    ldr x1, =$teret_hex
    ldr x2, =$ctrl_hex
    lsl x0, x2, #48
    orr x0, x0, x1                // Spojeni 64-bitni MID
    subs x12, x12, #1
    b.ne PETLJA_ENC_${mp}_${#rijec}
    mrs x20, cntvct_el0
    sub x22, x20, x19              // Total ciklusa za ENC

    // 2. DEKODIRANJE (MID -> Riječ) sa 1-taktnim UBFX dohvatom
    mrs x19, cntvct_el0
    ldr x12, =100000
PETLJA_DEC_${mp}_${#rijec}:
    ubfx x5, x0, #48, #16         // 1-TAKTNI TOPOLOŠKI CTRL DOHVAT
    lsr x3, x5, #11               // m.p razdvojen
    and x4, x5, #0x7FF            // f.u razdvojen
    subs x12, x12, #1
    b.ne PETLJA_DEC_${mp}_${#rijec}
    mrs x20, cntvct_el0
    sub x23, x20, x19              // Total ciklusa za DEC

    // Ispis naziva uzorka
    mov x0, #1
    ldr x1, =lbl_${mp}_${#rijec}
    ldr x2, =len_lbl_${mp}_${#rijec}
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
ASM_TEST

    elif [[ "$linija" =~ ^pir ]]; then
        cat << 'ASM_END' >> $IZLAZ_S
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
ASM_END
    fi
done < "$ULAZ"

# DATA SEKCIJA :: Generiranje dinamike ispisa
cat << 'ASM_DATA' >> $IZLAZ_S

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

ASM_DATA

while read -r linija || [ -n "$linija" ]; do
    if [[ "$linija" =~ ^test_uzorak\ \"([^\"]+)\" ]]; then
        rijec="${BASH_REMATCH[1]}"
        read ctrl_hex teret_hex mp < <(generiraj_lsbu_teret "$rijec")
        
        printf -v poravnan_str " %-6s| %-19s| " "$mp" "$rijec"
        cat << ASM_LBL >> $IZLAZ_S
lbl_${mp}_${#rijec}: .ascii "$poravnan_str"
len_lbl_${mp}_${#rijec} = . - lbl_${mp}_${#rijec}
ASM_LBL
    fi
done < "$ULAZ"

# Asambliranje i povezivanje u ELF64 binarac
as $IZLAZ_S -o 02_engine/lsbu_pogon.o
ld 02_engine/lsbu_pogon.o -o $IZLAZ_BIN
