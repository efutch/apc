/* main.cpp - programa principal para el compilador de pascal-a */
/* Escrito por Egdares Futch H.                                 */
/* Updated 2024: LLVM IR backend + x86 code generation          */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "token.h"
#include "table.h"
#include "parser.tab.h"
#include "tmpvar.h"
#include "llvmcodegen.h"

// LLVM initialization headers
#include <llvm/Support/TargetSelect.h>
#include <llvm/Support/raw_ostream.h>

// Line/column tracking
int column = 1;
int line   = 1;

extern int yyparse();
void usage(void);

SymbolTable *CurrentSymbolTable, *GlobalSymbolTable;
TmpVars      TmpVarGenerator;

// Build output filename: replace .pas extension with given ext
static std::string makeOutputName(const char *input, const char *ext)
{
    std::string out(input);
    auto dot = out.rfind('.');
    if (dot != std::string::npos)
        out = out.substr(0, dot);
    out += ext;
    return out;
}

int main(int argc, char *argv[])
{
    // ---- Initialize LLVM targets for x86 ----
    llvm::InitializeAllTargetInfos();
    llvm::InitializeAllTargets();
    llvm::InitializeAllTargetMCs();
    llvm::InitializeAllAsmParsers();
    llvm::InitializeAllAsmPrinters();

    extern FILE *yyin;
    GlobalSymbolTable = new SymbolTable;

    if (argc < 2)
        usage();

    // Determine output filenames
    std::string llFile  = makeOutputName(argv[1], ".ll");
    std::string asmFile = makeOutputName(argv[1], ".s");
    std::string objFile = makeOutputName(argv[1], ".o");
    std::string exeFile = makeOutputName(argv[1], "");

    yyin = fopen(argv[1], "rt");
    if (yyin == NULL) {
        perror("apc");
        exit(1);
    }

    printf("APC compiling %s\n", argv[1]);

    // ---- Create global LLVM codegen instance ----
    gCodeGen = new LLVMCodeGen(argv[1], llFile);

    CurrentSymbolTable = GlobalSymbolTable;

    while (yyparse())
        ;

    // ---- Finalize: write .ll file ----
    gCodeGen->finish();
    delete gCodeGen;
    gCodeGen = nullptr;

    printf("\nAPC finished compiling. LLVM IR -> %s\n", llFile.c_str());

    // ---- Invoke llc to generate x86 assembly ----
    {
        char cmd[1024];
        snprintf(cmd, sizeof(cmd),
                 "llc -filetype=asm -march=aarch64 -o %s %s",
                 asmFile.c_str(), llFile.c_str());
        printf("Running: %s\n", cmd);
        int rc = system(cmd);
        if (rc != 0) {
            fprintf(stderr, "llc failed (exit %d)\n", rc);
            return 1;
        }
        printf("Assembly -> %s\n", asmFile.c_str());
    }

    // ---- Invoke llc again to produce object file ----
    {
        char cmd[1024];
        snprintf(cmd, sizeof(cmd),
                 "llc -filetype=obj -march=aarch64 -o %s %s",
                 objFile.c_str(), llFile.c_str());
        printf("Running: %s\n", cmd);
        int rc = system(cmd);
        if (rc != 0) {
            fprintf(stderr, "llc (obj) failed (exit %d)\n", rc);
            return 1;
        }
        printf("Object   -> %s\n", objFile.c_str());
    }

    // ---- Link with clang to produce executable ----
    {
        char cmd[1024];
        snprintf(cmd, sizeof(cmd),
                 "gcc -o %s %s",
                 exeFile.c_str(), objFile.c_str());
        printf("Running: %s\n", cmd);
        int rc = system(cmd);
        if (rc != 0) {
            fprintf(stderr, "gcc link failed (exit %d)\n", rc);
            return 1;
        }
        printf("Executable -> %s\n", exeFile.c_str());
    }

    printf("\nDone.\n");
    return 0;
}

void usage(void)
{
    printf("APC      : A Pascal Compiler (LLVM backend)\n"
           "           Compiles Pascal-A source to AArch64 via LLVM IR.\n"
           "           Produces: <file>.ll  (LLVM IR)\n"
           "                     <file>.s   (AArch64 assembly)\n"
           "                     <file>.o   (object file)\n"
           "                     <file>     (executable)\n"
           "\n Usage : apc filename.pas\n");
    exit(1);
}
