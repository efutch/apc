Program GcdTest(Input,Output);
Var
        ProcResult, FuncResult, MixResult, NestResult : Integer;

{ Recursive procedure with parameters; reports through a global }
Procedure GCD(A,B : Integer);
Begin
   if b = 0 then ProcResult := a
   else gcd(b, a mod b)
End;

{ Recursive function with parameters; returns through its own name }
Function GCD2(A,B : Integer) : Integer;
Begin
   if b = 0 then gcd2 := a
   else gcd2 := gcd2(b, a mod b)
End;

{ Two parameter groups: count and order must both survive }
Function Combine(A,B : Integer; C : Integer) : Integer;
Begin
   Combine := A * 100 + B * 10 + C
End;

Begin
   GCD(48,18);
   FuncResult := GCD2(1071,462);
   MixResult := Combine(1,2,3);
   { Calls inside another call's argument list }
   NestResult := GCD2(Combine(0,4,8), GCD2(36,24))
End.
