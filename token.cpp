// token.cpp - modulo de manejo de tokens
// Escrito por Egdares Futch H.
// Compilador : Turbo C++ 1.01

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "token.h"
#include "parser.tab.h"
#include "error.h"

Token::Token(char *nameval, int toktype = ID,int t = INT_TOK)
{
	if (nameval != NULL)
	{
		name = new char[strlen(nameval) + 1];
		if (name == NULL)
		{
			error(ERR_NOMEM);
		}
		strcpy(name,nameval);
	}
   else
       name = NULL;
	tokentype = toktype;
   type = t;
   next = NULL;
   offset = NULL;
} // Token::Token()

Token::Token(char charconst)
{
   name = new char[4];
   sprintf(name,"'%c'",charconst);
   next = NULL;
   type = CHAR_TOK;
   tokentype = CHARCONST;
} // Token::Token()

Token::Token(int num)
{
   name = new char[5];
   snprintf(name,5,"%d",num);
 //  itoa(num,name,10);    no longer supported in Linux, this is more portable
   next = NULL;
   type = INT_TOK;
   tokentype = NUM;
} // Token::Token()

Token::~Token()
{
   if (name)
      delete name;
   if (next)
      delete next;
   if (offset)
      delete offset;
} // Token::~Token()

int Token::Compare(const char *n)
{
   if (strcmp(n,name) == 0)
      return 1;
   else
      return 0;
} // Token::Compare()
