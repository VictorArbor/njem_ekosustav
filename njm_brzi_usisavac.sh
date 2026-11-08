#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "==========================================================="
echo " NJM-OS :: DIRECT STREAM SHARDING INGEST (EXYNOS 1280)    "
echo "==========================================================="

TARGET_DIR="/sdcard/Download"
CHECKPOINT_LOG="obrađeni_dokumenti.log"
LIST_ALL="sve_datoteke.tmp"
LIST_NEW="novo_za_obradu.tmp"

touch "$CHECKPOINT_LOG"

echo "🔍 [1/3] Skeniram imenik i radim brzi stazni diff..."

# Brzi izravni sken bez teškog grep-a
find "$TARGET_DIR" -type f \( -name "*.txt" -o -name "*.docx" -o -name "*.pdf" -o -name "*.md" -o -name "*.njm" \) > "$LIST_ALL"

# In-memory awk diferencijal (100x brži od grep -vFf)
awk 'NR==FNR {done[$0]=1; next} !done[$0]' "$CHECKPOINT_LOG" "$LIST_ALL" > "$LIST_NEW"

TOTAL_NEW=$(wc -l < "$LIST_NEW")
echo " 📊 Pronađeno novih neobrađenih datoteka: $TOTAL_NEW"

if [ "$TOTAL_NEW" -eq 0 ]; then
    echo "🎉 Svi dokumenti su već usisani!"
    rm -f "$LIST_ALL" "$LIST_NEW"
    exit 0
fi

echo "🚀 [2/3] Pokrećem izravno usisavanje u Laloglosator v31.2..."

# Generiranje LSBU toka naredbi
INSTRUCT_FILE="stream_run.lsbu"
rm -f "$INSTRUCT_FILE"

while IFS= read -r filepath; do
    echo "ingest \"$filepath\"" >> "$INSTRUCT_FILE"
    echo "$filepath" >> "$CHECKPOINT_LOG"
done < "$LIST_NEW"

echo "stat>" >> "$INSTRUCTION_FILE" 2>/dev/null || echo "stat>" >> "$INSTRUCT_FILE"

START_TIME=$(date +%s)

# Izravno slanje toka naredbi u Laloglosator
./laloglosator < "$INSTRUCT_FILE"

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

rm -f "$LIST_ALL" "$LIST_NEW" "$INSTRUCT_FILE"

echo "==========================================================="
echo " 🎉 [3/3] USISAVANJE ZAVRŠENO!"
echo "   ├── Vrijeme obrade : ${ELAPSED} s"
echo "   └── Master oblak : mid_master_oblaci.lsbu"
echo "==========================================================="
