#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
#   NJM OS :: LSBU BOOTSTRAP TRANSPILER v5.1 (PUNI UTF-8 UNICODE ENGINE)
# ═══════════════════════════════════════════════════════════════════════════
set -uo pipefail

INPUT="$1"
OUTPUT="${2:-$HOME/njm_2_ekosustav_01/04_binarci/pokreni.elf}"

[ ! -f "$INPUT" ] && { echo "⚠️ Datoteka $INPUT ne postoji!"; exit 1; }
mkdir -p "$(dirname "$OUTPUT")"

TMP_HEX="$(dirname "$OUTPUT")/code_payload.hex"
rm -f "$TMP_HEX"

emit_op() {
    local val=$1
    printf "%02x%02x%02x%02x" \
        $((val & 0xFF)) \
        $(((val >> 8) & 0xFF)) \
        $(((val >> 16) & 0xFF)) \
        $(((val >> 24) & 0xFF)) >> "$TMP_HEX"
}

# ─── PROLOG: Alokacija 2048 B na stogu ───
emit_op 0xD12003FF   # SUB SP, SP, #2048
emit_op 0x910003EA   # ADD X10, SP, #0

# ─── PARSIRANJE I LEKSIČKA SINTEZA ───
while IFS= read -r rawline || [ -n "$rawline" ]; do
    line=$(printf '%s' "$rawline" | sed 's/#.*//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -z "$line" ] && continue

    IFS=';' read -ra statements <<< "$line"

    for stmt in "${statements[@]}"; do
        stmt=$(printf '%s' "$stmt" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [ -z "$stmt" ] && continue

        op=$(printf '%s' "$stmt" | awk '{print $1}')

        # ─── High-Level UTF-8 String Handler: wrt fd, "tekst" ───
        if [ "$op" = "wrt" ]; then
            fd=$(printf '%s' "$stmt" | awk '{print $2}' | tr -d ',')
            str=$(printf '%s' "$stmt" | sed -n 's/.*"\(.*\)".*/\1/p')

            if [ -n "$str" ]; then
                # Pretvorba escape sekvenci u sirove bajtove
                raw_bytes=$(printf '%b' "$str" | od -An -tx1 | tr -d ' \n')
                len=$(( ${#raw_bytes} / 2 ))

                # Serijsko pakiranje svakog bajta na stog
                for (( i=0; i<len; i++ )); do
                    hex_val="${raw_bytes:$((i*2)):2}"
                    ascii=$((16#$hex_val))
                    emit_op $((0xD2800000 | ((ascii & 0xFFFF) << 5) | 0))                 # MOV X0, #ascii
                    emit_op $((0x39000000 | ((i & 0xFFF) << 10) | (10 << 5) | 0))         # STRB W0, [X10, #i]
                done

                emit_op $((0xD2800000 | ((fd & 0xFFFF) << 5) | 0))                       # MOV X0, #fd
                emit_op $((0x91000000 | (0 << 10) | (10 << 5) | 1))                      # ADD X1, X10, #0
                emit_op $((0xD2800000 | ((len & 0xFFFF) << 5) | 2))                      # MOV X2, #len
                emit_op $((0xD2800000 | ((64 & 0xFFFF) << 5) | 8))                       # MOV X8, #64 (SYS_write)
                emit_op 0xD4000001                                                        # SVC #0
                continue
            fi
        fi

        # ─── Nativni NJM Mnemonici ───
        arg1=$(printf '%s' "$stmt" | awk '{print $2}' | tr -d ',')
        arg2=$(printf '%s' "$stmt" | awk '{print $3}' | tr -d ',')
        arg3=$(printf '%s' "$stmt" | awk '{print $4}' | tr -d ',')

        case "$op" in
            "mkm") ;;
            "nve")
                reg=${arg1//r/}
                imm=$arg2
                emit_op $((0xD2800000 | ((imm & 0xFFFF) << 5) | (reg & 0x1F)))
                ;;
            "ssb")
                rd=${arg1//r/}
                rn=${arg2//r/}
                off=$arg3
                emit_op $((0x39000000 | ((off & 0xFFF) << 10) | ((rn & 0x1F) << 5) | (rd & 0x1F)))
                ;;
            "sab")
                rd=${arg1//r/}
                rn=${arg2//r/}
                rm_raw=${arg3:-0}
                if [[ "$rm_raw" == r* ]]; then
                    rm=${rm_raw//r/}
                    emit_op $((0x8B000000 | ((rm & 0x1F) << 16) | ((rn & 0x1F) << 5) | (rd & 0x1F)))
                else
                    imm=$rm_raw
                    emit_op $((0x91000000 | ((imm & 0xFFF) << 10) | ((rn & 0x1F) << 5) | (rd & 0x1F)))
                fi
                ;;
            "uis")
                rd=${arg1//r/}
                rn=${arg2//r/}
                rm=${arg3//r/}
                emit_op $((0xAA000000 | ((rm & 0x1F) << 16) | ((rn & 0x1F) << 5) | (rd & 0x1F)))
                ;;
            "srs")
                rd=${arg1//r/}
                rn=${arg2//r/}
                rm=${arg3//r/}
                emit_op $((0xCA000000 | ((rm & 0x1F) << 16) | ((rn & 0x1F) << 5) | (rd & 0x1F)))
                ;;
            "spe")
                sys_num=$arg1
                emit_op $((0xD2800000 | ((sys_num & 0xFFFF) << 5) | 8))
                emit_op 0xD4000001
                ;;
            "pir")
                emit_op 0x912003FF   # ADD SP, SP, #2048
                emit_op 0xD2800000   # MOV X0, #0
                emit_op $((0xD2800000 | ((93 & 0xFFFF) << 5) | 8))  # MOV X8, #93
                emit_op 0xD4000001   # SVC #0
                ;;
        esac
    done
done < "$INPUT"

# ─── SIGURNOSNI IZLAZ ───
emit_op 0xD2800000
emit_op $((0xD2800000 | ((93 & 0xFFFF) << 5) | 8))
emit_op 0xD4000001

HEX_PAYLOAD=$(cat "$TMP_HEX")
PAYLOAD_BYTES=$(( ${#HEX_PAYLOAD} / 2 ))
TOTAL_SIZE=$(( 120 + PAYLOAD_BYTES ))

rm -f "$OUTPUT"

# ELF64 Header (64 B)
printf '\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00' >> "$OUTPUT"
printf '\x02\x00\xb7\x00\x01\x00\x00\x00' >> "$OUTPUT"
printf '\x78\x00\x40\x00\x00\x00\x00\x00' >> "$OUTPUT"
printf '\x40\x00\x00\x00\x00\x00\x00\x00' >> "$OUTPUT"
printf '\x00\x00\x00\x00\x00\x00\x00\x00' >> "$OUTPUT"
printf '\x00\x00\x00\x00\x40\x00\x38\x00\x01\x00\x00\x00\x00\x00\x00\x00' >> "$OUTPUT"

# Program Header Table (56 B)
printf '\x01\x00\x00\x00\x05\x00\x00\x00' >> "$OUTPUT"
printf '\x00\x00\x00\x00\x00\x00\x00\x00' >> "$OUTPUT"
printf '\x00\x00\x40\x00\x00\x00\x00\x00' >> "$OUTPUT"
printf '\x00\x00\x40\x00\x00\x00\x00\x00' >> "$OUTPUT"

printf '%b' "$(printf '\\x%02x\\x%02x\\x%02x\\x%02x\\x00\\x00\\x00\\x00' \
    $((TOTAL_SIZE & 0xFF)) \
    $(((TOTAL_SIZE >> 8) & 0xFF)) \
    $(((TOTAL_SIZE >> 16) & 0xFF)) \
    $(((TOTAL_SIZE >> 24) & 0xFF)))" >> "$OUTPUT"

printf '%b' "$(printf '\\x%02x\\x%02x\\x%02x\\x%02x\\x00\\x00\\x00\\x00' \
    $((TOTAL_SIZE & 0xFF)) \
    $(((TOTAL_SIZE >> 8) & 0xFF)) \
    $(((TOTAL_SIZE >> 16) & 0xFF)) \
    $(((TOTAL_SIZE >> 24) & 0xFF)))" >> "$OUTPUT"

printf '\x00\x00\x01\x00\x00\x00\x00\x00' >> "$OUTPUT"

for (( i=0; i<${#HEX_PAYLOAD}; i+=2 )); do
    b="${HEX_PAYLOAD:$i:2}"
    printf "\\x$b" >> "$OUTPUT"
done

chmod +x "$OUTPUT"
rm -f "$TMP_HEX"
echo "⚙️  Kompajlirano (UTF-8 Ready): $OUTPUT ($TOTAL_SIZE B)"
