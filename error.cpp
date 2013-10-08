// error.cpp - modulo de manejo de errores
// Escrito por Egdares Futch H.
// Compilador : Turbo C++ 1.01

#include <iostream>

using std::cin;
using std::cout;
using std::cerr;
using std::endl;

extern int line,column;

const int MAXERRORS = 12;

static char const *errors[MAXERRORS] =
{
	"Lexical error",
	"Nested comments are not allowed",
	"EOF inside comment",
	"No dynamic memory for installing new symbol",
   "Duplicate identifier",
   "Identifier not previously declared",
   "Intermediate code generator could not open files",
   "Unknown intermediate code opcode",
   "Lvalue expected",
   "Procedure identifier expected",
   "Type mismatch",
   "Wrong number of parameters in call"
};

void error(const int errno)
{
	if (errno < MAXERRORS)
		cerr << endl << errors[errno] << " in line "
			  << line << ", column " << column << endl;
	else
		cerr << "Unknown error" << errno << ".  Report to efutch" << endl;
} // error()
