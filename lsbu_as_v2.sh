#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ULAZ=${1:-""}
IZLAZ=${2:-"a.out"}

if [ -z "$ULAZ" ]; then
    echo "Uporaba: ./lsbu_as_v2.sh <ulaz.njm> <izlazni_binarac>"
    exit 1
fi

S_DATOTEKA="${ULAZ%.*}.s"
O_DATOTEKA="${ULAZ%.*}.o"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║  NJM-OS :: LSBU-S FULL KERNEL TRANSPILER (AUTARHIJA v2.1)     ║"
echo "╚═══════════════════════════════════════════════════════════════╝"

cat << 'ASM_HEAD' > "$S_DATOTEKA"
.global _start
.text
_start:
ASM_HEAD

sed 's/;/\n/g' "$ULAZ" | while IFS= read -r line || [ -n "$line" ]; do
    clean_line=$(echo "$line" | sed 's/#.*//' | xargs)
    [ -z "$clean_line" ] && continue

    if [[ "$clean_line" == *: ]]; then
        label_name=$(echo "$clean_line" | tr -d ' ')
        echo "${label_name}" >> "$S_DATOTEKA"
        continue
    fi

    mnem=$(echo "$clean_line" | awk '{print $1}')
    args=$(echo "$clean_line" | cut -d' ' -f2- | tr -d ' ')

    IFS=',' read -r -a arg_arr <<< "$args"

    case "$mnem" in
        # ARITMETIKA I LOGIKA
        "sab")
            rd=${arg_arr[0]/r/x}; rn=${arg_arr[1]/r/x}; rm=${arg_arr[2]}
            if [[ "$rm" == r* ]]; then echo "    add $rd, $rn, ${rm/r/x}" >> "$S_DATOTEKA"; else echo "    add $rd, $rn, #$rm" >> "$S_DATOTEKA"; fi
            ;;
        "odu")
            rd=${arg_arr[0]/r/x}; rn=${arg_arr[1]/r/x}; rm=${arg_arr[2]}
            if [[ "$rm" == r* ]]; then echo "    sub $rd, $rn, ${rm/r/x}" >> "$S_DATOTEKA"; else echo "    sub $rd, $rn, #$rm" >> "$S_DATOTEKA"; fi
            ;;
        "mno") echo "    mul ${arg_arr[0]/r/x}, ${arg_arr[1]/r/x}, ${arg_arr[2]/r/x}" >> "$S_DATOTEKA" ;;
        "pis") echo "    and ${arg_arr[0]/r/x}, ${arg_arr[1]/r/x}, ${arg_arr[2]/r/x}" >> "$S_DATOTEKA" ;;
        "uis") echo "    orr ${arg_arr[0]/r/x}, ${arg_arr[1]/r/x}, ${arg_arr[2]/r/x}" >> "$S_DATOTEKA" ;;
        "ris") echo "    bic ${arg_arr[0]/r/x}, ${arg_arr[1]/r/x}, ${arg_arr[2]/r/x}" >> "$S_DATOTEKA" ;;
        "srs") echo "    eor ${arg_arr[0]/r/x}, ${arg_arr[1]/r/x}, ${arg_arr[2]/r/x}" >> "$S_DATOTEKA" ;;
        "lpo") echo "    lsl ${arg_arr[0]/r/x}, ${arg_arr[1]/r/x}, #${arg_arr[2]}" >> "$S_DATOTEKA" ;;
        "dpo") echo "    lsr ${arg_arr[0]/r/x}, ${arg_arr[1]/r/x}, #${arg_arr[2]}" >> "$S_DATOTEKA" ;;
        "pje") echo "    mov ${arg_arr[0]/r/x}, ${arg_arr[1]/r/x}" >> "$S_DATOTEKA" ;;
        "nve") echo "    movz ${arg_arr[0]/r/x}, #${arg_arr[1]}" >> "$S_DATOTEKA" ;;

        # MEMORIJA
        "ujb"|"udb") echo "    ldrb ${arg_arr[0]/r/w}, [${arg_arr[1]/r/x}, #${arg_arr[2]}]" >> "$S_DATOTEKA" ;;
        "ssb") echo "    strb ${arg_arr[0]/r/w}, [${arg_arr[1]/r/x}, #${arg_arr[2]}]" >> "$S_DATOTEKA" ;;
        "mkm") echo "    sub sp, sp, #512"; echo "    mov ${arg_arr[0]/r/x}, sp" >> "$S_DATOTEKA" ;;

        # TOK I LABELE
        "ume") echo "    cmp ${arg_arr[0]/r/x}, ${arg_arr[1]/r/x}" >> "$S_DATOTEKA" ;;
        "gjn") target=${arg_arr[1]}; if [[ "$target" == r* ]]; then target=${target/r/x}; fi; echo "    cbz ${arg_arr[0]/r/x}, $target" >> "$S_DATOTEKA" ;;
        "gnn") target=${arg_arr[1]}; if [[ "$target" == r* ]]; then target=${target/r/x}; fi; echo "    cbnz ${arg_arr[0]/r/x}, $target" >> "$S_DATOTEKA" ;;
        "pio") echo "    b ${arg_arr[0]}" >> "$S_DATOTEKA" ;;
        "ppo") echo "    bl ${arg_arr[0]}" >> "$S_DATOTEKA" ;;
        "pir") echo "    add sp, sp, #512"; echo "    movz x0, #0"; echo "    movz x8, #93"; echo "    svc #0" >> "$S_DATOTEKA" ;;

        # SIMD / VEKTORI (128-bit)
        "vps") echo "    and ${arg_arr[0]/q/v}.16b, ${arg_arr[1]/q/v}.16b, ${arg_arr[2]/q/v}.16b" >> "$S_DATOTEKA" ;;
        "vus") echo "    orr ${arg_arr[0]/q/v}.16b, ${arg_arr[1]/q/v}.16b, ${arg_arr[2]/q/v}.16b" >> "$S_DATOTEKA" ;;
        "vrs") echo "    bic ${arg_arr[0]/q/v}.16b, ${arg_arr[1]/q/v}.16b, ${arg_arr[2]/q/v}.16b" >> "$S_DATOTEKA" ;;
        "vss") echo "    eor ${arg_arr[0]/q/v}.16b, ${arg_arr[1]/q/v}.16b, ${arg_arr[2]/q/v}.16b" >> "$S_DATOTEKA" ;;

        # DATOTEČNI SUSTAV & SISTEMSKI POZIVI
        "spe")
            # Direktni sistemski poziv (spe broj)
            echo "    movz x8, #${arg_arr[0]}" >> "$S_DATOTEKA"
            echo "    svc #0" >> "$S_DATOTEKA"
            ;;
        "opn")
            r_fd=${arg_arr[0]/r/x}; r_path=${arg_arr[1]/r/x}; flags=${arg_arr[2]}; mode=${arg_arr[3]}
            echo "    movn x0, #99" >> "$S_DATOTEKA"
            echo "    mov x1, $r_path" >> "$S_DATOTEKA"
            if [[ "$flags" == r* ]]; then echo "    mov x2, ${flags/r/x}" >> "$S_DATOTEKA"; else echo "    movz x2, #$flags" >> "$S_DATOTEKA"; fi
            if [[ "$mode" == r* ]]; then echo "    mov x3, ${mode/r/x}" >> "$S_DATOTEKA"; else echo "    movz x3, #$mode" >> "$S_DATOTEKA"; fi
            echo "    movz x8, #56" >> "$S_DATOTEKA"
            echo "    svc #0" >> "$S_DATOTEKA"
            echo "    mov $r_fd, x0" >> "$S_DATOTEKA"
            ;;
        "wrt")
            r_fd=${arg_arr[0]/r/x}; r_buf=${arg_arr[1]/r/x}; cnt=${arg_arr[2]}
            echo "    mov x19, $r_fd" >> "$S_DATOTEKA"
            echo "    mov x1, $r_buf" >> "$S_DATOTEKA"
            if [[ "$cnt" == r* ]]; then echo "    mov x2, ${cnt/r/x}" >> "$S_DATOTEKA"; else echo "    movz x2, #$cnt" >> "$S_DATOTEKA"; fi
            echo "    mov x0, x19" >> "$S_DATOTEKA"
            echo "    movz x8, #64" >> "$S_DATOTEKA"
            echo "    svc #0" >> "$S_DATOTEKA"
            echo "    mov $r_fd, x19" >> "$S_DATOTEKA"
            ;;
        "cls")
            echo "    mov x0, ${arg_arr[0]/r/x}" >> "$S_DATOTEKA"
            echo "    movz x8, #57" >> "$S_DATOTEKA"
            echo "    svc #0" >> "$S_DATOTEKA"
            ;;
    esac
done < "$ULAZ"

as "$S_DATOTEKA" -o "$O_DATOTEKA"
ld "$O_DATOTEKA" -o "$IZLAZ"
chmod +x "$IZLAZ"
rm -f "$S_DATOTEKA" "$O_DATOTEKA"

echo "⚙️  Kompajliran AArch64 binarac: $IZLAZ"
