#include <stdint.h>
#include <sys/mman.h>

#define SYS_read      63
#define SYS_write     64
#define SYS_exit      93
#define SYS_mmap      222
#define SYS_mprotect  226

#define EXEC_MEM_SIZE 65536

static uint32_t *JIT_MEM = 0;
static int JIT_PC = 0;

__attribute__((no_builtin("strlen")))
unsigned long strlen(const char *s) {
    unsigned long l = 0; while (s[l]) l++; return l;
}

static long sys_call(long n, long a, long b, long c, long d, long e, long f) {
    register long x8 __asm__("x8") = n, x0 __asm__("x0") = a, x1 __asm__("x1") = b;
    register long x2 __asm__("x2") = c, x3 __asm__("x3") = d, x4 __asm__("x4") = e, x5 __asm__("x5") = f;
    __asm__ volatile("svc 0" : "+r"(x0) : "r"(x8), "r"(x1), "r"(x2), "r"(x3), "r"(x4), "r"(x5));
    return x0;
}

static void print(const char *s) { sys_call(SYS_write, 1, (long)s, strlen(s), 0, 0, 0); }

static void print_num(uint64_t n) {
    if(n == 0) { print("0"); return; }
    char buf[24]; int i = 22; buf[23] = 0;
    while(n > 0) { buf[i--] = '0' + (n % 10); n /= 10; }
    print(&buf[i + 1]);
}

static void print_hex32(uint32_t val) {
    const char hex[] = "0123456789ABCDEF";
    char buf[9]; buf[8] = 0;
    for (int i = 7; i >= 0; i--) { buf[i] = hex[val & 0xF]; val >>= 4; }
    print(buf);
}

static int str_contains(const char *str, const char *sub) {
    int i = 0;
    while(str[i]) {
        int j = 0;
        while(sub[j] && str[i + j] == sub[j]) j++;
        if(!sub[j]) return 1;
        i++;
    }
    return 0;
}

static void init_jit(void) {
    if (JIT_MEM != 0) return;
    long addr = sys_call(SYS_mmap, 0, EXEC_MEM_SIZE, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (addr > 0) JIT_MEM = (uint32_t *)addr;
}

static void emit_op(uint32_t op, const char *mnem) {
    if (!JIT_MEM) init_jit();
    JIT_MEM[JIT_PC++] = op;
    print(" ⚡ [JIT EMIT] "); print(mnem); print(" ──► Opcode: 0x"); print_hex32(op); print("\n");
}

static void exec_jit(void) {
    if (!JIT_MEM || JIT_PC == 0) return;

    // Direct ISB synchronization (User-space safe)
    __asm__ volatile("isb\n" ::: "memory");

    print(" 🚀 Izvršavam generirani LSBU blok iz RAM-a...\n");
    typedef uint64_t (*jit_func_t)(void);
    jit_func_t fn = (jit_func_t)JIT_MEM;
    uint64_t res = fn();
    print(" ✅ [EXEC OK] Odaziv registra r0/x0 = "); print_num(res); print("\n\n");
    JIT_PC = 0;
}

static void parse_lsbu_line(char *cmd) {
    while(*cmd == ' ' || *cmd == '\t') cmd++;
    if (*cmd == '#' || *cmd == 0) return;

    if (str_contains(cmd, "pis")) emit_op(0x8A010002, "pis (A ∩ B)");
    else if (str_contains(cmd, "uis")) emit_op(0xAA010002, "uis (A ∪ B)");
    else if (str_contains(cmd, "ris")) emit_op(0x8A210002, "ris (A \\ B)");
    else if (str_contains(cmd, "srs")) emit_op(0xCA010002, "srs (A △ B)");
    else if (str_contains(cmd, "nve")) emit_op(0xD2800800, "nve (MOV r0, #0x40)");
    else if (str_contains(cmd, "vps")) emit_op(0x4E211C02, "vps (VAND)");
    else if (str_contains(cmd, "vus")) emit_op(0x4EA11C02, "vus (VORR)");
    else if (str_contains(cmd, "vrs")) emit_op(0x4E611C02, "vrs (VBIC)");
    else if (str_contains(cmd, "vss")) emit_op(0x6E211C02, "vss (VEOR)");
    else if (str_contains(cmd, "nno")) emit_op(0xD503201F, "nno (NOP)");
    else if (str_contains(cmd, "bar")) emit_op(0xD503201F, "bar (User-space NOP Barrier)");
    else if (str_contains(cmd, "pir") || str_contains(cmd, "pps") || str_contains(cmd, "pos")) {
        emit_op(0xD65F03C0, "pir (RET)");
        exec_jit();
    }
}

void _start(void) {
    init_jit();
    print("╔═══════════════════════════════════════════════════════════════╗\n");
    print("║  NJM-OS :: PIJETAO v6.2 (STABILNI USER-SPACE JIT ENGINE)      ║\n");
    print("╚═══════════════════════════════════════════════════════════════╝\n\n");

    char buf[1024]; int len = 0;
    char c;
    while(1) {
        long n = sys_call(SYS_read, 0, (long)&c, 1, 0, 0, 0);
        if(n <= 0) break;
        if(c == '\n' || c == '\r') {
            buf[len] = 0;
            if(len > 0) parse_lsbu_line(buf);
            len = 0;
        } else if(len < 1000) {
            buf[len++] = c;
        }
    }
    sys_call(SYS_exit, 0, 0, 0, 0, 0, 0);
}
