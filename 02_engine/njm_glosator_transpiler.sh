#!/bin/bash
# NJM Glosator Engine v15.0 :: Autarhični Generator Binarnih Uzoraka i AArch64 Transpiler

ULAZ=${1:-"03_leksik/lalator_kanonski.njm"}
IZLAZ_S="02_engine/njm_kanon.s"
IZLAZ_BIN="02_engine/njm_kanon_bin"

echo "================================================================================="
echo "⚡ [NJM ENGINE] Aktivacija Generatora Binarnih Uzoraka iz Hrvatskih Mnemonika..."
echo "================================================================================="

# MODUL: GENERATOR BINARNIH UZORAKA (LSBU Baza fonemskih masa)
generiraj_lsbu_uzorak() {
    local ulazna_rijec="$1"
    local maska=0
    local shift=0
    
    # Automatizirana generacija binarnog uzorka iz fonemskog niza
    for (( i=0; i<${#ulazna_rijec}; i++ )); do
        local char="${ulazna_rijec:$i:1}"
        local val=$(printf "%d" "'$char")
        local kod=$(( (val & 0x1F) ))
        
        maska=$(( maska | (kod << shift) ))
        shift=$(( shift + 5 ))
    done
    
    printf "0x%016X" $maska
}

# Početak generiranja AArch64 asemblerskog otiska
cat << 'ASMELEM' > $IZLAZ_S
.global _start
.text

_start:
    sub sp, sp, #512
    add x10, sp, #0
    mrs x19, cntvct_el0           // Početak mjerenja taktova

ASMELEM

while read -r linija || [ -n "$linija" ]; do
    [[ "$linija" =~ ^#.* ]] && continue
    [[ -z "$linija" ]] && continue

    # A. MNEMONIK: lsbu_generiraj_uzorak -> Poziva Generator binarnih uzoraka
    if [[ "$linija" =~ ^lsbu_generiraj_uzorak\ r([0-9]+),\ \"([^\"]+)\" ]]; then
        reg="${BASH_REMATCH[1]}"
        rijec="${BASH_REMATCH[2]}"
        
        # Generator u hodu izračunava i stvara binarni uzorak!
        binarni_uzorak=$(generiraj_lsbu_uzorak "$rijec")
        echo "    // Generator stvorio binarni uzorak za '$rijec': $binarni_uzorak" >> $IZLAZ_S
        echo "    ldr x$reg, =$binarni_uzorak" >> $IZLAZ_S

    # B. MNEMONIK: nve -> Nabijanje neposredne vrijednosti (duljina/m.p)
    elif [[ "$linija" =~ ^nve\ r([0-9]+),\ ([0-9]+) ]]; then
        reg="${BASH_REMATCH[1]}"; val="${BASH_REMATCH[2]}"
        echo "    mov x$reg, #$val" >> $IZLAZ_S

    # C. MNEMONIK: enc_ctrl -> Spajanje m.p || f.u u gornje bitove
    elif [[ "$linija" =~ ^enc_ctrl\ r([0-9]+),\ r([0-9]+),\ r([0-9]+) ]]; then
        rd="${BASH_REMATCH[1]}"; r_fu="${BASH_REMATCH[2]}"; r_mp="${BASH_REMATCH[3]}"
        echo "    // ENKODIRANJE: CTRL spajanje (m.p || f.u)" >> $IZLAZ_S
        echo "    lsl x$rd, x$r_mp, #11" >> $IZLAZ_S
        echo "    orr x$rd, x$rd, x$r_fu" >> $IZLAZ_S
        echo "    lsl x$rd, x$rd, #49           // Topološki pomak na bit [63..49]" >> $IZLAZ_S

    # D. MNEMONIK: dec_ctrl -> 1-taktni UBFX dohvat spojenog CTRL-a
    elif [[ "$linija" =~ ^dec_ctrl\ r([0-9]+),\ r([0-9]+),\ r([0-9]+) ]]; then
        r_mp="${BASH_REMATCH[1]}"; r_fu="${BASH_REMATCH[2]}"; r_mid="${BASH_REMATCH[3]}"
        echo "    // DEKODIRANJE: 1-taktni UBFX dohvat" >> $IZLAZ_S
        echo "    ubfx x5, x$r_mid, #49, #15    // 1 TAKT DOHVAT" >> $IZLAZ_S
        echo "    lsr x$r_mp, x5, #11           // m.p razdvojen" >> $IZLAZ_S
        echo "    and x$r_fu, x5, #0x7FF        // f.u razdvojen" >> $IZLAZ_S

    # E. MNEMONIK: pir -> Izlazak i egestija taktova
    elif [[ "$linija" =~ ^pir ]]; then
        echo "    mrs x20, cntvct_el0" >> $IZLAZ_S
        echo "    sub x0, x20, x19              // Razlika u ciklusu šalje se u exit code" >> $IZLAZ_S
        echo "    mov x8, #93                   // SYS_exit" >> $IZLAZ_S
        echo "    svc #0" >> $IZLAZ_S
    fi
done < "$ULAZ"

# Nativno AArch64 asambliranje i povezivanje u samostalni ELF64 binarac
as $IZLAZ_S -o 02_engine/njm_kanon.o
ld 02_engine/njm_kanon.o -o $IZLAZ_BIN

echo "✅ [SVE ČISTO] AArch64 binarac izgrađen u potpunosti po paradigmatskom lancu!"
