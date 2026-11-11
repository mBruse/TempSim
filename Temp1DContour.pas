unit Temp1DContour;

{ Hilfsroutinen für das Isoplethendiagramm (ohne UI-Abhängigkeiten).

  Ein Gitter Grid[Zeile][Spalte] enthält Temperaturen; Spalte = Knoten
  (Tiefe), Zeile = Zeitpunkt. Koordinaten in Gitterkoordinaten:
  X = Spalte (0..Spalten-1), Y = Zeile (0..Zeilen-1). }

interface

uses
  Temp1DModel;

type
  TGrid = array of TDoubleArray;

  TContourSegment = record
    X1, Y1, X2, Y2: Double;
  end;
  TSegmentArray = array of TContourSegment;

{ "Schöne" Isolinienwerte (Schrittweite 1, 2, 2.5 oder 5 * 10^n) zwischen
  AMin und AMax, höchstens etwa MaxLevels Stück. }
function ContourLevels(AMin, AMax: Double; MaxLevels: Integer;
  out Step: Double): TDoubleArray;

{ Isolinie für Level nach dem Marching-Squares-Verfahren mit linearer
  Interpolation; Sattelpunkte werden über den Zellmittelwert aufgelöst. }
function ContourSegments(const Grid: TGrid; Level: Double): TSegmentArray;

{ Bilinear interpolierter Wert an der Gitterposition (X, Y). }
function BilinearValue(const Grid: TGrid; X, Y: Double): Double;

{ Index des Farbbands für Value: 0 unterhalb des ersten Levels,
  k zwischen Levels[k-1] und Levels[k], Length(Levels) oberhalb. }
function BandIndex(const Levels: TDoubleArray; Step, Value: Double): Integer;

implementation

uses
  Math;

function ContourLevels(AMin, AMax: Double; MaxLevels: Integer;
  out Step: Double): TDoubleArray;
const
  Nice: array[0..4] of Double = (1, 2, 2.5, 5, 10);
var
  Raw, Mag, L: Double;
  i, n: Integer;
begin
  Result := nil;
  Step := 1;
  if (MaxLevels < 1) or (AMax - AMin < 1E-9) then
    Exit;

  Raw := (AMax - AMin) / MaxLevels;
  Mag := Power(10, Floor(Log10(Raw)));
  Step := Nice[High(Nice)] * Mag;
  for i := Low(Nice) to High(Nice) do
    if Nice[i] * Mag >= Raw then
    begin
      Step := Nice[i] * Mag;
      Break;
    end;

  n := 0;
  L := Ceil(AMin / Step - 1E-9) * Step;
  while L <= AMax + 1E-9 do
  begin
    SetLength(Result, n + 1);
    Result[n] := L;
    Inc(n);
    L := L + Step;
  end;
end;

function ContourSegments(const Grid: TGrid; Level: Double): TSegmentArray;
var
  Count: Integer;

  procedure AddSegment(X1, Y1, X2, Y2: Double);
  begin
    if Count = Length(Result) then
      SetLength(Result, Max(16, 2 * Count));
    Result[Count].X1 := X1;
    Result[Count].Y1 := Y1;
    Result[Count].X2 := X2;
    Result[Count].Y2 := Y2;
    Inc(Count);
  end;

var
  r, c, Rows, Cols, k: Integer;
  V: array[0..3] of Double;   // Ecken: 0 oben links, 1 oben rechts,
                              //        2 unten rechts, 3 unten links
  Hit: array[0..3] of Boolean; // Kanten: 0 oben, 1 rechts, 2 unten, 3 links
  PX, PY: array[0..3] of Double;

  procedure Edge(E, A, B: Integer; XA, YA, XB, YB: Double);
  var
    T: Double;
  begin
    Hit[E] := (V[A] >= Level) <> (V[B] >= Level);
    if Hit[E] then
    begin
      T := (Level - V[A]) / (V[B] - V[A]);
      PX[E] := XA + (XB - XA) * T;
      PY[E] := YA + (YB - YA) * T;
    end;
  end;

  procedure Join(E1, E2: Integer);
  begin
    AddSegment(PX[E1], PY[E1], PX[E2], PY[E2]);
  end;

var
  E: array[0..1] of Integer;
  n: Integer;
begin
  Result := nil;
  Count := 0;
  Rows := Length(Grid);
  if Rows < 2 then
    Exit;
  Cols := Length(Grid[0]);

  for r := 0 to Rows - 2 do
    for c := 0 to Cols - 2 do
    begin
      V[0] := Grid[r][c];
      V[1] := Grid[r][c + 1];
      V[2] := Grid[r + 1][c + 1];
      V[3] := Grid[r + 1][c];

      Edge(0, 0, 1, c, r, c + 1, r);
      Edge(1, 1, 2, c + 1, r, c + 1, r + 1);
      Edge(2, 3, 2, c, r + 1, c + 1, r + 1);
      Edge(3, 0, 3, c, r, c, r + 1);

      n := 0;
      for k := 0 to 3 do
        if Hit[k] then
        begin
          if n < 2 then
            E[n] := k;
          Inc(n);
        end;

      if n = 2 then
        Join(E[0], E[1])
      else if n = 4 then
      begin
        // Sattelpunkt: Mittelwert entscheidet, welche Ecken verbunden sind
        if ((V[0] + V[1] + V[2] + V[3]) / 4 >= Level) = (V[0] >= Level) then
        begin
          Join(0, 1);
          Join(2, 3);
        end
        else
        begin
          Join(0, 3);
          Join(1, 2);
        end;
      end;
    end;

  SetLength(Result, Count);
end;

function BilinearValue(const Grid: TGrid; X, Y: Double): Double;
var
  Rows, Cols, c, r: Integer;
  FX, FY, Top, Bottom: Double;
begin
  Rows := Length(Grid);
  Cols := Length(Grid[0]);
  X := EnsureRange(X, 0, Cols - 1);
  Y := EnsureRange(Y, 0, Rows - 1);
  c := Min(Floor(X), Cols - 2);
  r := Min(Floor(Y), Rows - 2);
  if c < 0 then c := 0;
  if r < 0 then r := 0;
  FX := X - c;
  FY := Y - r;

  if Cols = 1 then
    FX := 0;
  if Rows = 1 then
    FY := 0;

  Top := Grid[r][c];
  Bottom := Top;
  if Cols > 1 then
    Top := Top + (Grid[r][c + 1] - Top) * FX;
  if Rows > 1 then
  begin
    Bottom := Grid[r + 1][c];
    if Cols > 1 then
      Bottom := Bottom + (Grid[r + 1][c + 1] - Bottom) * FX;
  end;
  Result := Top + (Bottom - Top) * FY;
end;

function BandIndex(const Levels: TDoubleArray; Step, Value: Double): Integer;
begin
  if Length(Levels) = 0 then
    Exit(0);
  Result := EnsureRange(Floor((Value - Levels[0]) / Step) + 1, 0, Length(Levels));
end;

end.
