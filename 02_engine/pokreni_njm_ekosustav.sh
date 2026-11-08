#!/bin/bash
# =============================================================================
# NJM OS :: UJEDINJENI AUTARHIČNI LALOGLOSATOR POGON (LSBU ISA v4)
# =============================================================================

ULAZ=${1:-".debug/test_full.njm"}

echo "================================================================================="
echo "⚡ [NJM EKOSUSTAV] Pokretanje unificiranog JIT glosatora nad: $ULAZ"
echo "================================================================================="

if [ ! -f "02_engine/glosator_v4" ]; then
    echo "⚙️ Kompajliranje glosator_v4 motora..."
    clang -O2 02_engine/glosator_v4.c -o 02_engine/glosator_v4
fi

# Izvođenje unificiranog glosatora
./02_engine/glosator_v4 < "$ULAZ"

echo "================================================================================="
echo "✅ [STATUS] Izvršavanje završeno uredno uz W^X JIT sukladnost."
echo "================================================================================="
