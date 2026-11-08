import os
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Image, HRFlowable, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT, TA_RIGHT
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

def generiraj():
    # Registracija DejaVu fonta koji ima puna hrvatska slova (č, ć, š, ž, đ)
    font_path = "/data/data/com.termux/files/usr/share/fonts/TTF/DejaVuSans.ttf"
    font_bold_path = "/data/data/com.termux/files/usr/share/fonts/TTF/DejaVuSans-Bold.ttf"
    
    use_custom_font = False
    if os.path.exists(font_path) and os.path.exists(font_bold_path):
        pdfmetrics.registerFont(TTFont('DejaVu', font_path))
        pdfmetrics.registerFont(TTFont('DejaVu-Bold', font_bold_path))
        use_custom_font = True

    fn = "DejaVu" if use_custom_font else "Helvetica"
    fn_b = "DejaVu-Bold" if use_custom_font else "Helvetica-Bold"

    pdf_filename = "Zahtjev_Za_Nadzor_A_GrbRH.pdf"
    img_path = "/sdcard/Download/A_GrbRH.jpg"
    
    if not os.path.exists(img_path):
        img_path = "grb.jpg"

    doc = SimpleDocTemplate(
        pdf_filename,
        pagesize=A4,
        rightMargin=35,
        leftMargin=35,
        topMargin=25,
        bottomMargin=25
    )

    story = []
    styles = getSampleStyleSheet()

    # Stilovi s podrškom za Č, Ć, Ž, Š, Đ
    s_center_bold = ParagraphStyle('C_Bold', parent=styles['Normal'], alignment=TA_CENTER, fontSize=10, leading=13, fontName=fn_b, textColor=colors.HexColor("#002B49"))
    s_center_info = ParagraphStyle('C_Info', parent=styles['Normal'], alignment=TA_CENTER, fontSize=8.5, leading=11, fontName=fn)
    s_meta_left = ParagraphStyle('M_Left', parent=styles['Normal'], alignment=TA_LEFT, fontSize=8.5, leading=11, fontName=fn_b)
    s_meta_right = ParagraphStyle('M_Right', parent=styles['Normal'], alignment=TA_RIGHT, fontSize=8.5, leading=11, fontName=fn_b)
    
    s_body = ParagraphStyle('Body', parent=styles['Normal'], alignment=TA_JUSTIFY, fontSize=8.5, leading=11.5, fontName=fn)
    s_heading = ParagraphStyle('Heading', parent=styles['Normal'], alignment=TA_CENTER, fontSize=9, leading=12, fontName=fn_b, textColor=colors.white)

    # 1. SLIKA GRBA IZ DOWNLOAD MAPA (A_GrbRH.jpg)
    if os.path.exists(img_path):
        img = Image(img_path, width=50, height=66)
        img.hAlign = 'CENTER'
        story.append(img)
        story.append(Spacer(1, 3))

    # Zaglavlje DSV RH
    story.append(Paragraph("DRŽAVNO SUDBENO VIJEĆE REPUBLIKE HRVATSKE", s_center_bold))
    story.append(Paragraph("Ulica grada Vukovara 49, 10000 Zagreb; dsv@dsv.gov.hr ili dsv@pravosudje.hr", s_center_info))
    story.append(Paragraph("+385 1 6040 940 / +385 1 6040 934; dsv.pravosudje.hr", s_center_info))
    story.append(Paragraph("Darko Milković, predsjednik DSV RH", s_center_bold))
    story.append(Spacer(1, 4))
    story.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor("#002B49"), spaceAfter=6))

    # Klasa i Datum
    meta_data = [
        [Paragraph("<b>Klasifikacijska oznaka akta:</b> P-G22R/PBU-14-10-2026", s_meta_left),
         Paragraph("<b>Mjesto i datum:</b> U Zagrebu, 14. listopada 2026.", s_meta_right)]
    ]
    t_meta = Table(meta_data, colWidths=[310, 210])
    t_meta.setStyle(TableStyle([('VALIGN', (0,0), (-1,-1), 'TOP')]))
    story.append(t_meta)
    story.append(Spacer(1, 6))

    # Pravni temelji
    temelji_text = """<b>PRAVNI TEMELJI PODNESKA:</b><br/>
    • <b>Uredba (EU) br. 910/2014 (eIDAS Uredba)</b>, čl. 25. st. 2.;<br/>
    • <b>Zakon o provedbi Uredbe (EU) br. 910/2014</b> (NN 62/17); <b>Zakon o elektroničkom dokumentu</b> (NN 84/08, 154/14);<br/>
    • <b>Zakon o zaštiti prava pacijenata</b> (NN 169/04... 52/21); <b>Zakon o zaštiti osoba s duševnim smetnjama</b> (NN 76/14, 98/19);<br/>
    • <b>Kazneni zakon RH</b> (NN 125/11... 36/24), čl. 136., 291. i 315.; <b>ZKP RH</b> (NN 152/08... 36/24), čl. 47.–63.
    """
    t_basis = Table([[Paragraph(temelji_text, s_body)]], colWidths=[520])
    t_basis.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#F8F9FA")),
        ('LINELEFT', (0,0), (-1,-1), 3, colors.HexColor("#002B49")),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(t_basis)
    story.append(Spacer(1, 6))

    # Stranke
    p_left = """<b>PODNOSITELJ:</b> Duško Vučetić, OIB: 29383966489, Braće Buzolić 19, 21450 Hvar (duskovucetic3@gmail.com)<br/><br/>
    <b>PROTIV:</b> Psihijatrijska bolnica Ugljan, OIB: 43171567819 (n/r Mladen Mavar, ravnatelj)"""
    
    p_right = """<b>NASLOVNIK:</b> ŽUPANIJSKI SUD U ZADRU – Ured za zaštitu prava pacijenata (n/r Ivan Marković, Predsjednik)<br/><br/>
    <b>NA ZNANJE:</b> DRŽAVNO SUDBENO VIJEĆE RH (n/r Darko Milković, predsjednik)"""

    t_parties = Table([[Paragraph(p_left, s_body), Paragraph(p_right, s_body)]], colWidths=[255, 265])
    t_parties.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#F4F6F8")),
        ('BOX', (0,0), (-1,-1), 0.5, colors.HexColor("#E1E4E8")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E1E4E8")),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(t_parties)
    story.append(Spacer(1, 6))

    # Predmet
    predmet_html = "<b>PREDMET: ZAHTJEV ZA HITNI INTERVENTNI NADZOR, ODBACIVANJE NIŠTETNIH AKATA I TRENUTNO PUŠTANJE NA SLOBODU TE PRIGOVOR NA NEZAKONITO ZADRŽAVANJE I PROTUPRAVNO LIŠENJE SLOBODE PACIJENTA</b>"
    t_subj = Table([[Paragraph(predmet_html, s_heading)]], colWidths=[520])
    t_subj.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#002B49")),
        ('TOPPADDING', (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(t_subj)
    story.append(Spacer(1, 6))

    # Pobijani akti
    pobijani_html = """<b>Pobijani akti na kojima se protupravno temelji zadržavanje:</b><br/>
    1. <b>Rješenje Općinskog suda u Splitu, pos. br. R1 Ob-1071/19 od 15. travnja 2020.</b> – nevaljan akt bez zakonski verificiranog QES potpisa sutkinje Krasne Batarelo;<br/>
    2. <b>Dopis Ministarstva zdravstva, KLASA: 052-02/23-05/157 od 22. ožujka 2024.</b> – nevaljani akt bez verificiranog QES potpisa bivšeg ministra Vilija Beroša.
    """
    t_pob = Table([[Paragraph(pobijani_html, s_body)]], colWidths=[520])
    t_pob.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#FFF5F5")),
        ('BOX', (0,0), (-1,-1), 0.5, colors.HexColor("#FED7D7")),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(t_pob)
    story.append(Spacer(1, 8))

    # Sadržaj
    t_content = """
    <b>I. PRAVNA NOMOTETIKA I MATERIJALNO-PROCESNI TEMELJI</b><br/>
    Podnositelj temelji ovaj Zahtjev na kumulativnoj primjeni propisa EU i RH. Članak 25. stavak 2. eIDAS Uredbe (EU) br. 910/2014 propisuje da kvalificirani elektronički potpis (QES) ima jednak pravni učinak kao vlastoručni potpis. Akti bez QES-a smatraju se pravno nepostojećima (<i>non-existens</i>).<br/><br/>
    
    <b>II. KAZNENOPRAVNA ODGOVORNOST I STATUS ŽRTVE KAO OVLAŠTENOG TUŽITELJA</b><br/>
    Postupanje odgovornih osoba ostvaruje obilježja kaznenih djela iz čl. 136., 291. i 315. KZ-a. Temeljem Zakona o odgovornosti pravnih osoba za kaznena djela, Psihijatrijska bolnica Ugljan snosi izravnu kaznenopravnu odgovornost. Podnositelj zadržava pravo preuzimanja kaznenog progona u svojstvu oštećenika kao tužitelja (čl. 47.–63. ZKP-a).<br/><br/>

    <b>III. ČINJENIČNO STANJE I APSTRAKTNA NEZAKONITOST POSTUPANJA</b><br/>
    1. Pobijani akti nemaju verificirani QES potpis s vremenskim pečatom.<br/>
    2. Djelomično lišenje poslovne sposobnosti ne može služiti kao bjanko nalog za automatizirano nadomještanje sudskog postupka prisilnog smještaja propisanog ZZPDS-om.<br/><br/>

    <b>IV. ZAHTJEV I PRIJEDLOG PODNOSITELJA</b><br/>
    Podnositelj zahtijeva: 1. Hitno pokretanje postupka nadzora; 2. Utvrđivanje ništetnosti akata; 3. Nalog za trenutno puštanje na slobodu; 4. Dostavu spisa Državnom odvjetništvu; 5. Evidentiranje procesnog statusa žrtve i oštećenika.
    """
    story.append(Paragraph(t_content, s_body))
    story.append(Spacer(1, 15))

    # Potpis
    potpis_html = "<b>Podnositelj:</b><br/>_______________________<br/><b>Duško Vučetić</b><br/><i>(Oštećenik, žrtva i ovlašteni podnositelj)</i>"
    t_potpis = Table([[Paragraph("", s_body), Paragraph(potpis_html, s_body)]], colWidths=[310, 210])
    story.append(t_potpis)

    doc.build(story)
    print("Popravljen PDF i hrvatska slova!")

if __name__ == "__main__":
    generiraj()
