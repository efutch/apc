%{
#include <stdio.h>
#include <ctype.h>
#include <vector>
#include <string>
#include <utility>

#include "protos.h"
#include "token.h"
#include "tmpvar.h"
#include "error.h"
#include "table.h"
#include "llvmcodegen.h"

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

// Pending procedure/function argument types for startProc/startFunc
static std::vector<std::pair<std::string,int>> gPendingParams;

%}

%union
{
   int intval;
   unsigned char charval;
   int opval;
   Token *tokenpos;
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
%left     '+' '-' OR_TOK
%left     '*' '/' DIV_TOK MOD_TOK AND_TOK
%left     UMINUS

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

program :
            PROG_TOK
            allow_ids
            ID
            '('
            untyped_id_list
            ')'
            disallow_ids
            ';'
            subprogram_declarations
            {
               // Start main BEFORE its local declarations
               gPendingParams.clear();
               gCodeGen->startProc("main", gPendingParams);
            }
            declarations
            compound_statement
            '.'
            {
               gCodeGen->endProc();
            }
         ;

untyped_id_list  :  ID
                 |  untyped_id_list ',' ID
                 ;

identifier_list  :  ID
                    typed_id_list
                    {
                       $<tokenpos>1->SetType($<typeinfo>2[0]);
                       switch ($<typeinfo>2[0])
                       {
                          case INT_TOK:
                             if (CanInsert)
                             {
                                if (gCodeGen->isGlobalScope())
                                   gCodeGen->declareGlobalInt($<tokenpos>1->GetName());
                                else
                                   gCodeGen->declareLocalInt($<tokenpos>1->GetName());
                             }
                             break;
                          case CHAR_TOK:
                             if (CanInsert)
                             {
                                if (gCodeGen->isGlobalScope())
                                   gCodeGen->declareGlobalChar($<tokenpos>1->GetName());
                                else
                                   gCodeGen->declareLocalChar($<tokenpos>1->GetName());
                             }
                             break;
                          case ARR_INT:
                          {
                             int size = $<typeinfo>2[3] - $<typeinfo>2[2] + 1;
                             $<tokenpos>1->SetLowArrBound($<typeinfo>2[2]);
                             $<tokenpos>1->SetHighArrBound($<typeinfo>2[3]);
                             if (CanInsert)
                                gCodeGen->declareGlobalIntArray($<tokenpos>1->GetName(), size);
                             break;
                          }
                          case ARR_CHAR:
                          {
                             int size = $<typeinfo>2[3] - $<typeinfo>2[2] + 1;
                             $<tokenpos>1->SetLowArrBound($<typeinfo>2[2]);
                             $<tokenpos>1->SetHighArrBound($<typeinfo>2[3]);
                             if (CanInsert)
                                gCodeGen->declareGlobalCharArray($<tokenpos>1->GetName(), size);
                             break;
                          }
                       }
                       $<typeinfo>$[0] = $<typeinfo>2[0];
                       $<typeinfo>$[1] = $<typeinfo>2[1];
                       $<typeinfo>$[2] = $<typeinfo>2[2];
                       $<typeinfo>$[3] = $<typeinfo>2[3];
                       $<typeinfo>$[4] = $<typeinfo>2[4];
                       $<typeinfo>$[4]++;
                       // Also register as pending param if inside subprogram head
                       if (CanInsert && !gPendingParams.empty())
                       {
                          // params accumulate separately; just track type
                       }
                    }
                 ;

typed_id_list    :  ','
                    ID
                    typed_id_list
                    {
                       $<tokenpos>2->SetType($<typeinfo>3[0]);
                       switch ($<typeinfo>3[0])
                       {
                          case INT_TOK:
                             if (CanInsert)
                             {
                                if (gCodeGen->isGlobalScope())
                                   gCodeGen->declareGlobalInt($<tokenpos>2->GetName());
                                else
                                   gCodeGen->declareLocalInt($<tokenpos>2->GetName());
                             }
                             break;
                          case CHAR_TOK:
                             if (CanInsert)
                             {
                                if (gCodeGen->isGlobalScope())
                                   gCodeGen->declareGlobalChar($<tokenpos>2->GetName());
                                else
                                   gCodeGen->declareLocalChar($<tokenpos>2->GetName());
                             }
                             break;
                          case ARR_INT:
                          {
                             int size = $<typeinfo>3[3] - $<typeinfo>3[2] + 1;
                             $<tokenpos>2->SetLowArrBound($<typeinfo>3[2]);
                             $<tokenpos>2->SetHighArrBound($<typeinfo>3[3]);
                             if (CanInsert)
                                gCodeGen->declareGlobalIntArray($<tokenpos>2->GetName(), size);
                             break;
                          }
                          case ARR_CHAR:
                          {
                             int size = $<typeinfo>3[3] - $<typeinfo>3[2] + 1;
                             $<tokenpos>2->SetLowArrBound($<typeinfo>3[2]);
                             $<tokenpos>2->SetHighArrBound($<typeinfo>3[3]);
                             if (CanInsert)
                                gCodeGen->declareGlobalCharArray($<tokenpos>2->GetName(), size);
                             break;
                          }
                       }
                       $<typeinfo>$[0] = $<typeinfo>3[0];
                       $<typeinfo>$[1] = $<typeinfo>3[1];
                       $<typeinfo>$[2] = $<typeinfo>3[2];
                       $<typeinfo>$[3] = $<typeinfo>3[3];
                       $<typeinfo>$[4] = $<typeinfo>3[4];
                       $<typeinfo>$[4]++;
                    }
                 |  ':'
                    type
                    {
                       $<typeinfo>$[0] = $<typeinfo>2[0];
                       $<typeinfo>$[1] = $<typeinfo>2[1];
                       $<typeinfo>$[2] = $<typeinfo>2[2];
                       $<typeinfo>$[3] = $<typeinfo>2[3];
                       $<typeinfo>$[4] = $<typeinfo>2[4];
                    }
                 ;

declarations  :  declarations
                 VAR_TOK
                 allow_ids
                 identifier_list
                 ';'
                 disallow_ids
              |
              ;

type  :  standard_type
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

standard_type  :  INT_TOK
                  {
                     $<typeinfo>$[0] = INT_TOK;
                     $<typeinfo>$[4] = 0;
                  }
               |  CHAR_TOK
                  {
                     $<typeinfo>$[0] = CHAR_TOK;
                     $<typeinfo>$[4] = 0;
                  }
               ;

subprogram_declarations  :  subprogram_declarations
                            subprogram_declaration
                            ';'
                         |
                         ;

subprogram_declaration  :  allow_ids
                           subprogram_head
                           declarations
                           disallow_ids
                           compound_statement
                           {
                              gCodeGen->endProc();
                              CurrentSymbolTable = GlobalSymbolTable;
                              delete LocalSymbolTable;
                           }
                        ;

subprogram_head  :  PROC_TOK
                    {
                       proc_id = 1;
                       gPendingParams.clear();
                    }
                    PROC_ID
                    {
                       proc_id = 0;
                       LocalSymbolTable = new SymbolTable(CurrentSymbolTable);
                       CurrentSymbolTable = LocalSymbolTable;
                    }
                    arguments
                    {
                       $<tokenpos>3->SetParamCount($<typeinfo>5[4]);
                       std::string procName = "_" + std::string($<tokenpos>3->GetName());
                       gCodeGen->startProc(procName, gPendingParams);
                       gPendingParams.clear();
                    }
                    ';'
                 |  FUNC_TOK
                    {
                       func_id = 1;
                       gPendingParams.clear();
                    }
                    FUNC_ID
                    {
                       func_id = 0;
                       LocalSymbolTable = new SymbolTable(CurrentSymbolTable);
                       CurrentSymbolTable = LocalSymbolTable;
                    }
                    arguments
                    {
                       $<tokenpos>3->SetParamCount($<typeinfo>5[4]);
                    }
                    ':'
                    standard_type
                    {
                       $<tokenpos>3->SetFuncReturnType($<typeinfo>8[0]);
                       std::string funcName = "_" + std::string($<tokenpos>3->GetName());
                       if ($<typeinfo>8[0] == INT_TOK)
                          gCodeGen->startIntFunc(funcName, gPendingParams);
                       else
                          gCodeGen->startCharFunc(funcName, gPendingParams);
                       gPendingParams.clear();
                    }
                    ';'
                 ;

arguments  :  '('
              parameter_list
              ')'
              {
                  $<typeinfo>$[0] = $<typeinfo>2[0];
                  $<typeinfo>$[1] = $<typeinfo>2[1];
                  $<typeinfo>$[2] = $<typeinfo>2[2];
                  $<typeinfo>$[3] = $<typeinfo>2[3];
                  $<typeinfo>$[4] = $<typeinfo>2[4];
              }
           |  { $<typeinfo>$[4] = 0; }
           ;

parameter_list  :  identifier_list
               |   parameter_list
                   ';'
                   identifier_list
                   {
                       $<typeinfo>$[0] = $<typeinfo>3[0];
                       $<typeinfo>$[1] = $<typeinfo>3[1];
                       $<typeinfo>$[2] = $<typeinfo>3[2];
                       $<typeinfo>$[3] = $<typeinfo>3[3];
                       $<typeinfo>$[4] = $<typeinfo>3[4];
                   }
               ;

compound_statement  :  BEGIN_TOK
                       optional_statements
                       END_TOK
                    ;

optional_statements  :  statement_list
                     |
                     ;

statement_list  :  statement
               |   statement_list
                   ';'
                   statement
               ;

statement  :  variable
              ASSIGNOP
              expression
              {
                 Token *tmpoffset = $1->GetOffset();
                 if (tmpoffset)
                 {
                    gCodeGen->emitArrayStore($<tokenpos>1->GetName(),
                                             tmpoffset->GetName(),
                                             $<tokenpos>3->GetName());
                    TmpVarGenerator.FreeTemp(tmpoffset);
                    $1->SetOffset(NULL);
                 }
                 else
                    gCodeGen->emitAssign($<tokenpos>1->GetName(),
                                         $<tokenpos>3->GetName());
                 TmpVarGenerator.FreeTemp($<tokenpos>3);
                 $<tokenpos>$ = $<tokenpos>1;
              }
           |  procedure_statement
           |  compound_statement
           |  IF_TOK
              expression
              THEN_TOK
              {
                 $<typeinfo>$[FALSELABEL] = gCodeGen->newLabel();
                 $<typeinfo>$[OUTLABEL]   = gCodeGen->newLabel();
                 gCodeGen->emitGoFalse($2->GetName(), $<typeinfo>$[FALSELABEL]);
                 TmpVarGenerator.FreeTemp($2);
              }
              statement
              {
                 gCodeGen->emitGoto($<typeinfo>4[OUTLABEL]);
                 gCodeGen->emitLabel($<typeinfo>4[FALSELABEL]);
              }
              else_part
              {
                 gCodeGen->emitLabel($<typeinfo>4[OUTLABEL]);
              }
           |  WHILE_TOK
              {
                 $<typeinfo>$[OUTLABEL]   = gCodeGen->newLabel();
                 $<typeinfo>$[STARTLABEL] = gCodeGen->newLabel();
                 gCodeGen->emitLabel($<typeinfo>$[STARTLABEL]);
              }
              expression
              {
                 gCodeGen->emitGoFalse($3->GetName(), $<typeinfo>2[OUTLABEL]);
              }
              DO_TOK
              statement
              {
                 gCodeGen->emitGoto($<typeinfo>2[STARTLABEL]);
                 gCodeGen->emitLabel($<typeinfo>2[OUTLABEL]);
                 TmpVarGenerator.FreeTemp($3);
              }
           ;

else_part  :  ELSE_TOK
              statement
           |
           ;

variable  :  ID
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

procedure_statement  :  PROC_ID
                        {
                           if ($<tokenpos>1->GetParamCount() != 0)
                              apc_error(ERR_PARAMCOUNT);
                           else
                           {
                              std::string procName = std::string($<tokenpos>1->GetName());
                              std::vector<std::string> args = gCodeGen->flushArgs();
                              gCodeGen->emitCallProc(procName, args);
                           }
                        }
                     |  PROC_ID
                        '('
                        expression_list
                        ')'
                        {
                           if ($<tokenpos>1->GetParamCount() != $<intval>3)
                              apc_error(ERR_PARAMCOUNT);
                           else
                           {
                              std::string procName = std::string($<tokenpos>1->GetName());
                              std::vector<std::string> args = gCodeGen->flushArgs();
                              gCodeGen->emitCallProc(procName, args);
                           }
                        }
                     ;

expression_list  :  expression
                    {
                       gCodeGen->pushArg($<tokenpos>1->GetName());
                       TmpVarGenerator.FreeTemp($<tokenpos>1);
                       $<intval>$ = 1;
                    }
                 |  expression_list
                    ','
                    expression
                    {
                       gCodeGen->pushArg($<tokenpos>3->GetName());
                       TmpVarGenerator.FreeTemp($<tokenpos>3);
                       $<intval>$ = $<intval>1 + 1;
                    }
                 ;

expression  :  simple_expression
               {
                  $<tokenpos>$ = $<tokenpos>1;
               }
            |  simple_expression
               RELOP
               simple_expression
               {
                  static const char* RelOps[] = { "==","!=","<","<=",">=",">" };
                  std::string tmp = gCodeGen->emitRelop(RelOps[$<opval>2],
                                                        $<tokenpos>1->GetName(),
                                                        $<tokenpos>3->GetName());
                  TmpVarGenerator.FreeTemp($<tokenpos>1);
                  TmpVarGenerator.FreeTemp($<tokenpos>3);
                  // Return a synthetic Token pointing at tmp name
                  Token *t = TmpVarGenerator.NewTemp();
                  // Reuse name from gCodeGen result
                  // (TmpVarGenerator only manages its own pool; we just need a Token*)
                  // Store tmp name in token — requires a Token that can hold arbitrary name.
                  // Use a global/local lookup trick: declare local and reuse.
                  // Simplest: just return $1 renamed. Actually, we wrap in a new token.
                  $<tokenpos>$ = t;
                  // The actual LLVM value is already stored under tmp name.
                  // We need the Token name to match. Patch via a local alias.
                  gCodeGen->emitAssign(t->GetName(), tmp);
               }
            ;

simple_expression  :  term
                      {
                         $<tokenpos>$ = $<tokenpos>1;
                      }
                   |  simple_expression
                      '+'
                      term
                      {
                         if (($<tokenpos>1->GetType() != INT_TOK) ||
                             ($<tokenpos>3->GetType() != INT_TOK))
                                apc_error(ERR_TYPEMISMATCH);
                         Token *tmp = TmpVarGenerator.NewTemp();
                         std::string result = gCodeGen->emitAdd($<tokenpos>1->GetName(),
                                                                $<tokenpos>3->GetName());
                         gCodeGen->emitAssign(tmp->GetName(), result);
                         TmpVarGenerator.FreeTemp($<tokenpos>1);
                         TmpVarGenerator.FreeTemp($<tokenpos>3);
                         $<tokenpos>$ = tmp;
                      }
                   |  simple_expression
                      '-'
                      term
                      {
                         if (($<tokenpos>1->GetType() != INT_TOK) ||
                             ($<tokenpos>3->GetType() != INT_TOK))
                                apc_error(ERR_TYPEMISMATCH);
                         Token *tmp = TmpVarGenerator.NewTemp();
                         std::string result = gCodeGen->emitSub($<tokenpos>1->GetName(),
                                                                $<tokenpos>3->GetName());
                         gCodeGen->emitAssign(tmp->GetName(), result);
                         TmpVarGenerator.FreeTemp($<tokenpos>1);
                         TmpVarGenerator.FreeTemp($<tokenpos>3);
                         $<tokenpos>$ = tmp;
                      }
                   |  simple_expression
                      OR_TOK
                      term
                      {
                         if (($<tokenpos>1->GetType() != INT_TOK) ||
                             ($<tokenpos>3->GetType() != INT_TOK))
                                apc_error(ERR_TYPEMISMATCH);
                         Token *tmp = TmpVarGenerator.NewTemp();
                         std::string result = gCodeGen->emitOr($<tokenpos>1->GetName(),
                                                               $<tokenpos>3->GetName());
                         gCodeGen->emitAssign(tmp->GetName(), result);
                         TmpVarGenerator.FreeTemp($<tokenpos>1);
                         TmpVarGenerator.FreeTemp($<tokenpos>3);
                         $<tokenpos>$ = tmp;
                      }
                   ;

term  :  factor
         {
            $<tokenpos>$ = $<tokenpos>1;
         }
      |  term
         '*'
         factor
         {
            if (($<tokenpos>1->GetType() != INT_TOK) ||
                ($<tokenpos>3->GetType() != INT_TOK))
                   apc_error(ERR_TYPEMISMATCH);
            Token *tmp = TmpVarGenerator.NewTemp();
            std::string result = gCodeGen->emitMul($<tokenpos>1->GetName(),
                                                   $<tokenpos>3->GetName());
            gCodeGen->emitAssign(tmp->GetName(), result);
            TmpVarGenerator.FreeTemp($<tokenpos>1);
            TmpVarGenerator.FreeTemp($<tokenpos>3);
            $<tokenpos>$ = tmp;
         }
      |  term
         '/'
         factor
         {
            if (($<tokenpos>1->GetType() != INT_TOK) ||
                ($<tokenpos>3->GetType() != INT_TOK))
                   apc_error(ERR_TYPEMISMATCH);
            Token *tmp = TmpVarGenerator.NewTemp();
            std::string result = gCodeGen->emitDiv($<tokenpos>1->GetName(),
                                                   $<tokenpos>3->GetName());
            gCodeGen->emitAssign(tmp->GetName(), result);
            TmpVarGenerator.FreeTemp($<tokenpos>1);
            TmpVarGenerator.FreeTemp($<tokenpos>3);
            $<tokenpos>$ = tmp;
         }
      |  term
         AND_TOK
         factor
         {
            if (($<tokenpos>1->GetType() != INT_TOK) ||
                ($<tokenpos>3->GetType() != INT_TOK))
                   apc_error(ERR_TYPEMISMATCH);
            Token *tmp = TmpVarGenerator.NewTemp();
            std::string result = gCodeGen->emitAnd($<tokenpos>1->GetName(),
                                                   $<tokenpos>3->GetName());
            gCodeGen->emitAssign(tmp->GetName(), result);
            TmpVarGenerator.FreeTemp($<tokenpos>1);
            TmpVarGenerator.FreeTemp($<tokenpos>3);
            $<tokenpos>$ = tmp;
         }
      |  term
         DIV_TOK
         factor
         {
            if (($<tokenpos>1->GetType() != INT_TOK) ||
                ($<tokenpos>3->GetType() != INT_TOK))
                   apc_error(ERR_TYPEMISMATCH);
            Token *tmp = TmpVarGenerator.NewTemp();
            std::string result = gCodeGen->emitDiv($<tokenpos>1->GetName(),
                                                   $<tokenpos>3->GetName());
            gCodeGen->emitAssign(tmp->GetName(), result);
            TmpVarGenerator.FreeTemp($<tokenpos>1);
            TmpVarGenerator.FreeTemp($<tokenpos>3);
            $<tokenpos>$ = tmp;
         }
      |  term
         MOD_TOK
         factor
         {
            if (($<tokenpos>1->GetType() != INT_TOK) ||
                ($<tokenpos>3->GetType() != INT_TOK))
                   apc_error(ERR_TYPEMISMATCH);
            Token *tmp = TmpVarGenerator.NewTemp();
            std::string result = gCodeGen->emitMod($<tokenpos>1->GetName(),
                                                   $<tokenpos>3->GetName());
            gCodeGen->emitAssign(tmp->GetName(), result);
            TmpVarGenerator.FreeTemp($<tokenpos>1);
            TmpVarGenerator.FreeTemp($<tokenpos>3);
            $<tokenpos>$ = tmp;
         }
      ;

factor  :  ID
           {
              $$ = $1;
           }
        |  ID
           '['
           expression
           ']'
           {
              Token *tmp = TmpVarGenerator.NewTemp();
              std::string result = gCodeGen->emitArrayLoad($<tokenpos>1->GetName(),
                                                           $<tokenpos>3->GetName());
              gCodeGen->emitAssign(tmp->GetName(), result);
              TmpVarGenerator.FreeTemp($<tokenpos>3);
              $$ = tmp;
           }
        |  FUNC_ID
           {
              if ($1->GetParamCount() != 0)
                 apc_error(ERR_PARAMCOUNT);
              else
              {
                 std::string funcName = "_" + std::string($<tokenpos>1->GetName());
                 Token *tmp = TmpVarGenerator.NewTemp();
                 std::string result = gCodeGen->emitCallFunc(funcName, {});
                 gCodeGen->emitAssign(tmp->GetName(), result);
                 $$ = tmp;
              }
           }
        |  FUNC_ID
           '('
           expression_list
           ')'
           {
              if ($<tokenpos>1->GetParamCount() != $<intval>3)
                 apc_error(ERR_PARAMCOUNT);
              else
              {
                 std::string funcName = "_" + std::string($<tokenpos>1->GetName());
                 std::vector<std::string> args = gCodeGen->flushArgs();
                 Token *tmp = TmpVarGenerator.NewTemp();
                 std::string result = gCodeGen->emitCallFunc(funcName, args);
                 gCodeGen->emitAssign(tmp->GetName(), result);
                 $$ = tmp;
              }
           }
        |  NUM
           {
              Token *tmp = TmpVarGenerator.NewTemp();
              std::string result = gCodeGen->emitIntConst($<intval>1);
              gCodeGen->emitAssign(tmp->GetName(), result);
              $$ = tmp;
           }
        |  CHARCONST
           {
              Token *tmp = TmpVarGenerator.NewTemp(CHAR_TOK);
              std::string result = gCodeGen->emitCharConst($<charval>1);
              gCodeGen->emitAssign(tmp->GetName(), result);
              $$ = tmp;
           }
        |  '('
           expression
           ')'
           {
              $$ = $2;
           }
        |  NOT_TOK
           factor
           {
              Token *tmp = TmpVarGenerator.NewTemp();
              std::string result = gCodeGen->emitNot($<tokenpos>2->GetName());
              gCodeGen->emitAssign(tmp->GetName(), result);
              TmpVarGenerator.FreeTemp($<tokenpos>2);
              $$ = tmp;
           }
        |  '-'
           factor %prec UMINUS
           {
              Token *tmp = TmpVarGenerator.NewTemp();
              std::string result = gCodeGen->emitNeg($<tokenpos>2->GetName());
              gCodeGen->emitAssign(tmp->GetName(), result);
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
