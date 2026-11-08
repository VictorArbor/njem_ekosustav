#!/bin/bash
# Glosator Engine v13.1 :: AArch64 Nativni Transpiler sa spojenom CTRL topologijom

ULAZ=${1:-"03_leksik/leksik_laloglosator.njm"}
IZLAZ_S="02_engine/laloglosator_otisak.s"
IZLAZ_BIN="02_engine/laloglosator_binarac"

echo "⚡ [GLOSATOR] Prevođenje Lalator leksika u AArch64 silikonske uzorke..."

cat << 'ASMELEM' > $IZLAZ_S
.global _start
.text

_start:
    // Inicijalizacija i očitavanje početnog stanja AArch64 brojača (CNTVCT_EL0)
    mrs x19, cntvct_el0

ASMELEM

while read -r linija || [ -n "$linija" ]; do
    [[ "$linija" =~ ^#.* ]] && continue
    [[ -z "$linija" ]] && continue

    # mkm r10 -> Alokacija stoga
    if [[ "$linija" =~ ^mkm\ r10 ]]; then
        echo "    sub sp, sp, #512" >> $IZLAZ_S
        echo "    add x10, sp, #0" >> $IZLAZ_S

    # nve rd, imm -> Sigurno nabijanje 64-bitne vrijednosti u registar (LDR umjesto MOV)
    elif [[ "$linija" =~ ^nve\ r([0-9]+),\ (0x[0-9a-fA-F]+|[0-9]+) ]]; then
        reg="${BASH_REMATCH[1]}"; val="${BASH_REMATCH[2]}"
        echo "    ldr x$reg, =$val" >> $IZLAZ_S

    # enc_ctrl r0, r1, r2 -> Stvaranje CTRL bloka (m.p || f.u) u gornjim bitovima (63..49)
    elif [[ "$linija" =~ ^enc_ctrl\ r([0-9]+),\ r([0-9]+),\ r([0-9]+) ]]; then
        rd="${BASH_REMATCH[1]}"; r_fu="${BASH_REMATCH[2]}"; r_mp="${BASH_REMATCH[3]}"
        echo "    // --- ENKODIRANJE (Spajanje u CTRL) ---" >> $IZLAZ_S
        echo "    lsl x$rd, x$r_mp, #11         // Pomak m.p na poziciju" >> $IZLAZ_S
        echo "    orr x$rd, x$rd, x$r_fu        // CTRL = m.p || f.u" >> $IZLAZ_S
        echo "    lsl x$rd, x$rd, #49           // Topološko poravnanje na bit 63..49" >> $IZLAZ_S

    # dec_ctrl r3, r4, r0 -> 1-TAKTNI TOPOLOŠKI DOHVAT CIJELOG CTRL BLOKA (UBFX)
    elif [[ "$linija" =~ ^dec_ctrl\ r([0-9]+),\ r([0-9]+),\ r([0-9]+) ]]; then
        r_mp="${BASH_REMATCH[1]}"; r_fu="${BASH_REMATCH[2]}"; r_mid="${BASH_REMATCH[3]}"
        echo "    // --- DEKODIRANJE (1-Taktni UBFX CTRL Dohvat) ---" >> $IZLAZ_S
        echo "    ubfx x5, x$r_mid, #49, #15    // 1 TAKT: Učitavanje cijelog CTRL bloka" >> $IZLAZ_S
        echo "    lsr x$r_mp, x5, #11           // LSR razdvaja m.p (4 bita)" >> $IZLAZ_S
        echo "    and x$r_fu, x5, #0x7FF        // AND maskira f.u (11 bita)" >> $IZLAZ_S

    # pir -> Završetak i izračun razlike ciklusa
    elif [[ "$linija" =~ ^pir ]]; then
        echo "    // Očitavanje završnog stanja AArch64 brojača" >> $IZLAZ_S
        echo "    mrs x20, cntvct_el0" >> $IZLAZ_S
        echo "    sub x0, x20, x19              // Izračunata razlika predaje se u status code" >> $IZLAZ_S
        echo "    mov x8, #93                   // SYS_exit" >> $IZLAZ_S
        echo "    svc #0" >> $IZLAZ_S
    fi
done < "$ULAZ"

# Nativno asambliranje i povezivanje u samostalni ELF64 binarac
as $IZLAZ_S -o 02_engine/laloglosator_otisak.o
if [ $? -ne 0 ]; then
    echo "❌ Greška pri asambliranju otiska!"
    exit 1
fi

ld 02_engine/laloglosator_otisak.o -o $IZLAZ_BIN
if [ $? -ne 0 ]; then
    echo "❌ Greška pri povezivanju binarca!"
    exit 1
fi

echo "✅ [USPJEH] AArch64 Laloglosator binarac je izgrađen: $IZLAZ_BIN"
