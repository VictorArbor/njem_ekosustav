#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

cd ~/njm_2_ekosustav_01

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║  NJM-OS :: DIJAGNOSTIČKA VERIFIKACIJA PRIJE ČIŠĆENJA C KODA  ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

PASS=0
FAIL=0

for njm_file in test_*.njm; do
    if [ -f "$njm_file" ]; then
        out_bin="${njm_file%.njm}.bin"
        echo -n "[TEST] $njm_file ... "
        
        if ./lsbu_as_v3.sh "$njm_file" "$out_bin" > /dev/null 2>&1; then
            if ./"$out_bin" > /dev/null 2>&1; then
                echo "✅ PROŠAO"
                PASS=$((PASS + 1))
            else
                echo "⚠️ GREŠKA PRI IZVRŠENJU"
                FAIL=$((FAIL + 1))
            fi
        else
            echo "❌ GREŠKA PRI PREVOĐENJU"
            FAIL=$((FAIL + 1))
        fi
        rm -f "$out_bin"
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  REZULTAT PROVJERE: PROŠLO = $PASS | PALO = $FAIL"
echo "═══════════════════════════════════════════════════════════════"

if [ "$FAIL" -eq 0 ]; then
    echo "🟢 ZELENO SVJETLO: Svi testovi prolaze!"
fi
