#!/bin/bash
# Analiza pokrivenosti LSBU ISA po glosatorima

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   ANALIZA POKRIVENOSTI LSBU ISA                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Lista svih 32 mnemonika
MNEMONICI="pis uis ris srs lpo dpo ibo pje nve ujb udb ume gjn gnn pps guo pio nno ppo bar pos usb ssb mkm pkm spe pir vps vus vrs vss ooi"

echo "─── Što svaki glosator podržava ───"
echo ""

# Analiza glosatora
for g in glosator_v3 glosator_autarhik glosator_fonemski glosator_precizni; do
    echo "═══ $g ═══"
    if [ -f "02_engine/$g.c" ]; then
        for m in $MNEMONICI; do
            if grep -qw "$m" "02_engine/$g.c" 2>/dev/null; then
                echo "  ✅ $m"
            fi
        done
    fi
    echo ""
done

echo "─── Analiza parser.njm ───"
if [ -f "02_engine/parser.njm" ]; then
    for m in $MNEMONICI; do
        if grep -qw "$m" "02_engine/parser.njm" 2>/dev/null; then
            echo "  ✅ $m"
        fi
    done
fi

echo ""
echo "─── Ukupna pokrivenost ───"
COVERED=0
for m in $MNEMONICI; do
    if grep -rqw "$m" 02_engine/*.c 02_engine/parser.njm 2>/dev/null; then
        COVERED=$((COVERED + 1))
    fi
done
TOTAL=32
echo "  Pokriveno: $COVERED / $TOTAL ($((COVERED * 100 / TOTAL))%)"
