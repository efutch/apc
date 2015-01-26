%{
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#include "error.h"
#include "token.h"
#include "table.h"
#include "parser.tab.h"

#define TABSIZE	8

extern int column,line;
extern SymbolTable *CurrentSymbolTable;
extern int CanInsert;
extern int proc_id,func_id;

%}

%x comment
%option case-insensitive

space				[ ]
tab				[\t]
newline			[\n]

letter          [A-Za-z_]
digit           [0-9]
id              {letter}({letter}|{digit})*

num             {digit}{digit}*

addop           [+-]
mulop           [*/]

%%

{space}			{ ++column; }
{tab}				{ column += TABSIZE; }
{newline}		{ column = 1; ++line; fprintf(stderr,"(%d)\r",line); }

"(*"		|
"{"		{ column += yyleng; BEGIN(comment); }

<comment>{space}		|
<comment>{tab}			{ column += TABSIZE; }
<comment>{newline}	{ column = 1; ++line; fprintf(stderr,"(%d)\r",line); }
<comment>"*)"			{ column += 2; BEGIN(INITIAL); }
<comment>"}" 			{ ++column; BEGIN(INITIAL); }
<comment>"{"			|
<comment>"(*"			{
								error(ERR_NESTEDCOMMENT);
								yyterminate();
							}
<comment><<EOF>>	{
							error(ERR_EOFCOMMENT);
							yyterminate();
						}
<comment>.				{ ++column; }

program			{ column += 7; return(PROG_TOK); }
var				{ column += 3; return(VAR_TOK); }
integer			{ column += 7; return(INT_TOK); }
char				{ column += 4; return(CHAR_TOK); }
procedure		{ column += 9; return(PROC_TOK); }
function       { column += 8; return(FUNC_TOK); }
begin				{ column += 5; return(BEGIN_TOK); }
end				{ column += 3; return(END_TOK); }
if					{ column += 2; return(IF_TOK); }
then				{ column += 4; return(THEN_TOK); }
else				{ column += 4; return(ELSE_TOK); }
while				{ column += 5; return(WHILE_TOK); }
do					{ column += 2; return(DO_TOK); }
not				{ column += 3; return(NOT_TOK); }
array          { column += 5; return(ARR_TOK); }
of             { column += 2; return(OF_TOK); }
".."           { column += 2; return(DOT_DOT); }
"["            { ++column; return('['); }
"]"            { ++column; return(']'); }
"("				{ ++column; return('('); }
")"				{ ++column; return(')'); }
";"				{ ++column; return(';'); }
"."				{ ++column; return('.'); }
","				{ ++column; return(','); }
":="				{ column += 2; return(ASSIGNOP); }
":"				{ ++column; return(':'); }
\'.\'				{
                  column += yyleng;
                  yylval.charval = yytext[1];
                  return(CHARCONST);
               }
\#{digit}{1,3}	{
                 column += yyleng;
                 yylval.charval = atoi(yytext+1);
                 return(CHARCONST);
               }
\^{letter}		{
                 column += yyleng;
                 yylval.charval = toupper(yytext[1]) - 'A' + 1;
                 return(CHARCONST);
               }

{addop}         { ++column; yylval.opval = yytext[0]; return(yytext[0]); }
"or"            { column += 2; yylval.opval = 0; return(OR_TOK); }

{mulop}         { ++column; yylval.opval = yytext[0]; return(yytext[0]); }
"and"           { column += 3; yylval.opval = 0; return(AND_TOK); }
"div"           { column += 3; yylval.opval = 1; return(DIV_TOK); }
"mod"           { column += 3; yylval.opval = 2; return(MOD_TOK); }

{id}            {
                  char idbuf[40];
                  int retval,i;

		if (yyleng > 39)
		{
			error(ERR_IDTOOLONG);
			yyterminate();
		}
                  strcpy(idbuf,yytext);
		  for (i = 0; i < yyleng ; i++)
			idbuf[i] = toupper(idbuf[i]);
                  //strupr(idbuf);
                  if (CanInsert)
                  {
                     yylval.tokenpos = CurrentSymbolTable->lookup(idbuf,LOCALSEARCH);
                     if (yylval.tokenpos == NULL)
                     {
                        if (func_id == 1)
                        {
                           yylval.tokenpos = CurrentSymbolTable->insert_table(idbuf,FUNC_ID);
                           retval = FUNC_ID;
                        }
                        else if (proc_id == 1)
                        {
                           yylval.tokenpos = CurrentSymbolTable->insert_table(idbuf,PROC_ID);
                           retval = PROC_ID;
                        }
                        else
                        {
                           yylval.tokenpos = CurrentSymbolTable->insert_table(idbuf,ID);
                           retval = ID;
                        }
                     } // yylval.tokenpos == NULL
                     else
                        error(ERR_DUPID);
                  } // CanInsert
                  else
                  {
                     yylval.tokenpos = CurrentSymbolTable->lookup(idbuf,GLOBALSEARCH);
                     if (yylval.tokenpos == NULL)
                        error(ERR_NDECLID);
                     else
                        retval = yylval.tokenpos->GetTokenType();
                  }
                  column += yyleng;
                  return retval;
                }

{num}           {
                  column += yyleng;
                  yylval.intval = atoi(yytext);
                  return NUM;
                }

"="       { ++column   ; yylval.opval = 0; return(RELOP); }
"<>"      { column += 2; yylval.opval = 1; return(RELOP); }
"<"       { ++column   ; yylval.opval = 2; return(RELOP); }
"<="      { column += 2; yylval.opval = 3; return(RELOP); }
">="      { column += 2; yylval.opval = 4; return(RELOP); }
">"       { ++column   ; yylval.opval = 5; return(RELOP); }

.			{
			  error(ERR_LEXICAL);
			  yyterminate();
			}

%%

int yywrap(void)
{
	return 1;
}
