// llvmcodegen.cpp - LLVM IR Code Generation for APC
#include "llvmcodegen.h"

#include <llvm/IR/Constants.h>
#include <llvm/IR/DerivedTypes.h>
#include <llvm/Support/raw_ostream.h>
#include <llvm/Support/FileSystem.h>
#include <llvm/IR/Verifier.h>
#include <llvm/TargetParser/Triple.h>

#include <cassert>

LLVMCodeGen *gCodeGen = nullptr;

// ---------------------------------------------------------------------------
// Construction / destruction
// ---------------------------------------------------------------------------

LLVMCodeGen::LLVMCodeGen(const std::string &moduleName,
                         const std::string &outputFile)
    : mod_(std::make_unique<llvm::Module>(moduleName, ctx_)),
      builder_(std::make_unique<llvm::IRBuilder<>>(ctx_)),
      outFile_(outputFile),
      labelCounter_(0),
      tempCounter_(0)
{
    mod_->setTargetTriple(llvm::Triple("aarch64-linux-gnu"));
}

LLVMCodeGen::~LLVMCodeGen() {}

// ---------------------------------------------------------------------------
// Finish
// ---------------------------------------------------------------------------

void LLVMCodeGen::finish()
{
    std::string errStr;
    llvm::raw_string_ostream errOS(errStr);
    if (llvm::verifyModule(*mod_, &errOS))
        fprintf(stderr, "LLVM module verification failed:\n%s\n", errStr.c_str());

    std::error_code ec;
    llvm::raw_fd_ostream out(outFile_, ec, llvm::sys::fs::OF_Text);
    if (ec) {
        fprintf(stderr, "Cannot open output file %s: %s\n",
                outFile_.c_str(), ec.message().c_str());
        return;
    }
    mod_->print(out, nullptr);
    fprintf(stdout, "LLVM IR written to %s\n", outFile_.c_str());
}

// ---------------------------------------------------------------------------
// Type helpers
// ---------------------------------------------------------------------------

llvm::Type* LLVMCodeGen::intTy()  { return llvm::Type::getInt32Ty(ctx_); }
llvm::Type* LLVMCodeGen::charTy() { return llvm::Type::getInt8Ty(ctx_);  }
llvm::Type* LLVMCodeGen::voidTy() { return llvm::Type::getVoidTy(ctx_);  }

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------

void LLVMCodeGen::declareGlobalInt(const std::string &name)
{
    auto *gv = new llvm::GlobalVariable(
        *mod_, intTy(), false,
        llvm::GlobalValue::ExternalLinkage,
        llvm::ConstantInt::get(intTy(), 0), name);
    globals_[name] = gv;
}

void LLVMCodeGen::declareGlobalChar(const std::string &name)
{
    auto *gv = new llvm::GlobalVariable(
        *mod_, charTy(), false,
        llvm::GlobalValue::ExternalLinkage,
        llvm::ConstantInt::get(charTy(), 0), name);
    globals_[name] = gv;
}

void LLVMCodeGen::declareGlobalIntArray(const std::string &name, int size)
{
    auto *arrTy = llvm::ArrayType::get(intTy(), size);
    auto *gv = new llvm::GlobalVariable(
        *mod_, arrTy, false,
        llvm::GlobalValue::ExternalLinkage,
        llvm::ConstantAggregateZero::get(arrTy), name);
    globals_[name] = gv;
}

void LLVMCodeGen::declareGlobalCharArray(const std::string &name, int size)
{
    auto *arrTy = llvm::ArrayType::get(charTy(), size);
    auto *gv = new llvm::GlobalVariable(
        *mod_, arrTy, false,
        llvm::GlobalValue::ExternalLinkage,
        llvm::ConstantAggregateZero::get(arrTy), name);
    globals_[name] = gv;
}

// ---------------------------------------------------------------------------
// Function creation
// ---------------------------------------------------------------------------

llvm::Function* LLVMCodeGen::createFunction(
    const std::string &name,
    llvm::Type *retTy,
    const std::vector<std::pair<std::string,int>> &params)
{
    std::vector<llvm::Type*> paramTys;
    for (auto &p : params)
        paramTys.push_back(p.second == ICG_CHAR ? charTy() : intTy());

    auto *fty = llvm::FunctionType::get(retTy, paramTys, false);
    auto *fn  = llvm::Function::Create(
        fty, llvm::Function::ExternalLinkage, name, *mod_);

    unsigned i = 0;
    for (auto &arg : fn->args())
        arg.setName(params[i++].first);

    functions_[name] = fn;
    return fn;
}

