%{
#include <stdio.h>
#include <ctype.h>

#include "protos.h"
#include "token.h"
#include "tmpvar.h"
#include "error.h"
#include "table.h"

extern TmpVars TmpVarGenerator;
extern SymbolTable *GlobalSymbolTable,*CurrentSymbolTable;
int CanInsert;
int proc_id,func_id;
SymbolTable *LocalSymbolTable;
void yyerror(const char *);

#define TRUELABEL    0
#define FALSELABEL   1
#define OUTLABEL     2
#define STARTLABEL   3

%}

%union
{
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
}

%token PROG_TOK
%token VAR_TOK
%token INT_TOK
%token CHAR_TOK
%token ARR_TOK
%token DOT_DOT
%token OF_TOK
%token PROC_TOK
%token FUNC_TOK
%token BEGIN_TOK
%token END_TOK
%token IF_TOK
%token THEN_TOK
%token ELSE_TOK
%token WHILE_TOK
%token DO_TOK
%left  NOT_TOK
%token ASSIGNOP
%token <tokenpos> ID
%token NUM
%token CHARCONST
%token PROC_ID
%token <tokenpos> FUNC_ID
%token ARR_INT
%token ARR_CHAR

%nonassoc RELOP
%left	    '+'	'-'	OR_TOK
%left     '*'	'/'	DIV_TOK	MOD_TOK	AND_TOK
%left	UMINUS

%type <typeinfo> identifier_list typed_id_list arguments type parameter_list
%type <intval> expression_list
%type <tokenpos> untyped_id_list simple_expression expression term factor variable

%expect 1

%start program

%%

allow_ids    :
             {
               CanInsert = 1;
             }
             ;

disallow_ids :
             {
               CanInsert = 0;
             }
             ;

program	:
            PROG_TOK
            allow_ids
            ID
            '('
            untyped_id_list
            ')'
            disallow_ids
            ';'
				declarations
				subprogram_declarations
            {
               printf("proc main,0\n");
            }
				compound_statement
				'.'
            {
               printf("endproc\n");
            }
			;

untyped_id_list   :  ID
                  |  untyped_id_list ',' ID
                  ;

identifier_list	:  ID
                     typed_id_list
                     {
                        $<tokenpos>1->SetType($<typeinfo>2[0]);
                        switch ($<typeinfo>2[0])
                        {
                           case INT_TOK:
                              printf("defint %s\n",$<tokenpos>1->GetName());
                              break;
                           case CHAR_TOK:
                              printf("defchar %s\n",$<tokenpos>1->GetName());
                              break;
                           case ARR_INT:
                           {
                              int size = $<typeinfo>2[3] - $<typeinfo>2[2] + 1;
                              $<tokenpos>1->SetLowArrBound($<typeinfo>2[2]);
                              $<tokenpos>2->SetHighArrBound($<typeinfo>2[3]);
                              printf("defintarr %s %d\n",$<tokenpos>1->GetName(),size);
                              break;
                           }
                           case ARR_CHAR:
                           {
                              int size = $<typeinfo>2[3] - $<typeinfo>2[2] + 1;
                              $<tokenpos>1->SetLowArrBound($<typeinfo>2[2]);
                              $<tokenpos>2->SetHighArrBound($<typeinfo>2[3]);
                              printf("defchararr %s %d\n",$<tokenpos>1->GetName(),size);
                              break;
                           }
                        }
                        // Copia de atributo compuesto
                        $<typeinfo>$[0] = $<typeinfo>2[0];
                        $<typeinfo>$[1] = $<typeinfo>2[1];
                        $<typeinfo>$[2] = $<typeinfo>2[2];
                        $<typeinfo>$[3] = $<typeinfo>2[3];
                        $<typeinfo>$[4] = $<typeinfo>2[4];
                        // Fin de copia
                        $<typeinfo>$[4]++;
                     }
                  ;

