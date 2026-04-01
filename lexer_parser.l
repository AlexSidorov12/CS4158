%{
#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

static char *normalize_ident(const char *s) {
    size_t n = strlen(s);
    char *out = (char *)malloc(n + 1);
    if (!out) return NULL;

    for (size_t i = 0; i < n; i++) {
        out[i] = (char)toupper((unsigned char)s[i]);
    }
    out[n] = '\0';
    return out;
}
%}

%option caseless
%option noyywrap
%option yylineno

%%

BEGINNING   { return BEGINNING; }
BODY        { return BODY; }
END         { return END; }
MOVE        { return MOVE; }
ADD         { return ADD; }
TO          { return TO; }
INPUT       { return INPUT; }
PRINT       { return PRINT; }

X+          {
                yylval.capacity = (int)yyleng;
                return SIZE;
            }

[0-9]+       { yylval.ival = strtoll(yytext, NULL, 10); return INTEGER; }

\"[^\"]*\"   {
                yylval.str = strdup(yytext);
                return STRING;
            }

";"         { return SEMICOLON; }
"."         { return DOT; }

[a-zA-Z][a-zA-Z0-9\-]*  {
                yylval.str = normalize_ident(yytext);
                return IDENTIFIER;
            }

[ \t\r\n]+  ;

.            { return UNKNOWN; }

%%
