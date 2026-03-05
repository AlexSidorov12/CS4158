#!/bin/bash
# Run all 3 JIBUC lexer tests; diff output against .expected files

set -e
cd "$(dirname "$0")"

echo "Building lexer..."
flex lexer.l && gcc lex.yy.c -o lexer

failed=0
for f in test1_minimal test2_all_tokens test3_semicolon; do
    echo -n "Test $f ... "
    ./lexer < "${f}.jibuc" > "${f}.out" 2>&1
    if diff -q "${f}.expected" "${f}.out" > /dev/null 2>&1; then
        echo "PASS"
    else
        echo "FAIL"
        diff "${f}.expected" "${f}.out" || true
        failed=1
    fi
done

[ $failed -eq 0 ] && echo "All tests passed." || exit 1
