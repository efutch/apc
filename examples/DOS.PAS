Program sort(Input,Output);

Var
   a : array[0..10] of Integer;

Procedure Read(a : Integer);
Begin
End;

Procedure ReadArray;
Var
   i : Integer;
Begin
   i := 1;
   While (i < 10) do
      begin
         Read(a[i]);
         i := i + 1
      End
End;

Function Partition(y,z : integer) : Integer;
Var
  i,j,x,v : Integer;
Begin
   i := a[y+1]*2
End;

Procedure QuickSort(l,r : integer);
Var
  i,j,v,flag,tmp : integer;
Begin
   if (r > l) then
      Begin
         v := a[r];
         i := l-1;
         j := r;
         flag := 1;
         while (flag = 1) do
            Begin
              while (a[i] < v) do
                 i := i+1;
              while (a[j] > v) do
                 j := j-1;
              if (i >= j) then
                 flag := 0
              else begin
                      tmp := a[i];
                      a[i] := a[j];
                      a[j] := tmp
                   end
            End;
         tmp := a[i];
         a[i] := a[r];
         a[r] := a[i];
         QuickSort(1,i-1);
         QuickSort(i+1,r)
      End
end;

Begin
   a[0] := -9999;
   a[10] := 9999;
   ReadArray;
   Quicksort(1,9)
End.
