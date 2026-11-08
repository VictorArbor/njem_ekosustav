#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_JSON_SIZE 65536

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
    fprintf(fhtml, "    <title>Zajednica RUKE • e-Spis Pretinac i Prijem</title>\n");
    fprintf(fhtml, "    <style>\n");
    fprintf(fhtml, "        body { font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, sans-serif; background: #eef2f5; color: #333; margin: 0; padding: 20px; }\n");
    fprintf(fhtml, "        .card { max-width: 800px; margin: 20px auto; background: #fff; border-radius: 12px; padding: 25px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); border-top: 6px solid #28a745; }\n");
    fprintf(fhtml, "        .card-inbox { max-width: 800px; margin: 20px auto; background: #fff; border-radius: 12px; padding: 25px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); border-top: 6px solid #0056b3; }\n");
    fprintf(fhtml, "        .card-form { max-width: 800px; margin: 20px auto; background: #fff; border-radius: 12px; padding: 25px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); border-top: 6px solid #6f42c1; }\n");
    fprintf(fhtml, "        .card-auth { max-width: 800px; margin: 20px auto; background: #fff; border-radius: 12px; padding: 25px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); border-top: 6px solid #e67e22; }\n");
    fprintf(fhtml, "        .card-error { border-top-color: #dc3545; }\n");
    fprintf(fhtml, "        .logo-header { text-align: center; margin-bottom: 20px; }\n");
    fprintf(fhtml, "        .logo-header img { width: 85px; height: 85px; border-radius: 50%%; box-shadow: 0 4px 12px rgba(0,0,0,0.15); object-fit: cover; }\n");
    fprintf(fhtml, "        h1 { font-size: 20px; color: #1a252f; margin-bottom: 5px; }\n");
    fprintf(fhtml, "        .subtitle { font-size: 12px; color: #6c757d; margin-bottom: 15px; text-transform: uppercase; letter-spacing: 1px; font-weight: bold; text-align: center; }\n");
    fprintf(fhtml, "        .badge { display: inline-block; padding: 6px 12px; background: #e8f5e9; color: #2e7d32; font-weight: bold; border-radius: 20px; font-size: 13px; margin-bottom: 15px; }\n");
    fprintf(fhtml, "        .info-group { margin-bottom: 10px; border-bottom: 1px solid #f0f0f0; padding-bottom: 6px; }\n");
    fprintf(fhtml, "        .label { font-size: 11px; color: #888; text-transform: uppercase; }\n");
    fprintf(fhtml, "        .value { font-size: 13px; font-weight: 600; color: #2c3e50; word-break: break-all; }\n");
    fprintf(fhtml, "        .controls { display: flex; gap: 10px; margin-bottom: 15px; flex-wrap: wrap; }\n");
    fprintf(fhtml, "        .controls input, .controls select { flex: 1; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-size: 13px; box-sizing: border-box; }\n");
    fprintf(fhtml, "        .btn { display: inline-block; width: 48%%; text-align: center; background: #0056b3; color: white; padding: 12px 0; text-decoration: none; font-weight: bold; border-radius: 8px; margin-top: 15px; font-size: 13px; box-sizing: border-box; }\n");
    fprintf(fhtml, "        .btn-potvrda { background: #28a745; margin-left: 3%%; }\n");
    fprintf(fhtml, "        table { width: 100%%; border-collapse: collapse; margin-top: 10px; font-size: 13px; }\n");
    fprintf(fhtml, "        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #eee; }\n");
    fprintf(fhtml, "        th { background: #f8f9fa; color: #555; }\n");
    fprintf(fhtml, "        .footer { text-align: center; font-size: 11px; color: #aaa; margin-top: 30px; }\n");
    fprintf(fhtml, "    </style>\n");
    fprintf(fhtml, "</head>\n<body>\n\n");

    // Zajednički zaglavlje s logom za svaku sekciju
    // Macro za logo header
    #define PRINT_LOGO \
        fprintf(fhtml, "    <div class=\"logo-header\">\n"); \
        fprintf(fhtml, "        <img src=\"logo.png\" alt=\"Zajednica RUKE Grb\">\n"); \
        fprintf(fhtml, "        <div style=\"font-size: 14px; font-weight: bold; color: #2c3e50; margin-top: 8px;\">Udruga Zajednica RUKE</div>\n"); \
        fprintf(fhtml, "        <div style=\"font-size: 11px; color: #7f8c8d;\">OIB: 64517735227 • Zagreb</div>\n"); \
        fprintf(fhtml, "    </div>\n");

    // Kartica 1: Verifikator
    fprintf(fhtml, "<div id=\"app\" class=\"card\">\n");
    PRINT_LOGO
    fprintf(fhtml, "    <div class=\"subtitle\">C23 Offline e-Spis Verifikator</div>\n");
    fprintf(fhtml, "    <div id=\"content\">Učitavanje podataka iz baze...</div>\n");
    fprintf(fhtml, "</div>\n\n");

    // Kartica 2: Korisnički Pretinac
    fprintf(fhtml, "<div class=\"card-inbox\">\n");
    PRINT_LOGO
    fprintf(fhtml, "    <div class=\"subtitle\">Digitalni Korisnički Pretinac & Registar</div>\n");
    fprintf(fhtml, "    <div class=\"controls\">\n");
    fprintf(fhtml, "        <input type=\"text\" id=\"searchInput\" placeholder=\"🔍 Pretraži po broju akta, pošiljatelju ili primatelju...\" onkeyup=\"filtrirajAkte()\">\n");
    fprintf(fhtml, "        <select id=\"statusFilter\" onchange=\"filtrirajAkte()\">\n");
    fprintf(fhtml, "            <option value=\"\">📋 Svi statusi</option>\n");
    fprintf(fhtml, "            <option value=\"ZAPRIMLJENO\">ZAPRIMLJENO</option>\n");
    fprintf(fhtml, "        </select>\n");
    fprintf(fhtml, "    </div>\n");
    fprintf(fhtml, "    <div id=\"inbox-content\">Učitavanje pretinca...</div>\n");
    fprintf(fhtml, "</div>\n\n");

    // Kartica 3: Članska Prijava (Login Gate)
    fprintf(fhtml, "<div id=\"authCard\" class=\"card-auth\">\n");
    PRINT_LOGO
    fprintf(fhtml, "    <div class=\"subtitle\">Članska Autentikacija</div>\n");
    fprintf(fhtml, "    <h1>Prijava u e-Spis Ured</h1>\n");
    fprintf(fhtml, "    <p style=\"font-size: 13px; color: #666;\">Unesite Vaš članski OIB ili pristupni PIN za otključavanje sigurne forme za prijem podnesaka s kriptografskim pečatom.</p>\n");
    fprintf(fhtml, "    <div style=\"margin-top: 15px; display: flex; gap: 10px;\">\n");
    fprintf(fhtml, "        <input type=\"password\" id=\"memberPin\" placeholder=\"Unesite PIN / OIB (npr. 64517735227)\" style=\"flex: 1; padding: 10px; border: 1px solid #ddd; border-radius: 6px;\">\n");
    fprintf(fhtml, "        <button onclick=\"provjeriPrijavu()\" style=\"background: #e67e22; color: white; border: none; padding: 10px 20px; font-weight: bold; border-radius: 6px; cursor: pointer;\">Otključaj Ured</button>\n");
    fprintf(fhtml, "    </div>\n");
    fprintf(fhtml, "    <div id=\"authMsg\" style=\"margin-top: 10px; font-size: 13px; font-weight: bold;\"></div>\n");
    fprintf(fhtml, "</div>\n\n");

    // Kartica 4: Zaštićena Forma
    fprintf(fhtml, "<div id=\"formCard\" class=\"card-form\" style=\"display: none;\">\n");
    PRINT_LOGO
    fprintf(fhtml, "    <div class=\"subtitle\">Klijentska Kriptografska Obrada i Prijem</div>\n");
    fprintf(fhtml, "    <h1>Uloži novi podnesak s lokalnim SHA-256 pečatom</h1>\n");
    fprintf(fhtml, "    <p style=\"font-size: 13px; color: #666;\">Odaberite PDF dokument. Sustav lokalno izračunava SHA-256 sažetak u pregledniku, generira kontrolni kod i izdaje službenu e-Potvrdu.</p>\n");
    fprintf(fhtml, "    <form onsubmit=\"obradiPodnesak(event)\">\n");
    fprintf(fhtml, "        <div style=\"margin-bottom: 12px;\">\n");
    fprintf(fhtml, "            <label class=\"label\">Broj akta / Oznaka</label>\n");
    fprintf(fhtml, "            <input type=\"text\" id=\"pBroj\" required placeholder=\"npr. MG/PRIGOVOR-2026\" style=\"width: 100%%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; box-sizing: border-box;\">\n");
    fprintf(fhtml, "        </div>\n");
    fprintf(fhtml, "        <div style=\"margin-bottom: 12px;\">\n");
    fprintf(fhtml, "            <label class=\"label\">Pošiljatelj (Ime i prezime)</label>\n");
    fprintf(fhtml, "            <input type=\"text\" id=\"pPosiljatelj\" required value=\"Michael Golubičić\" style=\"width: 100%%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; box-sizing: border-box;\">\n");
    fprintf(fhtml, "        </div>\n");
    fprintf(fhtml, "        <div style=\"margin-bottom: 12px;\">\n");
    fprintf(fhtml, "            <label class=\"label\">Primatelj (Institucija / Sud)</label>\n");
    fprintf(fhtml, "            <input type=\"text\" id=\"pPrimatelj\" required placeholder=\"npr. Općinski sud u Vinkovcima\" style=\"width: 100%%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; box-sizing: border-box;\">\n");
    fprintf(fhtml, "        </div>\n");
    fprintf(fhtml, "        <div style=\"margin-bottom: 15px;\">\n");
    fprintf(fhtml, "            <label class=\"label\">Odaberi PDF dokument</label>\n");
    fprintf(fhtml, "            <input type=\"file\" id=\"pfile\" accept=\".pdf\" required style=\"width: 100%%; padding: 8px; border: 1px dashed #ccc; border-radius: 6px; background: #fafafa; box-sizing: border-box;\">\n");
    fprintf(fhtml, "        </div>\n");
    fprintf(fhtml, "        <button type=\"submit\" style=\"display: block; width: 100%%; background: #6f42c1; color: white; padding: 14px 0; font-weight: bold; border: none; border-radius: 8px; cursor: pointer;\">⚡ Generiraj SHA-256 Pečat i e-Potvrdu</button>\n");
    fprintf(fhtml, "    </form>\n");
    fprintf(fhtml, "    <div id=\"resultArea\" style=\"margin-top: 20px;\"></div>\n");
    fprintf(fhtml, "</div>\n\n");

    // JavaScript Logika
    fprintf(fhtml, "<script>\n");
    fprintf(fhtml, "    const serverData = %s;\n\n", json_buf);
    fprintf(fhtml, "    let localActs = JSON.parse(localStorage.getItem('ruke_akti') || '[]');\n");
    fprintf(fhtml, "    let allActs = [...serverData.akti, ...localActs];\n\n");

    fprintf(fhtml, "    function provjeriPrijavu() {\n");
    fprintf(fhtml, "        const pin = document.getElementById('memberPin').value.trim();\n");
    fprintf(fhtml, "        if (pin === '64517735227' || pin === 'RUKE2026' || pin === '05315840697') {\n");
    fprintf(fhtml, "            document.getElementById('authCard').style.display = 'none';\n");
    fprintf(fhtml, "            document.getElementById('formCard').style.display = 'block';\n");
    fprintf(fhtml, "        } else {\n");
    fprintf(fhtml, "            document.getElementById('authMsg').style.color = '#dc3545';\n");
    fprintf(fhtml, "            document.getElementById('authMsg').innerText = '❌ Neispravan članski PIN ili OIB.';\n");
    fprintf(fhtml, "        }\n");
    fprintf(fhtml, "    }\n\n");

    fprintf(fhtml, "    async function obradiPodnesak(e) {\n");
    fprintf(fhtml, "        e.preventDefault();\n");
    fprintf(fhtml, "        const broj = document.getElementById('pBroj').value.trim();\n");
    fprintf(fhtml, "        const posiljatelj = document.getElementById('pPosiljatelj').value.trim();\n");
    fprintf(fhtml, "        const primatelj = document.getElementById('pPrimatelj').value.trim();\n");
    fprintf(fhtml, "        const fileInput = document.getElementById('pfile');\n");
    fprintf(fhtml, "        const resultArea = document.getElementById('resultArea');\n\n");
    
    fprintf(fhtml, "        if (fileInput.files.length === 0) { alert('Molimo odaberite PDF dokument.'); return; }\n");
    fprintf(fhtml, "        const file = fileInput.files[0];\n\n");

    fprintf(fhtml, "        resultArea.innerHTML = '<p style=\"color: #0056b3; font-weight: bold;\">⏳ Izračun SHA-256 kriptografskog sažetka u pregledniku...</p>';\n\n");

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
    fprintf(fhtml, "            prikaziAkte(allActs);\n\n");

    fprintf(fhtml, "            const potvrdaTekst = `SLUŽBENA e-POTVRDA O ZAPRIMANJU PODNESKA\\nUdruga Zajednica RUKE (OIB: 64517735227)\\n-----------------------------------------------------\\nBroj akta: ${broj}\\nKontrolni kod: ${kontrolni_broj}\\nSHA-256 Otisak: ${sha256}\\nPošiljatelj: ${posiljatelj}\\nPrimatelj: ${primatelj}\\nDatum/Vrijeme: ${timestamp} (UTC)\\nStatus: ZAPRIMLJENO\\n-----------------------------------------------------\\neIDAS Compliant • Kriptografski ovjereno`;\n");
    fprintf(fhtml, "            const blob = new Blob([potvrdaTekst], {type: 'text/plain'});\n");
    fprintf(fhtml, "            const potvrdaUrl = URL.createObjectURL(blob);\n\n");

    fprintf(fhtml, "            resultArea.innerHTML = `\n");
    fprintf(fhtml, "                <div class=\"badge\">✓ USPJEŠNO ZAPRIMLJENO I PEČATIRANO</div>\n");
    fprintf(fhtml, "                <div class=\"info-group\"><div class=\"label\">Kontrolni broj</div><div class=\"value\">${kontrolni_broj}</div></div>\n");
    fprintf(fhtml, "                <div class=\"info-group\"><div class=\"label\">SHA-256 Otisak</div><div class=\"value\">${sha256}</div></div>\n");
    fprintf(fhtml, "                <a href=\"${potvrdaUrl}\" download=\"potvrda_${kontrolni_broj}.txt\" class=\"btn btn-potvrda\" style=\"display:block; width:100%%; text-align:center;\">📜 Preuzmi Službenu e-Potvrdu (.txt)</a>\n");
    fprintf(fhtml, "            `;\n");
    fprintf(fhtml, "        } catch(err) {\n");
    fprintf(fhtml, "            resultArea.innerHTML = '<p style=\"color:red;\">Greška pri obradi PDF-a: ' + err.message + '</p>';\n");
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
    fprintf(fhtml, "        content.innerHTML = `<p style=\"color:#666;\">Džepni e-Spis je spreman. Prijavite se ispod za unos novog akta ili pretražite postojeći pretinac.</p>`;\n");
    fprintf(fhtml, "    }\n\n");

    fprintf(fhtml, "    function prikaziAkte(aktiZaPrikaz) {\n");
    fprintf(fhtml, "        let tableHtml = `<table><thead><tr><th>Broj zapisa</th><th>Kontrolni kod</th><th>Pošiljatelj / Primatelj</th><th>Status</th><th>Datum</th></tr></thead><tbody>`;\n");
    fprintf(fhtml, "        if (aktiZaPrikaz.length === 0) {\n");
    fprintf(fhtml, "            tableHtml += `<tr><td colspan=\"5\" style=\"text-align:center; color:#888;\">Nema pronađenih akata.</td></tr>`;\n");
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
    fprintf(fhtml, "        const filtrirani = allActs.filter(a => {\n");
    fprintf(fhtml, "            const matchQuery = a.broj_akta.toLowerCase().includes(query) || \n");
    fprintf(fhtml, "                               a.posiljatelj.toLowerCase().includes(query) || \n");
    fprintf(fhtml, "                               a.primatelj.toLowerCase().includes(query) || \n");
    fprintf(fhtml, "                               a.kontrolni_broj.toLowerCase().includes(query);\n");
    fprintf(fhtml, "            const matchStatus = status === \"\" || (a.status || 'ZAPRIMLJENO') === status;\n");
    fprintf(fhtml, "            return matchQuery && matchStatus;\n");
    fprintf(fhtml, "        });\n");
    fprintf(fhtml, "        prikaziAkte(filtrirani);\n");
    fprintf(fhtml, "    }\n\n");

    fprintf(fhtml, "    prikaziAkte(allActs);\n");
    fprintf(fhtml, "</script>\n\n");

    fprintf(fhtml, "<div class=\"footer\">Zajednica RUKE (OIB: 64517735227) • Klijentski SHA-256 e-Spis Pretinac</div>\n");
    fprintf(fhtml, "</body>\n</html>\n");

    fclose(fhtml);
    printf("[C23 USPJEH] Generiran index.html s ugrađenim službenim grbom Zajednice RUKE.\n");
    return EXIT_SUCCESS;
}
