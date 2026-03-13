#pragma once
// llvmcodegen.h - LLVM IR Code Generation for APC
// Replaces the original printf-based custom IR with LLVM IR via the LLVM C++ API.

#include <llvm/IR/IRBuilder.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/Module.h>
#include <llvm/IR/Value.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/BasicBlock.h>
#include <llvm/IR/Verifier.h>
#include <llvm/Support/raw_ostream.h>
#include <llvm/Support/FileSystem.h>

#include <string>
#include <map>
#include <vector>
#include <stack>

#define ICG_INT  0
#define ICG_CHAR 1

struct FunctionContext {
    llvm::Function                         *func;
    llvm::BasicBlock                       *entryBB;
    std::map<std::string, llvm::AllocaInst*> locals;
    std::vector<std::string>                paramNames;
};

class LLVMCodeGen {
public:
    LLVMCodeGen(const std::string &moduleName, const std::string &outputFile);
    ~LLVMCodeGen();

    void finish();

    // Globals
    void declareGlobalInt(const std::string &name);
    void declareGlobalChar(const std::string &name);
    void declareGlobalIntArray(const std::string &name, int size);
    void declareGlobalCharArray(const std::string &name, int size);

    // Procedures / Functions
    void startProc(const std::string &name,
                   const std::vector<std::pair<std::string,int>> &params);
    void startIntFunc(const std::string &name,
                      const std::vector<std::pair<std::string,int>> &params);
    void startCharFunc(const std::string &name,
                       const std::vector<std::pair<std::string,int>> &params);
    void endProc();

    // Locals
    void declareLocalInt(const std::string &name);
    void declareLocalChar(const std::string &name);

    // Assignments
    void emitAssign(const std::string &dest, const std::string &src);
    void emitArrayStore(const std::string &arr, const std::string &idx, const std::string &val);
    std::string emitArrayLoad(const std::string &arr, const std::string &idx);

    // Arithmetic / logic
    std::string emitAdd(const std::string &a, const std::string &b);
    std::string emitSub(const std::string &a, const std::string &b);
    std::string emitMul(const std::string &a, const std::string &b);
    std::string emitDiv(const std::string &a, const std::string &b);
    std::string emitMod(const std::string &a, const std::string &b);
    std::string emitAnd(const std::string &a, const std::string &b);
    std::string emitOr(const std::string &a, const std::string &b);
    std::string emitNot(const std::string &a);
    std::string emitNeg(const std::string &a);

    // Relational
    std::string emitRelop(const std::string &op,
                          const std::string &a, const std::string &b);

    // Constants
    std::string emitIntConst(int val);
    std::string emitCharConst(char val);

    // Control flow
    int  newLabel();
    void emitLabel(int labelId);
    void emitGoto(int labelId);
    void emitGoFalse(const std::string &cond, int labelId);

    // Calls
    void        emitCallProc(const std::string &name,
                             const std::vector<std::string> &args);
    std::string emitCallFunc(const std::string &name,
                             const std::vector<std::string> &args);

    void emitReturn(const std::string &valName);

    // Pending args
    void pushArg(const std::string &name);
    std::vector<std::string> flushArgs();

    // Scope query
    bool isGlobalScope() const { return funcStack_.empty(); }

private:
    llvm::LLVMContext                       ctx_;
    std::unique_ptr<llvm::Module>           mod_;
    std::unique_ptr<llvm::IRBuilder<>>      builder_;
    std::string                             outFile_;

    std::map<std::string, llvm::GlobalVariable*> globals_;
    std::map<std::string, llvm::Function*>       functions_;
    std::stack<FunctionContext>                  funcStack_;

    int                                     labelCounter_;
    std::map<int, llvm::BasicBlock*>        labelBlocks_;
    std::vector<std::string>                pendingArgs_;
    int                                     tempCounter_;

    llvm::Type* intTy();
    llvm::Type* charTy();
    llvm::Type* voidTy();

    llvm::Value*      loadName(const std::string &name);
    llvm::AllocaInst* getAlloca(const std::string &name);
    void              storeName(const std::string &name, llvm::Value *val);
    llvm::AllocaInst* createEntryAlloca(const std::string &name, llvm::Type *ty);
    llvm::BasicBlock* getOrCreateBlock(int labelId);
    void              ensureTerminated(llvm::BasicBlock *fallthrough);
    std::string       newTemp();
    llvm::Function*   createFunction(const std::string &name,
                                     llvm::Type *retTy,
                                     const std::vector<std::pair<std::string,int>> &params);
};

extern LLVMCodeGen *gCodeGen;
