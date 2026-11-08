#!/data/data/com.termux/files/usr/bin/bash
set -eo pipefail

ULAZ=${1:-""}
IZLAZ=${2:-"bench_v12.elf"}

if [ -z "$ULAZ" ]; then
    echo "Uporaba: ./lsbu_na_v12.sh <ulaz.njm> <izlazni_elf>"
    exit 1
fi

TMP_HEX="tmp_v12.hex"
rm -f "$TMP_HEX" "$IZLAZ"

parse_val() {
    local token=${1:-0}
    token=${token/r/}
    token=${token/x/}
    token=${token/w/}
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

mapfile -t LINES < <(sed 's/;/\n/g' "$ULAZ")

# ─── 1. PROLAZ: Razrešavanje labela ─────────────────────────────────────────
declare -A LABELE
CURR_ADDR=0

for line in "${LINES[@]}"; do
    clean_line=$(echo "$line" | sed 's/#.*//' | xargs)
    [ -z "$clean_line" ] && continue

    if [[ "$clean_line" == *: ]]; then
        lbl=$(echo "$clean_line" | tr -d ': ')
        LABELE["$lbl"]=$CURR_ADDR
        continue
    fi

    mnem=$(echo "$clean_line" | awk '{print $1}')
    case "$mnem" in
        "mkm") CURR_ADDR=$((CURR_ADDR + 8)) ;;
        "vri") CURR_ADDR=$((CURR_ADDR + 16)) ;;
        "pir") CURR_ADDR=$((CURR_ADDR + 16)) ;;
        *)     CURR_ADDR=$((CURR_ADDR + 4)) ;;
    esac
done

# ─── 2. PROLAZ: Generiranje AArch64 opkoda ─────────────────────────────────
CURR_PC=0

for line in "${LINES[@]}"; do
    clean_line=$(echo "$line" | sed 's/#.*//' | xargs)
    [ -z "$clean_line" ] && continue
    [[ "$clean_line" == *: ]] && continue

    mnem=$(echo "$clean_line" | awk '{print $1}')
    args=$(echo "$clean_line" | cut -d' ' -f2- | tr -d ' ')
    IFS=',' read -r -a a <<< "$args"

    case "$mnem" in
        "mkm")
            rd=$(parse_val ${a[0]:-10})
            emit_hex 0xD10803FF                       # SUB SP, SP, #512
            emit_hex $((0x910003E0 | rd))             # ADD Xd, SP, #0
            CURR_PC=$((CURR_PC + 8))
            ;;
        "nve")
            rd=$(parse_val ${a[0]:-0}); imm=$(parse_val ${a[1]:-0})
            emit_hex $((0xD2800000 | ((imm & 0xFFFF) << 5) | rd))
            CURR_PC=$((CURR_PC + 4))
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
        "ssb")
            rt=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0}); off=$(parse_val ${a[2]:-0})
            emit_hex $((0x39000000 | ((off & 0xFFF) << 10) | (rn << 5) | rt))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "spe")
            sys_num=$(parse_val ${a[0]:-64})
            emit_hex $((0xD2800008 | ((sys_num & 0xFFFF) << 5)))
            emit_hex 0xD4000001
            CURR_PC=$((CURR_PC + 8))
            ;;
        "uis")
            rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0}); rm=$(parse_val ${a[2]:-0})
            emit_hex $((0xAA000000 | (rm << 16) | (rn << 5) | rd))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "srs")
            rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0}); rm=$(parse_val ${a[2]:-0})
            emit_hex $((0xCA000000 | (rm << 16) | (rn << 5) | rd))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "vri")
            rd=$(parse_val ${a[0]:-0})
            emit_hex 0xD2800020                     # MOV X0, #1
            emit_hex $((0x910003E0 | rd))           # ADD Xd, SP, #0
            emit_hex 0xD2800E28                     # MOV X8, #113 (SYS_clock_gettime)
            emit_hex 0xD4000001                     # SVC #0
            CURR_PC=$((CURR_PC + 16))
            ;;
        "gnn")
            rt=$(parse_val ${a[0]:-0})
            target=${a[1]:-""}
            target_addr=${LABELE["$target"]:-0}
            off_bytes=$((target_addr - CURR_PC))
            off_imm=$(((off_bytes / 4) & 0x7FFFF))
            emit_hex $((0xB5000000 | (off_imm << 5) | rt))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "pir")
            emit_hex 0x910803FF                           # ADD SP, SP, #512
            emit_hex 0xD2800000                           # MOV X0, #0
            emit_hex 0xD2800BA8                           # MOV X8, #93
            emit_hex 0xD4000001                           # SVC #0
            CURR_PC=$((CURR_PC + 16))
            ;;
    esac
done

hex_data=$(cat "$TMP_HEX")
num_bytes=$(echo "$hex_data" | wc -w)
filesz=$((120 + num_bytes))

python3 -c "
import struct, sys

filesz = $filesz
num_bytes = $num_bytes
hex_raw = '$hex_data'.split()
code_bytes = bytes([int(b, 16) for b in hex_raw])

ehdr = struct.pack('<16sHHIQQQIHHHHHH',
    b'\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00',
    2, 183, 1, 0x400078, 64, 0, 0, 64, 56, 1, 0, 0, 0
)

phdr = struct.pack('<IIQQQQQQ',
    1, 7, 0, 0x400000, 0x400000, filesz, filesz, 0x10000
)

sys.stdout.buffer.write(ehdr + phdr + code_bytes)
" > "$IZLAZ"

chmod +x "$IZLAZ"
rm -f "$TMP_HEX"
echo "✅ Transpiler ažuriran s podrškom za labele: $IZLAZ"