// Create the function, make it current, then give each parameter (and the
// result, for functions) a stack slot. The context must be pushed first:
// createEntryAlloca() allocates in the function on top of funcStack_.
void LLVMCodeGen::beginFunction(const std::string &name,
                                llvm::Type *retTy,
                                const std::vector<std::pair<std::string,int>> &params,
                                const std::string &resultVar)
{
    auto *fn = createFunction(name, retTy, params);
    auto *bb = llvm::BasicBlock::Create(ctx_, "entry", fn);
    builder_->SetInsertPoint(bb);

    FunctionContext fc;
    fc.func    = fn;
    fc.entryBB = bb;
    funcStack_.push(std::move(fc));
    auto &cur = funcStack_.top();

    for (auto &arg : fn->args()) {
        auto *alloca = createEntryAlloca(arg.getName().str(), arg.getType());
        builder_->CreateStore(&arg, alloca);
        cur.locals[arg.getName().str()] = alloca;
        cur.paramNames.push_back(arg.getName().str());
    }

    if (!retTy->isVoidTy()) {
        cur.retSlot = createEntryAlloca(name + "__retval", retTy);
        builder_->CreateStore(llvm::Constant::getNullValue(retTy), cur.retSlot);
        cur.locals[resultVar] = cur.retSlot;
    }

    labelBlocks_.clear();
}

void LLVMCodeGen::startProc(const std::string &name,
                            const std::vector<std::pair<std::string,int>> &params)
{
    beginFunction(name, voidTy(), params, "");
}

void LLVMCodeGen::startIntFunc(const std::string &name,
                               const std::vector<std::pair<std::string,int>> &params,
                               const std::string &resultVar)
{
    beginFunction(name, intTy(), params, resultVar);
}

void LLVMCodeGen::startCharFunc(const std::string &name,
                                const std::vector<std::pair<std::string,int>> &params,
                                const std::string &resultVar)
{
    beginFunction(name, charTy(), params, resultVar);
}

void LLVMCodeGen::endProc()
{
    assert(!funcStack_.empty());
    auto &fc = funcStack_.top();
    llvm::Function *fn = fc.func;

    if (!builder_->GetInsertBlock()->getTerminator()) {
        if (fn->getReturnType()->isVoidTy()) {
            builder_->CreateRetVoid();
        } else {
            if (fc.retSlot) {
                auto *val = builder_->CreateLoad(fn->getReturnType(),
                                                 fc.retSlot, "retval");
                builder_->CreateRet(val);
            } else {
                builder_->CreateRet(llvm::Constant::getNullValue(fn->getReturnType()));
            }
        }
    }
    funcStack_.pop();
    labelBlocks_.clear();
}

// ---------------------------------------------------------------------------
// Local declarations
// ---------------------------------------------------------------------------

void LLVMCodeGen::declareLocalInt(const std::string &name)
{
    auto *alloca = createEntryAlloca(name, intTy());
    builder_->CreateStore(llvm::ConstantInt::get(intTy(), 0), alloca);
    funcStack_.top().locals[name] = alloca;
}

void LLVMCodeGen::declareLocalChar(const std::string &name)
{
    auto *alloca = createEntryAlloca(name, charTy());
    builder_->CreateStore(llvm::ConstantInt::get(charTy(), 0), alloca);
    funcStack_.top().locals[name] = alloca;
}

// ---------------------------------------------------------------------------
// Alloca / load / store helpers
// ---------------------------------------------------------------------------

llvm::AllocaInst* LLVMCodeGen::createEntryAlloca(const std::string &name,
                                                   llvm::Type *ty)
{
    assert(!funcStack_.empty());
    llvm::Function *fn = funcStack_.top().func;
    llvm::IRBuilder<> tmp(&fn->getEntryBlock(),
                          fn->getEntryBlock().begin());
    return tmp.CreateAlloca(ty, nullptr, name);
}

llvm::AllocaInst* LLVMCodeGen::getAlloca(const std::string &name)
{
    if (!funcStack_.empty()) {
        auto &locs = funcStack_.top().locals;
        auto it = locs.find(name);
        if (it != locs.end()) return it->second;
    }
    return nullptr;
}

