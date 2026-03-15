# Makefile for APC - A Pascal Compiler
# Based on Aho, Sethi & Ullman (Dragon Book)
# Generates custom intermediate representation output

CXX      = g++
CXXFLAGS = -std=c++17 -Wall -g

OBJS = main.o table.o token.o error.o tmpvar.o parser.tab.o lex.yy.o

all: apc

apc: $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^

parser.tab.c parser.tab.h: parser.y
	bison -d parser.y

lex.yy.c: lexer.l parser.tab.h
	flex lexer.l

parser.tab.o: parser.tab.c parser.tab.h
	$(CXX) $(CXXFLAGS) -c parser.tab.c

lex.yy.o: lex.yy.c parser.tab.h
	$(CXX) $(CXXFLAGS) -c lex.yy.c

main.o: main.cpp parser.tab.h
	$(CXX) $(CXXFLAGS) -c main.cpp

table.o: table.cpp table.h parser.tab.h
	$(CXX) $(CXXFLAGS) -c table.cpp

token.o: token.cpp token.h parser.tab.h
	$(CXX) $(CXXFLAGS) -c token.cpp

error.o: error.cpp error.h
	$(CXX) $(CXXFLAGS) -c error.cpp

tmpvar.o: tmpvar.cpp tmpvar.h parser.tab.h
	$(CXX) $(CXXFLAGS) -c tmpvar.cpp

clean:
	rm -f *.o apc parser.tab.c parser.tab.h lex.yy.c

.PHONY: all clean
