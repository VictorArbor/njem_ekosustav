import os
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
import qrcode
from pypdf import PdfReader, PdfWriter

BROJ_AKTA = "MG/KANGOO-PUNOMOC-2026"
KOD_VERIFIKACIJE = "589F-1771"
URL_VERIFIKACIJE = f"http://localhost:8080/index.html?broj={BROJ_AKTA}&kod={KOD_VERIFIKACIJE}"

IME_DATOTEKE = BROJ_AKTA.replace('/', '_')
IZLAZNI_QR = f"QR_{IME_DATOTEKE}.png"
ULAZNI_PDF = "punomoc.pdf"
IZLAZNI_PDF = f"potpisan_{IME_DATOTEKE}.pdf"

def generiraj_qr_kod():
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=10,
        border=2,
    )
    qr.add_data(URL_VERIFIKACIJE)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    img.save(IZLAZNI_QR, "PNG")
    print(f"[OK] Generiran QR kod: {IZLAZNI_QR}")

def dodaj_pecat_na_pdf():
    if not os.path.exists(ULAZNI_PDF):
        print(f"[GREŠKA] Ulazni PDF '{ULAZNI_PDF}' nije pronađen u mapi ~/njm_2_ekosustav_01!")
        return

    vodeni_zig_pdf = "overlay_temp.pdf"
    c = canvas.Canvas(vodeni_zig_pdf, pagesize=A4)

    x_pos = 420
    y_pos = 50
    sirina_qr = 90
    visina_qr = 90

    c.drawImage(IZLAZNI_QR, x_pos, y_pos, width=sirina_qr, height=visina_qr)

    c.setFont("Helvetica", 7)
    c.drawString(x_pos, y_pos - 10, f"Akt: {BROJ_AKTA}")
    c.drawString(x_pos, y_pos - 18, f"Kontrolni kod: {KOD_VERIFIKACIJE}")
    c.drawString(x_pos, y_pos - 26, "Zajednica RUKE - eIDAS QES")

    c.save()

    reader_orig = PdfReader(ULAZNI_PDF)
    reader_overlay = PdfReader(vodeni_zig_pdf)
    writer = PdfWriter()

    stranica = reader_orig.pages[0]
    stranica.merge_page(reader_overlay.pages[0])
    writer.add_page(stranica)

    for i in range(1, len(reader_orig.pages)):
        writer.add_page(reader_orig.pages[i])

    with open(IZLAZNI_PDF, "wb") as f_out:
        writer.write(f_out)

    if os.path.exists(vodeni_zig_pdf):
        os.remove(vodeni_zig_pdf)
    if os.path.exists(IZLAZNI_QR):
        os.remove(IZLAZNI_QR)

    print(f"[ USPJEH ] Dokument je generiran i spreman: {IZLAZNI_PDF}")

if __name__ == "__main__":
    generiraj_qr_kod()
    dodaj_pecat_na_pdf()