typed_id_list     :  ','
                     ID
                     typed_id_list
                     {
                        $<tokenpos>2->SetType($<typeinfo>3[0]);
                        switch ($<typeinfo>3[0])
                        {
                           case INT_TOK:
                              printf("defint %s\n",$<tokenpos>2->GetName());
                              break;
                           case CHAR_TOK:
                              printf("defchar %s\n",$<tokenpos>2->GetName());
                              break;
                           case ARR_INT:
                           {
                              int size = $<typeinfo>2[3] - $<typeinfo>2[2] + 1;
                              $<tokenpos>1->SetLowArrBound($<typeinfo>2[2]);
                              $<tokenpos>2->SetHighArrBound($<typeinfo>2[3]);
                              printf("defintarr %s %d\n",$<tokenpos>1->GetName(),size);
                              break;
                           }
                           case ARR_CHAR:
                           {
                              int size = $<typeinfo>2[3] - $<typeinfo>2[2] + 1;
                              $<tokenpos>1->SetLowArrBound($<typeinfo>2[2]);
                              $<tokenpos>2->SetHighArrBound($<typeinfo>2[3]);
                              printf("defchararr %s %d\n",$<tokenpos>1->GetName(),size);
                              break;
                           }
                        }
                        // Copia de atributo compuesto
                        $<typeinfo>$[0] = $<typeinfo>3[0];
                        $<typeinfo>$[1] = $<typeinfo>3[1];
                        $<typeinfo>$[2] = $<typeinfo>3[2];
                        $<typeinfo>$[3] = $<typeinfo>3[3];
                        $<typeinfo>$[4] = $<typeinfo>3[4];
                        // Fin de copia
                        $<typeinfo>$[4]++;
                     }
                  |  ':'
                     type
                     {
                        // Copia de atributo compuesto
                        $<typeinfo>$[0] = $<typeinfo>2[0];
                        $<typeinfo>$[1] = $<typeinfo>2[1];
                        $<typeinfo>$[2] = $<typeinfo>2[2];
                        $<typeinfo>$[3] = $<typeinfo>2[3];
                        $<typeinfo>$[4] = $<typeinfo>2[4];
                        // Fin de copia
                     }
						;

declarations	:  declarations
                  VAR_TOK
                  allow_ids
                  identifier_list
                  ';'
                  disallow_ids
					|
					;

type	:	standard_type
         {
            $<typeinfo>$[0] = $<typeinfo>1[0];
            $<typeinfo>$[4] = $<typeinfo>1[4];
         }
      |  ARR_TOK '[' NUM DOT_DOT NUM ']' OF_TOK standard_type
         {
            if ($<typeinfo>8[0] == INT_TOK)
               $<typeinfo>$[0] = ARR_INT;
            else
               $<typeinfo>$[0] = ARR_CHAR;
            $<typeinfo>$[1] = $<typeinfo>8[0];
            $<typeinfo>$[2] = $<intval>3;
            $<typeinfo>$[3] = $<intval>5;
            $<typeinfo>$[4] = $<typeinfo>8[4];
         }
		;

standard_type	:	INT_TOK
                  {
                     $<typeinfo>$[0] = INT_TOK;
                     $<typeinfo>$[4] = 0;
                  }
					|	CHAR_TOK
                  {
                     $<typeinfo>$[0] = CHAR_TOK;
                     $<typeinfo>$[4] = 0;
                  }
					;

subprogram_declarations	:	subprogram_declarations
                           subprogram_declaration
                           ';'
								|
								;

subprogram_declaration	:  allow_ids
                           subprogram_head
                           declarations
                           disallow_ids
                           compound_statement
                           {
                              printf("endproc\n");
                              CurrentSymbolTable = GlobalSymbolTable;
                              delete LocalSymbolTable;
                           }
								;

