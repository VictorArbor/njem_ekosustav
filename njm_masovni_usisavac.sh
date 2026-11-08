#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "==========================================================="
echo " NJM-OS :: AUTOMATSKI MASOVNI INGEST (220.000+ DOKUMENATA) "
echo "==========================================================="

TARGET_DIR="/sdcard/Download"

# Stvaranje privremene LSBU serijske liste naredbi
INSTRUCTION_FILE="masovni_ingest_stream.lsbu"
rm -f "$INSTRUCTION_FILE"

echo "🔍 [1/3] Skeniram sve DOCX, TXT i PDF datoteke u $TARGET_DIR..."

# Pronalaženje svih staza i generiranje ingest komandi
find "$TARGET_DIR" -type f \( -name "*.txt" -o -name "*.docx" -o -name "*.pdf" -o -name "*.md" -o -name "*.njm" \) | while read -r filepath; do
    echo "ingest \"$filepath\"" >> "$INSTRUCTION_FILE"
done

echo "stat>" >> "$INSTRUCTION_FILE"

TOTAL_FOUND=$(wc -l < "$INSTRUCTION_FILE")
echo "✅ Pronađeno dokumenata za masovni ingest: $((TOTAL_FOUND - 1))"
echo "🚀 [2/3] Pokrećem Laloglosator v31.2 masovni silikatni usisavač..."

START_TIME=$(date +%s)
./laloglosator < "$INSTRUCTION_FILE"
END_TIME=$(date +%s)

ELAPSED=$((END_TIME - START_TIME))

echo "==========================================================="
echo " 🎉 [3/3] MASOVNI INGEST USPJEŠNO ZAVRŠEN!"
echo "   ├── Ukupno trajanje obrade : ${ELAPSED} s"
echo "   └── Master oblak stvoren u : mid_master_oblaci.lsbu"
echo "==========================================================="
