program TestModel;

{ Konsolentest für Temp1DModel (Delphi oder Free Pascal: fpc -Mdelphi). }

{$APPTYPE CONSOLE}

uses
  SysUtils, Math, Temp1DModel;

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

{ Originaler Algorithmus aus Temp1D.pas (6 Knoten, Single), zum Vergleich. }
function OriginalNode(Node, Steps: Integer; Tlf, dx, dt, TInit: Single): Single;
var
  T, TNeu: array[0..5] of Single;
  i, k: Integer;
  a, b, Time: Single;
begin
  for i := 0 to 5 do T[i] := TInit;
  Time := 0;
  for k := 1 to Steps do
  begin
    Time := Time + dt;
    TNeu[0] := Cos(Pi * (Time / 3600)) * 5 + TInit;
    for i := 1 to 4 do
    begin
      a := Tlf * (T[i - 1] - T[i]) / dx;
      b := Tlf * (T[i] - T[i + 1]) / dx;
      TNeu[i] := 1 / dx * (a - b) * dt + T[i];
    end;
    TNeu[5] := TInit;
    for i := 0 to 5 do T[i] := TNeu[i];
  end;
  Result := T[Node];
end;

var
  M: THeatModel1D;
  i, k: Integer;
  MaxDiff, Sum: Double;
begin
  M := THeatModel1D.Create;
  try
    // Standardwerte: Sand feucht, dx = 1 cm, dt = 1 min, 6 Knoten
    Check(Abs(M.FourierNumber - 0.198) < 1E-9, 'Fourier-Zahl Standardwerte = 0.198');
    Check(M.IsStable and (M.SubstepCount = 1), 'Standardwerte stabil, keine Unterschritte');

    // Vergleich mit dem Originalalgorithmus (Unterschied nur durch Single/Double
    // und den Startwert von Knoten 0)
    M.Reset;
    for k := 1 to 300 do M.Step;
    MaxDiff := 0;
    for i := 0 to 5 do
      MaxDiff := Max(MaxDiff, Abs(M[i] - OriginalNode(i, 300, 0.33E-6, 0.01, 60, 20)));
    Check(MaxDiff < 1E-3, Format('stimmt mit Original überein (max. Abw. %.2e K)', [MaxDiff]));
    Check(SameValue(M.Time, 300 * 60, 1E-6), 'Simulationszeit 300 min');
    Check(SameValue(M[0], M.BoundaryTemperature(M.Time), 1E-9), 'linker Rand folgt cos-Antrieb');
    Check(M[5] = 20, 'rechter Rand konstant');

    // Eisen: r = 13.68 -> ohne Unterschritte instabil
    M.Diffusivity := 22.8E-6;
    M.AutoSubstep := False;
    Check(not M.IsStable, 'Eisen ohne Unterschritte instabil');
    M.Reset;
    for k := 1 to 50 do M.Step;
    Check(Abs(M[2]) > 1E3, Format('Eisen ohne Unterschritte divergiert (T2 = %.3g)', [M[2]]));

    M.AutoSubstep := True;
    Check(M.IsStable and (M.SubstepCount = 28), Format('Eisen mit Unterschritten stabil (%d)', [M.SubstepCount]));
    M.Reset;
    for k := 1 to 300 do M.Step;
    Check((M.TMin[2] >= 15 - 1E-9) and (M.TMax[2] <= 25 + 1E-9), 'Eisen mit Unterschritten bleibt im Bereich 15..25 °C');

    // Ohne Antrieb (Amplitude 0) bleibt alles bei TInit
    M.Amplitude := 0;
    M.NodeCount := 11;
    for k := 1 to 100 do M.Step;
    Sum := 0;
    for i := 0 to M.NodeCount - 1 do Sum := Sum + Abs(M[i] - M.TInit);
    Check(Sum < 1E-9, 'Amplitude 0: Gleichgewicht bleibt erhalten');

    // Stationärer Zustand bei konstantem Rand (Period = 0): linearer Verlauf
    M.Amplitude := 10;
    M.Period := 0;
    M.Diffusivity := 1E-6;
    M.NodeCount := 6;
    for k := 1 to 20000 do M.Step;
    MaxDiff := 0;
    for i := 0 to 5 do
      MaxDiff := Max(MaxDiff, Abs(M[i] - (30 - 10 * i / 5)));
    Check(MaxDiff < 1E-6, 'konstanter Rand -> lineares Profil 30..20 °C');

    // Knotenzahl wird begrenzt
    M.NodeCount := 100;
    Check(M.NodeCount = MaxNodes, 'NodeCount auf MaxNodes begrenzt');
  finally
    M.Free;
  end;

  if Failures > 0 then
  begin
    WriteLn(Failures, ' Test(s) fehlgeschlagen');
    Halt(1);
  end;
  WriteLn('Alle Tests bestanden');
end.
