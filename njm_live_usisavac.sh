#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "==========================================================="
echo " NJM-OS :: AUTARKIČNI INGEST ENGINE S PRIKAZOM UŽIVO       "
echo " EXYNOS 1280 DIRECT STREAM & CHECKPOINT RESUME SYSTEM       "
echo "==========================================================="

TARGET_DIR="/sdcard/Download"
CHECKPOINT_LOG="obrađeni_dokumenti.log"
LIST_ALL="sve_datoteke.tmp"
LIST_NEW="novo_za_obradu.tmp"

touch "$CHECKPOINT_LOG"

echo "🔍 [1/3] Skeniram pohranu i utvrđujem preostali korpus..."

# Brzo pronalaženje svih datoteka
find "$TARGET_DIR" -type f \( -name "*.txt" -o -name "*.docx" -o -name "*.pdf" -o -name "*.md" -o -name "*.njm" \) > "$LIST_ALL"

# In-memory awk filtriranje izvedeno u milisekundama
awk 'NR==FNR {done[$0]=1; next} !done[$0]' "$CHECKPOINT_LOG" "$LIST_ALL" > "$LIST_NEW"

TOTAL_NEW=$(wc -l < "$LIST_NEW")
ALREADY_DONE=$(wc -l < "$CHECKPOINT_LOG")

echo " 📊 Stanje korpusa:"
echo "   ├── Ranije obrađeno : $ALREADY_DONE datoteka"
echo "   └── Preostalo za obradu : $TOTAL_NEW datoteka"

if [ "$TOTAL_NEW" -eq 0 ]; then
    echo "🎉 Svi dokumenti su već usisani u mid_master_oblaci.lsbu!"
    rm -f "$LIST_ALL" "$LIST_NEW"
    exit 0
fi

echo ""
echo "🚀 [2/3] Započinjem usisavanje s ispisom napretka u realnom vremenu..."
echo "-----------------------------------------------------------"

PROCESSED_COUNT=0
START_TIME=$(date +%s)

# Čitanje i slanje izravno u Laloglosator uz trenutni ispis i logiranje
while IFS= read -r filepath; do
    if [ -z "$filepath" ]; then continue; fi
    
    PROCESSED_COUNT=$((PROCESSED_COUNT + 1))
    
    # Trenutno slanje Laloglosatoru
    echo "ingest \"$filepath\"" | ./laloglosator > /dev/null 2>&1
    
    # Zapis u Checkpoint tek po uspješnoj obradi
    echo "$filepath" >> "$CHECKPOINT_LOG"
    
    # Prikaz napretka na ekranu uživo
    FILENAME=$(basename "$filepath")
    echo " [$PROCESSED_COUNT/$TOTAL_NEW] OK -> $FILENAME"

done < "$LIST_NEW"

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

rm -f "$LIST_ALL" "$LIST_NEW"

echo "==========================================================="
echo " 🎉 [3/3] SEKVENCE INGESTA ZAVRŠENA!"
echo "   ├── Ukupno trajanje   : ${ELAPSED} s"
echo "   ├── Ukupno usisano    : $(wc -l < "$CHECKPOINT_LOG") datoteka"
echo "   └── Master oblak     : mid_master_oblaci.lsbu"
echo "==========================================================="

echo "stat" | ./laloglosator
