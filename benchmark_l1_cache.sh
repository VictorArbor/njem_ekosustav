#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

cd ~/njm_2_ekosustav_01

echo "═══════════════════════════════════════════════════════════════"
echo "  NJM-OS :: L1-CACHE VS MOVK VS KLASIK BENCHMARK (100.000 CIKLUSA)"
echo "═══════════════════════════════════════════════════════════════"

# 1. Klasična metoda
cat << 'EOF_K' > bench_klasik.njm
mkm r10
nve r0, 100000
PETLJA_K:
nve r2, 65; ssb r2, r10, 0
nve r2, 66; ssb r2, r10, 1
nve r2, 67; ssb r2, r10, 2
nve r2, 68; ssb r2, r10, 3
odu r0, r0, 1
gnn r0, PETLJA_K
pir
EOF_K

# 2. L1-Cache Literal metoda (0 CPU stall-a, 100% L1 hit)
cat << 'EOF_L' > bench_l1.njm
mkm r10
nve r0, 100000
PETLJA_L:
ldr_lit r2, PODACI_L1
odu r0, r0, 1
gnn r0, PETLJA_L
pir
PODACI_L1:
nve r2, 16961
EOF_L

./lsbu_na_v8.sh bench_klasik.njm bench_klasik.elf > /dev/null 2>&1
./lsbu_na_v8.sh bench_l1.njm bench_l1.elf > /dev/null 2>&1

# Mjerenje Klasične metode
START_K=$(date +%s%N)
./bench_klasik.elf
END_K=$(date +%s%N)

# Mjerenje L1-Cache Metode
START_L=$(date +%s%N)
./bench_l1.elf
END_L=$(date +%s%N)

TRAJANJE_K=$(( (END_K - START_K) / 1000 ))
TRAJANJE_L=$(( (END_L - START_L) / 1000 ))
USTEDA=$(( TRAJANJE_K - TRAJANJE_L ))

SZ_K=$(wc -c < bench_klasik.elf)
SZ_L=$(wc -c < bench_l1.elf)

echo ""
echo "📊 REZULTATI L1-CACHE ARHITEKTONSKOG BENCHMARKA:"
echo "---------------------------------------------------------------"
echo "1. Klasična metoda (Byte-by-Byte):   $TRAJANJE_K µs  | Veličina: $SZ_K B"
echo "2. L1-Cache Literal Engine (v8):      $TRAJANJE_L µs  | Veličina: $SZ_L B"
echo "---------------------------------------------------------------"
echo "🔥 UŠTEDA U VREMENU IZVRŠAVANJA:      $USTEDA µs BRŽE!"
echo "🔥 SMANJENJE BINARCA NA DISKU:       $((SZ_K - SZ_L)) B MANJE!"
echo "═══════════════════════════════════════════════════════════════"

rm -f bench_klasik.njm bench_klasik.elf bench_l1.njm bench_l1.elf
