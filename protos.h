// protos.h - Header para que el parser generado por Bison no alegue en C++
// Escrito por Egdares Futch

//#ifdef __cplusplus
//extern "C" {
//#endif
int yylex(void);
void yyerror(char *);
//#ifdef __cplusplus
//};
//#endif