#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <openssl/evp.h>
#include <qrencode.h>

#define MAX_BUF 8192

void izracunaj_sha256(const char *filepath, char *hex_out) {
    FILE *f = fopen(filepath, "rb");
    if (!f) {
        perror("[GREŠKA] Otvaranje datoteke za SHA-256");
        exit(EXIT_FAILURE);
    }
    EVP_MD_CTX *mdctx = EVP_MD_CTX_new();
    const EVP_MD *md = EVP_sha256();
    unsigned char hash[EVP_MAX_MD_SIZE];
    unsigned int md_len;

    EVP_DigestInit_ex(mdctx, md, NULL);
    unsigned char buffer[4096];
    size_t bytes;
    while ((bytes = fread(buffer, 1, sizeof(buffer), f)) != 0) {
        EVP_DigestUpdate(mdctx, buffer, bytes);
    }
    EVP_DigestFinal_ex(mdctx, hash, &md_len);
    EVP_MD_CTX_free(mdctx);
    fclose(f);

    for (unsigned int i = 0; i < md_len; i++) {
        sprintf(hex_out + (i * 2), "%02x", hash[i]);
    }
    hex_out[64] = '\0';
}

void generiraj_kontrolni_kod(const char *sha256_hex, char *kod_out) {
    snprintf(kod_out, 10, "%.4s-%.4s", sha256_hex, sha256_hex + 4);
    for (int i = 0; kod_out[i]; i++) {
        if (kod_out[i] >= 'a' && kod_out[i] <= 'z') {
            kod_out[i] -= 32;
        }
    }
}

void generiraj_pbm_qr(const char *text, const char *out_pbm) {
    QRcode *qr = QRcode_encodeString(text, 0, QR_ECLEVEL_M, QR_MODE_8, 1);
    if (!qr) return;

    FILE *f = fopen(out_pbm, "w");
    if (!f) { QRcode_free(qr); return; }

    fprintf(f, "P1\n%d %d\n", qr->width, qr->width);
    for (int y = 0; y < qr->width; y++) {
        for (int x = 0; x < qr->width; x++) {
            fprintf(f, "%d ", (qr->data[y * qr->width + x] & 1) ? 1 : 0);
        }
        fprintf(f, "\n");
    }
    fclose(f);
    QRcode_free(qr);
}

void dobi_utc_timestamp(char *buf, size_t len) {
    time_t t = time(NULL);
    struct tm *g = gmtime(&t);
    strftime(buf, len, "%Y-%m-%dT%H:%M:%SZ", g);
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        printf("Upotreba: %s <broj_akta> <putanja_pdf> [posiljatelj] [primatelj]\n", argv[0]);
        return EXIT_FAILURE;
    }

    const char *broj_akta = argv[1];
    const char *pdf_path = argv[2];
    const char *posiljatelj = (argc >= 4) ? argv[3] : "Michael Golubičić (Zajednica RUKE)";
    const char *primatelj = (argc >= 5) ? argv[4] : "Općinski sud u Vinkovcima / e-Spis Pretinac";

    char sha256[65];
    char kod[10];
    char timestamp[32];

    izracunaj_sha256(pdf_path, sha256);
    generiraj_kontrolni_kod(sha256, kod);
    dobi_utc_timestamp(timestamp, sizeof(timestamp));

    char url[256];
    snprintf(url, sizeof(url), "https://victorarbor.github.io/njem_ekosustav/index.html?broj=%s&kod=%s", broj_akta, kod);

    char qr_pbm[128];
    snprintf(qr_pbm, sizeof(qr_pbm), "QR_%s.pbm", kod);
    generiraj_pbm_qr(url, qr_pbm);

    char pdf_filename[256];
    const char *base = strrchr(pdf_path, '/');
    snprintf(pdf_filename, sizeof(pdf_filename), "%s", base ? base + 1 : pdf_path);

    // Stvaranje tekstualno-kriptografske e-Potvrde o zaprimanju
    char potvrda_filename[256];
    snprintf(potvrda_filename, sizeof(potvrda_filename), "pdf/potvrda_%s.txt", kod);
    FILE *fpotvrda = fopen(potvrda_filename, "w");
    if (fpotvrda) {
        fprintf(fpotvrda, "=================================================================\n");
        fprintf(fpotvrda, "  ZAJEDNICA RUKE — POTVRDA O ZAPRIMANJU PODNESKA (e-Potvrda)\n");
        fprintf(fpotvrda, "=================================================================\n");
        fprintf(fpotvrda, "Broj akta / Zapisa:  %s\n", broj_akta);
        fprintf(fpotvrda, "Kontrolni broj:      %s\n", kod);
        fprintf(fpotvrda, "Vremenska oznaka:    %s (UTC)\n", timestamp);
        fprintf(fpotvrda, "SHA-256 Podneska:    %s\n", sha256);
        fprintf(fpotvrda, "Pošiljatelj:         %s\n", posiljatelj);
        fprintf(fpotvrda, "Primatelj:           %s\n", primatelj);
        fprintf(fpotvrda, "Izdavatelj potvrde:  Udruga ZAJEDNICA RUKE (OIB: 64517735227)\n");
        fprintf(fpotvrda, "Verifikacijski URL:  %s\n", url);
        fprintf(fpotvrda, "=================================================================\n");
        fclose(fpotvrda);
    }

    // Ažuriranje registar_akata.json
    FILE *fjson = fopen("registar_akata.json", "w");
    if (fjson) {
        fprintf(fjson, "{\n");
        fprintf(fjson, "  \"pravni_subjekt\": {\n");
        fprintf(fjson, "    \"naziv\": \" UDRUGA ZAJEDNICA RUKE\",\n");
        fprintf(fjson, "    \"oib\": \"64517735227\",\n");
        fprintf(fjson, "    \"adresa\": \"Delenšice 11, Zagreb\"\n");
        fprintf(fjson, "  },\n");
        fprintf(fjson, "  \"akti\": [\n");
        fprintf(fjson, "    {\n");
        fprintf(fjson, "      \"broj_akta\": \"%s\",\n", broj_akta);
        fprintf(fjson, "      \"kontrolni_broj\": \"%s\",\n", kod);
        fprintf(fjson, "      \"sha256\": \"%s\",\n", sha256);
        fprintf(fjson, "      \"timestamp\": \"%s\",\n", timestamp);
        fprintf(fjson, "      \"status\": \"ZAPRIMLJENO\",\n");
        fprintf(fjson, "      \"posiljatelj\": \"%s\",\n", posiljatelj);
        fprintf(fjson, "      \"primatelj\": \"%s\",\n", primatelj);
        fprintf(fjson, "      \"pdf_url\": \"pdf/%s\",\n", pdf_filename);
        fprintf(fjson, "      \"potvrda_url\": \"pdf/potvrda_%s.txt\"\n", kod);
        fprintf(fjson, "    }\n");
        fprintf(fjson, "  ]\n");
        fprintf(fjson, "}\n");
        fclose(fjson);
    }

    printf("✅ [C23 POGON] Generiran akt, e-Potvrda i ažuriran pretinac registra.\n");
    return EXIT_SUCCESS;
}
