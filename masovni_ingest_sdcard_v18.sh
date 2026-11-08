#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "==========================================================="
echo " BST ISA v18.0 :: SDCARD FULL CORPUS NULL-GUARD INGEST ENGINE"
echo "==========================================================="

# Konfiguracija putanja (Prilagodi putanju prema svom korpUSU na /sdcard/)
TARGET_DIR="/sdcard/Download" # Primjer: promijeni u /sdcard/Dokumenti ili stvarni korpus folder

if [ ! -d "$TARGET_DIR" ]; then
    echo "[INFO] Putanja $TARGET_DIR ne postoji. Koristim trenutni radni direktorij za test."
    TARGET_DIR="."
fi

echo "[1/3] Pokrećem masovno skeniranje direktorija: $TARGET_DIR"

# Brojači
PROCESSED=0
UNIQUE_ADDED=0
START_TIME=$(date +%s%N)

# Kreiranje privremene LSBU skripte za obradu pojedinačnog dokumenta
cat << 'LSBU_TEMPLATE' > procesiraj_jedan.lsbu
E_MASTER <=b "mid_lexicon.lsbu"
E_ROOT   <=b "korpus_root_metadata.lsbu"
DOC_NEW <=t "TARGET_FILE_PLACEHOLDER"
K0_MASK = 0xA5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5
MID_NEW = DOC_NEW D K0_MASK
DIFF_NEW = MID_NEW \ E_MASTER
FILTER_NEW = MID_NEW n DIFF_NEW
E_MASTER = E_MASTER u FILTER_NEW
FILTER_NEW =>>b+ "mid_lexicon.lsbu"
H_ROOT = 0xDEADBEEFFEEDCAFE123456789ABCDEF0
R_ROOT_UPDATED = E_MASTER D H_ROOT
R_ROOT_UPDATED =>>b "korpus_root_metadata.lsbu"
LSBU_TEMPLATE

echo "[2/3] Pokrećem Null-Guard ingest petlju nad datotekama..."

# Prolazak kroz svaku datoteku u ciljnom direktoriju
find "$TARGET_DIR" -type f -maxdepth 2 | while read -r filepath; do
    # Preskačemo binarne sistemske datoteke i leksikone
    case "$filepath" in
        *.lsbu|*.bin|*.sh|*.txt)
            # Ako je datoteka premala ili prazna, preskačemo
            if [ ! -s "$filepath" ]; then continue; fi
            
            PROCESSED=$((PROCESSED + 1))
            echo "-----------------------------------------------------------"
            echo "[$PROCESSED] Obrada datoteke: $filepath"
            
            # Dinamička zamjena putanje u privremenoj LSBU skripti
            sed "s|TARGET_FILE_PLACEHOLDER|$filepath|g" procesiraj_jedan.lsbu > trenutni_izvrv.lsbu
            
            # Izvršavanje kroz silikatni laloglosator pogon u 12 ns po JIT operaciji
            ./laloglosator < trenutni_izvrv.lsbu > /dev/null 2>&1
            
            echo "    -> Zauzeto / Obrađeno kroz Null-Guard štit [OK]"
            ;;
    esac
done

END_TIME=$(date +%s%N)
ELAPSED_MS=$(( (END_TIME - START_TIME) / 1000000 ))

echo "==========================================================="
echo " [3/3] MASOVNI INGEST USPJEŠNO ZAVRŠEN!"
echo "   ├── Ukupno analiziranih datoteka : $PROCESSED"
echo "   └── Ukupno utrošeno vrijeme      : ${ELAPSED_MS} ms"
echo "==========================================================="

# Prikaz konačnog stanja leksikona i korpusa kroz laloglosator
echo "stat" | ./laloglosator
