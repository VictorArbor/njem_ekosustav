#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#define SRC "napravi_offline_app.c"

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

static int count_occ(const char *hay, const char *needle) {
    if (!needle || !*needle) return 0;
    int c = 0;
    size_t nl = strlen(needle);
    const char *p = hay;
    while ((p = strstr(p, needle))) { c++; p += nl; }
    return c;
}

int main(void) {
    long len = 0;
    char *buf = read_all(SRC, &len);
    if (!buf) {
        fprintf(stderr, "[ERR] Ne mogu otvoriti %s\n", SRC);
        return EXIT_FAILURE;
    }

    printf("============================================\n");
    printf(" DIJAGNOSTIKA: %s\n", SRC);
    printf("============================================\n");
    printf(" Veličina: %ld bajtova\n\n", len);

    printf("[1] Prisutnost markera:\n");
    printf("  %-40s : %s\n", "pdf-lib.min.js", strstr(buf, "pdf-lib.min.js") ? "DA" : "NE");
    printf("  %-40s : %s\n", "qrious.min.js", strstr(buf, "qrious.min.js") ? "DA" : "NE");
    printf("  %-40s : %s\n", "logo_bst.png", strstr(buf, "logo_bst.png") ? "DA" : "NE");

    printf("\n[2] Brojevi pojava:\n");
    printf("  %-40s : %d\n", "ispisi_grb_zajednica(fhtml)", count_occ(buf, "ispisi_grb_zajednica(fhtml)"));
    printf("  %-40s : %d\n", "ispisi_grb_bst(fhtml)", count_occ(buf, "ispisi_grb_bst(fhtml)"));

    free(buf);
    printf("============================================\n");
    return EXIT_SUCCESS;
}
