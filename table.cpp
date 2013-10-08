// table.cpp - Rutinas de manejo de tabla de simbolos
// Escrito por Egdares Futch H. basado en Stroustrup Cap. 3
// Compilador : Borland C++ 3.0

#include <stdio.h>

#include "error.h"
#include "token.h"
#include "table.h"
#include "parser.tab.h"

// Constructor
SymbolTable::SymbolTable(SymbolTable *scopelink) : upperscope(scopelink)
{
   for (int h = 0 ; h < TABLESIZE ; table[h++] = NULL )
       ;

}

//Destructor
SymbolTable::~SymbolTable(void)
{
   for (int h = 0; h < TABLESIZE ; h++)
       if (table[h])
          delete table[h];
}

int SymbolTable::hashval(const char *p)
{
	int ii = 0;
	const char *pp = p;
	while (*pp)
   {
		ii <<= 1;
      ii ^= *pp++;
   }
	if (ii < 0)
		ii = -ii;
	return ii % TABLESIZE;
} // SymbolTable::hashval()

// Implementacion de los varios insert_table

Token *SymbolTable::insert_table(char *name,int type)
{
   int tmp_pos = hashval(name);
   if (table[tmp_pos] == NULL)   // espacio vacio en la tabla
   {
      table[tmp_pos] = new Token(name,type,0);
      return table[tmp_pos];
   }
   else
   {
// Hubo colision
      Token *tmp_ptr = table[tmp_pos];
      while (tmp_ptr->GetNext())
         tmp_ptr = tmp_ptr->GetNext();
      Token *newtok = new Token(name,type,0);
      tmp_ptr->SetNext(newtok);
      return newtok;
   };
} // insert_table()

Token *SymbolTable::lookup(const char *name,int localsrch)
{
   int tmp_pos = hashval(name);
   if (table[tmp_pos] == NULL)
   {
      if (upperscope && (localsrch == GLOBALSEARCH))
         // Buscarlo en el scope superior
         return upperscope->lookup(name,GLOBALSEARCH);
      else
         // No existe
         return NULL;
   }
// Hay algo en la tabla
   else
   {
// Encontro el token porque son iguales
      if (table[tmp_pos]->Compare(name))
         return table[tmp_pos];
      else
      {
// A buscarlo en la cola
         Token *iter = table[tmp_pos]->GetNext();
         while (iter)
         {
            if (iter->Compare(name))
               return iter;
            iter = iter->GetNext();
         }
// Si hace fall through, quiere decir que no lo encontro y devuelve NULL
         return iter;
      }
   };
} // SymbolTable::lookup()
