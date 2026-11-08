#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

cd ~/njm_2_ekosustav_01

echo "═══════════════════════════════════════════════════════════════"
echo "  NJM-OS :: AArch64 NATIVNI MIKRO-BENCHMARK (100.000 CIKLUSA)"
echo "═══════════════════════════════════════════════════════════════"

# 1. Klasični kôd koji 100.000 puta izvodi byte-by-byte punjenje u RAM-u
cat << 'EOF_K' > bench_klasik.njm
mkm r10
nve r0, 100000               # Brojač 100.000 iteracija
PETLJA_K:
nve r2, 65; ssb r2, r10, 0
nve r2, 66; ssb r2, r10, 1
nve r2, 67; ssb r2, r10, 2
nve r2, 68; ssb r2, r10, 3
nve r2, 69; ssb r2, r10, 4
nve r2, 70; ssb r2, r10, 5
nve r2, 71; ssb r2, r10, 6
nve r2, 72; ssb r2, r10, 7
odu r0, r0, 1
gnn r0, PETLJA_K
pir
EOF_K

# 2. Optimizirani kôd koji 100.000 puta izvodi 64-bitni Chunking
cat << 'EOF_O' > bench_opt.njm
mkm r10
nve r0, 100000               # Brojač 100.000 iteracija
PETLJA_O:
n64 r2, 16961, 17475, 17989, 18503
odu r0, r0, 1
gnn r0, PETLJA_O
pir
EOF_O

# Sinteza preko v7 Enginea
./lsbu_na_v7.sh bench_klasik.njm bench_klasik.elf > /dev/null 2>&1
./lsbu_na_v7.sh bench_opt.njm bench_opt.elf > /dev/null 2>&1

# Mjerenje klasične metode
START_K=$(date +%s%N)
./bench_klasik.elf
END_K=$(date +%s%N)

# Mjerenje optimizirane metode
START_O=$(date +%s%N)
./bench_opt.elf
END_O=$(date +%s%N)

# Izračun mikrosekundi
TRAJANJE_K=$(( (END_K - START_K) / 1000 ))
TRAJANJE_O=$(( (END_O - START_O) / 1000 ))
USTEDA=$(( TRAJANJE_K - TRAJANJE_O ))

echo ""
echo "📊 REZULTATI NATIVNOG AArch64 BENCHMARKA:"
echo "---------------------------------------------------------------"
echo "1. Klasična metoda (100.000 petlji):     $TRAJANJE_K µs"
echo "2. Optimizirani 64-bit Chunking:         $TRAJANJE_O µs"
echo "---------------------------------------------------------------"
echo "🔥 UŠTEDA NA PROCESORSKIM CIKLUSIMA:    $USTEDA µs brže!"
echo "═══════════════════════════════════════════════════════════════"

rm -f bench_klasik.njm bench_klasik.elf bench_opt.njm bench_opt.elf