subprogram_head	:  PROC_TOK
                     {
                        // Comunicar al analizador lexico que el proximo
                        // ID es un identificador de procedimiento PROC_ID
                        proc_id = 1;
                     }
                     PROC_ID
                     {
                        proc_id = 0;
                        // Entrando a un nuevo scope, cambiar tabla
                        LocalSymbolTable = new SymbolTable(CurrentSymbolTable);
                        CurrentSymbolTable = LocalSymbolTable;
                        printf("startargs\n");
                     }
                     arguments
                     {
                        printf("endargs\n");
                        $<tokenpos>3->SetParamCount($<typeinfo>5[4]);
                     }
                     ';'
                     {
                        printf("proc _%s,%d\n",$<tokenpos>3->GetName(),$<tokenpos>3->GetParamCount());
                     }
                  |  FUNC_TOK
                     {
                        // Comunicar al analizador lexico que el proximo
                        // ID es un identificador de funcion FUNC_ID
                        func_id = 1;
                     }
                     FUNC_ID
                     {
                        func_id = 0;
                        // Entrando a un nuevo scope, cambiar tabla
                        LocalSymbolTable = new SymbolTable(CurrentSymbolTable);
                        CurrentSymbolTable = LocalSymbolTable;
                        printf("startargs\n");
                     }
                     arguments
                     {
                        printf("endargs\n");
                        $<tokenpos>3->SetParamCount($<typeinfo>5[4]);
                     }
                     ':'
                     standard_type
                     {
                        $<tokenpos>3->SetFuncReturnType($<typeinfo>8[0]);
                        switch($<typeinfo>8[0])
                        {
                           case INT_TOK:
                              printf("intfunc _%s,%d\n",$<tokenpos>3->GetName(),$<tokenpos>3->GetParamCount());
                              break;
                           case CHAR_TOK:
                              printf("charfunc _%s,%d\n",$<tokenpos>3->GetName(),$<tokenpos>3->GetParamCount());
                              break;
                           default:
                              error(ERR_TYPEMISMATCH);
                        }
                     }
                     ';'
						;

arguments	:	'('
               parameter_list
               ')'
               {
                   // Copia de atributo compuesto
                   $<typeinfo>$[0] = $<typeinfo>2[0];
                   $<typeinfo>$[1] = $<typeinfo>2[1];
                   $<typeinfo>$[2] = $<typeinfo>2[2];
                   $<typeinfo>$[3] = $<typeinfo>2[3];
                   $<typeinfo>$[4] = $<typeinfo>2[4];
                   // Fin de copia
               }
				|  { $<typeinfo>$[4] = 0; }
				;

parameter_list	:  identifier_list
					|	parameter_list
                  ';'
                  identifier_list
                  {
                      // Copia de atributo compuesto
                      $<typeinfo>$[0] = $<typeinfo>2[0];
                      $<typeinfo>$[1] = $<typeinfo>2[1];
                      $<typeinfo>$[2] = $<typeinfo>2[2];
                      $<typeinfo>$[3] = $<typeinfo>2[3];
                      $<typeinfo>$[4] = $<typeinfo>2[4];
                      // Fin de copia
                  }
					;

compound_statement	:	BEGIN_TOK
                        optional_statements
                        END_TOK
							;

optional_statements	:	statement_list
							|
							;

statement_list	:	statement
					|	statement_list
                  ';'
                  statement

