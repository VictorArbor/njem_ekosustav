#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# 1. ČISTO BST ISA GORIVO (Samo skupovna LSBU logika)
cat > uzorak_kanonski.njm << 'NJM_EOF'
# ═══════════════════════════════════════════════════════════════
# NJM :: BST ISA KANONSKI UZORAK (vrabac -> vrapca)
# ═══════════════════════════════════════════════════════════════

# A. Konstrukcija ulaznog 128-bitnog MID-a iz skupovnih projekcija
V_N   = vps ( X0 , X1 )
V_FU  = vss ( X2 , X3 )
V_MU  = vrs ( X4 , X5 )
V0    = vus ( vus ( V_N , V_FU ) , V_MU )

# B. LSBU Skupovna transformacija (jednačenje po zvučnosti / b -> p)
V1    = vss ( V0 , X12 )
V2    = vrs ( V1 , X11 )
V3    = vps ( V2 , X10 )

# C. Silicijski JIT okidač i ekstrakcija
ooi ( V3 )

REC_N  = vps ( V3 , X10 )
REC_FU = vss ( V3 , X11 )
REC_MU = vrs ( V3 , X12 )

pir ( REC_N )
pir ( REC_FU )
pir ( REC_MU )
NJM_EOF

# 2. IZVRŠAVANJE NAD METABOLIZATOROM I DOHVAT RAW UZORAKA
echo "═══════════════════════════════════════════════════════════════"
echo "  NJM_2_EKOSUSTAV_01 :: GENERIRANJE SIROVIH BST ISA UZORAKA   "
echo "═══════════════════════════════════════════════════════════════"

./metabolizator_ID uzorak_kanonski.njm | grep -a -E "(NODE:|===|2200|2500|2400|2300|2600|4E21|6E23|4E65|4EA0|D63F)" > bst_isa_uzorci.txt

cat bst_isa_uzorci.txt

rm -f uzorak_kanonski.njm
echo "═══════════════════════════════════════════════════════════════"
echo "⚡ UZOČNI BLOK SPREMLJEN U: ~/njm_2_ekosustav_01/bst_isa_uzorci.txt"
