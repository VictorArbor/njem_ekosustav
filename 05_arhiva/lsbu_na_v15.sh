#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

ULAZ=${1:-"ulaz.njm"}
IZLAZ=${2:-"izlaz.elf"}

[ ! -f "$ULAZ" ] && { echo "⚠️ Datoteka $ULAZ ne postoji!"; exit 1; }

TMP_HEX="tmp_code.hex"
rm -f "$TMP_HEX"

parse_val() {
    local token=${1:-0}
    token=${token//[r|x|w]/}
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

# Razbijanje ulaza po točka-zarezima i novim redovima
MAP_LINES=()
while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    IFS=';' read -ra PARTS <<< "$line"
    for part in "${PARTS[@]}"; do
        clean_part=$(echo "$part" | xargs)
        [ -n "$clean_part" ] && MAP_LINES+=("$clean_part")
    done
done < "$ULAZ"

declare -A LABELE
CURR_ADDR=0

# Prolaz 1: Deklaracija labela
for line in "${MAP_LINES[@]}"; do
    if [[ "$line" == *: ]]; then
        LABELE["${line%:}"]=$CURR_ADDR
        continue
    fi
    mnem=${line%% *}
    case "$mnem" in
        "mkm") CURR_ADDR=$((CURR_ADDR + 8)) ;;
        "spe") CURR_ADDR=$((CURR_ADDR + 8)) ;;
        "pir") CURR_ADDR=$((CURR_ADDR + 16)) ;;
        "lsb"|"ssb"|"sab"|"odu"|"mno"|"nve"|"gnn"|"uis"|"srs") CURR_ADDR=$((CURR_ADDR + 4)) ;;
    esac
done

CURR_PC=0

# Prolaz 2: Generiranje opkoda
for line in "${MAP_LINES[@]}"; do
    [[ "$line" == *: ]] && continue

    mnem=${line%% *}
    args=${line#"$mnem"}
    args=${args// /}
    IFS=',' read -r -a a <<< "$args"

    case "$mnem" in
        "uis"|"sab") rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0}); rm=$(parse_val ${a[2]:-0}); emit_hex $((0x8A000000 | (rm << 16) | (rn << 5) | rd)); CURR_PC=$((CURR_PC + 4)) ;;
        "srs") rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0}); rm=$(parse_val ${a[2]:-0}); emit_hex $((0xCA000000 | (rm << 16) | (rn << 5) | rd)); CURR_PC=$((CURR_PC + 4)) ;;
        "ssb") rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0}); off=$(parse_val ${a[2]:-0}); emit_hex $((0x39000000 | ((off & 0xFFF) << 10) | (rn << 5) | rd)); CURR_PC=$((CURR_PC + 4)) ;;
        "lsb") rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0}); off=$(parse_val ${a[2]:-0}); emit_hex $((0x39400000 | ((off & 0xFFF) << 10) | (rn << 5) | rd)); CURR_PC=$((CURR_PC + 4)) ;;
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
        "nve") rd=$(parse_val ${a[0]:-0}); imm=$(parse_val ${a[1]:-0}); emit_hex $((0xD2800000 | ((imm & 0xFFFF) << 5) | rd)); CURR_PC=$((CURR_PC + 4)) ;;
        "mkm") rd=$(parse_val ${a[0]:-0}); emit_hex 0xD10803FF; emit_hex $((0x910003E0 | rd)); CURR_PC=$((CURR_PC + 8)) ;;
        "gnn") 
            rt=$(parse_val ${a[0]:-0}); target=${a[1]:-""}
            target_addr=${LABELE["$target"]:-0}
            off_bytes=$((target_addr - CURR_PC))
            off_imm=$(((off_bytes / 4) & 0x7FFFF))
            emit_hex $((0xB5000000 | (off_imm << 5) | rt))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "spe") sys_num=$(parse_val ${a[0]:-0}); emit_hex $((0xD2800008 | ((sys_num & 0xFFFF) << 5))); emit_hex 0xD4000001; CURR_PC=$((CURR_PC + 8)) ;;
        "pir") emit_hex 0x910803FF; emit_hex 0xD2800000; emit_hex 0xD2800BA8; emit_hex 0xD4000001; CURR_PC=$((CURR_PC + 16)) ;;
    esac
done

emit_hex 0xD2800000; emit_hex 0xD2800BA8; emit_hex 0xD4000001

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
