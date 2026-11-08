#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/mman.h>
#include <errno.h>

int main(void) {
    printf("=== TERMUX JIT DIJAGNOSTIKA ===\n\n");
    
    // TEST 1: RW + write + mprotect RX (PRAVI REDOSLIJED)
    printf("[1] Test RW → write → mprotect RX:\n");
    errno = 0;
    uint32_t* mem = mmap(NULL, 4096, PROT_READ | PROT_WRITE,
                         MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (mem == MAP_FAILED) {
        printf("    ❌ mmap pao (errno=%d)\n", errno);
        return 1;
    }
    printf("    ✅ mmap RW na %p\n", mem);
    
    // PIŠI KOD PRIJE MPROTECT
    mem[0] = 0xD2800560;  // mov x0, #0x2B
    mem[1] = 0xD65F03C0;  // ret
    printf("    ✅ Kôd zapisan: [0]=0x%08X [1]=0x%08X\n", mem[0], mem[1]);
    
    // PROVJERA — čitaj natrag
    if (mem[0] != 0xD2800560) {
        printf("    ❌ Kôd nije zapisan! [0]=0x%08X\n", mem[0]);
        return 1;
    }
    
    // SADA mprotect na RX
    errno = 0;
    if (mprotect(mem, 4096, PROT_READ | PROT_EXEC) != 0) {
        printf("    ❌ mprotect pao (errno=%d)\n", errno);
        return 1;
    }
    printf("    ✅ mprotect RX uspješan\n");
    
    // PROVJERA — čitaj nakon mprotect
    printf("    Kôd nakon mprotect: [0]=0x%08X [1]=0x%08X\n", mem[0], mem[1]);
    
    // IZVRŠI
    printf("    Izvršavam...\n");
    fflush(stdout);
    
    typedef uint64_t (*fn_t)(void);
    fn_t fn = (fn_t)mem;
    uint64_t result = fn();
    
    printf("    ✅ Izvršeno! x0 = 0x%llx (očekivano 0x2B)\n\n", 
           (unsigned long long)result);
    
    munmap(mem, 4096);
    
    printf("=== ZAKLJUČAK ===\n");
    printf("W^X pattern: mmap RW → write → mprotect RX → execute\n");
    printf("RADI! Koristi ovaj pattern za JIT.\n");
    
    return 0;
}
