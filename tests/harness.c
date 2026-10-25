/* harness.c - runs a compiled APC program and checks its globals.
 *
 * Pascal-A has no output statements, so tests report results through
 * global variables. run_tests.sh renames the program's main() to
 * pascal_main() and links it with this file.
 */
#include <stdio.h>

void pascal_main(void);

/* Globals from tests/gcd.pas (APC upper-cases identifiers) */
extern int PROCRESULT, FUNCRESULT, MIXRESULT, NESTRESULT;

static int failures = 0;

static void expect(const char *what, int got, int want)
{
    if (got == want)
        printf("  ok   %s = %d\n", what, got);
    else {
        printf("  FAIL %s = %d, expected %d\n", what, got, want);
        failures++;
    }
}

int main(void)
{
    pascal_main();
    expect("GCD(48,18) via procedure", PROCRESULT, 6);
    expect("GCD2(1071,462) via function", FUNCRESULT, 21);
    expect("Combine(1,2,3) with two parameter groups", MIXRESULT, 123);
    expect("GCD2(Combine(0,4,8), GCD2(36,24)) nested calls", NESTRESULT, 12);
    return failures != 0;
}
