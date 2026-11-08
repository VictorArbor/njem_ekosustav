#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "==========================================================="
echo " BST ISA v19.0 :: SDCARD FULL-TEXT CHUNK INGEST ENGINE     "
echo "==========================================================="

TARGET_DIR="/sdcard/Download"

if [ ! -d "$TARGET_DIR" ]; then
    TARGET_DIR="."
fi

echo "[1/3] Pokrećem full-text skeniranje i ingest iz: $TARGET_DIR"

PROCESSED=0
START_TIME=$(date +%s%N)

# Kreiranje LSBU šablone koja koristi novi operator <=T za puni tekst
cat << 'LSBU_TEMPLATE' > procesiraj_fulltext.lsbu
E_MASTER <=b "mid_lexicon.lsbu"
E_ROOT   <=b "korpus_root_metadata.lsbu"
DOC_FULL <=T "TARGET_FILE_PLACEHOLDER"
K0_MASK = 0xA5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5
MID_FULL = DOC_FULL D K0_MASK
DIFF_FULL = MID_FULL \ E_MASTER
FILTER_FULL = MID_FULL n DIFF_FULL
E_MASTER = E_MASTER u FILTER_FULL
FILTER_FULL =>>b+ "mid_lexicon.lsbu"
H_ROOT = 0xDEADBEEFFEEDCAFE123456789ABCDEF0
R_ROOT_UPDATED = E_MASTER D H_ROOT
R_ROOT_UPDATED =>>b "korpus_root_metadata.lsbu"
LSBU_TEMPLATE

echo "[2/3] Pokrećem Full-Text Null-Guard ingest petlju..."

find "$TARGET_DIR" -type f -maxdepth 3 | while read -r filepath; do
    case "$filepath" in
        *.lsbu|*.bin|*.sh|*.txt|*.md|*.log|*.njm)
            if [ ! -s "$filepath" ]; then continue; fi
            
            PROCESSED=$((PROCESSED + 1))
            echo "-----------------------------------------------------------"
            echo "[$PROCESSED] Full-Text obrada: $filepath"
            
            sed "s|TARGET_FILE_PLACEHOLDER|$filepath|g" procesiraj_fulltext.lsbu > trenutni_izvrv.lsbu
            
            ./laloglosator < trenutni_izvrv.lsbu > /dev/null 2>&1
            
            echo "    -> Sadržaj usisan, vektoriziran i zaštićen kroz Null-Guard [OK]"
            ;;
    esac
done

END_TIME=$(date +%s%N)
ELAPSED_MS=$(( (END_TIME - START_TIME) / 1000000 ))

echo "==========================================================="
echo " [3/3] FULL-TEXT MASOVNI INGEST USPJEŠNO ZAVRŠEN!"
echo "   ├── Ukupno procesiranih dokumenata : $PROCESSED"
echo "   └── Ukupno utrošeno vrijeme      : ${ELAPSED_MS} ms"
echo "==========================================================="

echo "stat" | ./laloglosator
