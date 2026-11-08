#include <stdint.h>
#include <sys/mman.h>

#define SYS_read  63
#define SYS_write 64
#define SYS_exit  93
#define SYS_mmap  222

// Direct AArch64 Syscall Wrapper
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

static void ispisi(const char *s) {
    long len = 0;
    while (s[len]) len++;
    sys_call(SYS_write, 1, (long)s, len, 0, 0, 0);
}

// JIT Emitent u izvršni RAM
static uint32_t *code_ptr;

static void emit_op(uint32_t op) {
    *code_ptr++ = op;
}

static void evaluiraj_i_izvrsi_jit(const char *input) {
    // Alokacija 4KB RWX memorijskog bloka za direktno izvođenje
    uint32_t *jit_buffer = (uint32_t *)sys_call(SYS_mmap, 0, 4096, 
                                                PROT_READ | PROT_WRITE | PROT_EXEC, 
                                                MAP_ANONYMOUS | MAP_PRIVATE, -1, 0);
    if ((long)jit_buffer < 0) {
        ispisi("⚠️ Greška alokacije JIT RAM bloka!\r\n");
        return;
    }

    code_ptr = jit_buffer;

    // Prolog: Alokacija 512B stoga (SUB SP, SP, #512; ADD X10, SP, #0)
    emit_op(0xD10803FF);
    emit_op(0x910003EA);

    const char *p = input;
    while (*p) {
        while (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r' || *p == ';') p++;
        if (!*p) break;

        // HIGH-LEVEL STRING EVALUATOR: wrt fd, "tekst"
        if (p[0] == 'w' && p[1] == 'r' && p[2] == 't') {
            p += 3;
            while (*p && *p != '"') p++;
            if (*p == '"') {
                p++; // Preskoči otvoren navodnik
                int off = 0;
                while (*p && *p != '"') {
                    char c = *p++;
                    if (c == '\\' && *p) {
                        if (*p == 'n') { c = '\n'; p++; }
                        else if (*p == 'r') { c = '\r'; p++; }
                        else if (*p == 't') { c = '\t'; p++; }
                    }
                    // MOV X0, #ascii; STRB W0, [X10, #off]
                    emit_op(0xD2800000 | (((uint32_t)c & 0xFFFF) << 5) | 0);
                    emit_op(0x39000000 | ((off & 0xFFF) << 10) | (10 << 5) | 0);
                    off++;
                }
                if (*p == '"') p++;
                // MOV X0, #1; ADD X1, X10, #0; MOV X2, #off; MOV X8, #64; SVC #0
                emit_op(0xD2800020);
                emit_op(0x91000141);
                emit_op(0xD2800002 | (((uint32_t)off & 0xFFFF) << 5));
                emit_op(0xD2800808);
                emit_op(0xD4000001);
            }
            continue;
        }

        // NATIVNI MNEMONIK: pir
        if (p[0] == 'p' && p[1] == 'i' && p[2] == 'r') {
            // Epilog: ADD SP, SP, #512; RET (0xD65F03C0)
            emit_op(0x910803FF);
            emit_op(0xD65F03C0);
            break;
        }

        p++;
    }

    // IZRAVNI SKOK NA SILIKON (JIT Execution)
    typedef void (*jit_func_t)(void);
    jit_func_t fn = (jit_func_t)jit_buffer;
    fn(); // Poziv strojnog koda izravno iz RAM-a!
}

void _start(void) {
    char buffer[2048];
    long n = sys_call(SYS_read, 0, (long)buffer, sizeof(buffer) - 1, 0, 0, 0);
    if (n > 0) {
        buffer[n] = 0;
        evaluiraj_i_izvrsi_jit(buffer);
    }
    sys_call(SYS_exit, 0, 0, 0, 0, 0, 0);
}
