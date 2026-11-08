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

# ─── 1. PROLAZ: Prikupljanje adresa labela u ISTOM SHELLU ────────────────
mapfile -t LINES < <(sed 's/;/\n/g' "$ULAZ")

declare -A LABELE
CURR_ADDR=0

for line in "${LINES[@]}"; do
    clean_line=$(echo "$line" | sed 's/#.*//' | xargs)
    [ -z "$clean_line" ] && continue
    [[ "$clean_line" == *: ]] && continue

    mnem=$(echo "$clean_line" | awk '{print $1}')
    case "$mnem" in
        "mkm") CURR_ADDR=$((CURR_ADDR + 8)) ;;
        "spe") CURR_ADDR=$((CURR_ADDR + 8)) ;;
        "pir") CURR_ADDR=$((CURR_ADDR + 16)) ;;
        "sab"|"odu"|"mno"|"udv"|"pis"|"uis"|"ris"|"srs"|"lpo"|"dpo"|"pje"|"nve"|"ssb"|"ujb"|"udb"|"ume"|"gjn"|"gnn"|"pio")
            CURR_ADDR=$((CURR_ADDR + 4))
            ;;
    esac
done

# ─── 2. PROLAZ: Generiranje opkoda ─────────────────────────────────────────
CURR_PC=0

for line in "${LINES[@]}"; do
    clean_line=$(echo "$line" | sed 's/#.*//' | xargs)
    [ -z "$clean_line" ] && continue
    [[ "$clean_line" == *: ]] && continue

    mnem=$(echo "$clean_line" | awk '{print $1}')
    args=$(echo "$clean_line" | cut -d' ' -f2- | tr -d ' ')
    IFS=',' read -r -a a <<< "$args"

    case "$mnem" in
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
        "mno")
            rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0}); rm=$(parse_val ${a[2]:-0})
            emit_hex $((0x9B000000 | (rm << 16) | (rn << 5) | rd))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "udv") # UDIV (Unsigned Divide) Xd, Xn, Xm
            rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0}); rm=$(parse_val ${a[2]:-0})
            emit_hex $((0x9AC00800 | (rm << 16) | (rn << 5) | rd))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "pje") # MOV Xd, Xn
            rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0})
            emit_hex $((0xAA0003E0 | (rn << 16) | rd))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "nve") # MOVZ Xd, #imm
            rd=$(parse_val ${a[0]:-0}); imm=$(parse_val ${a[1]:-0})
            emit_hex $((0xD2800000 | ((imm & 0xFFFF) << 5) | rd))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "mkm")
            rd=$(parse_val ${a[0]:-0})
            emit_hex 0xD10803FF                       # SUB SP, SP, #512
            emit_hex $((0x910003E0 | rd))             # MOV Xd, SP
            CURR_PC=$((CURR_PC + 8))
            ;;
        "ssb")
            rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0}); off=$(parse_val ${a[2]:-0})
            emit_hex $((0x39000000 | ((off & 0xFFF) << 10) | (rn << 5) | rd))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "ujb"|"udb")
            rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0}); off=$(parse_val ${a[2]:-0})
            emit_hex $((0x39400000 | ((off & 0xFFF) << 10) | (rn << 5) | rd))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "spe") # Syscall izravni
            sys_num=$(parse_val ${a[0]:-0})
            emit_hex $((0xD2800008 | ((sys_num & 0xFFFF) << 5))) # MOV X8, #sys_num
            emit_hex 0xD4000001                                  # SVC #0
            CURR_PC=$((CURR_PC + 8))
            ;;
        "gnn") # CBNZ
            rt=$(parse_val ${a[0]:-0}); target=${a[1]:-""}
            target_addr=${LABELE["$target"]:-0}
            off_bytes=$((target_addr - CURR_PC))
            off_imm=$(((off_bytes / 4) & 0x7FFFF))
            emit_hex $((0xB5000000 | (off_imm << 5) | rt))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "gjn") # CBZ
            rt=$(parse_val ${a[0]:-0}); target=${a[1]:-""}
            target_addr=${LABELE["$target"]:-0}
            off_bytes=$((target_addr - CURR_PC))
            off_imm=$(((off_bytes / 4) & 0x7FFFF))
            emit_hex $((0xB4000000 | (off_imm << 5) | rt))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "pio") # B
            target=${a[0]:-""}
            target_addr=${LABELE["$target"]:-0}
            off_bytes=$((target_addr - CURR_PC))
            off_imm=$(((off_bytes / 4) & 0x3FFFFFF))
            emit_hex $((0x14000000 | off_imm))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "pir") # Exit
            emit_hex 0x910803FF  # ADD SP, SP, #512
            emit_hex 0xD2800000  # MOV X0, #0
            emit_hex 0xD2800BA8  # MOV X8, #93
            emit_hex 0xD4000001  # SVC #0
            CURR_PC=$((CURR_PC + 16))
            ;;
    esac
done

# Sigurnosni izlaz
emit_hex 0xD2800000
emit_hex 0xD2800BA8
emit_hex 0xD4000001

# ─── GENERATOR BINARNIH UZORAKA (ELF64 Header) ───────────────────────────
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

echo "⚙️  FULL LSBU ENGINE v6.0 :: Stvoren $IZLAZ"
