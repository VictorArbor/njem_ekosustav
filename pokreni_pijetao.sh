#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "═══════════════════════════════════════════════════════════════"
echo "  NJM-OS :: PIJETAO v5.1 STABILNI BUILD (PURE AArch64)"
echo "═══════════════════════════════════════════════════════════════"

as -o pijetao_1.o pijetao_1.asm
ld -o pijetao_1 pijetao_1.o
strip --strip-all pijetao_1

cp -f pijetao_1 $PREFIX/bin/pijetao
chmod +x $PREFIX/bin/pijetao

cat > test.njm << 'NJM_EOF'
# ═════════════════════════════════════════════════════════════════════
# NJM-OS :: TEST — Hrvatski LSBU program
# ═════════════════════════════════════════════════════════════════════

nve r0, 0x40
nve r1, 0x10

pis r2, r0, r1
uis r2, r0, r1
ris r2, r0, r1
srs r2, r0, r1

vps q2, q0, q1
vus q2, q0, q1
vrs q2, q0, q1
vss q2, q0, q1

ujb r1, [r0]
udb r2, [r0+1]
usb r1, [r0+r1]
ssb [r0+1], r1

ume r0, r1
lpo r2, r0, 4
dpo r2, r0, 4

nno
bar
pir
NJM_EOF

echo "🚀 Pokrećem pijetao < test.njm..."
echo "═══════════════════════════════════════════════════════════════"
$PREFIX/bin/pijetao < test.njm
echo "═══════════════════════════════════════════════════════════════"
echo "✅ [SUCCESS] Pijetao v5.1 izvršio JIT blok bez pogreške!"
