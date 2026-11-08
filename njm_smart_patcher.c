/* ============================================================================
 *  njm_smart_patcher.c — C23 idempotentni patcher
 *  1. Ugrađuje ispisi_grb_zajednica/bst() ako ne postoje
 *  2. Zamjenjuje #define PRINT_LOGO s PRINT_GRB_ZAJEDNICA/PRINT_GRB_BST
 *  3. Zamjenjuje 1.-2. poziv PRINT_LOGO → PRINT_GRB_ZAJEDNICA
 *                   3.-4. poziv PRINT_LOGO → PRINT_GRB_BST
 *  4. Ugrađuje pdf-lib i qrious unutar "<head>\n" C stringa
 *
 *  Exit code: 0 = uspjeh, 1 = greška, 2 = ništa nije promijenjeno
 * ============================================================================ */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#define SRC "napravi_offline_app.c"
#define TMP "napravi_offline_app.c.tmp"

static char *read_all(const char *p, long *n) {
    FILE *f = fopen(p, "rb");
    if (!f) { perror(p); return NULL; }
    if (fseek(f, 0, SEEK_END)) { fclose(f); return NULL; }
    long len = ftell(f);
    if (len < 0) { fclose(f); return NULL; }
    rewind(f);
    char *b = malloc((size_t)len + 1);
    if (!b) { fclose(f); return NULL; }
    size_t r = fread(b, 1, (size_t)len, f);
    fclose(f);
    b[r] = '\0';
    if (n) *n = (long)r;
    return b;
}

static bool write_all(const char *p, const char *d) {
    FILE *f = fopen(p, "wb");
    if (!f) { perror(p); return false; }
    size_t n = strlen(d);
    bool ok = (fwrite(d, 1, n, f) == n);
    fclose(f);
    return ok;
}

static int count(const char *hay, const char *needle) {
    int c = 0;
    size_t nl = strlen(needle);
    const char *p = hay;
    while ((p = strstr(p, needle))) { c++; p += nl; }
    return c;
}

/* Buffer builder */
typedef struct { char *buf; size_t len, cap; } sb_t;

static bool sb_init(sb_t *s, size_t cap) {
    s->buf = malloc(cap);
    if (!s->buf) return false;
    s->buf[0] = '\0';
    s->len = 0;
    s->cap = cap;
    return true;
}
static bool sb_append(sb_t *s, const char *src, size_t n) {
    if (s->len + n + 1 > s->cap) {
        size_t nc = s->cap * 2;
        while (nc < s->len + n + 1) nc *= 2;
        char *nb = realloc(s->buf, nc);
        if (!nb) return false;
        s->buf = nb;
        s->cap = nc;
    }
    memcpy(s->buf + s->len, src, n);
    s->len += n;
    s->buf[s->len] = '\0';
    return true;
}
static bool sb_appends(sb_t *s, const char *src) {
    return sb_append(s, src, strlen(src));
}

/* Faza 1: definicije funkcija prije main() */
static int patch_defs(char **pbuf, long *plen) {
    char *buf = *pbuf;
    if (strstr(buf, "void ispisi_grb_zajednica")) {
        printf("[P1] Definicije već postoje.\n");
        return 0;
    }
    char *mp = strstr(buf, "int main(void)");
    if (!mp) { fprintf(stderr, "[P1 ERR] nema main()\n"); return -1; }

    const char *funcs =
        "void ispisi_grb_zajednica(FILE *fhtml) {\n"
        "    fprintf(fhtml, \"    <div class=\\\"logo-header\\\">\\n\");\n"
        "    fprintf(fhtml, \"        <img src=\\\"logo.png\\\" alt=\\\"Zajednica RUKE Grb\\\">\\n\");\n"
        "    fprintf(fhtml, \"        <div style=\\\"font-size:16px;font-weight:bold;color:#2c3e50;margin-top:8px;\\\">Zajednica RUKE</div>\\n\");\n"
        "    fprintf(fhtml, \"        <div style=\\\"font-size:11px;color:#7f8c8d;\\\">OIB: 64517735227 \\xE2\\x80\\xA2 Zagreb</div>\\n\");\n"
        "    fprintf(fhtml, \"    </div>\\n\");\n"
        "}\n\n"
        "void ispisi_grb_bst(FILE *fhtml) {\n"
        "    fprintf(fhtml, \"    <div class=\\\"logo-header\\\">\\n\");\n"
        "    fprintf(fhtml, \"        <img src=\\\"logo_bst.png\\\" alt=\\\"BST Hipostazološki Pečat\\\" style=\\\"width:90px;height:90px;border-radius:50%%;box-shadow:0 4px 12px rgba(0,0,0,0.15);object-fit:cover;display:block;margin:0 auto;border:3px solid #f39c12;\\\">\\n\");\n"
        "    fprintf(fhtml, \"        <div style=\\\"font-size:16px;font-weight:bold;color:#2c3e50;margin-top:8px;\\\">ANUH \\xE2\\x80\\xA2 Hipostazologija &amp; Zadružno Poduzetništvo</div>\\n\");\n"
        "    fprintf(fhtml, \"        <div style=\\\"font-size:11px;color:#7f8c8d;\\\">Fraktalni Meta-Ontološki Sustav \\xE2\\x80\\xA2 Županja</div>\\n\");\n"
        "    fprintf(fhtml, \"    </div>\\n\");\n"
        "}\n\n";

    size_t pre = (size_t)(mp - buf);
    sb_t sb;
    if (!sb_init(&sb, (size_t)*plen + strlen(funcs) + 64)) return -1;
    sb_append(&sb, buf, pre);
    sb_appends(&sb, funcs);
    sb_appends(&sb, mp);
    free(buf);
    *pbuf = sb.buf;
    *plen = (long)sb.len;
    printf("[P1] Definicije ugrađene.\n");
    return 1;
}

