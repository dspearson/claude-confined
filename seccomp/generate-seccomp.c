/*
 * generate-seccomp.c - Generate seccomp BPF filter for bubblewrap
 *
 * Compile with: gcc -o generate-seccomp generate-seccomp.c -lseccomp
 * Usage: ./generate-seccomp > filter.bpf
 */

#include <stdio.h>
#include <stdlib.h>
#include <seccomp.h>
#include <errno.h>
#include <string.h>

/* List of dangerous syscalls to block */
static const char *blocked_syscalls[] = {
    /* Kernel module operations */
    "init_module",
    "finit_module",
    "delete_module",

    /* System control */
    "reboot",
    "kexec_load",
    "kexec_file_load",

    /* Time manipulation */
    "clock_settime",
    "settimeofday",
    "stime",
    "clock_adjtime",
    "adjtimex",

    /* Process debugging */
    "ptrace",

    /* Personality changes */
    "personality",

    /* Kernel keyring */
    "keyctl",
    "add_key",
    "request_key",

    /* BPF operations */
    "bpf",

    /* Performance monitoring */
    "perf_event_open",

    /* Namespace manipulation (already sandboxed) */
    "unshare",
    "setns",

    /* Mount operations */
    "mount",
    "umount2",
    "umount",
    "pivot_root",
    "swapon",
    "swapoff",

    /* Process accounting */
    "acct",

    /* I/O port access */
    "iopl",
    "ioperm",

    /* Dangerous memory operations */
    "lookup_dcookie",
    "vmsplice",
    "process_vm_readv",
    "process_vm_writev",

    /* Quota operations */
    "quotactl",

    /* User namespace operations */
    "userfaultfd",

    /* Process comparison */
    "kcmp",

    NULL
};

int main(void) {
    scmp_filter_ctx ctx;
    int rc;
    size_t i;

    /* Create filter with default action ALLOW */
    ctx = seccomp_init(SCMP_ACT_ALLOW);
    if (ctx == NULL) {
        fprintf(stderr, "Error: seccomp_init failed\n");
        return 1;
    }

    /* Add architectures */
    rc = seccomp_arch_add(ctx, SCMP_ARCH_X86_64);
    if (rc < 0 && rc != -EEXIST) {
        fprintf(stderr, "Warning: Failed to add x86_64 arch: %s\n", strerror(-rc));
    }

    rc = seccomp_arch_add(ctx, SCMP_ARCH_X86);
    if (rc < 0 && rc != -EEXIST) {
        fprintf(stderr, "Warning: Failed to add x86 arch: %s\n", strerror(-rc));
    }

    rc = seccomp_arch_add(ctx, SCMP_ARCH_X32);
    if (rc < 0 && rc != -EEXIST) {
        fprintf(stderr, "Warning: Failed to add x32 arch: %s\n", strerror(-rc));
    }

    /* Block dangerous syscalls */
    for (i = 0; blocked_syscalls[i] != NULL; i++) {
        int syscall_nr = seccomp_syscall_resolve_name(blocked_syscalls[i]);

        /* Skip if syscall doesn't exist on this architecture */
        if (syscall_nr == __NR_SCMP_ERROR) {
            continue;
        }

        rc = seccomp_rule_add(ctx, SCMP_ACT_ERRNO(EPERM), syscall_nr, 0);
        if (rc < 0) {
            fprintf(stderr, "Warning: Failed to add rule for %s: %s\n",
                    blocked_syscalls[i], strerror(-rc));
        }
    }

    /* Export as BPF bytecode to stdout */
    rc = seccomp_export_bpf(ctx, 1);  /* 1 = stdout */
    if (rc < 0) {
        fprintf(stderr, "Error: seccomp_export_bpf failed: %s\n", strerror(-rc));
        seccomp_release(ctx);
        return 1;
    }

    seccomp_release(ctx);
    return 0;
}
