default:
	flex lexer.l
	bison -d parser.y
	g++ -g -o apc main.cpp table.cpp token.cpp error.cpp lex.yy.c parser.tab.c tmpvar.cpp
