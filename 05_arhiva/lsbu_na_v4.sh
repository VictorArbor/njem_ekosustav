#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

ULAZ=${1:-""}
IZLAZ=${2:-"a.out"}

if [ -z "$ULAZ" ]; then
    echo "Uporaba: ./lsbu_na_v4.sh <ulaz.njm> <izlazni_binarac>"
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

# ─── 1. PROLAZ: Izračun točnih adresa labela ───────────────────────────────
mapfile -t LINES < <(sed 's/;/\n/g' "$ULAZ")

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
        "mkm") CURR_ADDR=$((CURR_ADDR + 8)) ;;      # 2 opkoda
        "cls") CURR_ADDR=$((CURR_ADDR + 12)) ;;     # 3 opkoda
        "pir") CURR_ADDR=$((CURR_ADDR + 16)) ;;     # 4 opkoda
        "opn"|"wrt"|"rdl") CURR_ADDR=$((CURR_ADDR + 28)) ;; # 7 opkoda
        "sab"|"odu"|"mno"|"pis"|"uis"|"ris"|"srs"|"lpo"|"dpo"|"pje"|"nve"|"ssb"|"ujb"|"udb"|"spe"|"gjn"|"gnn"|"pio"|"ume")
            CURR_ADDR=$((CURR_ADDR + 4))            # 1 opkod
            ;;
    esac
done

