// ******************* INCLUDE FILE : TOKEN.H **********************

// token.h - Include file para manejar las constantes de token
// Escrito por Egdares Futch H.
// Compilador : Borland C++ 3.0

union Tokenval
{
	int arrbounds[2];
};

class Token
{
	char *name;
	Token *next;
   Token *offset;     // Si es un elemento de un array, aqui guarda el offset
	int tokentype;
   int type;
	Tokenval value;
public:
	Token()	{ name = NULL; next = NULL; tokentype = 0; offset = NULL; }
	Token(char *,int,int);
   Token(char);
	Token(int);
	~Token();
   int GetTokenType(void) const     { return tokentype; }
   void SetTokenType(int newtype)   { tokentype = newtype; }
   int GetType(void) const          { return type; }
   void SetType(int newtype)        { type = newtype; }
   char *GetName(void) const   { return name; }
   Token *GetNext(void) const  { return next; }
   void SetNext(Token *n)      { next = n; }
   void SetLowArrBound(int lowbound) { value.arrbounds[0] = lowbound; }
   void SetHighArrBound(int hibound) { value.arrbounds[1] = hibound; }
   int GetLowArrBound(void) const    { return value.arrbounds[0]; }
   int GetHighArrBound(void) const   { return value.arrbounds[1]; }
   void SetParamCount(int params)    { value.arrbounds[0] = params; }
   int GetParamCount(void) const     { return value.arrbounds[0]; }
   void SetFuncReturnType(int t)      { value.arrbounds[1] = t; }
   int GetFuncReturnType(void) const { return value.arrbounds[1]; }
   int Compare(const char *n);
   void SetOffset(Token *pos)        { offset = pos; }
   Token *GetOffset(void) const      { return offset; }
};

// ************************* FIN DEL INCLUDE FILE *******************
