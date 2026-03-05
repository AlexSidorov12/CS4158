#!/bin/bash
# Run all 3 JIBUC lexer tests

set -e
cd "$(dirname "$0")"

if [ ! -f ./lexer ]; then
    echo "Building lexer..."
    flex lexer.l && gcc lex.yy.c -o lexer
fi

for f in test1_minimal.jibuc test2_all_tokens.jibuc test3_semicolon.jibuc; do
    echo "========== $f =========="
    ./lexer < "$f"
    echo
done
