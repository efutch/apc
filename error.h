// error.h - header para el manejo de errores
// Escrito por Egdares Futch
// Compilador : Borland C++ 3.0
// Actualizado para compilador g++ de Linux, se agregan los tipos de los const

const int ERR_LEXICAL       = 0;
const int ERR_NESTEDCOMMENT = 1;
const int ERR_EOFCOMMENT    = 2;
const int ERR_NOMEM		= 3;
const int ERR_DUPID         = 4;
const int ERR_NDECLID       = 5;
const int ERR_ICGOPEN        = 6;
const int ERR_ICGUNKNOWNCODE = 7;
const int ERR_LVALUE         = 8;
const int ERR_PROCEXPECTED   = 9;
const int ERR_TYPEMISMATCH   = 10;
const int ERR_PARAMCOUNT     = 11;
const int ERR_IDTOOLONG	= 12;

void error(const int);
