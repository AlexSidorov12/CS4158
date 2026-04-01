# CS4158 JIBUC - Part 2 (Parser)

## What it does
- Parses a JIBUC program with **Bison**.
- Performs semantic checks during parsing:
  - Using an identifier that was **not declared**.
  - Assigning an integer that **does not fit** in the target variable’s capacity.
  - Emits a **warning** when moving/adding from an identifier with a **larger capacity** into one with a **smaller capacity**.

At the end it prints either:
- `Program is well-formed`
- `Program is not well-formed`

It also prints `Warnings: N` when applicable.

## Files
- `parser.y`
- `lexer_parser.l`

## Build
```bash
bison -d parser.y
flex -o lexer_parser.yy.c lexer_parser.l
gcc parser.tab.c lexer_parser.yy.c -o parser_part2 -lfl
```

## Run
```bash
./parser_part2 < your_program.jibuc
```
