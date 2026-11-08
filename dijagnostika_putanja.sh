#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "==========================================================="
echo " 🔍 NJM-OS :: DIJAGNOSTIKA I/O ZASTOJA DATOTEČNOG SUSTAVA   "
echo "==========================================================="

MAPETEST=(
    "/sdcard/Download"
    "/sdcard/Documents"
    "/sdcard/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Documents"
)

for dir in "${MAPETEST[@]}"; do
    if [ -d "$dir" ]; then
        echo -n "📁 Testiram pristupačnost: $dir ... "
        # Mjerenje vremena odaziva i brojanje datoteka uz timeout od 3 sekunde
        START=$(date +%s%N)
        COUNT=$(timeout 3 find "$dir" -maxdepth 3 -type f \( -name "*.txt" -o -name "*.docx" -o -name "*.pdf" -o -name "*.md" -o -name "*.njm" \) 2>/dev/null | wc -l || echo "TIMEOUT/BLOKIRANO")
        END=$(date +%s%N)
        DIFF=$(( (END - START) / 1000000 ))
        echo "Pronađeno: [$COUNT] (Vrijeme odaziva: ${DIFF} ms)"
    else
        echo "❌ Mapa ne postoji ili nema dopuštenja: $dir"
    fi
done

echo "-----------------------------------------------------------"
echo "🔍 Generiram brzinski uzorak bez blokiranja FUSE sloja..."
rm -f korpus_test.lsbu

# Skeniramo samo čiste korisničke dokumente bez medijskih podmapa
find /sdcard/Download /sdcard/Documents -maxdepth 4 -type f \( -name "*.txt" -o -name "*.docx" -o -name "*.pdf" -o -name "*.md" -o -name "*.njm" \) 2>/dev/null | awk '{print "ingest \"" $0 "\""}' > korpus_test.lsbu

TOTAL=$(wc -l < korpus_test.lsbu)
echo "✅ Uspješno stvorena brza matrica 'korpus_test.lsbu' s $TOTAL dokumenata."
echo "==========================================================="
