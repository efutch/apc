
/* A Bison parser, made by GNU Bison 2.4.1.  */

/* Skeleton interface for Bison's Yacc-like parsers in C
   
      Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006
   Free Software Foundation, Inc.
   
   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.
   
   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */


/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     PROG_TOK = 258,
     VAR_TOK = 259,
     INT_TOK = 260,
     CHAR_TOK = 261,
     ARR_TOK = 262,
     DOT_DOT = 263,
     OF_TOK = 264,
     PROC_TOK = 265,
     FUNC_TOK = 266,
     BEGIN_TOK = 267,
     END_TOK = 268,
     IF_TOK = 269,
     THEN_TOK = 270,
     ELSE_TOK = 271,
     WHILE_TOK = 272,
     DO_TOK = 273,
     NOT_TOK = 274,
     ASSIGNOP = 275,
     ID = 276,
     NUM = 277,
     CHARCONST = 278,
     PROC_ID = 279,
     FUNC_ID = 280,
     ARR_INT = 281,
     ARR_CHAR = 282,
     RELOP = 283,
     OR_TOK = 284,
     AND_TOK = 285,
     MOD_TOK = 286,
     DIV_TOK = 287,
     UMINUS = 288
   };
#endif



#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
{

/* Line 1676 of yacc.c  */
#line 26 "parser.y"

   int intval;
   unsigned char charval;
   int opval;
   Token *tokenpos;
//               SI SE USA EN DECLS                      ARRAY DE ETIQUETAS
// typeinfo[0] = type                                    true
// typeinfo[1] = base type if array                      false
// typeinfo[2] = low array bound                         out
// typeinfo[3] = high array bound                        start
// typeinfo[4] = cuantos elementos tienen este tipo
   int typeinfo[5];



/* Line 1676 of yacc.c  */
#line 101 "parser.tab.h"
} YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
#endif

extern YYSTYPE yylval;


