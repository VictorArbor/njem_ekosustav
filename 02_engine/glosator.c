#include <stdint.h>
#include <sys/mman.h>

#define SYS_read  63
#define SYS_write 64
#define SYS_exit  93
#define SYS_mmap  222

static long sys_call(long n, long a, long b, long c, long d, long e, long f) {
    register long x8 __asm__("x8") = n;
    register long x0 __asm__("x0") = a;
    register long x1 __asm__("x1") = b;
    register long x2 __asm__("x2") = c;
    register long x3 __asm__("x3") = d;
    register long x4 __asm__("x4") = e;
    register long x5 __asm__("x5") = f;
    __asm__ volatile("svc 0" : "+r"(x0) : "r"(x8), "r"(x1), "r"(x2), "r"(x3), "r"(x4), "r"(x5));
    return x0;
}

static uint32_t *code_ptr;

static void emit_op(uint32_t op) {
    *code_ptr++ = op;
}

// GLOSATOR :: Izlaz na stdout
static void ispisi(const char *s) {
    long len = 0;
    while (s[len]) len++;
    sys_call(SYS_write, 1, (long)s, len, 0, 0, 0);
}

// DISKRETNI KALKULATOR :: Čisti BNF šum i izvuče čisti hrvatski mnemonik
static const char *diskretni_kalkulator_bnf(const char *line) {
    const char *p = line;
    while (*p) {
        if (p[0] == ':' && p[1] == ':' && p[2] == '=') {
            p += 3;
            while (*p == ' ' || *p == '\t') p++;
            return p;
        }
        p++;
    }
    return line;
}

// GENERATOR BINARNIH UZORAKA :: Prevara Lalator mnemonike izravno u AArch64 silikon
static void pokreni_glosator(const char *input) {
    uint32_t *jit_ram = (uint32_t *)sys_call(SYS_mmap, 0, 8192, 
                                             PROT_READ | PROT_WRITE | PROT_EXEC, 
                                             MAP_ANONYMOUS | MAP_PRIVATE, -1, 0);
    if ((long)jit_ram < 0) return;

    code_ptr = jit_ram;

    // Alokacija stoga (512B) na X10
    emit_op(0xD10803FF); // SUB SP, SP, #512
    emit_op(0x910003EA); // ADD X10, SP, #0

    const char *p = input;
    while (*p) {
        while (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r') p++;
        if (!*p) break;

        char line[512];
        int li = 0;
        while (*p && *p != '\n' && *p != '\r' && li < 511) {
            line[li++] = *p++;
        }
        line[li] = 0;

        // Lalator traži čisti mnemonik preko Diskretnog kalkulatora
        const char *mnemonik = diskretni_kalkulator_bnf(line);
        while (*mnemonik == ' ' || *mnemonik == '\t') mnemonik++;

        // 1. GENERATOR UZORKA: mkm r10
        if (mnemonik[0] == 'm' && mnemonik[1] == 'k' && mnemonik[2] == 'm') {
            continue;
        }

        // 2. GENERATOR UZORKA: wrt 1, "..."
        if (mnemonik[0] == 'w' && mnemonik[1] == 'r' && mnemonik[2] == 't') {
            const char *cp = mnemonik + 3;
            while (*cp && *cp != '"') cp++;
            if (*cp == '"') {
                cp++;
                int off = 0;
                while (*cp && *cp != '"') {
                    char c = *cp++;
                    if (c == '\\' && *cp == 'n') { c = '\n'; cp++; }
                    
                    // DISKRETNI KALKULATOR :: Automatski unos bajta na stog
                    emit_op(0xD2800000 | (((uint32_t)c & 0xFF) << 5) | 0);          // MOV X0, #ascii
                    emit_op(0x39000000 | ((off & 0xFFF) << 10) | (10 << 5) | 0);    // STRB W0, [X10, #off]
                    off++;
                }
                // GENERATOR UZORAKA :: Nativni SYS_write (#64)
                emit_op(0xD2800020);                                           // MOV X0, #1
                emit_op(0x91000141);                                           // ADD X1, X10, #0
                emit_op(0xD2800002 | (((uint32_t)off & 0xFFFF) << 5));          // MOV X2, #off
                emit_op(0xD2800808);                                           // MOV X8, #64
                emit_op(0xD4000001);                                           // SVC #0
            }
            continue;
        }

        // 3. GENERATOR UZORKA: pir
        if (mnemonik[0] == 'p' && mnemonik[1] == 'i' && mnemonik[2] == 'r') {
            emit_op(0x910803FF); // ADD SP, SP, #512
            emit_op(0xD65F03C0); // RET
            break;
        }
    }

    // IZRAVNO POKRETANJE DOKAZA NA SILIKONU
    typedef void (*glosator_fn)(void);
    glosator_fn pokreni = (glosator_fn)jit_ram;
    pokreni();
}

void _start(void) {
    char buffer[4096];
    long total = 0;
    while (total < sizeof(buffer) - 1) {
        long n = sys_call(SYS_read, 0, (long)(buffer + total), sizeof(buffer) - 1 - total, 0, 0, 0);
        if (n <= 0) break;
        total += n;
    }
    buffer[total] = 0;

    if (total > 0) {
        pokreni_glosator(buffer);
    }
    sys_call(SYS_exit, 0, 0, 0, 0, 0, 0);
}
