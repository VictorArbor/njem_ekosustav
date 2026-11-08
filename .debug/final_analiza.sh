#!/bin/bash
# Finalna analiza svih parsera

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   FINALNA ANALIZA LSBU ISA — SVI PARSERI                      ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

MNEMONICI="pis uis ris srs lpo dpo ibo pje nve ujb udb ume gjn gnn pps guo pio nno ppo bar pos usb ssb mkm pkm spe pir vps vus vrs vss ooi"

echo "─── Pokrivenost po datoteci ───"
echo ""

for file in lsbu_na.sh lsbu_hrvatski_assembler.njm laloglosator_pijetao_v62.c glosator_v3.c glosator_autarhik.c parser.njm; do
    if [ -f "$file" ]; then
        echo "═══ $file ═══"
        COUNT=0
        for m in $MNEMONICI; do
            if grep -qw "$m" "$file" 2>/dev/null; then
                COUNT=$((COUNT + 1))
            fi
        done
        echo "  Pokriveno: $COUNT / 32"
        echo ""
    fi
done

echo "─── Ukupna pokrivenost ───"
COVERED=""
for m in $MNEMONICI; do
    if grep -rqw "$m" 02_engine/*.c 02_engine/*.njm *.sh 2>/dev/null; then
        COVERED="$COVERED $m"
    fi
done
echo "  Mnemonici pokriveni: $COVERED"
