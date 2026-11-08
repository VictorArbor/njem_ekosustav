#!/usr/bin/env python3
import sys
import re

# ═════════════════════════════════════════════════════════════════════
#  NJM-OS :: PIJETAO v4.0 — OPTIMIZIRANI LSBU FULL BITWISE ASSEMBLER
# ═════════════════════════════════════════════════════════════════════

REG_MAP = {f"r{i}": i for i in range(31)}
REG_MAP.update({f"x{i}": i for i in range(31)})
REG_MAP.update({"sp": 31, "xzr": 31})

VREG_MAP = {f"q{i}": i for i in range(32)}
VREG_MAP.update({f"v{i}": i for i in range(32)})

def parse_reg(token):
    tok = token.lower().strip(",[]")
    if tok in REG_MAP:
        return REG_MAP[tok]
    if tok in VREG_MAP:
        return VREG_MAP[tok]
        
    # Akvizicija numeričkih vrijednosti za nve / pomake
    if tok.startswith("0x"):
        return int(tok, 16)
    elif tok.isdigit():
        return int(tok, 10)
    return 0

def encode_lsbu_line(line):
    # Uklanjanje komentara i čišćenje tokena
    line = line.split('#')[0].strip()
    if not line:
        return None, None

    tokens = re.findall(r'[a-zA-Z0-9_x]+', line)
    if not tokens:
        return None, None

    mnem = tokens[0].lower()
    args = tokens[1:]

    op_code = 0xD503201F # Default NOP

    # 1. SKUPOVNE SKALARNE ABRACADABRA STRUKTURE (3 Register 64-bit Format)
    if mnem in ["pis", "uis", "ris", "srs"]:
        rd = parse_reg(args[0]) if len(args) > 0 else 0
        rn = parse_reg(args[1]) if len(args) > 1 else 0
        rm = parse_reg(args[2]) if len(args) > 2 else 0

        base_map = {
            "pis": 0x8A000000, # AND Xd, Xn, Xm
            "uis": 0xAA000000, # ORR Xd, Xn, Xm
            "ris": 0x8A200000, # BIC Xd, Xn, Xm
            "srs": 0xCA000000  # EOR Xd, Xn, Xm
        }
        op_code = base_map[mnem] | (rm << 16) | (rn << 5) | rd

    # 2. NEON 128-BITNI VEKTORSKI SKULL (128-bit SIMD Format)
    elif mnem in ["vps", "vus", "vrs", "vss"]:
        vd = parse_reg(args[0]) if len(args) > 0 else 0
        vn = parse_reg(args[1]) if len(args) > 1 else 0
        vm = parse_reg(args[2]) if len(args) > 2 else 0

        base_map = {
            "vps": 0x4E201C00, # VAND Vd.16B, Vn.16B, Vm.16B
            "vus": 0x4EA01C00, # VORR Vd.16B, Vn.16B, Vm.16B
            "vrs": 0x4E601C00, # VBIC Vd.16B, Vn.16B, Vm.16B
            "vss": 0x6E201C00  # VEOR Vd.16B, Vn.16B, Vm.16B
        }
        op_code = base_map[mnem] | (vm << 16) | (vn << 5) | vd

    # 3. NEPOSREDNA VRIJEDNOST (nve r0, #imm)
    elif mnem == "nve":
        rd = parse_reg(args[0]) if len(args) > 0 else 0
        imm = parse_reg(args[1]) if len(args) > 1 else 0
        op_code = 0xD2800000 | ((imm & 0xFFFF) << 5) | rd

    # 4. MEMORIJSKI PRISTUPI (ujb, udb, ssb)
    elif mnem in ["ujb", "udb", "ssb"]:
        rt = parse_reg(args[0]) if len(args) > 0 else 0
        rn = parse_reg(args[1]) if len(args) > 1 else 0
        imm = parse_reg(args[2]) if len(args) > 2 else (1 if mnem == "udb" else 0)

        if mnem == "ssb":
            op_code = 0x39000000 | ((imm & 0xFFF) << 10) | (rn << 5) | rt # STRB
        else:
            op_code = 0x39400000 | ((imm & 0xFFF) << 10) | (rn << 5) | rt # LDRB

    # 5. POVRATAK I SYSTEM CONTROL
    elif mnem in ["pir", "pps", "pos"]:
        op_code = 0xD65F03C0 # RET
    elif mnem == "spe":
        imm = parse_reg(args[0]) if len(args) > 0 else 1
        op_code = 0xD4000001 | ((imm & 0xFFFF) << 5) # SVC #imm
    elif mnem == "nno":
        op_code = 0xD503201F # NOP
    elif mnem == "bar":
        op_code = 0xD5033BBF # DMB ISH

    return f"0x{op_code:08x}", op_code

def main():
    print("════════════════════════════════════════════════════════════")
    print("  PIJETAO v4.0 :: LSBU Dynamic Bitwise Assembler (Optimized)")
    print("════════════════════════════════════════════════════════════")

    hex_lines = []
    bin_bytes = bytearray()

    for raw_line in sys.stdin:
        hex_str, op_int = encode_lsbu_line(raw_line)
        if hex_str:
            print(f" {hex_str}  │  {raw_line.strip()}")
            hex_lines.append(hex_str)
            bin_bytes.extend(op_int.to_bytes(4, byteorder='little'))

    # Opcionalni upis u binarnu datoteku ako je proslijeđen parametar
    if len(sys.argv) > 1:
        with open(sys_argv[1], "wb") as f:
            f.write(bin_bytes)

if __name__ == "__main__":
    main()