/* Faza 2: zamjena #define PRINT_LOGO i poziva */
static int patch_macros(char **pbuf, long *plen) {
    char *buf = *pbuf;
    if (strstr(buf, "PRINT_GRB_ZAJEDNICA")) {
        printf("[P2] Makroi već zamijenjeni.\n");
        return 0;
    }
    int logo = count(buf, "PRINT_LOGO");
    if (logo == 0) {
        printf("[P2] Nema PRINT_LOGO — preskačem.\n");
        return 0;
    }
    if (logo < 3) {
        fprintf(stderr, "[P2 WARN] Samo %d PRINT_LOGO — nastavljam ali sumnjivo.\n", logo);
    }

    sb_t sb;
    if (!sb_init(&sb, (size_t)*plen * 2 + 1024)) return -1;

    const char *needle = "PRINT_LOGO";
    size_t nl = strlen(needle);
    const char *cursor = buf;
    const char *found;
    int idx = 0;

    while ((found = strstr(cursor, needle))) {
        sb_append(&sb, cursor, (size_t)(found - cursor));

        /* je li #define? */
        bool is_define = false;
        const char *ls = found;
        while (ls > buf && *(ls-1) != '\n') ls--;
        if (*ls == '#') is_define = true;

        if (is_define) {
            /* Zamijeni cijeli #define blok: od 'found' do \n\n */
            const char *end = found;
            while (*end && !(*end == '\n' && *(end+1) == '\n')) end++;
            const char *repl =
                "#define PRINT_GRB_ZAJEDNICA do { ispisi_grb_zajednica(fhtml); } while (0)\n"
                "#define PRINT_GRB_BST        do { ispisi_grb_bst(fhtml); } while (0)\n";
            sb_appends(&sb, repl);
            cursor = end;
            printf("[P2] #define zamijenjen.\n");
            continue;
        }
        idx++;
        const char *repl = (idx <= 2) ? "PRINT_GRB_ZAJEDNICA" : "PRINT_GRB_BST";
        sb_appends(&sb, repl);
        printf("[P2] Poziv #%d → %s\n", idx, repl);
        cursor = found + nl;
    }
    sb_appends(&sb, cursor);
    free(buf);
    *pbuf = sb.buf;
    *plen = (long)sb.len;
    return 1;
}

/* Faza 3: pdf-lib i qrious u <head> */
static int patch_pdf(char **pbuf, long *plen) {
    char *buf = *pbuf;
    if (strstr(buf, "pdf-lib.min.js")) {
        printf("[P3] pdf-lib već ugrađen.\n");
        return 0;
    }

    /* Traži: fprintf(fhtml, "<head>\n");
     * U izvoru: "\"<head>\\n\"" — s literalnim backslash-n.
     * Ali možda je formatiran drukčije. Tražimo fleksibilno:
     * nailazimo na "<head>" pa gledamo što je nakon. */
    const char *anchor = "\"<head>\\n\"";
    char *pos = strstr(buf, anchor);
    if (!pos) {
        fprintf(stderr, "[P3 ERR] ne nalazim '\"<head>\\\\n\"' — provjeri grep '\"<head>' %s\n", SRC);
        return -1;
    }

    /* Ubacujemo C-konkatenacijom: "..." "..." "..." */
    const char *inject =
        "\\n\"\n"
        "        \"    <!-- pdf-lib i qrious -->\\n\"\n"
        "        \"    <script src=\\\"https://cdnjs.cloudflare.com/ajax/libs/pdf-lib/1.17.1/pdf-lib.min.js\\\"></script>\\n\"\n"
        "        \"    <script src=\\\"https://cdnjs.cloudflare.com/ajax/libs/qrious/4.0.2/qrious.min.js\\\"></script>\\n\"\n"
        "        \"";

    size_t insert_at = (size_t)(pos - buf) + strlen(anchor);

    sb_t sb;
    if (!sb_init(&sb, (size_t)*plen + strlen(inject) + 64)) return -1;
    sb_append(&sb, buf, insert_at);
    sb_appends(&sb, inject);
    sb_appends(&sb, buf + insert_at);
    free(buf);
    *pbuf = sb.buf;
    *plen = (long)sb.len;
    printf("[P3] pdf-lib i qrious ugrađeni.\n");
    return 1;
}

int main(void) {
    long len = 0;
    char *buf = read_all(SRC, &len);
    if (!buf) return 1;

    int total = 0;
    int r;
    if ((r = patch_defs(&buf, &len)) < 0) { free(buf); return 1; }
    total += r;

    if ((r = patch_macros(&buf, &len)) < 0) { free(buf); return 1; }
    total += r;

    if ((r = patch_pdf(&buf, &len)) < 0) { free(buf); return 1; }
    total += r;

    if (total == 0) {
        printf("[PATCHER] Ništa nije promijenjeno.\n");
        free(buf);
        return 2;
    }

    if (!write_all(TMP, buf)) { free(buf); return 1; }
    free(buf);

    if (rename(TMP, SRC)) { perror("rename"); return 1; }
    printf("[PATCHER] Ukupno faza promijenjeno: %d\n", total);
    return 0;
}
