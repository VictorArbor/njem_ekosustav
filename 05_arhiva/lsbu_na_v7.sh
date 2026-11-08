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
    token=${token/r/}; token=${token/x/}; token=${token/w/}
    echo "$token"
}

emit_hex() {
    local val=$1
    printf "%02x %02x %02x %02x " \
        $((val & 0xFF)) \
        $(((val >> 8) & 0xFF)) \
        $(((val >> 16) & 0xFF)) \
        $(((val >> 24) & 0xFF)) >> "$TMP_HEX"
}

# ─── 1. PROLAZ: Prikupljanje adresa labela ────────────────────────────────
mapfile -t LINES < <(sed 's/;/\n/g' "$ULAZ")

declare -A LABELE
CURR_ADDR=0

for line in "${LINES[@]}"; do
    clean_line=$(echo "$line" | sed 's/#.*//' | xargs)
    [ -z "$clean_line" ] && continue
    [[ "$clean_line" == *: ]] && {
        lbl=$(echo "$clean_line" | tr -d ': ')
        LABELE["$lbl"]=$CURR_ADDR
        continue
    }

    mnem=$(echo "$clean_line" | awk '{print $1}')
    case "$mnem" in
        "mkm") CURR_ADDR=$((CURR_ADDR + 8)) ;;
        "spe") CURR_ADDR=$((CURR_ADDR + 8)) ;;
        "pir") CURR_ADDR=$((CURR_ADDR + 16)) ;;
        "n64") CURR_ADDR=$((CURR_ADDR + 16)) ;; # 4 x MOVZ/MOVK za 64-bit učitavanje
        "sab"|"odu"|"mno"|"udv"|"pis"|"uis"|"ris"|"srs"|"lpo"|"dpo"|"pje"|"nve"|"ssb"|"ujb"|"udb"|"ume"|"gjn"|"gnn"|"pio")
            CURR_ADDR=$((CURR_ADDR + 4))
            ;;
    esac
done

# ─── 2. PROLAZ: Generiranje optimiziranih opkoda ─────────────────────────
CURR_PC=0

for line in "${LINES[@]}"; do
    clean_line=$(echo "$line" | sed 's/#.*//' | xargs)
    [ -z "$clean_line" ] && continue
    [[ "$clean_line" == *: ]] && continue

    mnem=$(echo "$clean_line" | awk '{print $1}')
    args=$(echo "$clean_line" | cut -d' ' -f2- | tr -d ' ')
    IFS=',' read -r -a a <<< "$args"

    case "$mnem" in
        "n64") # Optimizirano 64-bitno učitavanje (chunking od 8 bajtova u 1 registar)
            rd=$(parse_val ${a[0]:-0})
            v0=${a[1]:-0}; v1=${a[2]:-0}; v2=${a[3]:-0}; v4=${a[4]:-0}
            emit_hex $((0xD2800000 | ((v0 & 0xFFFF) << 5) | rd))
            emit_hex $((0xF2A00000 | ((v1 & 0xFFFF) << 5) | rd))
            emit_hex $((0xF2C00000 | ((v2 & 0xFFFF) << 5) | rd))
            emit_hex $((0xF2E00000 | ((v4 & 0xFFFF) << 5) | rd))
            CURR_PC=$((CURR_PC + 16))
            ;;
        "sab")
            rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0}); rm_raw=${a[2]:-0}
            if [[ "$rm_raw" == r* || "$rm_raw" == x* ]]; then
                rm=$(parse_val $rm_raw)
                emit_hex $((0x8B000000 | (rm << 16) | (rn << 5) | rd))
            else
                imm=$(parse_val $rm_raw)
                emit_hex $((0x91000000 | ((imm & 0xFFF) << 10) | (rn << 5) | rd))
            fi
            CURR_PC=$((CURR_PC + 4))
            ;;
        "odu")
            rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0}); rm_raw=${a[2]:-0}
            if [[ "$rm_raw" == r* || "$rm_raw" == x* ]]; then
                rm=$(parse_val $rm_raw)
                emit_hex $((0xCB000000 | (rm << 16) | (rn << 5) | rd))
            else
                imm=$(parse_val $rm_raw)
                emit_hex $((0xD1000000 | ((imm & 0xFFF) << 10) | (rn << 5) | rd))
            fi
            CURR_PC=$((CURR_PC + 4))
            ;;
        "pje") rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0}); emit_hex $((0xAA0003E0 | (rn << 16) | rd)); CURR_PC=$((CURR_PC + 4)) ;;
        "nve") rd=$(parse_val ${a[0]:-0}); imm=$(parse_val ${a[1]:-0}); emit_hex $((0xD2800000 | ((imm & 0xFFFF) << 5) | rd)); CURR_PC=$((CURR_PC + 4)) ;;
        "mkm") rd=$(parse_val ${a[0]:-0}); emit_hex 0xD10803FF; emit_hex $((0x910003E0 | rd)); CURR_PC=$((CURR_PC + 8)) ;;
        "ssb") rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0}); off=$(parse_val ${a[2]:-0}); emit_hex $((0x39000000 | ((off & 0xFFF) << 10) | (rn << 5) | rd)); CURR_PC=$((CURR_PC + 4)) ;;
        "spe") sys_num=$(parse_val ${a[0]:-0}); emit_hex $((0xD2800008 | ((sys_num & 0xFFFF) << 5))); emit_hex 0xD4000001; CURR_PC=$((CURR_PC + 8)) ;;
        "pir") emit_hex 0x910803FF; emit_hex 0xD2800000; emit_hex 0xD2800BA8; emit_hex 0xD4000001; CURR_PC=$((CURR_PC + 16)) ;;
    esac
done

# Sigurnosni izlaz
emit_hex 0xD2800000; emit_hex 0xD2800BA8; emit_hex 0xD4000001

# ─── GENERATOR UZORAKA (ELF64 Header) ────────────────────────────────────
hex_data=$(cat "$TMP_HEX")
num_bytes=$(echo "$hex_data" | wc -w)
filesz=$((120 + num_bytes))

rm -f "$IZLAZ"
printf "\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00" >> "$IZLAZ"
printf "\x02\x00\xb7\x00\x01\x00\x00\x00\x78\x00\x40\x00\x00\x00\x00\x00" >> "$IZLAZ"
printf "\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" >> "$IZLAZ"
printf "\x00\x00\x00\x00\x40\x00\x38\x00\x01\x00\x00\x00\x00\x00\x00\x00" >> "$IZLAZ"
printf "\x01\x00\x00\x00\x07\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" >> "$IZLAZ"
printf "\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00" >> "$IZLAZ"
printf $(printf '\\x%02x\\x%02x\\x00\\x00\\x00\\x00\\x00\\x00' $((filesz & 0xFF)) $(((filesz >> 8) & 0xFF))) >> "$IZLAZ"
printf $(printf '\\x%02x\\x%02x\\x00\\x00\\x00\\x00\\x00\\x00' $((filesz & 0xFF)) $(((filesz >> 8) & 0xFF))) >> "$IZLAZ"
printf "\x00\x00\x01\x00\x00\x00\x00\x00" >> "$IZLAZ"

for b in $hex_data; do printf "\\x$b" >> "$IZLAZ"; done
chmod +x "$IZLAZ"
rm -f "$TMP_HEX"