# ─── 2. PROLAZ: Diskretni kalkulator i generiranje opkoda ─────────────────
emit_hex() {
    local val=$1
    printf "%02x %02x %02x %02x " \
        $((val & 0xFF)) \
        $(((val >> 8) & 0xFF)) \
        $(((val >> 16) & 0xFF)) \
        $(((val >> 24) & 0xFF)) >> "$TMP_HEX"
}

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
        "pis") # AND
            rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0}); rm=$(parse_val ${a[2]:-0})
            emit_hex $((0x8A000000 | (rm << 16) | (rn << 5) | rd))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "uis") # ORR
            rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0}); rm=$(parse_val ${a[2]:-0})
            emit_hex $((0xAA000000 | (rm << 16) | (rn << 5) | rd))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "ris") # BIC
            rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0}); rm=$(parse_val ${a[2]:-0})
            emit_hex $((0x8A200000 | (rm << 16) | (rn << 5) | rd))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "srs") # EOR
            rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0}); rm=$(parse_val ${a[2]:-0})
            emit_hex $((0xCA000000 | (rm << 16) | (rn << 5) | rd))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "lpo") # LSL
            rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0}); sh=$(parse_val ${a[2]:-0})
            emit_hex $((0xD37AEC00 | ((sh & 0x3F) << 16) | (rn << 5) | rd))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "dpo") # LSR
            rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0}); sh=$(parse_val ${a[2]:-0})
            emit_hex $((0xD37AFC00 | ((sh & 0x3F) << 16) | (rn << 5) | rd))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "pje") # MOV
            rd=$(parse_val ${a[0]:-0}); rn=$(parse_val ${a[1]:-0})
            emit_hex $((0xAA0003E0 | (rn << 16) | rd))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "nve") # MOVZ
            rd=$(parse_val ${a[0]:-0}); imm=$(parse_val ${a[1]:-0})
            emit_hex $((0xD2800000 | ((imm & 0xFFFF) << 5) | rd))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "ume") # CMP Xn, Xm -> SUBS XZR, Xn, Xm
            rn=$(parse_val ${a[0]:-0}); rm_raw=${a[1]:-0}
            if [[ "$rm_raw" == r* || "$rm_raw" == x* ]]; then
                rm=$(parse_val $rm_raw)
                emit_hex $((0xEB00001F | (rm << 16) | (rn << 5)))
            else
                imm=$(parse_val $rm_raw)
                emit_hex $((0xF100001F | ((imm & 0xFFF) << 10) | (rn << 5)))
            fi
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
        "spe") # Syscall direktni
            sys_num=$(parse_val ${a[0]:-0})
            emit_hex $((0xD2800008 | ((sys_num & 0xFFFF) << 5))) # MOV X8, #sys_num
            emit_hex 0xD4000001                                  # SVC #0
            CURR_PC=$((CURR_PC + 8))
            ;;
        "gnn") # CBNZ rt, target
            rt=$(parse_val ${a[0]:-0}); target=${a[1]:-""}
            target_addr=${LABELE["$target"]:-0}
            off_bytes=$((target_addr - CURR_PC))
            off_imm=$(((off_bytes / 4) & 0x7FFFF))
            emit_hex $((0xB5000000 | (off_imm << 5) | rt))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "gjn") # CBZ rt, target
            rt=$(parse_val ${a[0]:-0}); target=${a[1]:-""}
            target_addr=${LABELE["$target"]:-0}
            off_bytes=$((target_addr - CURR_PC))
            off_imm=$(((off_bytes / 4) & 0x7FFFF))
            emit_hex $((0xB4000000 | (off_imm << 5) | rt))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "pio") # B target
            target=${a[0]:-""}
            target_addr=${LABELE["$target"]:-0}
            off_bytes=$((target_addr - CURR_PC))
            off_imm=$(((off_bytes / 4) & 0x3FFFFFF))
            emit_hex $((0x14000000 | off_imm))
            CURR_PC=$((CURR_PC + 4))
            ;;
        "opn")
            r_fd=$(parse_val ${a[0]:-0}); r_path=$(parse_val ${a[1]:-0}); flags=$(parse_val ${a[2]:-0}); mode=$(parse_val ${a[3]:-0})
            emit_hex 0x92800C60                            # MOVN X0, #99 (AT_FDCWD)
            emit_hex $((0xAA0003E0 | (r_path << 16) | 1))  # MOV X1, Xpath
            emit_hex $((0xD2800002 | ((flags & 0xFFFF) << 5))) # MOVZ X2, #flags
            emit_hex $((0xD2800003 | ((mode & 0xFFFF) << 5)))  # MOVZ X3, #mode
            emit_hex 0xD2800708                            # MOV X8, #56
            emit_hex 0xD4000001                            # SVC #0
            emit_hex $((0xAA0003E0 | (0 << 16) | r_fd))    # MOV Xfd, X0
            CURR_PC=$((CURR_PC + 28))
            ;;
        "wrt")
            r_fd=$(parse_val ${a[0]:-0}); r_buf=$(parse_val ${a[1]:-0}); cnt_raw=${a[2]:-0}
            cnt=$(parse_val $cnt_raw)
            emit_hex $((0xAA0003E0 | (r_fd << 16) | 19))    # MOV X19, Xfd
            emit_hex $((0xAA0003E0 | (r_buf << 16) | 1))     # MOV X1, Xbuf
            if [[ "$cnt_raw" == r* || "$cnt_raw" == x* ]]; then
                emit_hex $((0xAA0003E0 | (cnt << 16) | 2))  # MOV X2, Xcnt
            else
                emit_hex $((0xD2800002 | ((cnt & 0xFFFF) << 5))) # MOVZ X2, #cnt
            fi
            emit_hex 0xAA1303E0                              # MOV X0, X19
            emit_hex 0xD2800808                              # MOV X8, #64
            emit_hex 0xD4000001                              # SVC #0
            emit_hex $((0xAA0003E0 | (19 << 16) | r_fd))     # MOV Xfd, X19
            CURR_PC=$((CURR_PC + 28))
            ;;
        "cls")
            r_fd=$(parse_val ${a[0]:-0})
            emit_hex $((0xAA0003E0 | (r_fd << 16) | 0))      # MOV X0, Xfd
            emit_hex 0xD2800728                              # MOV X8, #57
            emit_hex 0xD4000001                              # SVC #0
            CURR_PC=$((CURR_PC + 12))
            ;;
        "pir")
            emit_hex 0x910803FF                              # ADD SP, SP, #512
            emit_hex 0xD2800000                              # MOV X0, #0
            emit_hex 0xD2800BA8                              # MOV X8, #93
            emit_hex 0xD4000001                              # SVC #0
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

echo "⚙️  BOOTSTRAP TRANSCOMPILER (S UME PODRŠKOM) :: Izgrađen $IZLAZ"
