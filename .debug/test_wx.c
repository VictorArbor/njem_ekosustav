#define _GNU_SOURCE
#include <stdio.h>
#include <sys/mman.h>
#include <errno.h>
#include <string.h>

int main(void) {
    // Test 1: RWX
    errno = 0;
    void* p1 = mmap(NULL, 4096, PROT_READ | PROT_WRITE | PROT_EXEC,
                    MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    printf("RWX mmap: %p (errno=%d: %s)\n", p1, errno, strerror(errno));
    
    // Test 2: RW, pa mprotect na RX
    errno = 0;
    void* p2 = mmap(NULL, 4096, PROT_READ | PROT_WRITE,
                    MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    printf("RW mmap:  %p (errno=%d: %s)\n", p2, errno, strerror(errno));
    
    errno = 0;
    int rc = mprotect(p2, 4096, PROT_READ | PROT_EXEC);
    printf("mprotect RX: rc=%d errno=%d: %s\n", rc, errno, strerror(errno));
    
    // Test 3: Može li se izvršiti kôd?
    if (rc == 0) {
        // NOP, NOP, RET
        uint32_t* code = (uint32_t*)p2;
        code[0] = 0xD503201F;  // NOP
        code[1] = 0xD503201F;  // NOP
        code[2] = 0xD65F03C0;  // RET
        
        // Sad je RX, ne možemo pisati... ali već smo pisali prije mprotect
        // Ovo je test samo za mprotect
        
        typedef void (*fn_t)(void);
        fn_t fn = (fn_t)p2;
        printf("Pokušavam izvršiti RX memoriju...\n");
        fflush(stdout);
        fn();
        printf("✅ RX izvršavanje USPJEŠNO!\n");
    }
    
    return 0;
}
