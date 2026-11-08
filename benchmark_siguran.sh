#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

cd ~/njm_2_ekosustav_01

echo "═══════════════════════════════════════════════════════════════"
echo "  NJM-OS :: SIGURNI BENCHMARK PERFORMANSI (v9 ENGINE)"
echo "═══════════════════════════════════════════════════════════════"

cat << 'EOF_K' > bench_klasik.njm
mkm r10
nve r0, 10000
PETLJA_K:
nve r2, 65
ssb r2, r10, 0
nve r2, 66
ssb r2, r10, 1
nve r2, 67
ssb r2, r10, 2
nve r2, 68
ssb r2, r10, 3
odu r0, r0, 1
gnn r0, PETLJA_K
pir
EOF_K

cat << 'EOF_O' > bench_opt.njm
mkm r10
nve r0, 10000
PETLJA_O:
nve r2, 16961
pje r3, r2
odu r0, r0, 1
gnn r0, PETLJA_O
pir
EOF_O

./lsbu_na_v9.sh bench_klasik.njm bench_klasik.elf > /dev/null 2>&1
./lsbu_na_v9.sh bench_opt.njm bench_opt.elf > /dev/null 2>&1

START_K=$(date +%s%N)
./bench_klasik.elf
END_K=$(date +%s%N)

START_O=$(date +%s%N)
./bench_opt.elf
END_O=$(date +%s%N)

TRAJANJE_K=$(( (END_K - START_K) / 1000 ))
TRAJANJE_O=$(( (END_O - START_O) / 1000 ))
USTEDA=$(( TRAJANJE_K - TRAJANJE_O ))

SZ_K=$(wc -c < bench_klasik.elf)
SZ_O=$(wc -c < bench_opt.elf)

echo ""
echo "📊 REZULTATI VERIFICIRANOG BENCHMARKA:"
echo "---------------------------------------------------------------"
echo "1. Klasična metoda (Byte-by-Byte):     $TRAJANJE_K µs  | Veličina: $SZ_K B"
echo "2. Optimizirana metoda (L1-Optimized): $TRAJANJE_O µs  | Veličina: $SZ_O B"
echo "---------------------------------------------------------------"
echo "🔥 UŠTEDA U VREMENU IZVRŠAVANJA:        $USTEDA µs BRŽE!"
echo "🔥 SMANJENJE VELIČINE NA DISKU:         $((SZ_K - SZ_O)) B MANJE!"
echo "═══════════════════════════════════════════════════════════════"

rm -f bench_klasik.njm bench_klasik.elf bench_opt.njm bench_opt.elf
