%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


using namespace std;

#include "y.tab.h"


#define MAX_LINE_LENG 256
#define LIST strcat(buf,yytext)
#define token(t) {LIST; if(Opt_T) printf("<%s>\n",#t);}
#define tokenInteger(t,i) {LIST; if(Opt_T) printf("<%s:%d>\n",#t,i);}
#define tokenString(t,s) {LIST; if(Opt_T) printf("<%s:%s>\n",#t,s);}

int Opt_T = 0;
int Opt_S = 0;
int linenum =1;
char buf[MAX_LINE_LENG];

%}

digit [0-9]
letter [a-zA-Z]
id {letter}({letter}|{digit})*
string \"(\"\"|[^"\n])*\"
comment \/\/[^\n]+
real [+-]?{digit}+\.{digit}+(e?[+-]?{digit}+)?
integer ([+-]?{digit}+)
arithmetic [+-*/]
relational [<>=]
begincomment (\(\*)
endcomment (\*\))

%x COMMENT


%%


"("	{token('('); return yytext[0];}
")"	{token(')'); return yytext[0];}
"["	{token('['); return yytext[0];}
"]"	{token(']'); return yytext[0];}
"{"	{token('{'); return yytext[0];}
"}"	{token('}'); return yytext[0];}
","	{token(','); return yytext[0];}
":"	{token(':'); return yytext[0];}
";"	{token(';'); return yytext[0];}
"+"	{token('+'); return yytext[0];}
"-"	{token('-'); return yytext[0];}
"*"	{token('*'); return yytext[0];}
"/"	{token('/'); return yytext[0];}
"%"	{token('%'); return yytext[0];}
"<"	{token('<'); return yytext[0];}
"<="	{token('<='); return LE;}
">="	{token('>='); return GE;}
">"	{token('>'); return yytext[0];}
"="	{token('='); return '=';}
"<>"	{token('<>'); return NEQ;}
"&&"	{token('&&'); return AND;}
"||"	{token('||'); return OR;}
"~"	{token('~'); return yytext[0];}
":="	{token(':='); return ASSIGN;}



array	{token('ARRAY'); return ARRAY;}
boolean	{token('BOOLEAN'); return BOOLEAN;}
begin	{token('BEGIN'); return BEG;}
break	{token('BREAK'); return BREAK;}
char	{token('CHAR'); return CHAR;}
case	{token('CASE'); return CASE;}
const	{token('CONST'); return CONST;}
continue	{token('CONTINUE'); return CONTINUE;}
do	{token('DO'); return DO;}
else	{token('ELSE'); return ELSE;}
end	{token('END'); return END;}
exit	{token('EXIT'); return EXIT;}
false	{token('FALSE'); 
	 yylval.bool_val = false;
	 return BOOLEAN_CONST;}
for	{token('FOR'); return FOR;}
fn	{token('FN'); return FN;}
if	{token('IF'); return IF;}
in	{token('IN'); return IN;}
integer	{token('INTEGER'); return INTEGER;}
loop	{token('LOOP'); return LOOP;}
module	{token('MODULE'); return MODULE;}
print	{token('PRINT'); return PRINT;}
println	{token('PRINTLN'); return PRINTLN;}
procedure	{token('PROCEDURE'); return PROCEDURE;}
repeat	{token('REPEAT'); return REPEAT;}
return	{token('RETURN'); return RETURN;}
real	{token('REAL'); return REAL;}
string	{token('STRING'); return STRING;}
record	{token('RECORD'); return RECORD;}
then	{token('THEN'); return THEN;}
true	{token('TRUE'); 
	 yylval.bool_val = true;
	 return BOOLEAN_CONST;}
type	{token('TYPE'); return TYPE;}
use	{token('USE'); return USE;}
util	{token('UTIL'); return UTIL;}
var	{token('VAR'); return VAR;}
while	{token('WHILE'); return WHILE;}
of	{token('OF'); return OF;}
read	{token('READ'); return READ;}


{id}	{
tokenString(id,yytext);
yylval.str_val = new string(yytext);
return ID;
}

{integer}	{
tokenInteger(integer,atoi(yytext));
yylval.int_val = atoi(yytext);
return INT_CONST;
}

{real}	{
tokenString(real,yytext);
yylval.double_val = atof(yytext);
return REAL_CONST;
}

{string}	{
char* str = (char*)malloc(sizeof(char)*(yyleng-2));
int index=0;
for(int i=1;i<yyleng-1;i++)
{
str[index] = yytext[i];
index++;
}
tokenString(string,str);
yylval.str_val = new string(str);
return STR_CONST;
}


{comment}	{LIST;}

{begincomment}	{
LIST;
BEGIN COMMENT;
}

<COMMENT>[^\n]	{LIST;}

<COMMENT>\n	{
LIST;
printf("%d: %s",linenum,buf);
linenum++;
buf[0] = '\0';
}

<COMMENT>{endcomment}	{
LIST;
BEGIN INITIAL;
}

\n {
LIST;
printf("%d: %s", linenum,buf);
linenum++;
buf[0] = '\0';
}

[ \t]* {LIST;}

. {
token('.');
printf("%d:%s\n",linenum,buf);
return '.';
exit(-1);
}



%%