statement	:	variable
               ASSIGNOP
               expression
               {
                  Token *tmpoffset = $1->GetOffset();
                  if (tmpoffset)
                  {
                     printf("%s[%s] = %s\n",$<tokenpos>1->GetName(),
                                            tmpoffset->GetName(),
                                            $<tokenpos>3->GetName());
                     TmpVarGenerator.FreeTemp(tmpoffset);
                     $1->SetOffset(NULL);
                  }
                  else
                     printf("%s = %s\n",$<tokenpos>1->GetName(),
                                        $<tokenpos>3->GetName());
                  TmpVarGenerator.FreeTemp($<tokenpos>3);
                  $<tokenpos>$ = $<tokenpos>1;
               }
				|	procedure_statement
				|	compound_statement
            |  IF_TOK
               expression
               THEN_TOK
               {
                  $<typeinfo>$[FALSELABEL] = TmpVarGenerator.NewLabel();
                  $<typeinfo>$[OUTLABEL] = TmpVarGenerator.NewLabel();
                  printf("gofalse %s,__lab%d\n",$2->GetName(),$<typeinfo>$[FALSELABEL]);
                  TmpVarGenerator.FreeTemp($2);
               }
               statement
               {
                  printf("goto __lab%d\n",$<typeinfo>4[OUTLABEL]);
                  printf("label __lab%d\n",$<typeinfo>4[FALSELABEL]);

               }
               else_part
               {
                  printf("label __lab%d\n",$<typeinfo>4[OUTLABEL]);
               }
				|	WHILE_TOK
               {
                  $<typeinfo>$[OUTLABEL] = TmpVarGenerator.NewLabel();
                  $<typeinfo>$[STARTLABEL] = TmpVarGenerator.NewLabel();
                  printf("label __lab%d\n",$<typeinfo>$[STARTLABEL]);
               }
               expression
               {
                  printf("gofalse %s,__lab%d\n",$3->GetName(),$<typeinfo>2[OUTLABEL]);
               }
               DO_TOK
               statement
               {
                  printf("goto __lab%d\n",$<typeinfo>2[STARTLABEL]);
                  printf("label __lab%d\n",$<typeinfo>2[OUTLABEL]);
                  TmpVarGenerator.FreeTemp($3);
               }
				;

else_part   :  ELSE_TOK
               statement
            |
            ;

variable	:	ID
            {
               $$ = $1;
               TmpVarGenerator.FreeTemp($<tokenpos>1);
            }
         |  ID '[' expression ']'
            {
               $1->SetOffset($3);
               $$ = $1;
            }
         |  FUNC_ID
			;

procedure_statement	:	PROC_ID
                        {
                           if ($<tokenpos>1->GetParamCount() != 0)
                              error(ERR_PARAMCOUNT);
                           else
                              printf("call %s\n",$<tokenpos>1->GetName());
                        }
							|	PROC_ID
                        '('
                        expression_list
                        ')'
                        {
                           if ($<tokenpos>1->GetParamCount() != $<intval>3)
                              error(ERR_PARAMCOUNT);
                           else
                              printf("call %s\n",$<tokenpos>1->GetName());
                        }
							;

expression_list	:	expression
                     {
                        printf("param %s\n",$<tokenpos>1->GetName());
                        TmpVarGenerator.FreeTemp($<tokenpos>1);
                        $<intval>$ = 1;
                     }
						|	expression_list
                     ','
                     expression
                     {
                        printf("param %s\n",$<tokenpos>3->GetName());
                        TmpVarGenerator.FreeTemp($<tokenpos>3);
                        $<intval>$ = $<intval>1 + 1;
                     }
						;

expression	:	simple_expression
               {
                  $<tokenpos>$ = $<tokenpos>1;
               }
				|	simple_expression
               RELOP
               simple_expression
               {
                  static const char* RelOps[] = { "==","!=","<","<=",">=",">" };

                  Token *tmp = TmpVarGenerator.NewTemp();
                  printf("%s = %s %s %s\n",tmp->GetName(),
                                           $<tokenpos>1->GetName(),
                                           RelOps[$<opval>2],
                                           $<tokenpos>3->GetName());
                  TmpVarGenerator.FreeTemp($<tokenpos>1);
                  TmpVarGenerator.FreeTemp($<tokenpos>3);
                  $<tokenpos>$ = tmp;
               }
				;

