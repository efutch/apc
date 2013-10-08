// *********************** INICIO DEL INCLUDE FILE *****************

// tmpvar.h - Header file para el generador de etiquetas y variables temp.
// Escrito por Egdares Futch H.
// Compilador : Borland C++ 3.0

#include "parser.tab.h"

const int TMP_ID = 2112;   // Rush

class TmpVars
{
   int varname[10];
   int labelname;
   int maxsize;
public:
   TmpVars(void)    { labelname = maxsize = 0; }
   ~TmpVars(void)   { }
   Token *NewTemp(int type = INT_TOK);
   void ResetSizeCounter(void)   { maxsize = 0; }
   int NewLabel(void)   { return ++labelname; }
   void FreeTemp(Token *tablepos);
};

// ********************* FIN DEL INCLUDE FILE
