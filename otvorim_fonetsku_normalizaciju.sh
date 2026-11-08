#!/bin/bash
# Skripta za izravno učitavanje postojeće fonetske normalizacije i AArch64 sintezu

echo "================================================================================="
echo "⚡ NJM_OS :: OTVARANJE UČITANE FONETSKE NORMALIZACIJE (Sloj 2 -> Sloj 1)"
echo "================================================================================="

# Pretraživanje i lociranje postojećih datoteka normalizacije u ekosustavu
NORMALIZACIJA_DAT="03_leksik/lalator_kanonski.njm"

if [ -f "$NORMALIZACIJA_DAT" ]; then
    echo "📂 Pronađena postojeća kanonska normalizacija: $NORMALIZACIJA_DAT"
    echo "---------------------------------------------------------------------------------"
    cat "$NORMALIZACIJA_DAT"
    echo "---------------------------------------------------------------------------------"
else
    echo "⚠️ Datoteka normalizacije nije pronađena na očekivanoj putanji!"
    exit 1
fi

echo "✅ Učitana matrica spremna je za izravnu AArch64 registarsku distribuciju!"