simple_expression	:	term
                     {
                        $<tokenpos>$ = $<tokenpos>1;
                     }
						|	simple_expression
                     '+'
                     term
                     {
                        if (($<tokenpos>1->GetType() != INT_TOK) ||
                            ($<tokenpos>3->GetType() != INT_TOK))
                               error(ERR_TYPEMISMATCH);
                        Token *tmp = TmpVarGenerator.NewTemp();
                        printf("%s = %s + %s\n",tmp->GetName(),
                                                $<tokenpos>1->GetName(),
                                                $<tokenpos>3->GetName());
                        TmpVarGenerator.FreeTemp($<tokenpos>1);
                        TmpVarGenerator.FreeTemp($<tokenpos>3);
                        $<tokenpos>$ = tmp;
                     }
                  |  simple_expression
                     '-'
                     term
                     {
                        if (($<tokenpos>1->GetType() != INT_TOK) ||
                            ($<tokenpos>3->GetType() != INT_TOK) ||
                            ($<tokenpos>1->GetType() != $<tokenpos>3->GetType()))
                               error(ERR_TYPEMISMATCH);
                        Token *tmp = TmpVarGenerator.NewTemp();
                        printf("%s = %s - %s\n",tmp->GetName(),
                                                $<tokenpos>1->GetName(),
                                                $<tokenpos>3->GetName());
                        TmpVarGenerator.FreeTemp($<tokenpos>1);
                        TmpVarGenerator.FreeTemp($<tokenpos>3);
                        $<tokenpos>$ = tmp;
                     }
                  |  simple_expression
                     OR_TOK
                     term
                     {
                        if (($<tokenpos>1->GetType() != INT_TOK) ||
                            ($<tokenpos>3->GetType() != INT_TOK) ||
                            ($<tokenpos>1->GetType() != $<tokenpos>3->GetType()))
                               error(ERR_TYPEMISMATCH);
                        Token *tmp = TmpVarGenerator.NewTemp();
                        printf("%s = %s | %s\n",tmp->GetName(),
                                                $<tokenpos>1->GetName(),
                                                $<tokenpos>3->GetName());
                        TmpVarGenerator.FreeTemp($<tokenpos>1);
                        TmpVarGenerator.FreeTemp($<tokenpos>3);
                        $<tokenpos>$ = tmp;
                     }
						;

term	:	factor
         {
            $<tokenpos>$ = $<tokenpos>1;
         }
      |	term
         '*'
         factor
         {
            if (($<tokenpos>1->GetType() != INT_TOK) ||
                ($<tokenpos>3->GetType() != INT_TOK) ||
                ($<tokenpos>1->GetType() != $<tokenpos>3->GetType()))
                   error(ERR_TYPEMISMATCH);
            Token *tmp = TmpVarGenerator.NewTemp();
            printf("%s = %s * %s\n",tmp->GetName(),
                                    $<tokenpos>1->GetName(),
                                    $<tokenpos>3->GetName());
            TmpVarGenerator.FreeTemp($<tokenpos>1);
            TmpVarGenerator.FreeTemp($<tokenpos>3);
            $<tokenpos>$ = tmp;
         }
      |  term
         '/'
         factor
         {
            if (($<tokenpos>1->GetType() != INT_TOK) ||
                ($<tokenpos>3->GetType() != INT_TOK) ||
                ($<tokenpos>1->GetType() != $<tokenpos>3->GetType()))
                   error(ERR_TYPEMISMATCH);
            Token *tmp = TmpVarGenerator.NewTemp();
            printf("%s = %s / %s\n",tmp->GetName(),
                                    $<tokenpos>1->GetName(),
                                    $<tokenpos>3->GetName());
            TmpVarGenerator.FreeTemp($<tokenpos>1);
            TmpVarGenerator.FreeTemp($<tokenpos>3);
            $<tokenpos>$ = tmp;
         }
      |  term
         AND_TOK
         factor
         {
            if (($<tokenpos>1->GetType() != INT_TOK) ||
                ($<tokenpos>3->GetType() != INT_TOK) ||
                ($<tokenpos>1->GetType() != $<tokenpos>3->GetType()))
                   error(ERR_TYPEMISMATCH);
            Token *tmp = TmpVarGenerator.NewTemp();
            printf("%s = %s & %s\n",tmp->GetName(),
                                    $<tokenpos>1->GetName(),
                                    $<tokenpos>3->GetName());
            TmpVarGenerator.FreeTemp($<tokenpos>1);
            TmpVarGenerator.FreeTemp($<tokenpos>3);
            $<tokenpos>$ = tmp;
         }
      |  term
         DIV_TOK
         factor
         {
            if (($<tokenpos>1->GetType() != INT_TOK) ||
                ($<tokenpos>3->GetType() != INT_TOK) ||
                ($<tokenpos>1->GetType() != $<tokenpos>3->GetType()))
                   error(ERR_TYPEMISMATCH);
            Token *tmp = TmpVarGenerator.NewTemp();
            printf("%s = %s / %s\n",tmp->GetName(),
                                    $<tokenpos>1->GetName(),
                                    $<tokenpos>3->GetName());
            TmpVarGenerator.FreeTemp($<tokenpos>1);
            TmpVarGenerator.FreeTemp($<tokenpos>3);
            $<tokenpos>$ = tmp;
         }
      |  term
         MOD_TOK
         factor
         {
            if (($<tokenpos>1->GetType() != INT_TOK) ||
                ($<tokenpos>3->GetType() != INT_TOK) ||
                ($<tokenpos>1->GetType() != $<tokenpos>3->GetType()))
                   error(ERR_TYPEMISMATCH);
            Token *tmp = TmpVarGenerator.NewTemp();
            printf("%s = %s %% %s\n",tmp->GetName(),
                                    $<tokenpos>1->GetName(),
                                    $<tokenpos>3->GetName());
            TmpVarGenerator.FreeTemp($<tokenpos>1);
            TmpVarGenerator.FreeTemp($<tokenpos>3);
            $<tokenpos>$ = tmp;
         }
		;

