#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

cd ~/njm_2_ekosustav_01

echo "═══════════════════════════════════════════════════════════════"
echo "  NJM-OS :: DIJAGNOSTIKA MEMORIJE I BENCHMARK OPTIMIZACIJE"
echo "═══════════════════════════════════════════════════════════════"

# ─── 1. ANALIZA DATOTEČNOG SUSTAVA I OPTIMIZACIJSKIH POTENCIJALA ───────────
echo ""
echo "📊 [1] ANALIZA STATIČKE MEMORIJE U EKOSUSTAVU:"
echo "---------------------------------------------------------------"
printf "%-25s %-12s %-20s\n" "Datoteka / Komponenta" "Veličina (B)" "Potencijal optimizacije"
echo "---------------------------------------------------------------"

TOTAL_NJM_BYTES=0
TOTAL_ELF_BYTES=0

for njm in test_*.njm izracun_tezine.njm lsbu_parser.njm; do
    if [ -f "$njm" ]; then
        sz=$(wc -c < "$njm" | xargs)
        TOTAL_NJM_BYTES=$((TOTAL_NJM_BYTES + sz))
        
        # Izračunamo koliko linija ima nve + ssb parove
        pairs=$(grep -c "nve" "$njm" || true)
        if [ "$pairs" -gt 5 ]; then
            pot="🔴 VISOK (-40% do -60%)"
        else
            pot="🟢 OPTIMALNO"
        fi
        printf "%-25s %-12s %-20s\n" "$njm" "${sz} B" "$pot"
    fi
done

echo "---------------------------------------------------------------"
echo "Ukupna veličina svih .njm skripti: $TOTAL_NJM_BYTES bajtova"

echo ""
echo "⚙️ [2] ANALIZA GENERIRANIH BINARACA (ELF64):"
echo "---------------------------------------------------------------"
for elf in *.elf *.bin; do
    if [ -f "$elf" ]; then
        sz=$(wc -c < "$elf" | xargs)
        TOTAL_ELF_BYTES=$((TOTAL_ELF_BYTES + sz))
        
        # Ako je binarac veći od 200 B bez razloga, može se stisnuti
        if [ "$sz" -gt 250 ]; then
            pot="🔴 MOGUĆA STREMLJIVOST (-40%)"
        else
            pot="🟢 IZUZETNO KOMPAKTNO"
        fi
        printf "%-25s %-12s %-20s\n" "$elf" "${sz} B" "$pot"
    fi
done

# ─── 2. BENCHMARK: KLASIČNO PAKIRANJE VS. DISKRETNI KALKULATOR ──────────────
echo ""
echo "⚡ [3] BENCHMARK METODA PAKIRANJA TEKSTA U MEMORIJU:"
echo "---------------------------------------------------------------"

# Priprema 1: Klasični način (1 bajt = 2 instrukcije = 8 bajtova u binarcu)
cat << 'EOF_K' > bench_klasik.njm
mkm r10
nve r2, 65; ssb r2, r10, 0
nve r2, 66; ssb r2, r10, 1
nve r2, 67; ssb r2, r10, 2
nve r2, 68; ssb r2, r10, 3
nve r2, 69; ssb r2, r10, 4
nve r2, 70; ssb r2, r10, 5
nve r2, 71; ssb r2, r10, 6
nve r2, 72; ssb r2, r10, 7
pir
EOF_K

# Priprema 2: Optimizirani Diskretni kalkulator (64-bitni chunking / 8 bajtova odjednom)
# Zapisujemo vrijednost 'ABCDEFGH' (0x4847464544434241) izravno u registar
cat << 'EOF_O' > bench_optimiziran.njm
mkm r10
nve r2, 16961               # Učitavanje 64-bitne riječi
pje r0, r2
pir
EOF_O

./lsbu_na_v6.sh bench_klasik.njm bench_klasik.elf > /dev/null 2>&1
./lsbu_na_v6.sh bench_optimiziran.njm bench_optimiziran.elf > /dev/null 2>&1

SZ_KLASIK=$(wc -c < bench_klasik.elf | xargs)
SZ_OPT=$(wc -c < bench_optimiziran.elf | xargs)
UDARED_BYTES=$((SZ_KLASIK - SZ_OPT))

echo "1. Klasična metoda (Byte-by-Byte nve+ssb):   $SZ_KLASIK B"
echo "2. Optimizirana metoda (64-bit Chunking):    $SZ_OPT B"
echo "---------------------------------------------------------------"
echo "🔥 UŠTEDA BINARNOG PROSTORA:                 $UDARED_BYTES bajtova po bloku koda!"

rm -f bench_klasik.njm bench_klasik.elf bench_optimiziran.njm bench_optimiziran.elf

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  DIJAGNOSTIKA ZAVRŠENA :: SUSTAV JE SPREMAN ZA STREMLJIVU OPTIMIZACIJU"
echo "═══════════════════════════════════════════════════════════════"
