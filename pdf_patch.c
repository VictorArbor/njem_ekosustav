#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#define SRC "napravi_offline_app.c"
#define TMP "napravi_offline_app.c.patched"
#define BAK "napravi_offline_app.c.backup"

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

int main(void) {
    long len = 0;
    char *buf = read_all(SRC, &len);
    if (!buf) return EXIT_FAILURE;

    if (strstr(buf, "pdf-lib.min.js")) {
        printf("[SKIP] pdf-lib je već ugrađen.\n");
        free(buf);
        return 2;
    }

    const char *anchor = "fprintf(fhtml, \"</head>\\n\");";
    char *pos = strstr(buf, anchor);

    if (!pos) {
        fprintf(stderr, "[ERR] Anchor nije nađen. Provjerite kod.\n");
        free(buf);
        return EXIT_FAILURE;
    }
    printf("[OK] Anchor nađen na poziciji %ld.\n", (long)(pos - buf));

    const char *injection =
        "    fprintf(fhtml, \"    <!-- pdf-lib i qrious -->\\n\");\n"
        "    fprintf(fhtml, \"    <script src=\\\"https://cdnjs.cloudflare.com/ajax/libs/pdf-lib/1.17.1/pdf-lib.min.js\\\"></script>\\n\");\n"
        "    fprintf(fhtml, \"    <script src=\\\"https://cdnjs.cloudflare.com/ajax/libs/qrious/4.0.2/qrious.min.js\\\"></script>\\n\");\n";

    size_t pre       = (size_t)(pos - buf);
    size_t inj_len   = strlen(injection);
    size_t tail_len  = strlen(pos);

    char *out = malloc(pre + inj_len + tail_len + 1);
    if (!out) { free(buf); return EXIT_FAILURE; }

    memcpy(out,             buf,     pre);
    memcpy(out + pre,       injection, inj_len);
    memcpy(out + pre + inj_len, pos, tail_len + 1);

    free(buf);

    // Backup
    {
        FILE *src = fopen(SRC, "rb");
        FILE *dst = fopen(BAK, "wb");
        if (src && dst) {
            char tmp[4096];
            size_t r;
            while ((r = fread(tmp, 1, sizeof(tmp), src)) > 0)
                fwrite(tmp, 1, r, dst);
        }
        if (src) fclose(src);
        if (dst) fclose(dst);
        printf("[OK] Backup spremljen: %s\n", BAK);
    }

    if (!write_all(TMP, out)) {
        fprintf(stderr, "[ERR] Ne mogu pisati %s\n", TMP);
        free(out);
        return EXIT_FAILURE;
    }
    free(out);

    if (rename(TMP, SRC) != 0) {
        perror("[ERR] rename");
        return EXIT_FAILURE;
    }

    printf("[OK] pdf-lib i qrious uspješno ugrađeni u %s.\n", SRC);
    return EXIT_SUCCESS;
}
