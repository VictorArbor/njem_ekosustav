#!/data/data/com.termux/files/usr/bin/bash
cd ~/njm_2_ekosustav_01/bst_metabolizator

# Pronalaženje izvornog C fajla za metabolizator
SRC_FILE=$(ls *.c 2>/dev/null | head -n 1 || echo "")

if [ -n "$SRC_FILE" ]; then
    echo "Pronađen izvorni kôd: $SRC_FILE - Ponovno prevođenje s čistim stdout ispsovim..."
    clang -O3 "$SRC_FILE" -o metabolizator_ID
    echo "[OK] Rekompajliran metabolizator_ID!"
else
    echo "Izvorni .c kôd je već arhiviran u binarac."
fi
