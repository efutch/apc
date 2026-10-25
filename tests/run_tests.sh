#!/bin/sh
# run_tests.sh - APC regression tests. Run from the repository root: make test
set -u

APC=./apc
fail=0

# Every example except dos.pas (which tests the "identifier too long"
# error on purpose) must compile, assemble and link.
for src in examples/*.pas; do
    case "$src" in examples/dos.pas) continue ;; esac
    if $APC "$src" >/dev/null 2>&1; then
        echo "ok   compile $src"
    else
        echo "FAIL compile $src"
        fail=1
    fi
done

# dos.pas must be rejected.
if $APC examples/dos.pas >/dev/null 2>&1; then
    echo "FAIL examples/dos.pas was accepted"
    fail=1
else
    echo "ok   examples/dos.pas rejected"
fi

# Run tests/gcd.pas through the C harness and check its results.
if $APC tests/gcd.pas >/dev/null 2>&1 &&
   objcopy --redefine-sym main=pascal_main tests/gcd.o tests/gcd_lib.o &&
   gcc -o tests/gcd_test tests/harness.c tests/gcd_lib.o; then
    echo "run  tests/gcd.pas"
    ./tests/gcd_test || fail=1
else
    echo "FAIL build tests/gcd.pas"
    fail=1
fi

if [ $fail -eq 0 ]; then
    echo "All tests passed."
else
    echo "Some tests failed."
fi
exit $fail
