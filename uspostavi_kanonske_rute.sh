#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "═══════════════════════════════════════════════════════════════"
echo "  NJM_2_EKOSUSTAV_01 :: USPOSTAVA SIMBOLIČKIH LINKOVA I GORIVA "
echo "═══════════════════════════════════════════════════════════════"

# 1. Stvaranje kanonskog goriva u novom okruženju ~/njm_2_ekosustav_01
cat > dostavi_uzorke.njm << 'NJM_EOF'
# ═══════════════════════════════════════════════════════════════
# NJM UZORAK :: Čisti BST ISA uzorci za BSTBIN v3 Cjevovod
# ═══════════════════════════════════════════════════════════════

# 1. Konstrukcija MID-a iz fonema
V_N   = vps ( X0 , X1 )
V_FU  = vss ( X2 , X3 )
V_MU  = vrs ( X4 , X5 )
V0    = vus ( vus ( V_N , V_FU ) , V_MU )

# 2. Transformacija (vrabac -> vrapca)
V1    = vss ( V0 , X12 )
V2    = vrs ( V1 , X11 )
V3    = vps ( V2 , X10 )

# 3. Izvršenje na siliciju
ooi ( V3 )

# 4. Ekstrakcija rezultata
REC_N  = vps ( V3 , X10 )
REC_FU = vss ( V3 , X11 )
REC_MU = vrs ( V3 , X12 )

pir ( REC_N )
pir ( REC_FU )
pir ( REC_MU )
NJM_EOF

# 2. Stvaranje simboličke poveznice u starom imeniku da se spriječi "No such file"
mkdir -p ~/njm_ekosustav_01
ln -sf ~/njm_2_ekosustav_01/metabolizator_ID ~/njm_ekosustav_01/metabolizator_ID
cp dostavi_uzorke.njm ~/njm_ekosustav_01/dostavi_uzorke.njm

echo -e "\033[1;32m[OK] Poveznice uspostavljene! Pokretanje verifikacije iz obaju direktorija:\033[0m\n"

echo "► Test 1: Pokretanje iz ~/njm_2_ekosustav_01:"
cd ~/njm_2_ekosustav_01 && ./metabolizator_ID dostavi_uzorke.njm | grep -A 10 "DUMP 3"

echo -e "\n► Test 2: Pokretanje iz ~/njm_ekosustav_01 (preko linka):"
cd ~/njm_ekosustav_01 && ./metabolizator_ID dostavi_uzorke.njm | grep -A 10 "DUMP 3"

rm -f ~/njm_2_ekosustav_01/uspostavi_kanonske_rute.sh
echo -e "\n═══════════════════════════════════════════════════════════════"