factor	:	ID
            {
               $$ = $1;
            }
         |  ID
            '['
            expression
            ']'
            {
               Token *tmp = TmpVarGenerator.NewTemp();
               printf("%s = %s[%s]\n",tmp->GetName(),$<tokenpos>1->GetName(),
                                      $<tokenpos>3->GetName());
               TmpVarGenerator.FreeTemp($<tokenpos>3);
               $$ = tmp;
            }
         |  FUNC_ID
            {
               if ($1->GetParamCount() != 0)
                  error(ERR_PARAMCOUNT);
               else
                  {
                     printf("callfunc %s\n",$<tokenpos>1->GetName());
                     $$ = $1;
                  }
            }
         |  FUNC_ID
            '('
            expression_list
            ')'
            {
               if ($<tokenpos>1->GetParamCount() != $<intval>3)
                  error(ERR_PARAMCOUNT);
               else
               {
                  printf("callfunc %s\n",$<tokenpos>1->GetName());
                  $$ = $1;
               }
            }
			|	NUM
            {
               Token *tmp = TmpVarGenerator.NewTemp();
               printf("%s = %d\n",tmp->GetName(),$<intval>1);
               $$ = tmp;
            }
			|	CHARCONST
            {
               Token *tmp = TmpVarGenerator.NewTemp(CHAR_TOK);
               printf("%s = '%c'\n",tmp->GetName(),$<charval>1);
               $$ = tmp;
            }
			|	'('
            expression
            ')'
            {
               $$ = $2;
            }
			|	NOT_TOK
            factor
            {
               Token *tmp = TmpVarGenerator.NewTemp();
               printf("%s = ~%s\n",tmp->GetName(),
                                   $<tokenpos>2->GetName());
               TmpVarGenerator.FreeTemp($<tokenpos>2);
               $$ = tmp;
            }
         |  '-'
            factor %prec UMINUS
            {
               Token *tmp = TmpVarGenerator.NewTemp();
               printf("%s = -%s\n",tmp->GetName(),
                                   $<tokenpos>2->GetName());
               TmpVarGenerator.FreeTemp($<tokenpos>2);
               $$ = tmp;
            }
			;

%%


extern int line,column;

void yyerror(char const *s)
{
	fprintf(stderr,"Error: %s in line %d, column %d\n",s,line,column);
	exit(1);
} /* yyerror() */
