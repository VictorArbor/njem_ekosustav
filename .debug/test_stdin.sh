#!/bin/bash
# Testiraj glosatore s STDIN (ne argument)

INPUT=".debug/mini.njm"

cat > "$INPUT" << 'EOF'
mkm r10
wrt 1, "AB\n"
pir
EOF

echo "═══ Test s mini.njm (Format B: mkm, wrt, pir) ═══"
echo ""

for g in glosator_autarhik glosator_fonemski glosator_precizni glosator_kanonski; do
    if [ -x "02_engine/$g" ]; then
        echo "─── $g ───"
        timeout 3 "02_engine/$g" < "$INPUT" 2>&1 | head -10
        echo ""
    fi
done

echo "═══ Test s laloglosator_kanonski_v5.njm ═══"
echo ""

for g in glosator_autarhik glosator_fonemski glosator_precizni glosator_kanonski; do
    if [ -x "02_engine/$g" ]; then
        echo "─── $g ───"
        timeout 3 "02_engine/$g" < 03_leksik/laloglosator_kanonski_v5.njm 2>&1 | head -10
        echo ""
    fi
done
