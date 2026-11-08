#!/bin/bash
# Glosator Engine v13.2 :: Nativni AArch64 Generira i Pokreće Matricu Mjerenja

ULAZ=${1:-"03_leksik/lalator_matrica_test.njm"}
IZLAZ_S="02_engine/matrica_otisak.s"
IZLAZ_BIN="02_engine/matrica_binarac"

echo "================================================================================="
echo "⚡ [GLOSATOR] Prevođenje Lalator Matrice u AArch64 silikonske binarne uzorke..."
echo "================================================================================="

cat << 'ASMELEM' > $IZLAZ_S
.global _start
.text

_start:
    // Inicijalizacija stoga r10
    sub sp, sp, #512
    add x10, sp, #0

ASMELEM

while read -r linija || [ -n "$linija" ]; do
    [[ "$linija" =~ ^#.* ]] && continue
    [[ -z "$linija" ]] && continue

    if [[ "$linija" =~ ^test_uzorak\ ([0-9]+),\ (0x[0-9a-fA-F]+|[0-9]+),\ \"([^\"]+)\" ]]; then
        mp="${BASH_REMATCH[1]}"
        fu="${BASH_REMATCH[2]}"
        rijec="${BASH_REMATCH[3]}"

        echo "    // --- ISPITNI BLOK: $rijec ($mp fonema) ---" >> $IZLAZ_S
        echo "    mrs x19, cntvct_el0           // Početak mjerenja" >> $IZLAZ_S
        echo "    ldr x1, =$fu" >> $IZLAZ_S
        echo "    mov x2, #$mp" >> $IZLAZ_S
        echo "    // ENKODIRANJE (m.p || f.u)" >> $IZLAZ_S
        echo "    lsl x0, x2, #11" >> $IZLAZ_S
        echo "    orr x0, x0, x1" >> $IZLAZ_S
        echo "    lsl x0, x0, #49               // MID uspostavljen na [63..49]" >> $IZLAZ_S
        echo "    // DEKODIRANJE (1-taktni UBFX CTRL dohvat)" >> $IZLAZ_S
        echo "    ubfx x5, x0, #49, #15         // 1 TAKT DOHVAT" >> $IZLAZ_S
        echo "    lsr x3, x5, #11               // m.p" >> $IZLAZ_S
        echo "    and x4, x5, #0x7FF            // f.u" >> $IZLAZ_S
        echo "    mrs x20, cntvct_el0           // Kraj mjerenja" >> $IZLAZ_S
        echo "    sub x6, x20, x19              // Razlika u x6" >> $IZLAZ_S

    elif [[ "$linija" =~ ^pir ]]; then
        echo "    mov x0, #0                    // Uredan završetak" >> $IZLAZ_S
        echo "    mov x8, #93                   // SYS_exit" >> $IZLAZ_S
        echo "    svc #0" >> $IZLAZ_S
    fi
done < "$ULAZ"

# Nativno asambliranje i prevođenje
as $IZLAZ_S -o 02_engine/matrica_otisak.o
if [ $? -ne 0 ]; then
    echo "❌ Greška pri asambliranju matrice!"
    exit 1
fi

ld 02_engine/matrica_otisak.o -o $IZLAZ_BIN
if [ $? -ne 0 ]; then
    echo "❌ Greška pri povezivanju matrice!"
    exit 1
fi

echo "✅ AArch64 binarac je uspješno izgrađen: $IZLAZ_BIN"
