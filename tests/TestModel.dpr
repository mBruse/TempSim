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

{ Halbe Schwankungsbreite eines Knotens über den nächsten Tag. }
function AmplitudeOverDay(M: THeatModel1D; Node: Integer): Double;
var
  k: Integer;
  Lo, Hi: Double;
begin
  Lo := M[Node];
  Hi := Lo;
  for k := 1 to Round(M.Period / M.Dt) do
  begin
    M.Step;
    Lo := Min(Lo, M[Node]);
    Hi := Max(Hi, M[Node]);
  end;
  Result := (Hi - Lo) / 2;
end;

var
  M: THeatModel1D;
  i, k: Integer;
  MaxDiff, Sum: Double;
begin
  M := THeatModel1D.Create;
  try
    Check(SameValue(M.Period, 24 * 3600, 1E-9), 'Standardperiode 24 h');

    // Standardmaterial muss mit dx = 1 cm, dt = 1 min stabil sein
    Check(M.IsStable and (M.SubstepCount = 1),
      Format('Standardwerte stabil, keine Unterschritte (r = %.3f)', [M.FourierNumber]));

    // Stofftabelle: a = lambda/(rho*c) im plausiblen Bereich, Referenzwerte
    MaxDiff := 0;
    for i := Low(Materials) to High(Materials) do
      if not InRange(MaterialDiffusivity(Materials[i]), 0.05, 200) then
        MaxDiff := 1;
    Check(MaxDiff = 0, 'alle Materialien: 0,05 <= a <= 200 mm²/s');
    Check(Pos('Sand feucht', Materials[DefaultMaterial].Name) = 1, 'Standardmaterial ist Sand feucht');
    for i := Low(Materials) to High(Materials) do
    begin
      if Pos('Wasser (', Materials[i].Name) = 1 then
        Check(Abs(MaterialDiffusivity(Materials[i]) - 0.143) < 0.002, 'Wasser a = 0,143 mm²/s');
      if Pos('Eisen', Materials[i].Name) = 1 then
        Check(Abs(MaterialDiffusivity(Materials[i]) - 22.8) < 0.5, 'Eisen a ~ 22,8 mm²/s');
      if Pos('Luft', Materials[i].Name) = 1 then
        Check(Abs(MaterialDiffusivity(Materials[i]) - 21) < 1.5, 'Luft a ~ 21 mm²/s');
      if Pos('Eis (', Materials[i].Name) = 1 then
        Check(Abs(MaterialDiffusivity(Materials[i]) - 1.16) < 0.02, 'Eis a = 1,16 mm²/s');
    end;

    // Vergleich mit dem Originalprogramm: Sand feucht hatte dort 0,33 mm²/s,
    // Periode 2 h
    M.Diffusivity := 0.33E-6;
    M.Period := 2 * 3600;
    M.Dx := 0.01;
    M.NodeCount := 6;
    Check(Abs(M.FourierNumber - 0.198) < 1E-9, 'Fourier-Zahl Originalwerte = 0.198');

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

    // Zahleneingabe mit Komma oder Punkt
    Check(TryParseNumber('1,5', Sum) and SameValue(Sum, 1.5, 1E-12), 'TryParseNumber "1,5"');
    Check(TryParseNumber(' 0.33 ', Sum) and SameValue(Sum, 0.33, 1E-12), 'TryParseNumber " 0.33 "');
    Check(TryParseNumber('-2', Sum) and SameValue(Sum, -2, 1E-12), 'TryParseNumber "-2"');
    Check(not TryParseNumber('abc', Sum), 'TryParseNumber "abc" ungültig');
    Check(not TryParseNumber('', Sum), 'TryParseNumber "" ungültig');

    // Analytische Lösung für den periodisch erwärmten Halbraum:
    // Amplitude A*exp(-z/d), d = sqrt(a*P/pi). Feuchter Sand, Tagesgang,
    // Gitter 1 m tief, ausgewertet am 6. Tag (eingeschwungen).
    M.Diffusivity := MaterialDiffusivity(Materials[DefaultMaterial]) / 1E6;
    M.Period := 24 * 3600;
    M.Amplitude := 5;
    M.Dt := 60;
    M.Dx := 0.05;
    M.NodeCount := 21;
    for k := 1 to 5 * 1440 do M.Step;
    MaxDiff := 0;
    for i := 1 to 6 do
    begin
      Sum := 5 * Exp(-M.NodeDepth(i) / Sqrt(M.Diffusivity * M.Period / Pi));
      // Amplitude über einen Tag aus Minimum/Maximum
      MaxDiff := Max(MaxDiff, Abs(Sum - AmplitudeOverDay(M, i)));
    end;
    Check(MaxDiff < 0.05, Format('Dämpfung wie analytische Lösung (max. Abw. %.3f K)', [MaxDiff]));

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
