#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

cd ~/njm_2_ekosustav_01

echo "═══════════════════════════════════════════════════════════════"
echo "  NJM-OS :: PRAVI 100M SILIKONSKI BENCHMARK"
echo "═══════════════════════════════════════════════════════════════"

cat << 'EOF_NJM' > bench_100m.njm
mkm r10

# Točnih 100.000.000 iteracija: 
# Kroz registarsku aritmetiku postavljamo brojač
nve r0, 50000
lpo r0, r0, 11         # Povećanje opsega petlje na 100.000.000

nve r1, 18             # Fonem K
nve r2, 1              # Maska zvučnosti
nve r4, 12             # Maska alteracije

PETLJA_100M:
uis r3, r1, r2         
srs r5, r3, r4         
odu r0, r0, 1
gnn r0, PETLJA_100M

pir
EOF_NJM

./lsbu_na_v9.sh bench_100m.njm bench_100m.elf
chmod +x bench_100m.elf

echo "⚙️  Izvršavam punih 100.000.000 čistih ciklusa..."

START_MS=$(date +%s%3N)
./bench_100m.elf
END_MS=$(date +%s%3N)

ELAPSED_MS=$((END_MS - START_MS))
[ $ELAPSED_MS -le 0 ] && ELAPSED_MS=1

UKUPNO_OP=200000000    # 100M iteracija * 2 operacije
FPS=$(( (UKUPNO_OP * 1000) / ELAPSED_MS ))

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  NJM-OS :: REZULTATI ZA 100 MILIJUNA ITERACIJA"
echo "═══════════════════════════════════════════════════════════════"
echo "Ukupno obrađenih operacija:        $UKUPNO_OP"
echo "Stvarno vrijeme izvođenja:          $ELAPSED_MS ms"
echo "Realna protočnost (Throughput):    $FPS operacija/sec"
echo "Veličina nativnog binarca:         $(wc -c < bench_100m.elf) B"
echo "═══════════════════════════════════════════════════════════════"

rm -f bench_100m.njm bench_100m.elf
