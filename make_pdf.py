import base64
from weasyprint import HTML

with open("grb.jpg", "rb") as f:
    jpg_b64 = base64.b64encode(f.read()).decode("utf-8")

img_uri = f"data:image/jpeg;base64,{jpg_b64}"

html = f"""<!DOCTYPE html>
<html lang="hr">
<head>
    <meta charset="UTF-8">
    <style>
        @page {{ size: A4; margin: 10mm 15mm 12mm 15mm; }}
        body {{ font-family: 'Times New Roman', serif; font-size: 9.5pt; line-height: 1.35; color: #111; }}
        .header-container {{ text-align: center; border-bottom: 2px solid #002B49; padding-bottom: 6px; margin-bottom: 10px; }}
        .coat-of-arms {{ height: 75px; width: auto; display: block; margin: 0 auto 4px auto; }}
        .header-title {{ font-size: 11pt; font-weight: bold; color: #002B49; text-transform: uppercase; margin: 0 0 2px 0; }}
        .header-info {{ font-size: 8.5pt; color: #222; margin: 1px 0; font-family: Arial, sans-serif; }}
        .header-subinfo {{ font-size: 9pt; font-weight: bold; color: #002B49; margin-top: 3px; font-family: Arial, sans-serif; }}
        .meta-table {{ width: 100%; border-collapse: collapse; margin-bottom: 8px; font-size: 8.5pt; }}
        .basis-box {{ background-color: #f8f9fa; border-left: 3px solid #002B49; padding: 6px 10px; margin-bottom: 10px; font-size: 8.5pt; }}
        .parties-grid {{ width: 100%; border-collapse: collapse; margin-bottom: 10px; font-size: 8.5pt; }}
        .parties-grid td {{ width: 50%; vertical-align: top; padding: 4px 6px; background-color: #f4f6f8; border: 1px solid #e1e4e8; }}
        .party-header {{ font-weight: bold; color: #002B49; border-bottom: 1px solid #ccc; font-size: 8pt; text-transform: uppercase; }}
        .subject-box {{ background-color: #002B49; color: #fff; padding: 7px 10px; text-align: center; font-weight: bold; font-size: 9.5pt; margin-bottom: 10px; }}
        .contested-acts {{ background-color: #fff5f5; border: 1px solid #fed7d7; padding: 6px 10px; margin-bottom: 10px; font-size: 8.5pt; }}
        h2 {{ font-size: 10pt; color: #002B49; border-bottom: 1px solid #002B49; margin-top: 10px; margin-bottom: 5px; text-transform: uppercase; page-break-after: avoid; }}
        h3 {{ font-size: 9pt; color: #1a365d; margin-top: 6px; margin-bottom: 3px; page-break-after: avoid; }}
        p {{ margin: 0 0 5px 0; text-align: justify; }}
        ul, ol {{ margin: 0 0 5px 0; padding-left: 18px; }}
        li {{ margin-bottom: 2px; text-align: justify; }}
        .signature-block {{ float: right; width: 220px; text-align: center; margin-top: 15px; page-break-inside: avoid; }}
        .signature-line {{ border-bottom: 1px dashed #333; margin: 30px 0 4px 0; }}
    </style>
</head>
<body>
    <div class="header-container">
        <img src="{img_uri}" class="coat-of-arms" alt="Grb RH">
        <div class="header-title">DRŽAVNO SUDBENO VIJEĆE REPUBLIKE HRVATSKE</div>
        <div class="header-info">Ulica grada Vukovara 49, 10000 Zagreb; dsv@dsv.gov.hr ili dsv@pravosudje.hr</div>
        <div class="header-info">+385 1 6040 940 / +385 1 6040 934; dsv.pravosudje.hr</div>
        <div class="header-subinfo">Darko Milković, predsjednik DSV RH</div>
    </div>

    <table class="meta-table">
        <tr>
            <td style="width: 60%;"><strong>Klasifikacijska oznaka akta:</strong> P-G22R/PBU-14-10-2026</td>
            <td style="width: 40%; text-align: right;"><strong>Mjesto i datum:</strong> U Zagrebu, 14. listopada 2026. godine</td>
        </tr>
    </table>

    <div class="basis-box">
        <strong>PRAVNI TEMELJI PODNESKA:</strong>
        <ul>
            <li><strong>Uredba (EU) br. 910/2014 (eIDAS Uredba)</strong>, čl. 25. st. 2.</li>
            <li><strong>Zakon o provedbi Uredbe (EU) br. 910/2014</strong> (NN 62/17)</li>
            <li><strong>Zakon o elektroničkom dokumentu</strong> (NN 84/08, 154/14)</li>
            <li><strong>Zakon o zaštiti prava pacijenata</strong> (NN 169/04, 37/08, 71/15, 120/16, 52/21)</li>
            <li><strong>Zakon o zaštiti osoba s duševnim smetnjama</strong> (NN 76/14, 98/19)</li>
            <li><strong>Kazneni zakon RH</strong> (NN 125/11 do 36/24), čl. 136., 291. i 315.</li>
            <li><strong>Zakon o odgovornosti pravnih osoba za kaznena djela</strong> (NN 151/03 do 114/23)</li>
            <li><strong>Zakon o kaznenom postupku</strong> (NN 152/08 do 36/24), čl. 47.–63.</li>
        </ul>
    </div>

    <table class="parties-grid">
        <tr>
            <td>
                <div class="party-header">PODNOSITELJ</div>
                <strong>Duško Vučetić</strong>, OIB: 29383966489<br>
                Braće Buzolić 19, 21450 Hvar<br>
                E-mail: duskovucetic3@gmail.com | Tel: +385 91 978 1838
            </td>
            <td>
                <div class="party-header">NASLOVNIK</div>
                <strong>ŽUPANIJSKI SUD U ZADRU</strong><br>
                Ured za zaštitu prava pacijenata<br>
                Ulica plemića Borelli 9, 23000 Zadar<br>
                <em>N/r Ivan Marković, Predsjednik Županijskog suda u Zadru</em>
            </td>
        </tr>
        <tr>
            <td>
                <div class="party-header">PROTIV</div>
                <strong>Psihijatrijska bolnica Ugljan</strong>, OIB: 43171567819<br>
                Ulica Otočkih Dragovoljaca 42, 23273 Ugljan<br>
                E-mail: info@pbu.hr | Tel: 023/208-200<br>
                <em>N/r Mladen Mavar, ravnatelj</em>
            </td>
            <td>
                <div class="party-header">NA ZNANJE</div>
                <strong>DRŽAVNO SUDBENO VIJEĆE REPUBLIKE HRVATSKE</strong><br>
                Ulica grada Vukovara 49, 10000 Zagreb<br>
                E-mail: dsv@dsv.gov.hr | dsv@pravosudje.hr<br>
                <em>N/r Darko Milković, predsjednik DSV RH</em>
            </td>
        </tr>
    </table>

    <div class="subject-box">
        PREDMET: ZAHTJEV ZA HITNI INTERVENTNI NADZOR, ODBACIVANJE NIŠTETNIH AKATA I TRENUTNO PUŠTANJE NA SLOBODU TE PRIGOVOR NA NEZAKONITO ZADRŽAVANJE I PROTUPRAVNO LIŠENJE SLOBODE PACIJENTA
    </div>

    <div class="contested-acts">
        <strong>Pobijani akti na kojima se protupravno temelji zadržavanje:</strong>
        <ol>
            <li><strong>Rješenje Općinskog suda u Splitu, pos. br. R1 Ob-1071/19 od 15. travnja 2020. godine</strong> – nevaljan akt bez zakonski verificiranog Kvalificiranog elektroničkog potpisa (QES) sutkinje Krasne Batarelo;</li>
            <li><strong>Dopis Ministarstva zdravstva, KLASA: 052-02/23-05/157 od 22. ožujka 2024. godine</strong> – nevaljani akt bez zakonski verificiranog Kvalificiranog elektroničkog potpisa (QES) bivšeg ministra Vilija Beroša.</li>
        </ol>
    </div>

    <h2>I. Pravna nomotetika i materijalno-procesni temelji</h2>
    <p>Podnositelj temelji ovaj Zahtjev i Prigovor na kumulativnoj primjeni pozitivnih propisa Europske unije i Republike Hrvatske koji jamče zakonitost postupanja tijela s javnim ovlastima, formalnu autentičnost službenih akata te nepovredivost osobne slobode i ljudskih prava:</p>
    
    <h3>A. Pravne norme Europske unije (Izravna primjena)</h3>
    <p><strong>1. Uredba (EU) br. 910/2014 (eIDAS Uredba):</strong> Članak 25. stavak 2. izričito propisuje neoborivu normu: kvalificirani elektronički potpis (QES) ima jednak pravni učinak kao vlastoručni potpis. Sukladno eIDAS-u, svaki elektronički izdan akt tijela javne vlasti koji nema tehnički i pravno verificiran QES smatra se neautentičnim, pravno nepostojećim i lišenim svakog pravnog učinka (Akti <i>non-existens</i>).</p>

    <h3>B. Propisi Republike Hrvatske</h3>
    <ul>
        <li><strong>Zakon o provedbi Uredbe (EU) br. 910/2014 (NN 62/17):</strong> Obvezuje sva pravosudna i upravna tijela na primjenu kvalificiranih usluga povjerenja.</li>
        <li><strong>Zakon o elektroničkom dokumentu (NN 84/08, 154/14):</strong> Dokument bez odgovarajućeg elektroničkog potpisa ne predstavlja valjan pravni akt.</li>
        <li><strong>Zakon o zaštiti prava pacijenata (NN 169/04 do 52/21):</strong> Jamči temeljna prava na obaviještenost, samostalno odlučivanje, tjelesni integritet te obvezatnu sudsku zaštitu.</li>
        <li><strong>Zakon o zaštiti osoba s duševnim smetnjama (ZZPDS) (NN 76/14, 98/19):</strong> Propisuje strogo formalni, hitni sudski postupak za prisilni smještaj i zadržavanje. Odredbe ZZPDS-a su <i>iuris cogentis</i>.</li>
        <li><strong>Kazneni zakon RH (NN 125/11 do 36/24):</strong> Članci 136. (Protupravno oduzimanje slobode), 291. (Zlouporaba položaja i ovlasti) i 315. (Neizvršenje sudske odluke).</li>
        <li><strong>Zakon o odgovornosti pravnih osoba za kaznena djela (NN 151/03 do 114/22):</strong> Utvrđuje izravnu kaznenopravnu odgovornost Psihijatrijske bolnice Ugljan.</li>
        <li><strong>Zakon o kaznenom postupku (ZKP) (NN 152/08 do 36/24), čl. 47.–63.:</strong> Uređuju procesni status žrtve i oštećenika te oštećenika kao tužitelja.</li>
    </ul>

    <h2>II. Kaznenopravna odgovornost i status žrtve kao ovlaštenog tužitelja</h2>
    <p>Postupanje odgovornih osoba unutar Psihijatrijske bolnice Ugljan predstavlja izravno i kontinuirano ostvarivanje obilježja teških kaznenih djela iz Kaznenog zakona RH (čl. 136., čl. 291. i čl. 315. KZ-a). Temeljem Zakona o odgovornosti pravnih osoba za kaznena djela, Psihijatrijska bolnica Ugljan snosi izravnu kaznenopravnu odgovornost.</p>
    <p>Prema člancima 47.–63. ZKP-a, podnositelj Duško Vučetić ima nesporan status <strong>žrtve i oštećenika</strong> te podređeno preuzima procesnu ulogu <strong>OŠTEĆENIKA KAO TUŽITELJA</strong> u slučaju izostanka reakcije državnog odvjetništva.</p>

    <h2>III. Činjenično stanje i apstraktna nezakonitost postupanja</h2>
    <p><strong>1. Potpuni nedostatak valjanog QES potpisnog naloga (Ništetnost akata):</strong> Pobijani akti nemaju zakonski verificiran Kvalificirani elektronički potpis (QES). Akt koji nema takav certifikat pravno je ništetan i ne proizvodi nikakve pravne učinke.</p>
    <p><strong>2. Nedopušteno prekoračenje opsega djelomičnog lišenja poslovne sposobnosti:</strong> Mjera djelomičnog lišenja poslovne sposobnosti ne može služiti kao bjanko nalog za automatizirano nadomještanje posebnog sudskog postupka prisilnog smještaja propisanog ZZPDS-om.</p>

    <h2>IV. Zahtjev i prijedlog podnositelja</h2>
    <ol>
        <li><strong>HITNO POKRETANJE POSTUPKA NADZORA:</strong> Pokretanje izvanrednog nadzora nad zakonitošću hospitalizacije u Psihijatrijskoj bolnici Ugljan;</li>
        <li><strong>UTVRĐIVANJE NIŠTETNOSTI AKATA:</strong> Službeno utvrđivanje nedostatka verificiranog QES sudskog naloga;</li>
        <li><strong>NALOG ZA TRENUTNO PUŠTANJE NA SLOBODU:</strong> Hitan nalog za puštanje podnositelja Duška Vučetića na slobodu;</li>
        <li><strong>DOSTAVA SPISA DRŽAVNOM ODVJETNIŠTVU:</strong> Pokretanje kaznenog progona protiv odgovornih osoba i bolnice;</li>
        <li><strong>EVIDENTIRANJE PROCESNOG STATUSA:</strong> Evidentiranje statusa žrtve, oštećenika i oštećenika kao tužitelja.</li>
    </ol>

    <div class="signature-block">
        <strong>Podnositelj:</strong>
        <div class="signature-line"></div>
        <strong>Duško Vučetić</strong><br>
        <small><em>(Oštećenik, žrtva i ovlašteni podnositelj)</em></small>
    </div>
</body>
</html>
"""

HTML(string=html).write_pdf("Zahtjev_Za_Nadzor_A_GrbRH.pdf")
print("PDF USPJEŠNO GENERIRAN!")
