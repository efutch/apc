// codegen.h - Modulo generador de codigo intermedio
// Escrito por Egdares Futch H.
// Compilador : Borland C++

const int icgGLOBALINT  = 0;
const int icgGLOBALCHAR = 1;
const int icgPROCDECL   = 2;
const int icgENDPROC    = 3;
const int icgLOCALINT   = 4;
const int icgLOCALCHAR  = 5;
const int icgPARAMCOUNT = 6;
const int icgCALLPROC   = 7;
const int icgASSIGN     = 8;
const int icgGOTO       = 9;
const int icgLABEL      = 10;
const int icgNOT        = 11;
const int icgASSIGNNUM  = 12;
const int icgASSIGNCHAR = 13;
const int icgMOD        = 14;
const int icgAND        = 15;
const int icgEQUAL      = 16;
const int icgMUL        = 17;
const int icgDIV        = 18;
const int icgADD        = 19;
const int icgSUB        = 20;
const int icgGOFALSE    = 21;

void icgInit(void);
void icgClose(void);
void icgEmit(int,int = -1,int = 0,int = 0);