llvm::Value* LLVMCodeGen::loadName(const std::string &name)
{
    // 1. Local / parameter
    if (auto *alloca = getAlloca(name))
        return builder_->CreateLoad(alloca->getAllocatedType(), alloca, name);

    // 2. Global scalar or array
    if (globals_.count(name)) {
        auto *gv = globals_[name];
        return builder_->CreateLoad(gv->getValueType(), gv, name);
    }

    // 3. Auto-create as i32 local (handles temporaries seen for first time on load)
    if (!funcStack_.empty()) {
        fprintf(stderr, "loadName: auto-creating unknown variable '%s'\n", name.c_str());
        auto *alloca = createEntryAlloca(name, intTy());
        builder_->CreateStore(llvm::ConstantInt::get(intTy(), 0), alloca);
        funcStack_.top().locals[name] = alloca;
        return builder_->CreateLoad(intTy(), alloca, name);
    }

    fprintf(stderr, "loadName: unknown variable '%s' in global scope\n", name.c_str());
    return llvm::ConstantInt::get(intTy(), 0);
}

void LLVMCodeGen::storeName(const std::string &name, llvm::Value *val)
{
    // 1. Local
    if (auto *alloca = getAlloca(name)) {
        llvm::Type *destTy = alloca->getAllocatedType();
        if (val->getType() != destTy)
            val = builder_->CreateIntCast(val, destTy, true);
        builder_->CreateStore(val, alloca);
        return;
    }
    // 2. Global
    if (globals_.count(name)) {
        auto *gv = globals_[name];
        llvm::Type *destTy = gv->getValueType();
        if (val->getType() != destTy)
            val = builder_->CreateIntCast(val, destTy, true);
        builder_->CreateStore(val, gv);
        return;
    }
    // 3. Auto-register unknown name as a local (handles parser temporaries)
    if (!funcStack_.empty()) {
        llvm::Type *ty = val->getType()->isIntegerTy(8) ? charTy() : intTy();
        auto *alloca = createEntryAlloca(name, ty);
        funcStack_.top().locals[name] = alloca;
        if (val->getType() != ty)
            val = builder_->CreateIntCast(val, ty, true);
        builder_->CreateStore(val, alloca);
        return;
    }
    fprintf(stderr, "storeName: unknown variable '%s' in global scope\n", name.c_str());
}

// ---------------------------------------------------------------------------
// Assign
// ---------------------------------------------------------------------------

void LLVMCodeGen::emitAssign(const std::string &dest, const std::string &src)
{
    storeName(dest, loadName(src));
}

void LLVMCodeGen::emitArrayStore(const std::string &arr,
                                  const std::string &idx,
                                  const std::string &val)
{
    llvm::Value *idxVal = loadName(idx);
    llvm::Value *valVal = loadName(val);
    llvm::Value *gep    = nullptr;

    if (auto *alloca = getAlloca(arr)) {
        gep = builder_->CreateGEP(alloca->getAllocatedType(), alloca,
                                   {llvm::ConstantInt::get(intTy(),0), idxVal});
    } else if (globals_.count(arr)) {
        auto *gv = globals_[arr];
        gep = builder_->CreateGEP(gv->getValueType(), gv,
                                   {llvm::ConstantInt::get(intTy(),0), idxVal});
    }
    if (gep) {
        auto *elemTy = llvm::cast<llvm::GetElementPtrInst>(gep)->getResultElementType();
        if (valVal->getType() != elemTy)
            valVal = builder_->CreateIntCast(valVal, elemTy, true);
        builder_->CreateStore(valVal, gep);
    }
}

std::string LLVMCodeGen::emitArrayLoad(const std::string &arr,
                                        const std::string &idx)
{
    llvm::Value *idxVal = loadName(idx);
    llvm::Value *gep    = nullptr;

    if (auto *alloca = getAlloca(arr)) {
        gep = builder_->CreateGEP(alloca->getAllocatedType(), alloca,
                                   {llvm::ConstantInt::get(intTy(),0), idxVal});
    } else if (globals_.count(arr)) {
        auto *gv = globals_[arr];
        gep = builder_->CreateGEP(gv->getValueType(), gv,
                                   {llvm::ConstantInt::get(intTy(),0), idxVal});
    }

    std::string tmp = newTemp();
    if (gep) {
        auto *elemTy = llvm::cast<llvm::GetElementPtrInst>(gep)->getResultElementType();
        llvm::Value *loaded = builder_->CreateLoad(elemTy, gep, tmp);
        if (elemTy != intTy())
            loaded = builder_->CreateSExt(loaded, intTy(), tmp + "_ext");
        // storeName auto-registers the temp
        storeName(tmp, loaded);
    }
    return tmp;
}

// ---------------------------------------------------------------------------
// Arithmetic / Logic
// ---------------------------------------------------------------------------

std::string LLVMCodeGen::emitAdd(const std::string &a, const std::string &b)
{
    std::string t = newTemp();
    storeName(t, builder_->CreateAdd(loadName(a), loadName(b), t));
    return t;
}

