#!/data/data/com.termux/files/usr/bin/bash
# ═════════════════════════════════════════════════════════════════════════
#  NJM-OS :: LALOGLOSATOR v43.1 — BUILD & TEST
# ═════════════════════════════════════════════════════════════════════════

set -euo pipefail

echo "═══════════════════════════════════════════════════════════════"
echo "  NJM-OS :: LALOGLOSATOR v43.1 BUILD"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ─── 1. KOMPAJLIRAJ ─────────────────────────────────────────────────
echo "[1] Kompajliram laloglosator_v43_1.c..."
clang -O3 -march=armv8-a+simd -nostdlib -fno-builtin -static \
      laloglosator_v43_1.c -o $PREFIX/bin/laloglosator

chmod +x $PREFIX/bin/laloglosator
ln -sf $PREFIX/bin/laloglosator $PREFIX/bin/laloglosator_1

echo "[2] Instaliran u: $PREFIX/bin/laloglosator"
echo ""

# ─── 2. TEST SKRIPTA ────────────────────────────────────────────────
cat > test_fsv43_1.njm << 'NJM_EOF'
# ═════════════════════════════════════════════════════════════════════════
# NJM-OS :: TEST v43.1 — Autarhija FS
# ─────────────────────────────────────────────────────────────────────────
# Testira:
#   1. Rezervaciju stack memorije (mkm)
#   2. Upis stringa "autarhija.txt\0"
#   3. Otvaranje datoteke (opn)
#   4. Upis slova 'A' (wrt)
#   5. Zatvaranje (cls)
#   6. Ponovno otvaranje za čitanje
#   7. Čitanje natrag (rdl)
#   8. Zatvaranje (cls)
#   9. Učitavanje 'A' u r0 (ujb)
#   10. Povratak (pir)
# ═════════════════════════════════════════════════════════════════════════

# ─── 1. REZERVIRAJ STACK MEMORIJU ────────────────────────────────────
mkm r10

# ─── 2. UPIŠI "autarhija.txt\0" NA [r10 + 0..13] ─────────────────────
nve r2, 97     # 'a'
ssb r2, r10, 0
nve r2, 117    # 'u'
ssb r2, r10, 1
nve r2, 116    # 't'
ssb r2, r10, 2
nve r2, 97     # 'a'
ssb r2, r10, 3
nve r2, 114    # 'r'
ssb r2, r10, 4
nve r2, 104    # 'h'
ssb r2, r10, 5
nve r2, 105    # 'i'
ssb r2, r10, 6
nve r2, 106    # 'j'
ssb r2, r10, 7
nve r2, 97     # 'a'
ssb r2, r10, 8
nve r2, 46     # '.'
ssb r2, r10, 9
nve r2, 116    # 't'
ssb r2, r10, 10
nve r2, 120    # 'x'
ssb r2, r10, 11
nve r2, 116    # 't'
ssb r2, r10, 12
nve r2, 0      # '\0'
ssb r2, r10, 13

# ─── 3. UPIŠI SLOVO 'A' (65) NA [r10 + 32] ───────────────────────────
nve r3, 65
ssb r3, r10, 32

# ─── 4. OTVORI DATOTEKU ZA PISANJE ───────────────────────────────────
# O_WRONLY(1) | O_CREAT(64) | O_TRUNC(512) = 577, mode = 420
nve r2, 577
opn r1, r10, r2, 420

# ─── 5. UPIŠI 1 BAJT IZ [r10 + 32] ───────────────────────────────────
mkm r4                # r4 = novi rezervirani prostor
nve r5, 32
sab r4, r4, r5        # r4 += 32
nve r6, 1             # count = 1
wrt r1, r4, r6        # write(r1, r4, 1)

# ─── 6. ZATVORI ──────────────────────────────────────────────────────
cls r1

# ─── 7. OTVORI ZA ČITANJE ────────────────────────────────────────────
nve r2, 0             # O_RDONLY
opn r1, r10, r2, 0

# ─── 8. ČITAJ 1 BAJT U [r10 + 64] ────────────────────────────────────
mkm r4                # r4 = novi rezervirani prostor
nve r5, 64
sab r4, r4, r5        # r4 += 64
nve r6, 1             # count = 1
rdl r1, r4, r6        # read(r1, r4, 1)

# ─── 9. ZATVORI I UČITAJ 'A' U r0 ────────────────────────────────────
cls r1
ujb r0, r4, 0         # r0 = M[r4] = 'A' (65)

# ─── 10. POVRATAK ────────────────────────────────────────────────────
pir
NJM_EOF

echo "[3] Test skripta kreirana: test_fsv43_1.njm"
echo ""

# ─── 3. POKRENI LALOGLOSATOR ───────────────────────────────────────
echo "[4] Pokrećem laloglosator v43.1 (prevodim u ELF64)..."
echo "═══════════════════════════════════════════════════════════════"

laloglosator test_fsv43_1.njm -o test_fsv43_1

echo ""
echo "[5] Postavljam execute permisije..."
chmod +x test_fsv43_1

# ─── 4. POKRENI BINARKU ─────────────────────────────────────────────
echo "[6] Pokrećem ELF64 izvršnik..."
echo "═══════════════════════════════════════════════════════════════"

./test_fsv43_1
EXIT_CODE=$?

echo "═══════════════════════════════════════════════════════════════"
echo "[7] Exit kod: $EXIT_CODE"
echo ""

# ─── 5. PROVJERA ────────────────────────────────────────────────────
if [ -f autarhija.txt ]; then
    echo "[8] ✅ Datoteka autarhija.txt postoji!"
    echo "    Sadržaj (hex):"
    xxd autarhija.txt
    echo "    Sadržaj (ASCII):"
    cat autarhija.txt
    echo ""
    echo "    Veličina: $(wc -c < autarhija.txt) bajtova"
else
    echo "[8] ❌ Datoteka autarhija.txt NE postoji!"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  [OK] Test završen"
echo "═══════════════════════════════════════════════════════════════"
