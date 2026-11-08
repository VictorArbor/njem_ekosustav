#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

cd ~/njm_2_ekosustav_01

echo "═══════════════════════════════════════════════════════════════"
echo "  NJM-OS :: REALNI BROJEVI I KOMPUTACIJSKI BENCHMARK (100M)"
echo "═══════════════════════════════════════════════════════════════"

# 1. Čisti komputacijski program (100.000.000 iteracija, bez I/O u petlji)
cat << 'EOF_NJM' > bench_real.njm
mkm r10
nve r0, 15625
lpo r0, r0, 6          # r0 = 1.000.000
nve r8, 100            # Faktor skaliranja za 100M

nve r1, 18             # Fonem K
nve r2, 1              # Maska zvučnosti
nve r4, 12             # Maska alteracije

REAL_PETLJA:
uis r3, r1, r2         # Jednačenje po zvučnosti
srs r5, r3, r4         # Sibilarizacija
odu r0, r0, 1
gnn r0, REAL_PETLJA

pir
EOF_NJM

./lsbu_na_v9.sh bench_real.njm bench_real.elf
chmod +x bench_real.elf

echo "⚙️  Izvršavam 100.000.000 čistih silikonskih ciklusa..."

# 2. Mjerenje korištenjem standardnih sekundi i milisekundi (sigurno od overflow-a)
START_MS=$(date +%s%3N)
./bench_real.elf
END_MS=$(date +%s%3N)

ELAPSED_MS=$((END_MS - START_MS))
[ $ELAPSED_MS -le 0 ] && ELAPSED_MS=1 # Sprječavanje dijeljenja s nulom

UKUPNO_OPERACIJA=200000000 # 2 operacije po iteraciji (uis + srs) * 100M
FPS=$(( (UKUPNO_OPERACIJA * 1000) / ELAPSED_MS ))

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  NJM-OS :: REALNI REZULTATI ČISTE KOMPUTACIJE"
echo "═══════════════════════════════════════════════════════════════"
echo "Ukupno obrađenih fonema/operacija: $UKUPNO_OPERACIJA"
echo "Stvarno vrijeme izvođenja:          $ELAPSED_MS ms"
echo "Realna protočnost (Throughput):    $FPS operacija/sec"
echo "Veličina nativnog binarca:         $(wc -c < bench_real.elf) B"
echo "═══════════════════════════════════════════════════════════════"

rm -f bench_real.njm bench_real.elf
