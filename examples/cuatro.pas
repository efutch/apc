Program Cuatro(Input,Output);
Var
  a : array[0..10] of integer;
Var
  i : integer;
Begin
   i := 4;
   a[i+1] := a[i];
   i := a[i+1] * a[i+2] + i - 2
End.
