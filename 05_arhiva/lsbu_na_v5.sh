#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

ULAZ=${1:-"ulaz.njm"}
IZLAZ=${2:-"izlaz.elf"}

if [ ! -f "$ULAZ" ]; then
    echo "⚠️ Datoteka $ULAZ ne postoji!"
    exit 1
fi

TMP_HEX="tmp_code.hex"
rm -f "$TMP_HEX"

parse_val() {
    local token=${1:-0}
    token=${token/r/}
    token=${token/x/}
    token=${token/w/}
    echo "$token"
}

# ─── DISKRETNI KALKULATOR OPKODA (Sinteza bitnih uzoraka) ──────────────────
emit_hex() {
    local val=$1
    printf "%02x %02x %02x %02x " \
        $((val & 0xFF)) \
        $(((val >> 8) & 0xFF)) \
        $(((val >> 16) & 0xFF)) \
        $(((val >> 24) & 0xFF)) >> "$TMP_HEX"
}

# Čitanje i diskretni izračun opkoda
while IFS= read -r line || [ -n "$line" ]; do
    clean_line=$(echo "$line" | sed 's/#.*//' | xargs)
    [ -z "$clean_line" ] && continue
    [[ "$clean_line" == *: ]] && continue

    mnem=$(echo "$clean_line" | awk '{print $1}')
    args=$(echo "$clean_line" | cut -d' ' -f2- | tr -d ' ')
    IFS=',' read -r -a a <<< "$args"

    case "$mnem" in
        "sab") # ADD Xd, Xn, Xm
            rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0}); rm=$(parse_val ${a[2]:-0})
            op=$((0x8B000000 | (rm << 16) | (rn << 5) | rd))
            emit_hex $op
            ;;
        "nve") # MOVZ Xd, #imm
            rd=$(parse_val ${a[0]:-0}); imm=$(parse_val ${a[1]:-0})
            op=$((0xD2800000 | ((imm & 0xFFFF) << 5) | rd))
            emit_hex $op
            ;;
        "pir") # Exit (SVC #0)
            emit_hex 0x910803FF  # ADD SP, SP, #512
            emit_hex 0xD2800000  # MOV X0, #0
            emit_hex 0xD2800BA8  # MOV X8, #93
            emit_hex 0xD4000001  # SVC #0
            ;;
    esac
done < "$ULAZ"

# Sigurnosni izlaz
emit_hex 0xD2800000
emit_hex 0xD2800BA8
emit_hex 0xD4000001

# ─── GENERATOR BINARNIH UZORAKA (ELF64 Header) ───────────────────────────
hex_data=$(cat "$TMP_HEX")
num_bytes=$(echo "$hex_data" | wc -w)
filesz=$((120 + num_bytes))

rm -f "$IZLAZ"
# 120 bajtova determinističkog ELF64 zaglavlja
printf "\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00" >> "$IZLAZ"
printf "\x02\x00\xb7\x00\x01\x00\x00\x00" >> "$IZLAZ"
printf "\x78\x00\x40\x00\x00\x00\x00\x00" >> "$IZLAZ"
printf "\x40\x00\x00\x00\x00\x00\x00\x00" >> "$IZLAZ"
printf "\x00\x00\x00\x00\x00\x00\x00\x00" >> "$IZLAZ"
printf "\x00\x00\x00\x00\x40\x00\x38\x00\x01\x00\x00\x00\x00\x00\x00\x00" >> "$IZLAZ"

printf "\x01\x00\x00\x00\x07\x00\x00\x00" >> "$IZLAZ"
printf "\x00\x00\x00\x00\x00\x00\x00\x00" >> "$IZLAZ"
printf "\x00\x00\x40\x00\x00\x00\x00\x00" >> "$IZLAZ"
printf "\x00\x00\x40\x00\x00\x00\x00\x00" >> "$IZLAZ"

printf $(printf '\\x%02x\\x%02x\\x00\\x00\\x00\\x00\\x00\\x00' $((filesz & 0xFF)) $(((filesz >> 8) & 0xFF))) >> "$IZLAZ"
printf $(printf '\\x%02x\\x%02x\\x00\\x00\\x00\\x00\\x00\\x00' $((filesz & 0xFF)) $(((filesz >> 8) & 0xFF))) >> "$IZLAZ"
printf "\x00\x00\x01\x00\x00\x00\x00\x00" >> "$IZLAZ"

for b in $hex_data; do
    printf "\\x$b" >> "$IZLAZ"
done

chmod +x "$IZLAZ"
rm -f "$TMP_HEX"

echo "⚙️  DISKRETNI KALKULATOR I GENERATOR UZORAKA :: Stvoren $IZLAZ"
