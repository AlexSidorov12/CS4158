%{
/*
 * JIBUC Lexical Analyzer
 * Case-insensitive language: programs start with BEGINNING. and end with END.
 */
#include <stdio.h>
%}

%option caseless
%option noyywrap

%%

BEGINNING   { printf("KEYWORD: BEGINNING\n"); }
BODY        { printf("KEYWORD: BODY\n"); }
END         { printf("KEYWORD: END\n"); }
MOVE        { printf("KEYWORD: MOVE\n"); }
ADD         { printf("KEYWORD: ADD\n"); }
TO          { printf("KEYWORD: TO\n"); }
INPUT       { printf("KEYWORD: INPUT\n"); }
PRINT       { printf("KEYWORD: PRINT\n"); }

X+          { printf("SIZE: %s\n", yytext); }

[0-9]+      { printf("INTEGER: %s\n", yytext); }

\"[^"]*\"   { printf("STRING: %s\n", yytext); }

";"         { printf("SEMICOLON\n"); }
"."         { printf("DOT\n"); }

[a-zA-Z][a-zA-Z0-9\-]*   { printf("IDENTIFIER: %s\n", yytext); }

[ \t\n\r]+  ;

.           { printf("UNKNOWN: %s\n", yytext); }

%%

int main(void) {
    yylex();
    return 0;
}
