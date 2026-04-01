%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

extern int yylex(void);
extern int yylineno;

static int syntax_errors = 0;
static int semantic_errors = 0;
static int semantic_warnings = 0;

typedef struct {
    char *name;     // normalized identifier (upper-case)
    int digits;    // number of X's => capacity digits
} Symbol;

#define MAX_SYMBOLS 1024
static Symbol symtab[MAX_SYMBOLS];
static int symcount = 0;

static int lookup_digits(const char *name) {
    for (int i = 0; i < symcount; i++) {
        if (strcmp(symtab[i].name, name) == 0) return symtab[i].digits;
    }
    return -1;
}

static int declare_symbol(const char *name, int digits) {
    if (lookup_digits(name) >= 0) {
        fprintf(stderr, "SEMANTIC ERROR (line %d): variable '%s' redeclared\n", yylineno, name);
        semantic_errors++;
        return 0;
    }
    if (symcount >= MAX_SYMBOLS) {
        fprintf(stderr, "SEMANTIC ERROR: symbol table full\n");
        semantic_errors++;
        return 0;
    }

    symtab[symcount].name = strdup(name);
    symtab[symcount].digits = digits;
    symcount++;
    return 1;
}

static long long max_value_for_digits(int digits) {
    // capacity is interpreted as “up to digits decimal digits” => 10^digits - 1
    if (digits <= 0) return 0;

    long long max = 1;
    for (int i = 0; i < digits; i++) {
        if (max > LLONG_MAX / 10) return LLONG_MAX;
        max *= 10;
    }
    return max - 1;
}

#ifndef JIBUC_VALUE_DEFINED
#define JIBUC_VALUE_DEFINED
typedef struct {
    int kind;        // 0 = integer literal, 1 = identifier
    long long ival; // when kind==0
    char *ident;    // when kind==1
    int digits;     // capacity digits when kind==1, or -1
} Value;
#endif

static Value make_int(long long v) {
    Value x;
    x.kind = 0;
    x.ival = v;
    x.ident = NULL;
    x.digits = -1;
    return x;
}

static Value make_ident(char *id) {
    Value x;
    x.kind = 1;
    x.ival = 0;
    x.ident = id;
    x.digits = lookup_digits(id);
    return x;
}

static void check_assignment(Value v, const char *dest, int is_add) {
    int destDigits = lookup_digits(dest);
    if (destDigits < 0) {
        fprintf(stderr, "SEMANTIC ERROR (line %d): variable '%s' assigned to but not declared\n", yylineno, dest);
        semantic_errors++;
        return;
    }

    const long long maxDest = max_value_for_digits(destDigits);
    const char *op = is_add ? "ADD" : "MOVE";

    if (v.kind == 0) {
        if (v.ival > maxDest) {
            fprintf(stderr,
                    "SEMANTIC ERROR (line %d): value %lld does not fit in '%s' (capacity %d digits, max %lld)\n",
                    yylineno, v.ival, dest, destDigits, maxDest);
            semantic_errors++;
        }
        return;
    }

    if (v.digits >= 0 && v.digits > destDigits) {
        // Warning: source declared capacity is bigger than destination.
        fprintf(stderr,
                "WARNING (line %d): %s from '%s' (capacity %d digits) to '%s' (capacity %d digits) may overflow\n",
                yylineno, op, v.ident, v.digits, dest, destDigits);
        semantic_warnings++;
    }
}

void yyerror(const char *s);
%}

%code requires {
    #ifndef JIBUC_VALUE_DEFINED
    #define JIBUC_VALUE_DEFINED
    typedef struct {
        int kind;        // 0 = integer literal, 1 = identifier
        long long ival; // when kind==0
        char *ident;    // when kind==1
        int digits;     // capacity digits when kind==1, or -1
    } Value;
    #endif
}

%union {
    long long ival;
    int capacity;
    char *str;
    Value value;
}

%token BEGINNING BODY END MOVE ADD TO INPUT PRINT
%token DOT SEMICOLON
%token <capacity> SIZE
%token <ival> INTEGER
%token <str> IDENTIFIER STRING
%token UNKNOWN

%type <value> value

%%

program:
    BEGINNING DOT decl_list BODY DOT stmt_list END DOT
    {
        if (syntax_errors == 0 && semantic_errors == 0) {
            printf("Program is well-formed\n");
        } else {
            printf("Program is not well-formed\n");
        }
        if (semantic_warnings > 0) {
            printf("Warnings: %d\n", semantic_warnings);
        }
    }
    ;

decl_list:
    decl_list decl
    | decl
    ;

decl:
    SIZE IDENTIFIER DOT
    {
        declare_symbol($2, $1);
    }
    ;

stmt_list:
    stmt_list stmt
    | stmt
    ;

stmt:
    assignment DOT
    | input_stmt DOT
    | output_stmt DOT
    ;

assignment:
    MOVE value TO IDENTIFIER
    {
        check_assignment($2, $4, 0);
    }
    | ADD value TO IDENTIFIER
    {
        check_assignment($2, $4, 1);
    }
    ;

value:
    INTEGER
    {
        $$ = make_int($1);
    }
    | IDENTIFIER
    {
        // Validate declaration early so we can emit helpful messages.
        if (lookup_digits($1) < 0) {
            fprintf(stderr, "SEMANTIC ERROR (line %d): variable '%s' used but not declared\n", yylineno, $1);
            semantic_errors++;
        }
        $$ = make_ident($1);
    }
    ;

input_stmt:
    INPUT ident_list
    ;

ident_list:
    IDENTIFIER
    {
        if (lookup_digits($1) < 0) {
            fprintf(stderr, "SEMANTIC ERROR (line %d): variable '%s' used in INPUT but not declared\n", yylineno, $1);
            semantic_errors++;
        }
    }
    | ident_list SEMICOLON IDENTIFIER
    {
        if (lookup_digits($3) < 0) {
            fprintf(stderr, "SEMANTIC ERROR (line %d): variable '%s' used in INPUT but not declared\n", yylineno, $3);
            semantic_errors++;
        }
    }
    ;

output_stmt:
    PRINT print_list
    ;

print_list:
    print_item
    | print_list SEMICOLON print_item
    ;

print_item:
    IDENTIFIER
    {
        if (lookup_digits($1) < 0) {
            fprintf(stderr, "SEMANTIC ERROR (line %d): variable '%s' used in PRINT but not declared\n", yylineno, $1);
            semantic_errors++;
        }
    }
    | STRING
    ;

%%

void yyerror(const char *s) {
    syntax_errors++;
    fprintf(stderr, "SYNTAX ERROR (line %d): %s\n", yylineno, s);
}

int main(void) {
    yyparse();
    return (syntax_errors != 0 || semantic_errors != 0) ? 1 : 0;
}
