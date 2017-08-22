/* main.cpp - programa principal para el compilador de pascal-a */
/* Escrito por Egdares Futch H.                                 */
/* Compilador : Borland C++ 3.0                                 */
// Basado en el original APC, reescrito en 10-Oct-94

#include <stdio.h>
#include <stdlib.h>

#include "token.h"
#include "table.h"
#include "parser.tab.h"
#include "tmpvar.h"

// Inicializacion de contadores de lineas y columnas

int column = 1;
int line = 1;

extern int yyparse();

void usage(void);
int yyparse(void);

SymbolTable *CurrentSymbolTable,*GlobalSymbolTable;
TmpVars TmpVarGenerator;

int main(int argc,char *argv[])
{
	extern FILE *yyin;
   GlobalSymbolTable = new SymbolTable;
/* Commented out August 2017 - Ubuntu version seems to have a problem with bison.skel and YYDEBUG	
#ifdef YYDEBUG
   extern int yydebug;
#endif
*/
	if (argc < 2)
		usage();
	yyin = fopen(argv[1],"rt");
	if (yyin == NULL)
	{
		perror("apc");
		exit(1);
	}
	printf("APC compiling %s\n",argv[1]);
   CurrentSymbolTable = GlobalSymbolTable;
/* Corrected August 2017 - Ubuntu version seems to have a problem with bison.skel and YYDEBUG	
#ifdef YYDEBUG
   yydebug = 1;
#endif
*/
	while (yyparse())
		;
	printf("\nAPC finished compiling.\n");
	return 0;
} /* main() */

void usage(void)
{
	printf("APC      : A Pascal Compiler (as defined in Aho, Sethi & Ullman)\n"
			 "           This compiler generates a .ASM file to be input to\n"
			 "           Turbo Assembler >= 2.0\n"
			 "\n Usage : apc filename.pas\n");
	exit(1);
} /* usage() */
