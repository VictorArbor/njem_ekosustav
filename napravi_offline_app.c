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

    FILE *fhtml = fopen("Zajednica_RUKE_eSpis.html", "w");
    if (!fhtml) {
        perror("[C23 GREŠKA] Ne mogu stvoriti Zajednica_RUKE_eSpis.html");
        return EXIT_FAILURE;
    }

    // HTML / CSS / JS predložak s naprednim značajkama pretraživanja i filtriranja
    fprintf(fhtml, "<!DOCTYPE html>\n");
    fprintf(fhtml, "<html lang=\"hr\">\n");
    fprintf(fhtml, "<head>\n");
    fprintf(fhtml, "    <meta charset=\"UTF-8\">\n");
    fprintf(fhtml, "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n");
    fprintf(fhtml, "    <title>Džepni e-Spis Pretinac — Zajednica RUKE</title>\n");
    fprintf(fhtml, "    <style>\n");
    fprintf(fhtml, "        body { font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, sans-serif; background: #eef2f5; color: #333; margin: 0; padding: 20px; }\n");
    fprintf(fhtml, "        .card { max-width: 800px; margin: 20px auto; background: #fff; border-radius: 12px; padding: 25px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); border-top: 6px solid #28a745; }\n");
    fprintf(fhtml, "        .card-inbox { max-width: 800px; margin: 20px auto; background: #fff; border-radius: 12px; padding: 25px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); border-top: 6px solid #0056b3; }\n");
    fprintf(fhtml, "        .card-form { max-width: 800px; margin: 20px auto; background: #fff; border-radius: 12px; padding: 25px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); border-top: 6px solid #6f42c1; }\n");
    fprintf(fhtml, "        .card-error { border-top-color: #dc3545; }\n");
    fprintf(fhtml, "        h1 { font-size: 20px; color: #1a252f; margin-bottom: 5px; }\n");
    fprintf(fhtml, "        .subtitle { font-size: 12px; color: #6c757d; margin-bottom: 20px; text-transform: uppercase; letter-spacing: 1px; font-weight: bold; }\n");
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

    // Kartica 1: Verifikator pojedinačnog akta
    fprintf(fhtml, "<div id=\"app\" class=\"card\">\n");
    fprintf(fhtml, "    <div class=\"subtitle\">Zajednica RUKE • C23 Offline e-Spis Verifikator</div>\n");
    fprintf(fhtml, "    <div id=\"content\">Učitavanje podataka iz ugrađene baze...</div>\n");
    fprintf(fhtml, "</div>\n\n");

    // Kartica 2: Korisnički pretinac s trailicom i filterima
    fprintf(fhtml, "<div class=\"card-inbox\">\n");
    fprintf(fhtml, "    <div class=\"subtitle\">📬 Digitalni Korisnički Pretinac (Native C23 Baza)</div>\n");
    fprintf(fhtml, "    <div class=\"controls\">\n");
    fprintf(fhtml, "        <input type=\"text\" id=\"searchInput\" placeholder=\"🔍 Pretraži po broju akta, pošiljatelju ili primatelju...\" onkeyup=\"filtrirajAkte()\">\n");
    fprintf(fhtml, "        <select id=\"statusFilter\" onchange=\"filtrirajAkte()\">\n");
    fprintf(fhtml, "            <option value=\"\">📋 Svi statusi</option>\n");
    fprintf(fhtml, "            <option value=\"ZAPRIMLJENO\">ZAPRIMLJENO</option>\n");
    fprintf(fhtml, "        </select>\n");
    fprintf(fhtml, "    </div>\n");
    fprintf(fhtml, "    <div id=\"inbox-content\">Učitavanje pretinca...</div>\n");
    fprintf(fhtml, "</div>\n\n");

    // Kartica 3: Forma za podnošenje
    fprintf(fhtml, "<div class=\"card-form\">\n");
    fprintf(fhtml, "    <div class=\"subtitle\">📤 e-Spis Ured • Priprema Podneska</div>\n");
    fprintf(fhtml, "    <h1>Podnesi novi akt</h1>\n");
    fprintf(fhtml, "    <form action=\"mailto:zajednicaruke@gmail.com\" method=\"POST\" enctype=\"text/plain\">\n");
    fprintf(fhtml, "        <div style=\"margin-bottom: 12px;\">\n");
    fprintf(fhtml, "            <label class=\"label\">Broj akta</label>\n");
    fprintf(fhtml, "            <input type=\"text\" name=\"broj_akta\" required style=\"width: 100%%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; box-sizing: border-box;\">\n");
    fprintf(fhtml, "        </div>\n");
    fprintf(fhtml, "        <div style=\"margin-bottom: 12px;\">\n");
    fprintf(fhtml, "            <label class=\"label\">Pošiljatelj</label>\n");
    fprintf(fhtml, "            <input type=\"text\" name=\"posiljatelj\" required value=\"Michael Golubičić\" style=\"width: 100%%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; box-sizing: border-box;\">\n");
    fprintf(fhtml, "        </div>\n");
    fprintf(fhtml, "        <button type=\"submit\" style=\"display: block; width: 100%%; background: #6f42c1; color: white; padding: 14px 0; font-weight: bold; border: none; border-radius: 8px; cursor: pointer;\">📧 Pošalji podnesak</button>\n");
    fprintf(fhtml, "    </form>\n");
    fprintf(fhtml, "</div>\n\n");

    // JavaScript logika za pretragu, filtriranje i verifikaciju
    fprintf(fhtml, "<script>\n");
    fprintf(fhtml, "    const data = %s;\n\n", json_buf);
    fprintf(fhtml, "    const params = new URLSearchParams(window.location.search);\n");
    fprintf(fhtml, "    const trazeniBroj = params.get('broj');\n");
    fprintf(fhtml, "    const trazeniKod = params.get('kod');\n");
    fprintf(fhtml, "    const content = document.getElementById('content');\n");
    fprintf(fhtml, "    const app = document.getElementById('app');\n\n");

    fprintf(fhtml, "    if (trazeniBroj && trazeniKod) {\n");
    fprintf(fhtml, "        const akt = data.akti.find(a => a.broj_akta === trazeniBroj && a.kontrolni_broj === trazeniKod);\n");
    fprintf(fhtml, "        if (akt) {\n");
    fprintf(fhtml, "            content.innerHTML = `\n");
    fprintf(fhtml, "                <div class=\"badge\">✓ VERIFICIRAN IZVORNIK (C23 OFFLINE)</div>\n");
    fprintf(fhtml, "                <h1>Broj akta: ${akt.broj_akta}</h1>\n");
    fprintf(fhtml, "                <div class=\"info-group\"><div class=\"label\">Kontrolni broj</div><div class=\"value\">${akt.kontrolni_broj}</div></div>\n");
    fprintf(fhtml, "                <div class=\"info-group\"><div class=\"label\">SHA-256 Otisak</div><div class=\"value\">${akt.sha256}</div></div>\n");
    fprintf(fhtml, "                <div class=\"info-group\"><div class=\"label\">Pošiljatelj ➔ Primatelj</div><div class=\"value\">${akt.posiljatelj} ➔ ${akt.primatelj}</div></div>\n");
    fprintf(fhtml, "                <a href=\"${akt.pdf_url}\" target=\"_blank\" class=\"btn\">📥 Preuzmi PDF</a>\n");
    fprintf(fhtml, "                <a href=\"${akt.potvrda_url}\" target=\"_blank\" class=\"btn btn-potvrda\">📜 e-Potvrda</a>\n");
    fprintf(fhtml, "            `;\n");
    fprintf(fhtml, "        } else {\n");
    fprintf(fhtml, "            app.classList.add('card-error');\n");
    fprintf(fhtml, "            content.innerHTML = `<div class=\"badge\" style=\"background:#ffebee; color:#c62828;\">❌ NEVAŽEĆI AKT</div><p>Dokument ne postoji u bazi.</p>`;\n");
    fprintf(fhtml, "        }\n");
    fprintf(fhtml, "    } else {\n");
    fprintf(fhtml, "        content.innerHTML = `<p style=\"color:#666;\">Džepni C23 e-Spis je spreman. Pretražujte akte u pretincu ispod.</p>`;\n");
    fprintf(fhtml, "    }\n\n");

    // Funkcija za iscrtavanje i filtriranje tablice
    fprintf(fhtml, "    function prikaziAkte(aktiZaPrikaz) {\n");
    fprintf(fhtml, "        let tableHtml = `<table><thead><tr><th>Broj zapisa</th><th>Kontrolni kod</th><th>Pošiljatelj / Primatelj</th><th>Status</th><th>Akcije</th></tr></thead><tbody>`;\n");
    fprintf(fhtml, "        if (aktiZaPrikaz.length === 0) {\n");
    fprintf(fhtml, "            tableHtml += `<tr><td colspan=\"5\" style=\"text-align:center; color:#888;\">Nema pronađenih akata.</td></tr>`;\n");
    fprintf(fhtml, "        } else {\n");
    fprintf(fhtml, "            aktiZaPrikaz.forEach(a => {\n");
    fprintf(fhtml, "                tableHtml += `<tr><td><b>${a.broj_akta}</b></td><td><code>${a.kontrolni_broj}</code></td><td>${a.posiljatelj}<br><small style=\"color:#888;\">➔ ${a.primatelj}</small></td><td><span style=\"color:#28a745; font-weight:bold;\">${a.status || 'ZAPRIMLJENO'}</span></td><td><a href=\"${a.pdf_url}\" target=\"_blank\" style=\"color:#0056b3; font-weight:bold; margin-right:8px;\">[PDF]</a> <a href=\"${a.potvrda_url}\" target=\"_blank\" style=\"color:#28a745; font-weight:bold;\">[Potvrda]</a></td></tr>`;\n");
    fprintf(fhtml, "            });\n");
    fprintf(fhtml, "        }\n");
    fprintf(fhtml, "        tableHtml += `</tbody></table>`;\n");
    fprintf(fhtml, "        document.getElementById('inbox-content').innerHTML = tableHtml;\n");
    fprintf(fhtml, "    }\n\n");

    fprintf(fhtml, "    function filtrirajAkte() {\n");
    fprintf(fhtml, "        const query = document.getElementById('searchInput').value.toLowerCase();\n");
    fprintf(fhtml, "        const status = document.getElementById('statusFilter').value;\n");
    fprintf(fhtml, "        const filtrirani = data.akti.filter(a => {\n");
    fprintf(fhtml, "            const matchQuery = a.broj_akta.toLowerCase().includes(query) || \n");
    fprintf(fhtml, "                               a.posiljatelj.toLowerCase().includes(query) || \n");
    fprintf(fhtml, "                               a.primatelj.toLowerCase().includes(query) || \n");
    fprintf(fhtml, "                               a.kontrolni_broj.toLowerCase().includes(query);\n");
    fprintf(fhtml, "            const matchStatus = status === \"\" || (a.status || 'ZAPRIMLJENO') === status;\n");
    fprintf(fhtml, "            return matchQuery && matchStatus;\n");
    fprintf(fhtml, "        });\n");
    fprintf(fhtml, "        prikaziAkte(filtrirani);\n");
    fprintf(fhtml, "    }\n\n");

    fprintf(fhtml, "    // Inicijalni prikaz svih akata\n");
    fprintf(fhtml, "    prikaziAkte(data.akti);\n");
    fprintf(fhtml, "</script>\n\n");

    fprintf(fhtml, "<div class=\"footer\">Zajednica RUKE (OIB: 64517735227) • C23 Strojni Offline e-Spis Pretinac sa Trailicom</div>\n");
    fprintf(fhtml, "</body>\n</html>\n");

    fclose(fhtml);
    printf("[C23 USPJEH] Ažurirana offline aplikacija s trailicom i filterima: Zajednica_RUKE_eSpis.html\n");
    return EXIT_SUCCESS;
}
