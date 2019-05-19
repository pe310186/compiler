all: parser

parser: lex.yy.c y.tab.c symbol.c symbol.h
	g++ y.tab.c symbol.c -o parser -ll -ly -std=c++11 

lex.yy.c: scanner.l
	lex -o lex.yy.c scanner.l

y.tab.c: parser.y
	yacc -d parser.y -o y.tab.c
