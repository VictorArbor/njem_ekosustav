#!/usr/bin/env bash
set -e

if [ "$#" -lt 2 ]; then
    echo "⚠️ Upotreba: ./dodaj_akt.sh <broj_akta> <putanja_do_pdf>"
    exit 1
fi

BROJ_AKTA="$1"
PDF_PATH="$2"
NAZIV_DATOTEKE=$(basename "$PDF_PATH")

# 1. Provjera i rekompajliranje C23 binarca
if [ ! -f "./pečat_zajednica_RUKE" ] || [ "./pečat_zajednica_RUKE.c" -nt "./pečat_zajednica_RUKE" ]; then
    echo "🔨 Rekompajliranje C23 pogona..."
    clang -std=c23 pečat_zajednica_RUKE.c -lcrypto -lqrencode -o pečat_zajednica_RUKE
fi

# 2. Kopiranje PDF akta u javnu mapa pdf/ za preuzimanje s web portala
mkdir -p pdf
cp "$PDF_PATH" "pdf/$NAZIV_DATOTEKE"

# 3. Izvršavanje C23 verifikatora, QR generatora i ugradnja u JSON
echo "⚡ Izračun SHA-256, generiranje QR koda i ažuriranje registra..."
./pečat_zajednica_RUKE "$BROJ_AKTA" "$PDF_PATH"

# 4. Git dodavanje i objava
git add registar_akata.json index.html README.md QR_*.pbm pdf/* 2>/dev/null
if git diff-index --quiet HEAD --; then
    echo "ℹ️ Nema promjena za commit."
else
    git commit -m "feat(akt): dodan akt $BROJ_AKTA s mogućnošću preuzimanja"
    git push origin main
    echo "✅ Akt $BROJ_AKTA je objavljen! Preuzimanje omogućen na portalu."
fi
