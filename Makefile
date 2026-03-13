# Makefile for APC - A Pascal Compiler (LLVM backend)
# Usage: make
# Requires: bison, flex, clang/g++ with LLVM dev libraries
#   Ubuntu: sudo apt install bison flex llvm-dev clang

CXX      = g++
LLVM_CONFIG = llvm-config

# LLVM flags — auto-detected from llvm-config
LLVM_CXXFLAGS := $(shell $(LLVM_CONFIG) --cxxflags)
LLVM_LDFLAGS  := $(shell $(LLVM_CONFIG) --ldflags)
LLVM_LIBS     := $(shell $(LLVM_CONFIG) --libs core support irreader passes aarch64 aarch64codegen aarch64asmparser) \
                 $(shell $(LLVM_CONFIG) --system-libs)

CXXFLAGS = -std=c++17 -Wall -g $(LLVM_CXXFLAGS)
LDFLAGS  = $(LLVM_LDFLAGS) $(LLVM_LIBS)

OBJS = parser.tab.o lex.yy.o main.o token.o table.o tmpvar.o error.o llvmcodegen.o

all: apc

apc: $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

parser.tab.c parser.tab.h: parser.y
	bison -d parser.y

lex.yy.c: lexer.l parser.tab.h
	flex lexer.l

parser.tab.o: parser.tab.c
	$(CXX) $(CXXFLAGS) -c parser.tab.c

lex.yy.o: lex.yy.c
	$(CXX) $(CXXFLAGS) -c lex.yy.c

llvmcodegen.o: llvmcodegen.cpp llvmcodegen.h
	$(CXX) $(CXXFLAGS) -c llvmcodegen.cpp

main.o: main.cpp llvmcodegen.h
	$(CXX) $(CXXFLAGS) -c main.cpp

token.o: token.cpp token.h
	$(CXX) $(CXXFLAGS) -c token.cpp

table.o: table.cpp table.h
	$(CXX) $(CXXFLAGS) -c table.cpp

tmpvar.o: tmpvar.cpp tmpvar.h
	$(CXX) $(CXXFLAGS) -c tmpvar.cpp

error.o: error.cpp error.h
	$(CXX) $(CXXFLAGS) -c error.cpp

clean:
	rm -f *.o apc parser.tab.c parser.tab.h lex.yy.c *.ll *.s *.out

.PHONY: all clean
