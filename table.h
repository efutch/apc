// ******************** INCLUDE FILE : TABLE.H ***********************

// table.h - Include file de definiciones para la tabla de simbolos
// Escrito por Egdares Futch H.
// Compilador : Borland C++ 3.0

const int TABLESIZE = 513;
const int LOCALSEARCH = 1;
const int GLOBALSEARCH = 0;

class SymbolTable
{
   Token *table[TABLESIZE];
   static int hashval(const char *p);
   SymbolTable *upperscope;
public:
   SymbolTable(SymbolTable *scopelink = NULL);
   ~SymbolTable();
   Token *insert_table(char *name,int type);
   Token *lookup(const char *name,int localsrch);
};

// ************************** FIN DEL INCLUDE FILE *******************
