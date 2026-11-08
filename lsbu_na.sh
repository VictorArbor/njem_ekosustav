#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

ULAZ=${1:-""}
IZLAZ=${2:-"a.out"}

if [ -z "$ULAZ" ]; then
    echo "Uporaba: ./lsbu_na.sh <ulaz.njm> <izlazni_binarac>"
    exit 1
fi

TMP_HEX="tmp_code.hex"
rm -f "$TMP_HEX"

emit_hex() {
    local val=$1
    printf "%02x %02x %02x %02x " \
        $((val & 0xFF)) \
        $(((val >> 8) & 0xFF)) \
        $(((val >> 16) & 0xFF)) \
        $(((val >> 24) & 0xFF)) >> "$TMP_HEX"
}

parse_val() {
    local token=${1:-0}
    token=${token/r/}
    token=${token/x/}
    token=${token/w/}
    echo "$token"
}

while IFS= read -r line || [ -n "$line" ]; do
    clean_line=$(echo "$line" | sed 's/#.*//' | xargs)
    [ -z "$clean_line" ] && continue
    [[ "$clean_line" == *: ]] && continue

    mnem=$(echo "$clean_line" | awk '{print $1}')
    args=$(echo "$clean_line" | cut -d' ' -f2- | tr -d ' ')
    IFS=',' read -r -a a <<< "$args"

    case "$mnem" in
        "sab")
            rd=$(parse_val ${a[0]:-0})
            rn=$(parse_val ${a[1]:-0})
            rm=$(parse_val ${a[2]:-0})
            op=$((0x8B000000 | (rm << 16) | (rn << 5) | rd))
            emit_hex $op
            ;;
        "odu")
            rd=$(parse_val ${a[0]:-0})
            rn=$(parse_val ${a[1]:-0})
            rm=$(parse_val ${a[2]:-0})
            op=$((0xCB000000 | (rm << 16) | (rn << 5) | rd))
            emit_hex $op
            ;;
        "nve")
            rd=$(parse_val ${a[0]:-0})
            imm=$(parse_val ${a[1]:-0})
            op=$((0xD2800000 | ((imm & 0xFFFF) << 5) | rd))
            emit_hex $op
            ;;
        "mkm")
            rd=$(parse_val ${a[0]:-0})
            emit_hex 0xD10803FF
            op=$((0x910003E0 | rd))
            emit_hex $op
            ;;
        "ssb")
            rd=$(parse_val ${a[0]:-0})
            rn=$(parse_val ${a[1]:-0})
            off=$(parse_val ${a[2]:-0})
            op=$((0x39000000 | ((off & 0xFFF) << 10) | (rn << 5) | rd))
            emit_hex $op
            ;;
        "ujb"|"udb")
            rd=$(parse_val ${a[0]:-0})
            rn=$(parse_val ${a[1]:-0})
            off=$(parse_val ${a[2]:-0})
            op=$((0x39400000 | ((off & 0xFFF) << 10) | (rn << 5) | rd))
            emit_hex $op
            ;;
        "opn")
            r_fd=$(parse_val ${a[0]:-0})
            r_path=$(parse_val ${a[1]:-0})
            flags=$(parse_val ${a[2]:-0})
            mode=$(parse_val ${a[3]:-0})
            emit_hex 0x92800C60
            emit_hex $((0xAA0003E0 | (r_path << 16) | 1))
            emit_hex $((0xD2800002 | ((flags & 0xFFFF) << 5)))
            emit_hex $((0xD2800003 | ((mode & 0xFFFF) << 5)))
            emit_hex 0xD2800708
            emit_hex 0xD4000001
            emit_hex $((0xAA0003E0 | (0 << 16) | r_fd))
            ;;
        "wrt")
            r_fd=$(parse_val ${a[0]:-0})
            r_buf=$(parse_val ${a[1]:-0})
            cnt_raw=${a[2]:-0}
            cnt=$(parse_val $cnt_raw)
            emit_hex $((0xAA0003E0 | (r_fd << 16) | 19))
            emit_hex $((0xAA0003E0 | (r_buf << 16) | 1))
            if [[ "$cnt_raw" == r* || "$cnt_raw" == x* ]]; then
                emit_hex $((0xAA0003E0 | (cnt << 16) | 2))
            else
                emit_hex $((0xD2800002 | ((cnt & 0xFFFF) << 5)))
            fi
            emit_hex 0xAA0003E0
            emit_hex 0xD2800808
            emit_hex 0xD4000001
            emit_hex $((0xAA0003E0 | (19 << 16) | r_fd))
            ;;
        "cls")
            r_fd=$(parse_val ${a[0]:-0})
            emit_hex $((0xAA0003E0 | (r_fd << 16) | 0))
            emit_hex 0xD2800728
            emit_hex 0xD4000001
            ;;
        "pir")
            emit_hex 0x910803FF
            emit_hex 0xD2800000
            emit_hex 0xD2800BA8
            emit_hex 0xD4000001
            ;;
    esac
done < <(sed 's/;/\n/g' "$ULAZ")

# Sigurnosni izlaz
emit_hex 0xD2800000
emit_hex 0xD2800BA8
emit_hex 0xD4000001

# --- GENERATOR BINARNIH UZORAKA (ELF64 Header Generator) ---
hex_data=$(cat "$TMP_HEX")
num_bytes=$(echo "$hex_data" | wc -w)
filesz=$((120 + num_bytes))

rm -f "$IZLAZ"
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

echo "⚙️ Kompajliran nativni ELF64 binarac (BEZ GNU as/ld!): $IZLAZ"
