program TestContour;

{ Konsolentest für Temp1DContour (Delphi oder Free Pascal: fpc -Mdelphi). }

{$APPTYPE CONSOLE}

uses
  SysUtils, Math, Temp1DModel, Temp1DContour;

var
  Failures: Integer = 0;

procedure Check(Condition: Boolean; const Msg: string);
begin
  if Condition then
    WriteLn('OK    ', Msg)
  else
  begin
    WriteLn('FAIL  ', Msg);
    Inc(Failures);
  end;
end;

function MakeGrid(Rows, Cols: Integer): TGrid;
var
  r: Integer;
begin
  SetLength(Result, Rows);
  for r := 0 to Rows - 1 do
    SetLength(Result[r], Cols);
end;

var
  G: TGrid;
  L: TDoubleArray;
  S: TSegmentArray;
  Step: Double;
  r, c, i: Integer;
  AllOnLine: Boolean;
begin
  // Schöne Levels
  L := ContourLevels(15.3, 24.8, 10, Step);
  Check(SameValue(Step, 1, 1E-9) and (Length(L) = 9) and SameValue(L[0], 16, 1E-9)
    and SameValue(L[8], 24, 1E-9), 'Levels 15.3..24.8 -> 16..24, Schritt 1');
  L := ContourLevels(0, 37, 8, Step);
  Check(SameValue(Step, 5, 1E-9) and SameValue(L[0], 0, 1E-9) and (Length(L) = 8),
    'Levels 0..37 -> Schritt 5');
  L := ContourLevels(20, 20, 10, Step);
  Check(Length(L) = 0, 'konstantes Feld -> keine Levels');

  // Lineares Feld T = Spalte -> Isolinie 1.5 ist die senkrechte Linie X = 1.5
  G := MakeGrid(5, 4);
  for r := 0 to 4 do
    for c := 0 to 3 do
      G[r][c] := c;
  S := ContourSegments(G, 1.5);
  AllOnLine := Length(S) = 4;
  for i := 0 to High(S) do
    AllOnLine := AllOnLine and SameValue(S[i].X1, 1.5, 1E-9) and SameValue(S[i].X2, 1.5, 1E-9);
  Check(AllOnLine, 'lineares Feld: Isolinie X = 1.5 aus 4 Segmenten');
  Check(Length(ContourSegments(G, 10)) = 0, 'Level ausserhalb -> keine Segmente');

  // Sattelpunkt erzeugt zwei Segmente
  G := MakeGrid(2, 2);
  G[0][0] := 1; G[0][1] := 0; G[1][1] := 1; G[1][0] := 0;
  Check(Length(ContourSegments(G, 0.5)) = 2, 'Sattelpunkt -> 2 Segmente');

  // Bilinear
  G := MakeGrid(2, 2);
  G[0][0] := 0; G[0][1] := 10; G[1][0] := 20; G[1][1] := 30;
  Check(SameValue(BilinearValue(G, 0.5, 0.5), 15, 1E-9), 'bilinear Mitte = 15');
  Check(SameValue(BilinearValue(G, 1, 1), 30, 1E-9), 'bilinear Ecke = 30');
  Check(SameValue(BilinearValue(G, 5, -3), 10, 1E-9), 'bilinear ausserhalb wird begrenzt');

  // Farbbänder
  L := ContourLevels(15.3, 24.8, 10, Step);
  Check(BandIndex(L, Step, 15.5) = 0, 'Band unter erstem Level = 0');
  Check(BandIndex(L, Step, 16.2) = 1, 'Band 16..17 = 1');
  Check(BandIndex(L, Step, 24.5) = 9, 'Band über letztem Level = 9');

  if Failures > 0 then
  begin
    WriteLn(Failures, ' Test(s) fehlgeschlagen');
    Halt(1);
  end;
  WriteLn('Alle Tests bestanden');
end.
