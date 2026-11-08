from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas

c = canvas.Canvas("punomoc.pdf", pagesize=A4)
width, height = A4

# Zaglavlje izdavatelja
c.setFont("Helvetica-Bold", 12)
c.drawString(50, height - 60, "ZAJEDNICA RUKE")
c.setFont("Helvetica", 9)
c.drawString(50, height - 73, "Zagreb, Delenšice 11 | OIB: 64517735227")
c.drawString(50, height - 85, "E-pošta: zajednicaruke@gmail.com | Tel: +385 97 687 7787")

c.setLineWidth(0.8)
c.line(50, height - 95, width - 50, height - 95)

# Naslov dokumenta
c.setFont("Helvetica-Bold", 15)
c.drawCentredString(width / 2, height - 135, "SPECIJALNA PUNOMOĆ")
c.setFont("Helvetica", 9)
c.drawCentredString(width / 2, height - 150, "Klasa / Akt: MG/KANGOO-PUNOMOC-2026 | Verifikacijski kod: 589F-1771")

# Pravni sadržaj punomoći
text = c.beginText(50, height - 185)
text.setFont("Helvetica", 10)
text.setLeading(14)

redci = [
    "Udruga ZAJEDNICA RUKE, Zagreb, Delenšice 11, OIB: 64517735227, zastupana po",
    "ovlaštenom zastupniku Michaelu Golubičiću, ovime daje i izdaje sljedeću:",
    "",
    "                                          P U N O M O Ć",
    "",
    "Kojom se ovlašćuje MICHAEL GOLUBIČIĆ, OIB: 05315840697, iz Županje,",
    "da u ime i za račun udruge ZAJEDNICA RUKE može poduzimati sve pravne i administrativne",
    "radnje vezane uz tehnički pregled, ugovaranje osiguranja, postupak registracije i preuzimanja",
    "prometnih dokumenata te registarskih pločica kod nadležnih stanica za tehnički pregled (STP)",
    "i Ministarstva unutarnjih poslova RH za teretno vozilo N1 kategorije:",
    "",
    "  • Marka i model: RENAULT KANGOO EXPRESS 1.5 dCi (N1 furgon)",
    "  • Broj šasije (VIN): VE1FC07AF33105542",
    "  • Snaga motora / Oblik karoserije: 48 kW / Furgon (2 sjedala)",
    "  • Boja vozila: Bijela",
    "",
    "Ova punomoć uključuje ovlaštenje za potpisivanje svih zahtjeva, podnošenje dokumentacije,",
    "preuzimanje prometne dozvole i registarskih pločica pred Stanicom za tehnički pregled i MUP-om.",
    "",
    "U Županji / Zagrebu, 2026. godine.",
    "",
    "Za ZAJEDNICU RUKE:",
    "Michael Golubičić, ovlašteni zastupnik"
]

for r in redci:
    text.textLine(r)

c.drawText(text)
c.save()
print("[OK] Izrađen izvorni PDF: punomoc.pdf")
