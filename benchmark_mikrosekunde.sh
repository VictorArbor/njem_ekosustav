#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

cd ~/njm_2_ekosustav_01

echo "═══════════════════════════════════════════════════════════════"
echo "  NJM-OS :: AArch64 MIKRO-BENCHMARK PERFORMANSI I CIKLUSA"
echo "═══════════════════════════════════════════════════════════════"

# 1. Priprema testnih .njm skripti
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

cat << 'EOF_O' > bench_opt.njm
mkm r10
n64 r2, 16961, 17475, 17989, 18503
pir
EOF_O

# 2. Sinteza binaraca pomoću v7 Enginea
./lsbu_na_v7.sh bench_klasik.njm bench_klasik.elf > /dev/null 2>&1
./lsbu_na_v7.sh bench_opt.njm bench_opt.elf > /dev/null 2>&1

# 3. Izvršavanje 10.000 iteracija u petlji i mjerenje mikrosekundi
ITERACIJA=10000

echo ""
echo "⚙️ Izvršavanje $ITERACIJA iteracija za Klasičnu metodu (byte-by-byte)..."
START_KLASIK=$(date +%s%N)
for ((i=0; i<ITERACIJA; i++)); do
    ./bench_klasik.elf
done
END_KLASIK=$(date +%s%N)

echo "⚙️ Izvršavanje $ITERACIJA iteracija za Optimiziranu metodu (64-bit chunking)..."
START_OPT=$(date +%s%N)
for ((i=0; i<ITERACIJA; i++)); do
    ./bench_opt.elf
done
END_OPT=$(date +%s%N)

# 4. Izračun proteklog vremena u mikrosekundama (us)
TRAJANJE_KLASIK=$(( (END_KLASIK - START_KLASIK) / 1000 ))
TRAJANJE_OPT=$(( (END_OPT - START_OPT) / 1000 ))
UŠTEDA_US=$(( TRAJANJE_KLASIK - TRAJANJE_OPT ))
POSTOTAK=$(( (UŠTEDA_US * 100) / TRAJANJE_KLASIK ))

echo ""
echo "📊 REZULTATI CPU BENCHMARKA ($ITERACIJA IZVRŠAVANJA):"
echo "---------------------------------------------------------------"
echo "1. Klasična metoda (Byte-by-Byte):     $TRAJANJE_KLASIK µs"
echo "2. Optimizirani 64-bit Chunking:       $TRAJANJE_OPT µs"
echo "---------------------------------------------------------------"
echo "🔥 UŠTEDA U VREMENU IZVRŠAVANJA:        $UŠTEDA_US µs ($POSTOTAK% BRŽE!)"
echo "═══════════════════════════════════════════════════════════════"

# Čišćenje prolaznih bench datoteka
rm -f bench_klasik.njm bench_klasik.elf bench_opt.njm bench_opt.elf
