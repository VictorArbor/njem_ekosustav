#!/bin/bash
# Transpiler: Hrvatski LSBU mnemonici -> Nativni AArch64 Asembler

ULAZ=${1:-"03_leksik/matrica_lsbu.njm"}
IZLAZ_S="02_engine/otisak.s"
IZLAZ_BIN="02_engine/lsbu_binarac"

echo "⚡ [GLOSATOR] Prevođenje LSBU mnemonika u AArch64 binarne uzorke..."

cat << 'ASMELEM' > $IZLAZ_S
.global _start
.text

_start:
    // Očitavanje početnog stanja AArch64 brojača ciklusa (CNTVCT_EL0)
    mrs x19, cntvct_el0

ASMELEM

while read -r linija || [ -n "$linija" ]; do
    # Zanemari komentare i prazne redove
    [[ "$linija" =~ ^#.* ]] && continue
    [[ -z "$linija" ]] && continue

    # Parsiranje hrvatskih LSBU mnemonika
    if [[ "$linija" =~ ^mkm\ r10 ]]; then
        echo "    // mkm r10 (Alokacija stoga)" >> $IZLAZ_S
        echo "    sub sp, sp, #512" >> $IZLAZ_S
        echo "    add x10, sp, #0" >> $IZLAZ_S
    elif [[ "$linija" =~ ^nve\ r([0-9]+),\ (0x[0-9a-fA-F]+|[0-9]+) ]]; then
        reg="${BASH_REMATCH[1]}"
        val="${BASH_REMATCH[2]}"
        echo "    mov x$reg, $val" >> $IZLAZ_S
    elif [[ "$linija" =~ ^uis\ r([0-9]+),\ r([0-9]+),\ r([0-9]+) ]]; then
        rd="${BASH_REMATCH[1]}"; rn="${BASH_REMATCH[2]}"; rm="${BASH_REMATCH[3]}"
        echo "    orr x$rd, x$rn, x$rm  // uis (Unija)" >> $IZLAZ_S
    elif [[ "$linija" =~ ^srs\ r([0-9]+),\ r([0-9]+),\ r([0-9]+) ]]; then
        rd="${BASH_REMATCH[1]}"; rn="${BASH_REMATCH[2]}"; rm="${BASH_REMATCH[3]}"
        echo "    eor x$rd, x$rn, x$rm  // srs (Simetrična razlika)" >> $IZLAZ_S
    elif [[ "$linija" =~ ^pir ]]; then
        echo "    // Očitavanje završnog stanja AArch64 brojača" >> $IZLAZ_S
        echo "    mrs x20, cntvct_el0" >> $IZLAZ_S
        echo "    sub x0, x20, x19  // Razlika taktova predaje se u exit code" >> $IZLAZ_S
        echo "    mov x8, #93       // SYS_exit" >> $IZLAZ_S
        echo "    svc #0" >> $IZLAZ_S
    fi
done < "$ULAZ"

# Izravno asambliranje u ELF64 AArch64 binarac pomoću sistematiziranog asemblera (as/ld)
as $IZLAZ_S -o 02_engine/otisak.o
ld 02_engine/otisak.o -o $IZLAZ_BIN

echo "✅ [SVE ČISTO] AArch64 binarac je izgrađen bez C-runtimea: $IZLAZ_BIN"
