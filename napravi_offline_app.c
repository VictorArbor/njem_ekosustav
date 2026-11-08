#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_JSON_SIZE 65536

/* ==== Početak: vizualni identiteti (auto-generirano) ==== */

/* Službeni grb Zajednice RUKE (Verifikator i Prijava) */
void ispisi_grb_zajednica(FILE *fhtml) {
    fprintf(fhtml, "    <div class=\"logo-header\">\n");
    fprintf(fhtml, "        <img src=\"logo.png\" alt=\"Zajednica RUKE Grb\">\n");
    fprintf(fhtml, "        <div style=\"font-size: 16px; font-weight: bold; color: #2c3e50; margin-top: 8px;\">Zajednica RUKE</div>\n");
    fprintf(fhtml, "        <div style=\"font-size: 11px; color: #7f8c8d;\">OIB: 64517735227 \xE2\x80\xA2 Zagreb</div>\n");
    fprintf(fhtml, "    </div>\n");
}

/* Autentični BST pečat hipostazologije i zadružnog poduzetništva */
void ispisi_grb_bst(FILE *fhtml) {
    fprintf(fhtml, "    <div class=\"logo-header\">\n");
    fprintf(fhtml, "        <div style=\"width: 90px; height: 90px; border-radius: 50%%; background: linear-gradient(135deg, #1a252f, #2c3e50); color: #f39c12; display: flex; align-items: center; justify-content: center; font-size: 26px; font-weight: bold; margin: 0 auto; box-shadow: 0 4px 12px rgba(0,0,0,0.2); border: 3px solid #f39c12;\">BST</div>\n");
    fprintf(fhtml, "        <div style=\"font-size: 16px; font-weight: bold; color: #2c3e50; margin-top: 8px;\">ANUH \xE2\x80\xA2 Hipostazologija &amp; Zadružno Poduzetništvo</div>\n");
    fprintf(fhtml, "        <div style=\"font-size: 11px; color: #7f8c8d;\">Fraktalni Meta-Ontološki Sustav \xE2\x80\xA2 Županja</div>\n");
    fprintf(fhtml, "    </div>\n");
}
/* ==== Kraj: vizualni identiteti ==== */

