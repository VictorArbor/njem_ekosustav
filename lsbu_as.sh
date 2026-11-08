#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ULAZ=${1:-""}
IZLAZ=${2:-"a.out"}

if [ -z "$ULAZ" ]; then
    echo "Uporaba: ./lsbu_as.sh <ulaz.njm> <izlazni_binarac>"
    exit 1
fi

S_DATOTEKA="${ULAZ%.*}.s"
O_DATOTEKA="${ULAZ%.*}.o"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║  NJM-OS :: FULL LSBU-S -> AArch64 ASEMBLER PREVODITELJ (v1.0) ║"
echo "╚═══════════════════════════════════════════════════════════════╝"

cat << 'ASM_HEAD' > "$S_DATOTEKA"
.global _start
.text
_start:
ASM_HEAD

while IFS= read -r line || [ -n "$line" ]; do
    clean_line=$(echo "$line" | sed 's/#.*//' | xargs)
    [ -z "$clean_line" ] && continue

    mnem=$(echo "$clean_line" | awk '{print $1}')
    args=$(echo "$clean_line" | cut -d' ' -f2- | tr -d ' ')

    IFS=',' read -r -a arg_arr <<< "$args"

    case "$mnem" in
        # ═════════════════════════════════════════════════════════════════
        # SLOJ ALG — Skupovna algebra
        # ═════════════════════════════════════════════════════════════════
        "pis")
            echo "    and ${arg_arr[0]/r/x}, ${arg_arr[1]/r/x}, ${arg_arr[2]/r/x}" >> "$S_DATOTEKA"
            ;;
        "uis")
            echo "    orr ${arg_arr[0]/r/x}, ${arg_arr[1]/r/x}, ${arg_arr[2]/r/x}" >> "$S_DATOTEKA"
            ;;
        "ris")
            echo "    bic ${arg_arr[0]/r/x}, ${arg_arr[1]/r/x}, ${arg_arr[2]/r/x}" >> "$S_DATOTEKA"
            ;;
        "srs")
            echo "    eor ${arg_arr[0]/r/x}, ${arg_arr[1]/r/x}, ${arg_arr[2]/r/x}" >> "$S_DATOTEKA"
            ;;

        # ═════════════════════════════════════════════════════════════════
        # SLOJ BIT — Bitne operacije
        # ═════════════════════════════════════════════════════════════════
        "lpo")
            echo "    lsl ${arg_arr[0]/r/x}, ${arg_arr[1]/r/x}, #${arg_arr[2]}" >> "$S_DATOTEKA"
            ;;
        "dpo")
            echo "    lsr ${arg_arr[0]/r/x}, ${arg_arr[1]/r/x}, #${arg_arr[2]}" >> "$S_DATOTEKA"
            ;;
        "ibo")
            echo "    ubfx ${arg_arr[0]/r/x}, ${arg_arr[1]/r/x}, #${arg_arr[2]}, #${arg_arr[3]}" >> "$S_DATOTEKA"
            ;;

        # ═════════════════════════════════════════════════════════════════
        # SLOJ MOV / ARITMETIKA — Prijenos i dodjela
        # ═════════════════════════════════════════════════════════════════
        "pje")
            echo "    mov ${arg_arr[0]/r/x}, ${arg_arr[1]/r/x}" >> "$S_DATOTEKA"
            ;;
        "nve")
            echo "    movz ${arg_arr[0]/r/x}, #${arg_arr[1]}" >> "$S_DATOTEKA"
            ;;
        "sab")
            echo "    add ${arg_arr[0]/r/x}, ${arg_arr[1]/r/x}, ${arg_arr[2]/r/x}" >> "$S_DATOTEKA"
            ;;
        "mno")
            echo "    mul ${arg_arr[0]/r/x}, ${arg_arr[1]/r/x}, ${arg_arr[2]/r/x}" >> "$S_DATOTEKA"
            ;;

        # ═════════════════════════════════════════════════════════════════
        # SLOJ MEM — Rad s memorijom i stekom
        # ═════════════════════════════════════════════════════════════════
        "ujb"|"udb")
            echo "    ldrb ${arg_arr[0]/r/w}, [${arg_arr[1]/r/x}, #${arg_arr[2]}]" >> "$S_DATOTEKA"
            ;;
        "usb")
            echo "    ldrb ${arg_arr[0]/r/w}, [${arg_arr[1]/r/x}, ${arg_arr[2]/r/x}]" >> "$S_DATOTEKA"
            ;;
        "ssb")
            echo "    strb ${arg_arr[0]/r/w}, [${arg_arr[1]/r/x}, #${arg_arr[2]}]" >> "$S_DATOTEKA"
            ;;
        "mkm")
            echo "    sub sp, sp, #512" >> "$S_DATOTEKA"
            echo "    mov ${arg_arr[0]/r/x}, sp" >> "$S_DATOTEKA"
            ;;

        # ═════════════════════════════════════════════════════════════════
        # SLOJ FLOW — Upravljanje tokom
        # ═════════════════════════════════════════════════════════════════
        "ume")
            echo "    cmp ${arg_arr[0]/r/x}, ${arg_arr[1]/r/x}" >> "$S_DATOTEKA"
            ;;
        "gjn")
            echo "    cbz ${arg_arr[0]/r/x}, ${arg_arr[1]}" >> "$S_DATOTEKA"
            ;;
        "gnn")
            echo "    cbnz ${arg_arr[0]/r/x}, ${arg_arr[1]}" >> "$S_DATOTEKA"
            ;;
        "pio")
            echo "    b ${arg_arr[0]}" >> "$S_DATOTEKA"
            ;;
        "ppo")
            echo "    bl ${arg_arr[0]}" >> "$S_DATOTEKA"
            ;;
        "ooi")
            echo "    blr ${arg_arr[0]/r/x}" >> "$S_DATOTEKA"
            ;;
        "pir")
            echo "    add sp, sp, #512" >> "$S_DATOTEKA"
            echo "    movz x0, #0" >> "$S_DATOTEKA"
            echo "    movz x8, #93" >> "$S_DATOTEKA"
            echo "    svc #0" >> "$S_DATOTEKA"
            ;;

        # ═════════════════════════════════════════════════════════════════
        # SLOJ SIMD — Vektorske operacije (128-bit)
        # ═════════════════════════════════════════════════════════════════
        "vps")
            echo "    and ${arg_arr[0]/q/v}.16b, ${arg_arr[1]/q/v}.16b, ${arg_arr[2]/q/v}.16b" >> "$S_DATOTEKA"
            ;;
        "vus")
            echo "    orr ${arg_arr[0]/q/v}.16b, ${arg_arr[1]/q/v}.16b, ${arg_arr[2]/q/v}.16b" >> "$S_DATOTEKA"
            ;;
        "vrs")
            echo "    bic ${arg_arr[0]/q/v}.16b, ${arg_arr[1]/q/v}.16b, ${arg_arr[2]/q/v}.16b" >> "$S_DATOTEKA"
            ;;
        "vss")
            echo "    eor ${arg_arr[0]/q/v}.16b, ${arg_arr[1]/q/v}.16b, ${arg_arr[2]/q/v}.16b" >> "$S_DATOTEKA"
            ;;

        # ═════════════════════════════════════════════════════════════════
        # SLOJ FS — Datotečni sustav (sa X19 Callee-Saved zaštitom)
        # ═════════════════════════════════════════════════════════════════
        "opn")
            r_fd=${arg_arr[0]/r/x}
            r_path=${arg_arr[1]/r/x}
            flags=${arg_arr[2]}
            mode=${arg_arr[3]}
            echo "    movn x0, #99" >> "$S_DATOTEKA"
            echo "    mov x1, $r_path" >> "$S_DATOTEKA"
            if [[ "$flags" == r* ]]; then echo "    mov x2, ${flags/r/x}" >> "$S_DATOTEKA"; else echo "    movz x2, #$flags" >> "$S_DATOTEKA"; fi
            if [[ "$mode" == r* ]]; then echo "    mov x3, ${mode/r/x}" >> "$S_DATOTEKA"; else echo "    movz x3, #$mode" >> "$S_DATOTEKA"; fi
            echo "    movz x8, #56" >> "$S_DATOTEKA"
            echo "    svc #0" >> "$S_DATOTEKA"
            echo "    mov $r_fd, x0" >> "$S_DATOTEKA"
            ;;
        "wrt")
            r_fd=${arg_arr[0]/r/x}
            r_buf=${arg_arr[1]/r/x}
            cnt=${arg_arr[2]}
            echo "    mov x19, $r_fd" >> "$S_DATOTEKA"
            echo "    mov x1, $r_buf" >> "$S_DATOTEKA"
            if [[ "$cnt" == r* ]]; then echo "    mov x2, ${cnt/r/x}" >> "$S_DATOTEKA"; else echo "    movz x2, #$cnt" >> "$S_DATOTEKA"; fi
            echo "    mov x0, x19" >> "$S_DATOTEKA"
            echo "    movz x8, #64" >> "$S_DATOTEKA"
            echo "    svc #0" >> "$S_DATOTEKA"
            echo "    mov $r_fd, x19" >> "$S_DATOTEKA"
            ;;
        "rdl")
            r_fd=${arg_arr[0]/r/x}
            r_buf=${arg_arr[1]/r/x}
            cnt=${arg_arr[2]}
            echo "    mov x19, $r_fd" >> "$S_DATOTEKA"
            echo "    mov x1, $r_buf" >> "$S_DATOTEKA"
            if [[ "$cnt" == r* ]]; then echo "    mov x2, ${cnt/r/x}" >> "$S_DATOTEKA"; else echo "    movz x2, #$cnt" >> "$S_DATOTEKA"; fi
            echo "    mov x0, x19" >> "$S_DATOTEKA"
            echo "    movz x8, #63" >> "$S_DATOTEKA"
            echo "    svc #0" >> "$S_DATOTEKA"
            echo "    mov $r_fd, x19" >> "$S_DATOTEKA"
            ;;
        "cls")
            echo "    mov x0, ${arg_arr[0]/r/x}" >> "$S_DATOTEKA"
            echo "    movz x8, #57" >> "$S_DATOTEKA"
            echo "    svc #0" >> "$S_DATOTEKA"
            ;;

        # ═════════════════════════════════════════════════════════════════
        # SLOJ SYS — Sistemske instrukcije
        # ═════════════════════════════════════════════════════════════════
        "nno")
            echo "    nop" >> "$S_DATOTEKA"
            ;;
        "bar")
            echo "    dmb ish" >> "$S_DATOTEKA"
            ;;
    esac
done < "$ULAZ"

as "$S_DATOTEKA" -o "$O_DATOTEKA"
ld "$O_DATOTEKA" -o "$IZLAZ"
chmod +x "$IZLAZ"
rm -f "$S_DATOTEKA" "$O_DATOTEKA"

echo "⚙️  Kompajliran puni nativni binarac: $IZLAZ"
