#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "==========================================================="
echo " NJM-OS :: PARALELNI SHARDING INGEST & RESUME ENGINE       "
echo " EXYNOS 1280 MULTI-CORE (8 PARALELNIH TOKOVA)             "
echo "==========================================================="

TARGET_DIR="/sdcard/Download"
CHECKPOINT_LOG="obrađeni_dokumenti.log"
QUEUE_FILE="preostale_datoteke.tmp"

touch "$CHECKPOINT_LOG"

echo "🔍 [1/4] Registriram neobrađene DOCX, TXT i PDF datoteke..."

# Pronalaženje svih datoteka i filtriranje već obrađenih (Resume logika)
find "$TARGET_DIR" -type f \( -name "*.txt" -o -name "*.docx" -o -name "*.pdf" -o -name "*.md" -o -name "*.njm" \) | \
    grep -vFf "$CHECKPOINT_LOG" > "$QUEUE_FILE" || true

TOTAL_QUEUE=$(wc -l < "$QUEUE_FILE")
ALREADY_DONE=$(wc -l < "$CHECKPOINT_LOG")

echo " 📊 Stanje korpusa:"
echo "   ├── Već ranije obrađeno : $ALREADY_DONE dokumenata"
echo "   └── Preostalo za obradu : $TOTAL_QUEUE dokumenata"

if [ "$TOTAL_QUEUE" -eq 0 ]; then
    echo "🎉 Svi dokumenti su već usisani u mid_master_oblaci.lsbu!"
    exit 0
fi

echo ""
echo "🚀 [2/4] Pokrećem 8 paralelnih AArch64 radnika s prikazom napretka uživo..."
START_TIME=$(date +%s)

# Radnička funkcija s trenutnim zapisom u Checkpoint log i izlazom u Laloglosator
export CHECKPOINT_LOG
process_file() {
    local filepath="$1"
    echo "ingest \"$filepath\"" | ./laloglosator > /dev/null 2>&1
    echo "$filepath" >> "$CHECKPOINT_LOG"
    echo "  [OK] Usisano: $(basename "$filepath")"
}
export -f process_file

# Paralelno izvršavanje (8 dionica odjednom uz xargs)
cat "$QUEUE_FILE" | xargs -P 8 -I {} bash -c 'process_file "$@"' _ "{}"

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

rm -f "$QUEUE_FILE"

echo ""
echo "==========================================================="
echo " 🎉 [3/4] PARALELNI INGEST USPJEŠNO ZAVRŠEN / PAUZIRAN!"
echo "   ├── Ukupno trajanje sekvence : ${ELAPSED} s"
echo "   ├── Ukupno obrađeno do sada  : $(wc -l < "$CHECKPOINT_LOG") dokumenata"
echo "   └── Master oblak stvoren u   : mid_master_oblaci.lsbu"
echo "==========================================================="

echo "stat" | ./laloglosator