std::string LLVMCodeGen::emitSub(const std::string &a, const std::string &b)
{
    std::string t = newTemp();
    storeName(t, builder_->CreateSub(loadName(a), loadName(b), t));
    return t;
}

std::string LLVMCodeGen::emitMul(const std::string &a, const std::string &b)
{
    std::string t = newTemp();
    storeName(t, builder_->CreateMul(loadName(a), loadName(b), t));
    return t;
}

std::string LLVMCodeGen::emitDiv(const std::string &a, const std::string &b)
{
    std::string t = newTemp();
    storeName(t, builder_->CreateSDiv(loadName(a), loadName(b), t));
    return t;
}

std::string LLVMCodeGen::emitMod(const std::string &a, const std::string &b)
{
    std::string t = newTemp();
    storeName(t, builder_->CreateSRem(loadName(a), loadName(b), t));
    return t;
}

std::string LLVMCodeGen::emitAnd(const std::string &a, const std::string &b)
{
    std::string t = newTemp();
    storeName(t, builder_->CreateAnd(loadName(a), loadName(b), t));
    return t;
}

std::string LLVMCodeGen::emitOr(const std::string &a, const std::string &b)
{
    std::string t = newTemp();
    storeName(t, builder_->CreateOr(loadName(a), loadName(b), t));
    return t;
}

std::string LLVMCodeGen::emitNot(const std::string &a)
{
    std::string t = newTemp();
    storeName(t, builder_->CreateNot(loadName(a), t));
    return t;
}

std::string LLVMCodeGen::emitNeg(const std::string &a)
{
    std::string t = newTemp();
    storeName(t, builder_->CreateNeg(loadName(a), t));
    return t;
}

// ---------------------------------------------------------------------------
// Relational
// ---------------------------------------------------------------------------

