#!/bin/bash
# Testiraj sve glosatore s istim inputom

INPUT="${1:-03_leksik/laloglosator_kanonski_v5.njm}"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   TESTIRANJE GLOSATORA                                        ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "Input: $INPUT"
echo ""

for g in glosator glosator_autarhik glosator_ctrl_matrica glosator_fonemski glosator_kanonski glosator_mjernik glosator_precizni autarhik_lsbu_v2; do
    if [ -x "02_engine/$g" ]; then
        echo "═══ $g ═══"
        timeout 5 "02_engine/$g" "$INPUT" 2>&1 | head -15
        echo ""
    fi
done

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   TEST S PRAZNIM INPUTOM (provjera hardkodiranja)             ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

for g in glosator glosator_autarhik glosator_kanonski; do
    if [ -x "02_engine/$g" ]; then
        echo "═══ $g (prazan input) ═══"
        echo "" | timeout 5 "02_engine/$g" 2>&1 | head -5
        echo ""
    fi
done