int main(void) {
    FILE *fjson = fopen("registar_akata.json", "r");
    if (!fjson) {
        perror("[C23 GREŠKA] Ne mogu otvoriti registar_akata.json");
        return EXIT_FAILURE;
    }

    char json_buf[MAX_JSON_SIZE];
    memset(json_buf, 0, sizeof(json_buf));
    fread(json_buf, 1, sizeof(json_buf) - 1, fjson);
    fclose(fjson);

    FILE *fhtml = fopen("index.html", "w");
    if (!fhtml) {
        perror("[C23 GREŠKA] Ne mogu stvoriti index.html");
        return EXIT_FAILURE;
    }

    fprintf(fhtml, "<!DOCTYPE html>\n");
    fprintf(fhtml, "<html lang=\"hr\">\n");
    fprintf(fhtml, "<head>\n");
    fprintf(fhtml, "    <meta charset=\"UTF-8\">\n");
    fprintf(fhtml, "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n");
    fprintf(fhtml, "    <title>Zajednica RUKE • Osobni e-Spis Pretinac</title>\n");
    fprintf(fhtml, "    <style>\n");
    fprintf(fhtml, "        body { font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, sans-serif; background: #eef2f5; color: #333; margin: 0; padding: 20px; }\n");
    fprintf(fhtml, "        .card { max-width: 800px; margin: 20px auto; background: #fff; border-radius: 12px; padding: 25px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); border-top: 6px solid #28a745; }\n");
    fprintf(fhtml, "        .card-inbox { max-width: 800px; margin: 20px auto; background: #fff; border-radius: 12px; padding: 25px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); border-top: 6px solid #0056b3; }\n");
    fprintf(fhtml, "        .card-form { max-width: 800px; margin: 20px auto; background: #fff; border-radius: 12px; padding: 25px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); border-top: 6px solid #6f42c1; }\n");
    fprintf(fhtml, "        .card-auth { max-width: 800px; margin: 20px auto; background: #fff; border-radius: 12px; padding: 25px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); border-top: 6px solid #e67e22; }\n");
    fprintf(fhtml, "        .card-error { border-top-color: #dc3545; }\n");
    fprintf(fhtml, "        .logo-header { text-align: center; margin-bottom: 20px; }\n");
    fprintf(fhtml, "        .logo-header img { width: 90px; height: 90px; border-radius: 50%%; box-shadow: 0 4px 12px rgba(0,0,0,0.15); object-fit: cover; display: block; margin: 0 auto; }\n");
    fprintf(fhtml, "        h1 { font-size: 20px; color: #1a252f; margin-bottom: 5px; }\n");
    fprintf(fhtml, "        .subtitle { font-size: 12px; color: #6c757d; margin-bottom: 15px; text-transform: uppercase; letter-spacing: 1px; font-weight: bold; text-align: center; }\n");
    fprintf(fhtml, "        .badge { display: inline-block; padding: 6px 12px; background: #e8f5e9; color: #2e7d32; font-weight: bold; border-radius: 20px; font-size: 13px; margin-bottom: 15px; }\n");
    fprintf(fhtml, "        .info-group { margin-bottom: 10px; border-bottom: 1px solid #f0f0f0; padding-bottom: 6px; }\n");
    fprintf(fhtml, "        .label { font-size: 11px; color: #888; text-transform: uppercase; }\n");
    fprintf(fhtml, "        .value { font-size: 13px; font-weight: 600; color: #2c3e50; word-break: break-all; }\n");
    fprintf(fhtml, "        .controls { display: flex; gap: 10px; margin-bottom: 15px; flex-wrap: wrap; }\n");
    fprintf(fhtml, "        .controls input, .controls select { flex: 1; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 13px; box-sizing: border-box; }\n");
    fprintf(fhtml, "        .btn { display: inline-block; width: 48%%; text-align: center; background: #0056b3; color: white; padding: 12px 0; text-decoration: none; font-weight: bold; border-radius: 8px; margin-top: 15px; font-size: 13px; box-sizing: border-box; }\n");
    fprintf(fhtml, "        .btn-potvrda { background: #28a745; width: 100%%; margin-top: 10px; }\n");
    fprintf(fhtml, "        .btn-mail { background: #6f42c1; width: 100%%; margin-top: 10px; }\n");
    fprintf(fhtml, "        table { width: 100%%; border-collapse: collapse; margin-top: 10px; font-size: 13px; }\n");
    fprintf(fhtml, "        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #eee; }\n");
    fprintf(fhtml, "        th { background: #f8f9fa; color: #555; }\n");
    fprintf(fhtml, "        .footer { text-align: center; font-size: 11px; color: #aaa; margin-top: 30px; }\n");
    fprintf(fhtml, "        .user-bar { background: #e8f4f8; border: 1px solid #bce0fd; padding: 10px 15px; border-radius: 8px; font-size: 13px; margin-bottom: 15px; display: flex; justify-content: space-between; align-items: center; }\n");
    fprintf(fhtml, "    </style>\n");
    fprintf(fhtml, "</head>\n<body>\n\n");

    #define ispisi_grb_zajednica(fhtml); \
        fprintf(fhtml, "    <div class=\"logo-header\">\n"); \
        fprintf(fhtml, "        <img src=\"logo.png\" alt=\"Zajednica RUKE Grb\">\n"); \
        fprintf(fhtml, "        <div style=\"font-size: 16px; font-weight: bold; color: #2c3e50; margin-top: 8px;\">Zajednica RUKE</div>\n"); \
        fprintf(fhtml, "        <div style=\"font-size: 11px; color: #7f8c8d;\">OIB: 64517735227 • Zagreb</div>\n"); \
        fprintf(fhtml, "    </div>\n");

    // Kartica 1: Verifikator pojedinačnog akta
    fprintf(fhtml, "<div id=\"app\" class=\"card\">\n");
    ispisi_grb_zajednica(fhtml);
    fprintf(fhtml, "    <div class=\"subtitle\">C23 Offline e-Spis Verifikator</div>\n");
    fprintf(fhtml, "    <div id=\"content\">Učitavanje podataka iz baze...</div>\n");
    fprintf(fhtml, "</div>\n\n");

    // Kartica 2: Članska Prijava
    fprintf(fhtml, "<div id=\"authCard\" class=\"card-auth\">\n");
    ispisi_grb_bst(fhtml);
    fprintf(fhtml, "    <div class=\"subtitle\">Osobna Članska Autentikacija</div>\n");
    fprintf(fhtml, "    <h1>Prijava u Osobni e-Spis Pretinac</h1>\n");
    fprintf(fhtml, "    <p style=\"font-size: 13px; color: #666;\">Unesite Vaš osobni pristupni PIN za otključavanje Vašeg pretinca i sigurno podnošenje akata.</p>\n");
    fprintf(fhtml, "    <div style=\"margin-top: 15px; display: flex; gap: 10px;\">\n");
    fprintf(fhtml, "        <input type=\"password\" id=\"memberPin\" placeholder=\"Unesite Vaš osobni PIN\" style=\"flex: 1; padding: 10px; border: 1px solid #ddd; border-radius: 6px;\">\n");
    fprintf(fhtml, "        <button onclick=\"provjeriPrijavu()\" style=\"background: #e67e22; color: white; border: none; padding: 10px 20px; font-weight: bold; border-radius: 6px; cursor: pointer;\">Otključaj Pretinac</button>\n");
    fprintf(fhtml, "    </div>\n");
    fprintf(fhtml, "    <div id=\"authMsg\" style=\"margin-top: 10px; font-size: 13px; font-weight: bold;\"></div>\n");
    fprintf(fhtml, "</div>\n\n");

    // Privata Sekcija
    fprintf(fhtml, "<div id=\"privateSection\" style=\"display: none;\">\n");
    fprintf(fhtml, "    <div class=\"card-inbox\" style=\"margin-bottom: 0px;\">\n");
    fprintf(fhtml, "        <div class=\"user-bar\">\n");
    fprintf(fhtml, "            <div>👤 Prijavljeni korisnik: <b id=\"userNameDisplay\">-</b> (<span id=\"userRoleDisplay\">-</span>)</div>\n");
    fprintf(fhtml, "            <button onclick=\"odjava()\" style=\"background: #dc3545; color: white; border: none; padding: 5px 12px; border-radius: 4px; font-size: 12px; cursor: pointer;\">Odjava</button>\n");
    fprintf(fhtml, "        </div>\n");
    fprintf(fhtml, "    </div>\n\n");

    // Pretinac
    fprintf(fhtml, "    <div class=\"card-inbox\">\n");
    ispisi_grb_bst(fhtml);
    fprintf(fhtml, "        <div class=\"subtitle\">📬 Osobni Digitalni Pretinac & Registar Akata</div>\n");
    fprintf(fhtml, "        <div class=\"controls\">\n");
    fprintf(fhtml, "            <input type=\"text\" id=\"searchInput\" placeholder=\"🔍 Pretraži Vaše akte...\" onkeyup=\"filtrirajAkte()\">\n");
    fprintf(fhtml, "            <select id=\"statusFilter\" onchange=\"filtrirajAkte()\">\n");
    fprintf(fhtml, "                <option value=\"\">📋 Svi statusi</option>\n");
    fprintf(fhtml, "                <option value=\"ZAPRIMLJENO\">ZAPRIMLJENO</option>\n");
    fprintf(fhtml, "            </select>\n");
    fprintf(fhtml, "        </div>\n");
    fprintf(fhtml, "        <div id=\"inbox-content\">Učitavanje osobnog pretinca...</div>\n");
    fprintf(fhtml, "    </div>\n\n");

    // Forma
    fprintf(fhtml, "    <div class=\"card-form\">\n");
    
    fprintf(fhtml, "        <div class=\"subtitle\">Klijentska Kriptografska Obrada i Automatski Prijem</div>\n");
    fprintf(fhtml, "        <h1>Uloži novi podnesak s lokalnim SHA-256 pečatom</h1>\n");
    fprintf(fhtml, "        <p style=\"font-size: 13px; color: #666;\">Odaberite PDF dokument. Sustav lokalno izračunava SHA-256 sažetak, generira Potvrdu o zaprimanju te šalje obavijest u ured.</p>\n");
    fprintf(fhtml, "        <form onsubmit=\"obradiPodnesak(event)\">\n");
    fprintf(fhtml, "            <div style=\"margin-bottom: 12px;\">\n");
    fprintf(fhtml, "                <label class=\"label\">Broj akta / Oznaka</label>\n");
    fprintf(fhtml, "                <input type=\"text\" id=\"pBroj\" required placeholder=\"npr. MG/PRIGOVOR-2026\" style=\"width: 100%%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; box-sizing: border-box;\">\n");
    fprintf(fhtml, "            </div>\n");
    fprintf(fhtml, "            <div style=\"margin-bottom: 12px;\">\n");
    fprintf(fhtml, "                <label class=\"label\">Pošiljatelj (Ime i prezime)</label>\n");
    fprintf(fhtml, "                <input type=\"text\" id=\"pPosiljatelj\" required readonly style=\"width: 100%%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; background: #f8f9fa; box-sizing: border-box;\">\n");
    fprintf(fhtml, "            </div>\n");
    fprintf(fhtml, "            <div style=\"margin-bottom: 12px;\">\n");
    fprintf(fhtml, "                <label class=\"label\">Primatelj (Institucija / Sud / Zajednica)</label>\n");
    fprintf(fhtml, "                <input type=\"text\" id=\"pPrimatelj\" required placeholder=\"npr. Općinski sud u Vinkovcima\" style=\"width: 100%%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; box-sizing: border-box;\">\n");
    fprintf(fhtml, "            </div>\n");
    fprintf(fhtml, "            <div style=\"margin-bottom: 15px;\">\n");
    fprintf(fhtml, "                <label class=\"label\">Odaberi PDF dokument</label>\n");
    fprintf(fhtml, "                <input type=\"file\" id=\"pfile\" accept=\".pdf\" required style=\"width: 100%%; padding: 8px; border: 1px dashed #ccc; border-radius: 6px; background: #fafafa; box-sizing: border-box;\">\n");
    fprintf(fhtml, "            </div>\n");
    fprintf(fhtml, "            <button type=\"submit\" style=\"display: block; width: 100%%; background: #6f42c1; color: white; padding: 14px 0; font-weight: bold; border: none; border-radius: 8px; cursor: pointer;\">⚡ Izradi SHA-256 Pečat i Generiraj Potvrdu</button>\n");
    fprintf(fhtml, "        </form>\n");
    fprintf(fhtml, "        <div id=\"resultArea\" style=\"margin-top: 20px;\"></div>\n");
    fprintf(fhtml, "    </div>\n");
    fprintf(fhtml, "</div>\n\n");

    // JavaScript
    fprintf(fhtml, "<script>\n");
    fprintf(fhtml, "    const serverData = %s;\n\n", json_buf);

    fprintf(fhtml, "    const clanoviBaza = {\n");
    fprintf(fhtml, "        '3PutSvet!': { ime: 'Michael Golubičić', oib: '64517735227', uloga: 'Ovlašteni zastupnik' },\n");
    fprintf(fhtml, "        'RUKE2026': { ime: 'Član Zajednice RUKE', oib: '64517735227', uloga: 'Član' }\n");
    fprintf(fhtml, "    };\n\n");

    // UNESITE VAŠ TELEGRAM BOT TOKEN I CHAT ID OVDJE DA VAM STIŽE PUSH DIREKTNO NA MOBITEL
    fprintf(fhtml, "    const TG_BOT_TOKEN = '2209975:AAHxxxxxxx'; // Upišite npr: '7891234567:AAHxxx...'\n");
    fprintf(fhtml, "    const TG_CHAT_ID = '2209975';   // Upišite npr: '123456789'\n\n");

    fprintf(fhtml, "    let trenutniKorisnik = JSON.parse(sessionStorage.getItem('ruke_active_user') || 'null');\n");
    fprintf(fhtml, "    let localActs = JSON.parse(localStorage.getItem('ruke_akti') || '[]');\n");
    fprintf(fhtml, "    let allActs = [...serverData.akti, ...localActs];\n\n");

    fprintf(fhtml, "    function initsijalizirajKorisnika() {\n");
    fprintf(fhtml, "        if (trenutniKorisnik) {\n");
    fprintf(fhtml, "            document.getElementById('authCard').style.display = 'none';\n");
    fprintf(fhtml, "            document.getElementById('privateSection').style.display = 'block';\n");
    fprintf(fhtml, "            document.getElementById('userNameDisplay').innerText = trenutniKorisnik.ime;\n");
    fprintf(fhtml, "            document.getElementById('userRoleDisplay').innerText = trenutniKorisnik.uloga;\n");
    fprintf(fhtml, "            document.getElementById('pPosiljatelj').value = trenutniKorisnik.ime;\n");
    fprintf(fhtml, "            prikaziAkte(dohvatiOsobneAkte());\n");
    fprintf(fhtml, "        } else {\n");
    fprintf(fhtml, "            document.getElementById('authCard').style.display = 'block';\n");
    fprintf(fhtml, "            document.getElementById('privateSection').style.display = 'none';\n");
    fprintf(fhtml, "        }\n");
    fprintf(fhtml, "    }\n\n");

    fprintf(fhtml, "    function provjeriPrijavu() {\n");
    fprintf(fhtml, "        const pin = document.getElementById('memberPin').value.trim();\n");
    fprintf(fhtml, "        if (clanoviBaza[pin]) {\n");
    fprintf(fhtml, "            trenutniKorisnik = clanoviBaza[pin];\n");
    fprintf(fhtml, "            sessionStorage.setItem('ruke_active_user', JSON.stringify(trenutniKorisnik));\n");
    fprintf(fhtml, "            initsijalizirajKorisnika();\n");
    fprintf(fhtml, "        } else {\n");
    fprintf(fhtml, "            document.getElementById('authMsg').style.color = '#dc3545';\n");
    fprintf(fhtml, "            document.getElementById('authMsg').innerText = '❌ Neispravan osobni PIN.';\n");
    fprintf(fhtml, "        }\n");
    fprintf(fhtml, "    }\n\n");

    fprintf(fhtml, "    function odjava() {\n");
    fprintf(fhtml, "        sessionStorage.removeItem('ruke_active_user');\n");
    fprintf(fhtml, "        trenutniKorisnik = null;\n");
    fprintf(fhtml, "        initsijalizirajKorisnika();\n");
    fprintf(fhtml, "    }\n\n");

    fprintf(fhtml, "    function dohvatiOsobneAkte() {\n");
    fprintf(fhtml, "        if (!trenutniKorisnik) return [];\n");
    fprintf(fhtml, "        return allActs.filter(a => \n");
    fprintf(fhtml, "            a.posiljatelj.toLowerCase().includes(trenutniKorisnik.ime.toLowerCase()) || \n");
    fprintf(fhtml, "            a.primatelj.toLowerCase().includes(trenutniKorisnik.ime.toLowerCase()) ||\n");
    fprintf(fhtml, "            a.posiljatelj.includes('Victor Arbor') ||\n");
    fprintf(fhtml, "            a.posiljatelj.includes('Zajednica RUKE')\n");
    fprintf(fhtml, "        );\n");
    fprintf(fhtml, "    }\n\n");

    fprintf(fhtml, "    async function obradiPodnesak(e) {\n");
    fprintf(fhtml, "        e.preventDefault();\n");
    fprintf(fhtml, "        if (!trenutniKorisnik) { alert('Sesija je istekla.'); return; }\n");
    fprintf(fhtml, "        const broj = document.getElementById('pBroj').value.trim();\n");
    fprintf(fhtml, "        const posiljatelj = trenutniKorisnik.ime;\n");
    fprintf(fhtml, "        const primatelj = document.getElementById('pPrimatelj').value.trim();\n");
    fprintf(fhtml, "        const fileInput = document.getElementById('pfile');\n");
    fprintf(fhtml, "        const resultArea = document.getElementById('resultArea');\n\n");
    
    fprintf(fhtml, "        if (fileInput.files.length === 0) { alert('Odaberite PDF.'); return; }\n");
    fprintf(fhtml, "        const file = fileInput.files[0];\n\n");

    fprintf(fhtml, "        resultArea.innerHTML = '<p style=\"color: #0056b3; font-weight: bold;\">⏳ Kriptografska obrada u tijeku...</p>';\n\n");

    fprintf(fhtml, "        try {\n");
    fprintf(fhtml, "            const buffer = await file.arrayBuffer();\n");
    fprintf(fhtml, "            const hashBuffer = await crypto.subtle.digest('SHA-256', buffer);\n");
    fprintf(fhtml, "            const hashArray = Array.from(new Uint8Array(hashBuffer));\n");
    fprintf(fhtml, "            const sha256 = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');\n");
    fprintf(fhtml, "            const kontrolni_broj = sha256.substring(0, 4).toUpperCase() + '-' + sha256.substring(4, 8).toUpperCase();\n");
    fprintf(fhtml, "            const timestamp = new Date().toISOString();\n\n");

    fprintf(fhtml, "            const noviAkt = {\n");
    fprintf(fhtml, "                broj_akta: broj,\n");
    fprintf(fhtml, "                kontrolni_broj: kontrolni_broj,\n");
    fprintf(fhtml, "                sha256: sha256,\n");
    fprintf(fhtml, "                posiljatelj: posiljatelj,\n");
    fprintf(fhtml, "                primatelj: primatelj,\n");
    fprintf(fhtml, "                timestamp: timestamp,\n");
    fprintf(fhtml, "                status: 'ZAPRIMLJENO',\n");
    fprintf(fhtml, "                pdf_url: '#',\n");
    fprintf(fhtml, "                potvrda_url: '#'\n");
    fprintf(fhtml, "            };\n\n");

    fprintf(fhtml, "            localActs.push(noviAkt);\n");
    fprintf(fhtml, "            localStorage.setItem('ruke_akti', JSON.stringify(localActs));\n");
    fprintf(fhtml, "            allActs = [...serverData.akti, ...localActs];\n");
    fprintf(fhtml, "            prikaziAkte(dohvatiOsobneAkte());\n\n");

    // Tekst Potvrde s UTF-8 BOM-om za ispravna hrvatska slova
    fprintf(fhtml, "            const potvrdaTekst = `SLUŽBENA POTVRDA O ZAPRIMANJU PODNESKA\\nZajednica RUKE (OIB: 64517735227)\\n-----------------------------------------------------\\nBroj akta / Podneska: ${broj}\\nKontrolni kod verifikacije: ${kontrolni_broj}\\nSHA-256 Kriptografski sažetak: ${sha256}\\nPošiljatelj: ${posiljatelj}\\nPrimatelj: ${primatelj}\\nDatum i vrijeme zaprimanja: ${timestamp} (UTC)\\nStatus obrade: ZAPRIMLJENO UNUTAR OSOBNOG e-SPISA\\n-----------------------------------------------------\\nKriptografski pečatirano • eIDAS standard compliant`;\n");
    
    // Dodavanje UTF-8 BOM bajtova (\uFEFF) za čist prikaz hrvatskih slova na Androidu i Windowsima
    fprintf(fhtml, "            const blob = new Blob(['\\uFEFF' + potvrdaTekst], {type: 'text/plain;charset=utf-8'});\n");
    fprintf(fhtml, "            const potvrdaUrl = URL.createObjectURL(blob);\n\n");

    // 1. Automatsko preuzimanje Potvrde
    fprintf(fhtml, "            const autoDownloadLink = document.createElement('a');\n");
    fprintf(fhtml, "            autoDownloadLink.href = potvrdaUrl;\n");
    fprintf(fhtml, "            autoDownloadLink.download = `Potvrda_zaprimanja_${broj.replace(/[^a-zA-Z0-9_-]/g, '_')}_${kontrolni_broj}.txt`;\n");
    fprintf(fhtml, "            document.body.appendChild(autoDownloadLink);\n");
    fprintf(fhtml, "            autoDownloadLink.click();\n");
    fprintf(fhtml, "            document.body.removeChild(autoDownloadLink);\n\n");

    // 2. Automatska Push obavijest na tvoj Telegram (ako su uneseni token i chat id)
    fprintf(fhtml, "            if (TG_BOT_TOKEN !== '' && TG_CHAT_ID !== '') {\n");
    fprintf(fhtml, "                const tgMsg = encodeURIComponent(`🚨 [Zajednica RUKE] NOVI PODNESAK!\\n\\nBroj: ${broj}\\nKod: ${kontrolni_broj}\\nSHA-256: ${sha256}\\nPošiljatelj: ${posiljatelj}\\nPrimatelj: ${primatelj}\\nDatum: ${timestamp}`);\n");
    fprintf(fhtml, "                fetch(`https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage?chat_id=${TG_CHAT_ID}&text=${tgMsg}`).catch(e => console.log(e));\n");
    fprintf(fhtml, "            }\n\n");

    // 3. E-mail obavijest na mail klijent
    fprintf(fhtml, "            const mailSubject = encodeURIComponent('[Potvrda e-Spis] Akt: ' + broj);\n");
    fprintf(fhtml, "            const mailBody = encodeURIComponent(potvrdaTekst);\n");
    fprintf(fhtml, "            const mailtoUrl = `mailto:zajednicaruke@gmail.com?subject=${mailSubject}&body=${mailBody}`;\n\n");

    fprintf(fhtml, "            resultArea.innerHTML = `\n");
    fprintf(fhtml, "                <div class=\"badge\">✓ USPJEŠNO ZAPRIMLJENO I PEČATIRANO</div>\n");
    fprintf(fhtml, "                <p style=\"font-size:13px; color:#28a745; font-weight:bold;\">📥 Potvrda je preuzeta s ispravnim hrvatskim slovima (UTF-8).</p>\n");
    fprintf(fhtml, "                <div class=\"info-group\"><div class=\"label\">Kontrolni broj</div><div class=\"value\">${kontrolni_broj}</div></div>\n");
    fprintf(fhtml, "                <div class=\"info-group\"><div class=\"label\">SHA-256 Otisak</div><div class=\"value\">${sha256}</div></div>\n");
    fprintf(fhtml, "                <a href=\"${potvrdaUrl}\" download=\"Potvrda_zaprimanja_${kontrolni_broj}.txt\" class=\"btn btn-potvrda\" style=\"display:block; text-align:center;\">📜 Ponovno preuzmi Potvrdu (.txt)</a>\n");
    fprintf(fhtml, "                <a href=\"${mailtoUrl}\" class=\"btn btn-mail\" style=\"display:block; text-align:center;\">📧 Otvori mail obavijest</a>\n");
    fprintf(fhtml, "            `;\n\n");

    fprintf(fhtml, "        } catch(err) {\n");
    fprintf(fhtml, "            resultArea.innerHTML = '<p style=\"color:red;\">Greška: ' + err.message + '</p>';\n");
    fprintf(fhtml, "        }\n");
    fprintf(fhtml, "    }\n\n");

    fprintf(fhtml, "    const params = new URLSearchParams(window.location.search);\n");
    fprintf(fhtml, "    const trazeniBroj = params.get('broj');\n");
    fprintf(fhtml, "    const trazeniKod = params.get('kod');\n");
    fprintf(fhtml, "    const content = document.getElementById('content');\n");
    fprintf(fhtml, "    const app = document.getElementById('app');\n\n");

    fprintf(fhtml, "    if (trazeniBroj && trazeniKod) {\n");
    fprintf(fhtml, "        const akt = allActs.find(a => a.broj_akta === trazeniBroj && a.kontrolni_broj === trazeniKod);\n");
    fprintf(fhtml, "        if (akt) {\n");
    fprintf(fhtml, "            content.innerHTML = `\n");
    fprintf(fhtml, "                <div class=\"badge\">✓ VERIFICIRAN IZVORNIK (OFFLINE)</div>\n");
    fprintf(fhtml, "                <h1>Broj akta: ${akt.broj_akta}</h1>\n");
    fprintf(fhtml, "                <div class=\"info-group\"><div class=\"label\">Kontrolni broj</div><div class=\"value\">${akt.kontrolni_broj}</div></div>\n");
    fprintf(fhtml, "                <div class=\"info-group\"><div class=\"label\">SHA-256 Otisak</div><div class=\"value\">${akt.sha256}</div></div>\n");
    fprintf(fhtml, "                <div class=\"info-group\"><div class=\"label\">Pošiljatelj ➔ Primatelj</div><div class=\"value\">${akt.posiljatelj} ➔ ${akt.primatelj}</div></div>\n");
    fprintf(fhtml, "                <div class=\"info-group\"><div class=\"label\">Vremenska oznaka</div><div class=\"value\">${akt.timestamp}</div></div>\n");
    fprintf(fhtml, "            `;\n");
    fprintf(fhtml, "        } else {\n");
    fprintf(fhtml, "            app.classList.add('card-error');\n");
    fprintf(fhtml, "            content.innerHTML = `<div class=\"badge\" style=\"background:#ffebee; color:#c62828;\">❌ NEVAŽEĆI AKT</div><p>Dokument ne postoji u bazi.</p>`;\n");
    fprintf(fhtml, "        }\n");
    fprintf(fhtml, "    } else {\n");
    fprintf(fhtml, "        content.innerHTML = `<p style=\"color:#666;\">Osobni e-Spis je spreman. Prijavite se ispod s osobnim PIN-om za ulaz u pretinac.</p>`;\n");
    fprintf(fhtml, "    }\n\n");

    fprintf(fhtml, "    function prikaziAkte(aktiZaPrikaz) {\n");
    fprintf(fhtml, "        let tableHtml = `<table><thead><tr><th>Broj zapisa</th><th>Kontrolni kod</th><th>Pošiljatelj / Primatelj</th><th>Status</th><th>Datum</th></tr></thead><tbody>`;\n");
    fprintf(fhtml, "        if (aktiZaPrikaz.length === 0) {\n");
    fprintf(fhtml, "            tableHtml += `<tr><td colspan=\"5\" style=\"text-align:center; color:#888;\">Nema pronađenih akata u Vašem osobnome pretincu.</td></tr>`;\n");
    fprintf(fhtml, "        } else {\n");
    fprintf(fhtml, "            aktiZaPrikaz.forEach(a => {\n");
    fprintf(fhtml, "                tableHtml += `<tr><td><b>${a.broj_akta}</b></td><td><code>${a.kontrolni_broj}</code></td><td>${a.posiljatelj}<br><small style=\"color:#888;\">➔ ${a.primatelj}</small></td><td><span style=\"color:#28a745; font-weight:bold;\">${a.status || 'ZAPRIMLJENO'}</span></td><td><span style=\"color:#0056b3; font-size:12px;\">${a.timestamp ? a.timestamp.substring(0,10) : ''}</span></td></tr>`;\n");
    fprintf(fhtml, "            });\n");
    fprintf(fhtml, "        }\n");
    fprintf(fhtml, "        tableHtml += `</tbody></table>`;\n");
    fprintf(fhtml, "        document.getElementById('inbox-content').innerHTML = tableHtml;\n");
    fprintf(fhtml, "    }\n\n");

    fprintf(fhtml, "    function filtrirajAkte() {\n");
    fprintf(fhtml, "        const query = document.getElementById('searchInput').value.toLowerCase();\n");
    fprintf(fhtml, "        const status = document.getElementById('statusFilter').value;\n");
    fprintf(fhtml, "        const osobniAkti = dohvatiOsobneAkte();\n");
    fprintf(fhtml, "        const filtrirani = osobniAkti.filter(a => {\n");
    fprintf(fhtml, "            const matchQuery = a.broj_akta.toLowerCase().includes(query) || \n");
    fprintf(fhtml, "                               a.posiljatelj.toLowerCase().includes(query) || \n");
    fprintf(fhtml, "                               a.primatelj.toLowerCase().includes(query) || \n");
    fprintf(fhtml, "                               a.kontrolni_broj.toLowerCase().includes(query);\n");
    fprintf(fhtml, "            const matchStatus = status === \"\" || (a.status || 'ZAPRIMLJENO') === status;\n");
    fprintf(fhtml, "            return matchQuery && matchStatus;\n");
    fprintf(fhtml, "        });\n");
    fprintf(fhtml, "        prikaziAkte(filtrirani);\n");
    fprintf(fhtml, "    }\n\n");

    fprintf(fhtml, "    initsijalizirajKorisnika();\n");
    fprintf(fhtml, "</script>\n\n");

    fprintf(fhtml, "<div class=\"footer\">Zajednica RUKE (OIB: 64517735227) • Osobni SHA-256 e-Spis Pretinac</div>\n");
    fprintf(fhtml, "</body>\n</html>\n");

    fclose(fhtml);
    printf("[C23 USPJEH] Regeneriran index.html s UTF-8 BOM-om i spreman za Telegram Push.\n");
    return EXIT_SUCCESS;
}