std::string LLVMCodeGen::emitRelop(const std::string &op,
                                    const std::string &a,
                                    const std::string &b)
{
    llvm::Value *lhs = loadName(a);
    llvm::Value *rhs = loadName(b);
    llvm::Value *cmp = nullptr;

    if      (op == "==") cmp = builder_->CreateICmpEQ (lhs, rhs);
    else if (op == "!=") cmp = builder_->CreateICmpNE (lhs, rhs);
    else if (op == "<" ) cmp = builder_->CreateICmpSLT(lhs, rhs);
    else if (op == "<=") cmp = builder_->CreateICmpSLE(lhs, rhs);
    else if (op == ">=") cmp = builder_->CreateICmpSGE(lhs, rhs);
    else if (op == ">" ) cmp = builder_->CreateICmpSGT(lhs, rhs);
    else                 cmp = builder_->CreateICmpEQ (lhs, rhs);

    llvm::Value *widened = builder_->CreateZExt(cmp, intTy());
    std::string t = newTemp();
    storeName(t, widened);
    return t;
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

std::string LLVMCodeGen::emitIntConst(int val)
{
    std::string t = newTemp();
    storeName(t, llvm::ConstantInt::get(intTy(), val));
    return t;
}

std::string LLVMCodeGen::emitCharConst(char val)
{
    std::string t = newTemp();
    storeName(t, llvm::ConstantInt::get(intTy(), (unsigned char)val));
    return t;
}

// ---------------------------------------------------------------------------
// Control flow
// ---------------------------------------------------------------------------

int LLVMCodeGen::newLabel()
{
    return labelCounter_++;
}

llvm::BasicBlock* LLVMCodeGen::getOrCreateBlock(int labelId)
{
    auto it = labelBlocks_.find(labelId);
    if (it != labelBlocks_.end()) return it->second;
    assert(!funcStack_.empty());
    auto *bb = llvm::BasicBlock::Create(
        ctx_, "__lab" + std::to_string(labelId), funcStack_.top().func);
    labelBlocks_[labelId] = bb;
    return bb;
}

void LLVMCodeGen::ensureTerminated(llvm::BasicBlock *fallthrough)
{
    if (!builder_->GetInsertBlock()->getTerminator())
        builder_->CreateBr(fallthrough);
}

void LLVMCodeGen::emitLabel(int labelId)
{
    auto *bb = getOrCreateBlock(labelId);
    ensureTerminated(bb);
    builder_->SetInsertPoint(bb);
}

void LLVMCodeGen::emitGoto(int labelId)
{
    auto *bb = getOrCreateBlock(labelId);
    if (!builder_->GetInsertBlock()->getTerminator())
        builder_->CreateBr(bb);
    // New dead block so subsequent emits have a valid insert point
    auto *dead = llvm::BasicBlock::Create(ctx_, "dead", funcStack_.top().func);
    builder_->SetInsertPoint(dead);
}

void LLVMCodeGen::emitGoFalse(const std::string &cond, int labelId)
{
    llvm::Value *condVal = loadName(cond);
    llvm::Value *condBit = builder_->CreateICmpNE(
        condVal, llvm::ConstantInt::get(intTy(), 0));

    auto *falseBB = getOrCreateBlock(labelId);
    auto *trueBB  = llvm::BasicBlock::Create(ctx_, "cont", funcStack_.top().func);
    builder_->CreateCondBr(condBit, trueBB, falseBB);
    builder_->SetInsertPoint(trueBB);
}

// ---------------------------------------------------------------------------
// Calls
// ---------------------------------------------------------------------------

// Copy the argument's current value into a fresh temporary: the parser
// frees and reuses its own temporaries before the call is emitted.
void LLVMCodeGen::pushArg(const std::string &name)
{
    std::string t = newTemp();
    storeName(t, loadName(name));
    pendingArgs_.push_back(t);
}

// Take the last `count` pushed arguments, leaving any belonging to an
// enclosing call that is still being parsed.
std::vector<std::string> LLVMCodeGen::flushArgs(int count)
{
    assert(count >= 0 && (size_t)count <= pendingArgs_.size());
    auto first = pendingArgs_.end() - count;
    std::vector<std::string> args(first, pendingArgs_.end());
    pendingArgs_.erase(first, pendingArgs_.end());
    return args;
}

void LLVMCodeGen::emitCallProc(const std::string &name,
                                const std::vector<std::string> &args)
{
    llvm::Function *fn = nullptr;
    auto it = functions_.find(name);
    if (it == functions_.end()) {
        // Auto-declare as external with i32 params
        std::vector<llvm::Type*> paramTys(args.size(), intTy());
        auto *fty = llvm::FunctionType::get(voidTy(), paramTys, false);
        fn = llvm::Function::Create(fty, llvm::Function::ExternalLinkage, name, *mod_);
        functions_[name] = fn;
    } else {
        fn = it->second;
    }

    std::vector<llvm::Value*> llvmArgs;
    const auto params = fn->args();
    auto pit = params.begin();
    for (auto &a : args) {
        llvm::Value *v = loadName(a);
        if (pit != params.end()) {
            if (v->getType() != pit->getType())
                v = builder_->CreateIntCast(v, pit->getType(), true);
            ++pit;
        }
        llvmArgs.push_back(v);
    }
    builder_->CreateCall(fn, llvmArgs);
}

std::string LLVMCodeGen::emitCallFunc(const std::string &name,
                                       const std::vector<std::string> &args)
{
    llvm::Function *fn = nullptr;
    auto it = functions_.find(name);
    if (it == functions_.end()) {
        // Auto-declare as external with i32 params and i32 return
        std::vector<llvm::Type*> paramTys(args.size(), intTy());
        auto *fty = llvm::FunctionType::get(intTy(), paramTys, false);
        fn = llvm::Function::Create(fty, llvm::Function::ExternalLinkage, name, *mod_);
        functions_[name] = fn;
    } else {
        fn = it->second;
    }

    std::vector<llvm::Value*> llvmArgs;
    const auto params = fn->args();
    auto pit = params.begin();
    for (auto &a : args) {
        llvm::Value *v = loadName(a);
        if (pit != params.end()) {
            if (v->getType() != pit->getType())
                v = builder_->CreateIntCast(v, pit->getType(), true);
            ++pit;
        }
        llvmArgs.push_back(v);
    }

    llvm::Value *ret = builder_->CreateCall(fn, llvmArgs, name + "_ret");
    std::string t = newTemp();
    storeName(t, ret);
    return t;
}

void LLVMCodeGen::emitReturn(const std::string &valName)
{
    assert(!funcStack_.empty());
    llvm::Function *fn = funcStack_.top().func;
    if (fn->getReturnType()->isVoidTy()) {
        builder_->CreateRetVoid();
    } else {
        llvm::Value *val = loadName(valName);
        if (val->getType() != fn->getReturnType())
            val = builder_->CreateIntCast(val, fn->getReturnType(), true);
        builder_->CreateRet(val);
    }
}

// ---------------------------------------------------------------------------
// Temp name generator
// ---------------------------------------------------------------------------

std::string LLVMCodeGen::newTemp()
{
    return "__t" + std::to_string(tempCounter_++);
}
