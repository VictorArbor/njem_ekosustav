#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

cd ~/njm_2_ekosustav_01

echo "═══════════════════════════════════════════════════════════════"
echo "  NJM-OS :: MASTER NATIVE TEST SUITE (PURE LSBU-S v4.0)"
echo "═══════════════════════════════════════════════════════════════"

PASS=0
FAIL=0

for njm_file in test_*.njm; do
    if [ -f "$njm_file" ]; then
        out_bin="${njm_file%.njm}.nat.bin"
        echo -n "[TEST NATIVE] $njm_file ... "
        
        if ./lsbu_na_v4.sh "$njm_file" "$out_bin" > /dev/null 2>&1; then
            if ./"$out_bin" > /dev/null 2>&1; then
                echo "✅ OK"
                PASS=$((PASS + 1))
            else
                echo "⚠️ GREŠKA IZVRŠAVANJA"
                FAIL=$((FAIL + 1))
            fi
        else
            echo "❌ GREŠKA PREVOĐENJA"
            FAIL=$((FAIL + 1))
        fi
        rm -f "$out_bin"
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  REZULTAT AUTARHIJE: USPJEŠNO = $PASS | NEUSPJEŠNO = $FAIL"
echo "═══════════════════════════════════════════════════════════════"
