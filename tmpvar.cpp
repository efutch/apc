// tmpvar.cpp - Programa que genera variables y etiquetas temporales
// Escrito por Egdares Futch H.
// Compilador : Borland C++ 3.0

#include <stdio.h>
#include <assert.h>

//#include "parser.tab.h"
#include "token.h"
#include "table.h"
#include "tmpvar.h"

extern SymbolTable CompilerSymbolTable;

Token *TmpVars::NewTemp(int tokentype)
{
   char namebuf[10];
   int tmpvarname = 0;

   while (varname[tmpvarname++])
      ;
   varname[--tmpvarname] = 1;
   sprintf(namebuf,"t%d",tmpvarname);
   if (tmpvarname > maxsize)
      maxsize = tmpvarname;
//   return CompilerSymbolTable.insert_table(namebuf,TMP_ID);
   return new Token(namebuf,TMP_ID,tokentype);
}

void TmpVars::FreeTemp(Token *tmppos)
{
   assert(tmppos);
   if (tmppos->GetTokenType() == TMP_ID)
   {
      varname[tmppos->GetName()[1] - '0'] = 0;
      delete tmppos;
   }
}
