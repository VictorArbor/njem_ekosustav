#!/usr/bin/env python3
import sys

# ═════════════════════════════════════════════════════════════════════
#  NJM-OS :: PIJETAO v3.2 — TABLICA HRVATSKIH LSBU MNEMONIKA U OPKODE
# ═════════════════════════════════════════════════════════════════════
OPCODES = {
    "pis": "0x8a010002", "uis": "0xaa010002", "ris": "0x8a210002", "srs": "0xca010002",
    "lpo": "0xd37aec02", "dpo": "0xd37afc02", "ibo": "0xd3401c02", "pje": "0xaa0103e2",
    "nve": "0xd2800800", "ujb": "0x39400001", "udb": "0x39400402", "usb": "0x38616801",
    "ssb": "0x39000001", "mkm": "0xd2800000", "pkm": "0xd2800000", "ume": "0xeb01001f",
    "gjn": "0xb4000000", "gnn": "0xb5000000", "guo": "0x54000000", "pio": "0x14000000",
    "ppo": "0x94000000", "nno": "0xd503201f", "bar": "0xd5033bbf", "ooi": "0xd63f0000",
    "pps": "0xd65f03c0", "pos": "0xd65f03c0", "spe": "0xd4000001", "vps": "0x4e211c02",
    "vus": "0x4ea11c02", "vrs": "0x4e611c02", "vss": "0x6e211c02", "pir": "0xd65f03c0"
}

print("════════════════════════════════════════════════════════════")
print("  PIJETAO v3.2 :: Tvoji mnemonici → AArch64 opkodi (hex)")
print("════════════════════════════════════════════════════════════")

for line in sys.stdin:
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    # Izdvoj prvu riječ (mnemonik)
    parts = line.replace(",", " ").split()
    if not parts:
        continue
    mnem = parts[0].lower()
    if mnem in OPCODES:
        print(OPCODES[mnem])

