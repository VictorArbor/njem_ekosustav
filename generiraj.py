import base64
from weasyprint import HTML

# Učitavanje Vaše originalne JPG slike i pretvaranje u Base64
with open("grb.jpg", "rb") as f:
    jpg_b64 = base64.b64encode(f.read()).decode("utf-8")

img_uri = f"data:image/jpeg;base64,{jpg_b64}"

html_content = f"""<!DOCTYPE html>
<html lang="hr">
<head>
    <meta charset="UTF-8">
    <title>Zahtjev za hitni interventni nadzor</title>
    <style>
        *, *::before, *::after {{ box-sizing: border-box; }}
        @page {{
            size: A4;
            margin: 10mm 15mm 12mm 15mm;
            background-color: #ffffff;
            @bottom-right {{
                content: "Stranica " counter(page) " od " counter(pages);
                font-size: 8pt;
                font-family: Arial, sans-serif;
                color: #555;
            }}
        }}
        body {{
            font-family: 'Times New Roman', Times, serif;
            font-size: 9.5pt;
            line-height: 1.35;
            color: #111;
            margin: 0;
            padding: 0;
        }}
        .header-container {{
            text-align: center;
            border-bottom: 2px solid #002B49;
            padding-bottom: 6px;
            margin-bottom: 10px;
        }}
        .coat-of-arms {{
            height: 70px;
            width: auto;
            display: block;
            margin: 0 auto 4px auto;
        }}
        .header-title {{
            font-size: 11pt;
            font-weight: bold;
            color: #002B49;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin: 0 0 2px 0;
        }}
        .header-info {{
            font-size: 8.5pt;
            color: #222;
            margin: 1px 0;
            font-family: Arial, sans-serif;
        }}
        .header-subinfo {{
            font-size: 9pt;
            font-weight: bold;
            color: #002B49;
            margin-top: 3px;
            font-family: Arial, sans-serif;
        }}
        .meta-table {{ width: 100%; border-collapse: collapse; margin-bottom: 8px; font-size: 8.5pt; }}
        .meta-table td {{ vertical-align: top; padding: 2px 0; }}
        .basis-box {{
            background-color: #f8f9fa;
            border-left: 3px solid #002B49;
            padding: 6px 10px;
            margin-bottom: 10px;
            font-size: 8.5pt;
            line-height: 1.25;
        }}
        .basis-title {{ font-weight: bold; color: #002B49; text-transform: uppercase; margin-bottom: 3px; }}
        .basis-list {{ margin: 0; padding-left: 15px; }}
        .basis-list li {{ margin-bottom: 1px; }}
        .parties-grid {{ width: 100%; border-collapse: collapse; margin-bottom: 10px; font-size: 8.5pt; }}
        .parties-grid td {{ width: 50%; vertical-align: top; padding: 4px 6px; background-color: #f4f6f8; border: 1px solid #e1e4e8; }}
        .party-header {{ font-weight: bold; color: #002B49; border-bottom: 1px solid #ccc; padding-bottom: 2px; margin-bottom: 3px; font-size: 8pt; text-transform: uppercase; }}
        .subject-box {{ background-color: #002B49; color: #ffffff; padding: 7px 10px; text-align: center; font-weight: bold; font-size: 9.5pt; margin-bottom: 10px; line-height: 1.25; }}
        .contested-acts {{ background-color: #fff5f5; border: 1px solid #fed7d7; padding: 6px 10px; margin-bottom: 10px; font-size: 8.5pt; }}
        .contested-acts-title {{ font-weight: bold; color: #c53030; margin-bottom: 3px; }}
        h2 {{ font-size: 10pt; color: #002B49; border-bottom: 1px solid #002B49; padding-bottom: 2px; margin-top: 10px; margin-bottom: 5px; text-transform: uppercase; page-break-after: avoid; }}
        h3 {{ font-size: 9pt; color: #1a365d; margin-top: 6px; margin-bottom: 3px; page-break-after: avoid; }}
        p {{ margin-top: 0; margin-bottom: 5px; text-align: justify; }}
        ul {{ margin-top: 0; margin-bottom: 5px; padding-left: 18px; }}
        li {{ margin-bottom: 2px; text-align: justify; }}
        .signature-section {{ margin-top: 15px; page-break-inside: avoid; width: 100%; }}
        .signature-block {{ float: right; width: 220px; text-align: center; }}
        .signature-line {{ border-bottom: 1px dashed #333; margin-top: 30px; margin-bottom: 4px; }}
    </style>
</head>
<body>

    <!-- IZVORNA JPG SLIKA U ZAGLAVLJU -->
    <div class="header-container">
        <img src="{img_uri}" class="coat-of-arms" alt="Grb RH">
        <div class="header-title">DRŽAVNO SUDBENO VIJEĆE REPUBLIKE HRVATSKE</div>
        <div class="header-info">Ulica grada Vukovara 49, 10000 Zagreb; dsv@dsv.gov.hr ili dsv@pravosudje.hr</div>
        <div class="header-info">+385 1 6040 940 / +385 1 6040 934; dsv.pravosudje.hr</div>
        <div class="header-subinfo">Darko Milković, predsjednik DSV RH</div>
    </div>

    <!-- METAPODACI -->
    <table class="meta-table">
        <tr>
            <td style="width: 60%;"><strong>Klasifikacijska oznaka akta:</strong> P-G22R/PBU-14-10-2026</td>
            <td style="width: 40%; text-align: right;"><strong>Mjesto i datum:</strong> U Zagrebu, 14. listopada 2026. godine</td>
        </tr>
    </table>

    <!-- PRAVNI TEMELJI -->
    <div class="basis-box">
        <div class="basis-title">Pravni temelji podneska:</div>
        <ul class="basis-list">
            <li><strong>Uredba (EU) br. 910/2014 Europskog parlamenta i Vijeća (eIDAS Uredba)</strong>, članak 25. stavak 2.</li>
            <li><strong>Zakon o provedbi Uredbe (EU) br. 910/2014</strong> (NN 62/17)</li>
            <li><strong>Zakon o elektroničkom dokumentu</strong> (NN 84/08, 154/14)</li>
            <li><strong>Zakon o zaštiti prava pacijenata</strong> (NN 169/04, 37/08, 71/15, 120/16, 52/21)</li>
            <li><strong>Zakon o zaštiti osoba s duševnim smetnjama</strong> (NN 76/14, 98/19)</li>
            <li><strong>Kazneni zakon RH</strong> (NN 125/11, 144/12, 56/15, 61/15, 101/17, 118/18, 126/19, 84/21, 114/22, 114/23, 36/24), članci 136., 291. i 315.</li>
            <li><strong>Zakon o odgovornosti pravnih osoba za kaznena djela</strong> (NN 151/03, 110/07, 45/11, 143/12, 114/22, 114/23)</li>
            <li><strong>Zakon o kaznenom postupku</strong> (NN 152/08, 76/09, 80/11, 91/12, 143/12, 56/13, 145/13, 152/14, 70/17, 126/19, 130/20, 80/22, 36/24), članci 47.–63.</li>
        </ul>
    </div>

    <!-- STRANKE -->
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

    <!-- PREDMET -->
    <div class="subject-box">
        PREDMET: ZAHTJEV ZA HITNI INTERVENTNI NADZOR, ODBACIVANJE NIŠTETNIH AKATA I TRENUTNO PUŠTANJE NA SLOBODU TE PRIGOVOR NA NEZAKONITO ZADRŽAVANJE I PROTUPRAVNO LIŠENJE SLOBODE PACIJENTA
    </div>

    <!-- POBIJANIAKTI -->
    <div class="contested-acts">
        <div class="contested-acts-title">Pobijani akti na kojima se protupravno temelji zadržavanje:</div>
        <ol style="margin: 0; padding-left: 18px;">
            <li><strong>Rješenje Općinskog suda u Splitu, pos. br. R1 Ob-1071/19 od 15. travnja 2020. godine</strong> – formalno, materijalno i tehnički nevaljan akt bez zakonski verificiranog Kvalificiranog elektroničkog potpisa (QES) sutkinje/ovlaštene osobe Krasne Batarelo;</li>
            <li><strong>Dopis Ministarstva zdravstva, KLASA: 052-02/23-05/157 od 22. ožujka 2024. godine</strong> – nevaljani upravni/sluzi akt bez zakonski verificiranog Kvalificiranog elektroničkog potpisa (QES) bivšeg ministra Vilija Beroša.</li>
        </ol>
    </div>

    <!-- SADRŽAJ -->
    <h2>I. Pravna nomotetika i materijalno-procesni temelji</h2>
    <p>Podnositelj temelji ovaj Zahtjev i Prigovor na kumulativnoj primjeni pozitivnih propisa Europske unije i Republike Hrvatske koji jamče zakonitost postupanja tijela s javnim ovlastima, formalnu autentičnost službenih akata te nepovredivost osobne slobode i ljudskih prava:</p>
    
    <h3>A. Pravne norme Europske unije (Izravna primjena)</h3>
    <p><strong>1. Uredba (EU) br. 910/2014 Europskog parlamenta i Vijeća od 23. srpnja 2014. (eIDAS Uredba):</strong> Članak 25. stavak 2. izričito propisuje neoborivu normu: kvalificirani elektronički potpis (QES) ima jednak pravni učinak kao vlastoručni potpis. Sukladno eIDAS-u, svaki elektronički izdan akt tijela javne vlasti koji nema tehnički i pravno verificiran QES smatra se neautentičnim, pravno nepostojećim i lišenim svakog pravnog učinka (Akti <em>non-existens</em>).</p>

    <h3>B. Propisi Republike Hrvatske</h3>
    <ul>
        <li><strong>Zakon o provedbi Uredbe (EU) br. 910/2014 (NN 62/17):</strong> Uređuje provedbu eIDAS standarda u pravnom poretku RH te obvezuje sva pravosudna i upravna tijela na primjenu kvalificiranih usluga povjerenja.</li>
        <li><strong>Zakon o elektroničkom dokumentu (NN 84/08, 154/14):</strong> Uređuje pravnu valjanost, izradu, pohranu i uporabu elektroničkih dokumenata pred tijelima državne vlasti i tijelima s javnim ovlastima, propisujući da dokument bez odgovarajućeg elektroničkog potpisa ne predstavlja valjan pravni akt.</li>
        <li><strong>Zakon o zaštiti prava pacijenata (NN 169/04, 37/08, 71/15, 120/16, 52/21):</strong> Jamči temeljna prava na obaviještenost, samostalno odlučivanje, tjelesni integritet te obvezatnu sudsku i institucionalnu zaštitu prava pacijenta od samovolje javnopravnih ustanova.</li>
        <li><strong>Zakon o zaštiti osoba s duševnim smetnjama (ZZPDS) (NN 76/14, 98/19):</strong> Propisuje strogo formalni, hitni sudski postupak za prisilni smještaj i zadržavanje u psihijatrijskoj ustanovi. Odredbe ZZPDS-a su <em>iuris cogentis</em> (prisilne prirode) i ne trpe nikakvu proizvoljnost ili pretpostavljenu suglasnost.</li>
        <li><strong>Kazneni zakon RH (NN 125/11, 144/12, 56/15, 61/15, 101/17, 118/18, 126/19, 84/21, 114/22, 114/23, 36/24):</strong>
            <ul>
                <li><strong>Članak 136. – Protupravno oduzimanje slobode:</strong> Kvalificirani oblik kaznenog djela počinjen od strane službene osobe, zlouporabom položaja ili protupravnim zadržavanjem bez valjanog i zakonitog sudskog naloga.</li>
                <li><strong>Članak 291. – Zlouporaba položaja i ovlasti:</strong> Počinjeno od strane odgovornih osoba bolnice i tijela koja prekoračuju granice svojih ovlasti ili ne obavljaju dužnost, čime teže povrijeđuju prava druge osobe.</li>
                <li><strong>Članak 315. – Neizvršenje sudske odluke / Zlouporaba zapovijedi ili ovlasti u postupku:</strong> Izvršavanje naloga koji nemaju zakonsku snagu ili opstruiranje primjene zakonskih propisa na štetu podnositelja.</li>
            </ul>
        </li>
        <li><strong>Zakon o odgovornosti pravnih osoba za kaznena djela (NN 151/03, 110/07, 45/11, 143/12, 114/22, 114/23):</strong> Izričito utvrđuje izravnu kaznenopravnu odgovornost pravne osobe (Psihijatrijska bolnica Ugljan) za kaznena djela koja su odgovorne osobe (ravnatelj, odjelni liječnici) počinile u okviru svojih ovlasti ili propuštanjem dužnog nadzora.</li>
        <li><strong>Zakon o kaznenom postupku (ZKP) (NN 152/08, 76/09, 80/11, 91/12, 143/12, 56/13, 145/13, 152/14, 70/17, 126/19, 130/20, 80/22, 36/24), članci 47.–63.:</strong> Uređuju procesni status žrtve i oštećenika te procesni institut oštećenika kao tužitelja.</li>
    </ul>

    <h2>II. Kaznenopravna odgovornost i status žrtve kao ovlaštenog tužitelja</h2>
    <p>Postupanje odgovornih i ovlaštenih osoba unutar Psihijatrijske bolnice Ugljan, kao i pratećih tijela koja postupaju bez zakonite, formalno valjane i tehnički verificirane sudske ili upravne odluke, predstavlja izravno i kontinuirano ostvarivanje obilježja teških kaznenih djela iz Kaznenog zakona RH (čl. 136., čl. 291. i čl. 315. KZ-a).</p>
    <p>Temeljem <strong>Zakona o odgovornosti pravnih osoba za kaznena djela</strong>, Psihijatrijska bolnica Ugljan kao pravna osoba snosi samostalnu i izravnu kaznenopravnu odgovornost jer su njezina tijela i odgovorne osobe (ravnatelj Mladen Mavar, odjelni liječnici i nadležne službe) dopustili i provođenjem omogućili protupravno lišenje slobode i sustavno kršenje temeljnih prava pacijenta.</p>
    <p><strong>Procesni položaj podnositelja – Žrtva i oštećenik kao ovlašteni tužitelj:</strong> Prema člancima 47.–63. ZKP-a, podnositelj Duško Vučetić ima nesporan status <strong>žrtve i oštećenika</strong> kaznenog djela. U slučaju da nadležno državno odvjetništvo ne pokrene kazneni progon, odbaci kaznenu prijavu ili ne poduzme radnje u zakonom propisanim rokovima, podnositelj podređeno i izričito stječe pravo i preuzima procesnu ulogu <strong>OŠTEĆENIKA KAO TUŽITELJA</strong> (supstitutivni tužitelj). U tom statusu podnositelj će samostalno pokrenuti i voditi kazneni progon pred nadležnim kaznenim sudom protiv svih odgovornih fizičkih i pravnih osoba.</p>

    <h2>III. Činjenično stanje i apstraktna nezakonitost postupanja</h2>
    <p><strong>1. Potpuni nedostatak valjanog QES potpisnog naloga (Ništetnost akata):</strong> Uvidom i analitičkom provjerom pobijanih akata – <em>Rješenja Općinskog suda u Splitu, pos. br. R1 Ob-1071/19 od 15. travnja 2020. (Krasna Batarelo)</em> te <em>Dopisa Ministarstva zdravstva KLASA: 052-02/23-05/157 od 22. ožujka 2024. (Vili Beroš)</em> – utvrđeno je da se isti pokušavaju izvršiti i primijeniti bez zakonski obvezujućeg, tehnički verificiranog i valjanog Kvalificiranog elektroničkog potpisa (QES). Prema eIDAS Uredbi (čl. 25. st. 2.) i Zakonu o provedbi eIDAS Uredbe (NN 62/17), svaki pojedinačni elektronički akt tijela državne vlasti koji zadire u temeljna ljudska prava i služi kao osnov za lišenje slobode <strong>mora</strong> posjedovati valjan QES s vremenskim pečatom. Akt koji nema takav certifikat i potpis pravno je ništetan, ne proizvodi nikakve pravne učinke i ne može predstavljati zakonitu osnovu za prisilno privođenje, hospitalizaciju ili zadržavanje podnositelja.</p>
    <p><strong>2. Nedopušteno prekoračenje opsega djelomičnog lišenja poslovne sposobnosti:</strong> Mjera djelomičnog lišenja poslovne sposobnosti iz 2020. godine nipošto ne može služiti kao trajni ili bjanko nalog za automatizirano i protupravno nadomještanje posebnog sudskog postupka prisilnog smještaja propisanog Zakonom o zaštiti osoba s duševnim smetnjama (ZZPDS). Svaka pojedinačna hospitalizacija i svako zadržavanje u psihijatrijskoj ustanovi zahtijeva poseban, zakonom strogo normiran sudski postupak u kojem se donosi pojedinačno, formalno-pravno i tehnički besprijekorno sudsko rješenje s valjanim QES potpisom. Postupanje Psihijatrijske bolnice Ugljan mimo te procedure predstavlja izravnu zlouporabu položaja i teški oblik protupravnog oduzimanja slobode.</p>

    <h2>IV. Zahtjev i prijedlog podnositelja</h2>
    <p>Na temelju iznesenog činjeničnog stanja, pravnih temelja te materijalnog i procesnog prava, podnositelj Duško Vučetić od Županijskog suda u Zadru (Ureda za zaštitu prava pacijenata i Predsjednika suda Ivana Markovića) <strong>ZAHTIJEVA I PREDLAŽE:</strong></p>
    <ol style="margin-top: 3px; padding-left: 18px;">
        <li><strong>HITNO POKRETANJE POSTUPKA NADZORA:</strong> Da Ured za zaštitu prava pacijenata i Predsjednik Županijskog suda u Zadru odmah i bez odgode pokrenu izvanredni nadzor nad zakonitošću smještaja, hospitalizacije i zadržavanja pacijenta Duška Vučetića u Psihijatrijskoj bolnici Ugljan;</li>
        <li><strong>UTVRĐIVANJE NIŠTETNOSTI I NEPOSTOJANJA LEGITIMNOG OSNOVA:</strong> Da se službeno utvrdi potpuni nedostatak valjanog pravnog i tehničkog temelja (nedostatak verificiranog QES sudskog naloga) za bilo kakvo ograničenje slobode kretanja i osobnih prava podnositelja;</li>
        <li><strong>NALOG ZA TRENUTNO PUŠTANJE NA SLOBODU:</strong> Da Županijski sud u Zadru izda hitan nalog Psihijatrijskoj bolnici Ugljan za trenutno i bezuvjetno puštanje podnositelja Duška Vučetića na slobodu;</li>
        <li><strong>DOSTAVA SPISA DRŽAVNOM ODVJETNIŠTVU:</strong> Da se cjelokupni spisi i saznanja bez odgode dostave nadležnom Državnom odvjetništvu radi pokretanja kaznenog progona protiv odgovornih fizičkih osoba (u bolnici i nadležnim tijelima) te Psihijatrijske bolnice Ugljan kao pravne osobe, temeljem Kaznenog zakona RH i Zakona o odgovornosti pravnih osoba za kaznena djela;</li>
        <li><strong>EVIDENTIRANJE PROCESNOG STATUSA:</strong> Da se u spisima predmeta evidentira primarni status podnositelja kao <strong>žrtve i oštećenika</strong>, uz formalno primanje na znanje rezerve prava na stupanje u postupak u svojstvu <strong>oštećenika kao tužitelja</strong>.</li>
    </ol>

    <!-- POTPIS -->
    <div class="signature-section">
        <div class="signature-block">
            <strong>Podnositelj:</strong>
            <div class="signature-line"></div>
            <strong>Duško Vučetić</strong><br>
            <small><em>(Oštećenik, žrtva i ovlašteni podnositelj)</em></small>
        </div>
        <div style="clear: both;"></div>
    </div>

</body>
</html>
"""

HTML(string=html_content).write_pdf("Zahtjev_Za_Nadzor_Izvorni_JPG.pdf")
print("PDF uspjesno kreiran!")
