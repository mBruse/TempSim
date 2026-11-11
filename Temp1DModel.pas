unit Temp1DModel;

{ Numerischer Kern von Temperatur1D (ohne UI-Abhängigkeiten).

  Explizites Differenzenverfahren (FTCS) für die 1D-Wärmeleitungsgleichung

      dT/dt = a * d²T/dx²

  auf NodeCount Knoten im Abstand Dx:

      T_i(t+dt) = T_i(t) + r * (T_(i-1) - 2*T_i + T_(i+1)),   r = a*dt/dx²

  Randbedingungen:
      Knoten 0           : T = TInit + Amplitude * cos(2*pi*t / Period)
      Knoten NodeCount-1 : T = TInit  (konstant)

  Das Verfahren ist nur für r <= 0.5 stabil. Mit AutoSubstep wird der
  Zeitschritt intern so unterteilt, dass diese Bedingung immer erfüllt ist. }

interface

const
  MinNodes = 3;
  MaxNodes = 21;
  StabilityLimit = 0.5;

type
  TDoubleArray = array of Double;

  { Stoffwerte: Wärmeleitfähigkeit lambda (W/(m·K)), Dichte rho (kg/m³),
    spezifische Wärmekapazität c (J/(kg·K)). Das Modell braucht die
    Temperaturleitfähigkeit a = lambda / (rho·c). }
  TMaterial = record
    Name: string;
    Conductivity: Double;  // lambda, W/(m·K)
    Density: Double;       // rho, kg/m³
    SpecificHeat: Double;  // c, J/(kg·K)
  end;

const
  { Typische Werte; natürliche Stoffe streuen je nach Porosität, Feuchte und
    Temperatur stark. }
  Materials: array[0..26] of TMaterial = (
    // Böden, Schnee, Wasser, Luft (nach Oke 1987, Boundary Layer Climates, Tab. 2.1)
    (Name: 'Sand trocken'; Conductivity: 0.3; Density: 1600; SpecificHeat: 800),  // a = 0.234 mm²/s
    (Name: 'Sand feucht (20 Vol.-% Wasser)'; Conductivity: 1.6; Density: 1800; SpecificHeat: 1178),  // a = 0.755 mm²/s
    (Name: 'Ton trocken'; Conductivity: 0.25; Density: 1600; SpecificHeat: 890),  // a = 0.176 mm²/s
    (Name: 'Ton wassergesättigt'; Conductivity: 1.58; Density: 2000; SpecificHeat: 1550),  // a = 0.51 mm²/s
    (Name: 'Torf trocken'; Conductivity: 0.06; Density: 300; SpecificHeat: 1920),  // a = 0.104 mm²/s
    (Name: 'Torf wassergesättigt'; Conductivity: 0.5; Density: 1100; SpecificHeat: 3650),  // a = 0.125 mm²/s
    (Name: 'Schnee frisch'; Conductivity: 0.06; Density: 100; SpecificHeat: 2090),  // a = 0.287 mm²/s
    (Name: 'Schnee alt'; Conductivity: 0.42; Density: 480; SpecificHeat: 2090),  // a = 0.419 mm²/s
    (Name: 'Eis (0 °C)'; Conductivity: 2.24; Density: 917; SpecificHeat: 2100),  // a = 1.16 mm²/s
    (Name: 'Wasser (ruhend, 20 °C)'; Conductivity: 0.598; Density: 998; SpecificHeat: 4182),  // a = 0.143 mm²/s
    (Name: 'Luft (ruhend, 20 °C)'; Conductivity: 0.0257; Density: 1.204; SpecificHeat: 1005),  // a = 21.2 mm²/s
    // Gestein und Baustoffe (Richtwerte nach DIN EN ISO 10456 / DIN 4108-4)
    (Name: 'Granit'; Conductivity: 2.8; Density: 2600; SpecificHeat: 1000),  // a = 1.08 mm²/s
    (Name: 'Sandstein'; Conductivity: 2.3; Density: 2600; SpecificHeat: 1000),  // a = 0.885 mm²/s
    (Name: 'Kalkstein'; Conductivity: 1.7; Density: 2200; SpecificHeat: 1000),  // a = 0.773 mm²/s
    (Name: 'Beton (Normalbeton)'; Conductivity: 2.0; Density: 2400; SpecificHeat: 1000),  // a = 0.833 mm²/s
    (Name: 'Ziegelstein (Vollziegel)'; Conductivity: 0.81; Density: 1800; SpecificHeat: 1000),  // a = 0.45 mm²/s
    (Name: 'Putz (Kalkzement)'; Conductivity: 1.0; Density: 1800; SpecificHeat: 1000),  // a = 0.556 mm²/s
    (Name: 'Gipskarton'; Conductivity: 0.25; Density: 900; SpecificHeat: 1000),  // a = 0.278 mm²/s
    (Name: 'Asphalt'; Conductivity: 0.7; Density: 2100; SpecificHeat: 1000),  // a = 0.333 mm²/s
    (Name: 'Glas'; Conductivity: 1.0; Density: 2500; SpecificHeat: 750),  // a = 0.533 mm²/s
    (Name: 'Holz (Nadelholz)'; Conductivity: 0.13; Density: 500; SpecificHeat: 1600),  // a = 0.163 mm²/s
    (Name: 'Dämmung (Polystyrol EPS)'; Conductivity: 0.035; Density: 20; SpecificHeat: 1450),  // a = 1.21 mm²/s
    // Metalle (Raumtemperatur)
    (Name: 'Eisen (rein)'; Conductivity: 80.2; Density: 7870; SpecificHeat: 449),  // a = 22.7 mm²/s
    (Name: 'Stahl (unlegiert)'; Conductivity: 50.0; Density: 7850; SpecificHeat: 460),  // a = 13.8 mm²/s
    (Name: 'Edelstahl'; Conductivity: 15.0; Density: 7900; SpecificHeat: 500),  // a = 3.8 mm²/s
    (Name: 'Aluminium'; Conductivity: 237.0; Density: 2700; SpecificHeat: 897),  // a = 97.9 mm²/s
    (Name: 'Kupfer'; Conductivity: 401.0; Density: 8960; SpecificHeat: 385)  // a = 116 mm²/s
  );

  DefaultMaterial = 1; // Sand feucht

{ Temperaturleitfähigkeit a = lambda / (rho·c) in mm²/s. }
function MaterialDiffusivity(const M: TMaterial): Double;

{ Volumetrische Wärmekapazität rho·c in MJ/(m³·K). }
function MaterialHeatCapacity(const M: TMaterial): Double;

{ Liest eine Zahl mit Dezimalkomma oder -punkt ("1,5" und "1.5"). }
function TryParseNumber(const S: string; out Value: Double): Boolean;

type
  THeatModel1D = class
  private
    FNodeCount: Integer;
    FT, FTNew: TDoubleArray;
    FTMin, FTMax: TDoubleArray;
    FTime: Double;
    FStepCount: Integer;
    procedure SetNodeCount(Value: Integer);
    function GetT(Index: Integer): Double;
    function GetTMin(Index: Integer): Double;
    function GetTMax(Index: Integer): Double;
  public
    Diffusivity: Double; // m²/s
    Dx: Double;          // m
    Dt: Double;          // s
    TInit: Double;       // °C
    Amplitude: Double;   // K
    Period: Double;      // s
    AutoSubstep: Boolean;

    constructor Create;
    procedure Reset;
    { Führt einen Ausgabeschritt der Länge Dt aus (ggf. in Unterschritten). }
    procedure Step;
    function BoundaryTemperature(ATime: Double): Double;
    function FourierNumber: Double;
    function SubstepCount: Integer;
    function IsStable: Boolean;
    function NodeDepth(Index: Integer): Double; // m

    property NodeCount: Integer read FNodeCount write SetNodeCount;
    property T[Index: Integer]: Double read GetT; default;
    property TMin[Index: Integer]: Double read GetTMin;
    property TMax[Index: Integer]: Double read GetTMax;
    property Time: Double read FTime;           // s
    property StepCount: Integer read FStepCount;
  end;

implementation

uses
  SysUtils, Math;

function MaterialDiffusivity(const M: TMaterial): Double;
begin
  Result := M.Conductivity / (M.Density * M.SpecificHeat) * 1E6;
end;

function MaterialHeatCapacity(const M: TMaterial): Double;
begin
  Result := M.Density * M.SpecificHeat / 1E6;
end;

function TryParseNumber(const S: string; out Value: Double): Boolean;
var
  FS: TFormatSettings;
begin
  FS := FormatSettings;
  FS.DecimalSeparator := '.';
  FS.ThousandSeparator := #0;
  Result := TryStrToFloat(StringReplace(Trim(S), ',', '.', [rfReplaceAll]), Value, FS);
end;

constructor THeatModel1D.Create;
begin
  inherited Create;
  Diffusivity := MaterialDiffusivity(Materials[DefaultMaterial]) / 1E6;
  Dx := 0.01;
  Dt := 60;
  TInit := 20;
  Amplitude := 5;
  Period := 24 * 3600;
  AutoSubstep := True;
  NodeCount := 6;
end;

procedure THeatModel1D.SetNodeCount(Value: Integer);
begin
  FNodeCount := EnsureRange(Value, MinNodes, MaxNodes);
  SetLength(FT, FNodeCount);
  SetLength(FTNew, FNodeCount);
  SetLength(FTMin, FNodeCount);
  SetLength(FTMax, FNodeCount);
  Reset;
end;

procedure THeatModel1D.Reset;
var
  i: Integer;
begin
  FTime := 0;
  FStepCount := 0;
  for i := 0 to FNodeCount - 1 do
    FT[i] := TInit;
  FT[0] := BoundaryTemperature(0);
  for i := 0 to FNodeCount - 1 do
  begin
    FTMin[i] := FT[i];
    FTMax[i] := FT[i];
  end;
end;

function THeatModel1D.BoundaryTemperature(ATime: Double): Double;
begin
  if Period > 0 then
    Result := TInit + Amplitude * Cos(2 * Pi * ATime / Period)
  else
    Result := TInit + Amplitude;
end;

function THeatModel1D.FourierNumber: Double;
begin
  Result := Diffusivity * Dt / Sqr(Dx);
end;

function THeatModel1D.SubstepCount: Integer;
begin
  if AutoSubstep and (FourierNumber > StabilityLimit) then
    Result := Ceil(FourierNumber / StabilityLimit)
  else
    Result := 1;
end;

function THeatModel1D.IsStable: Boolean;
begin
  Result := FourierNumber / SubstepCount <= StabilityLimit;
end;

function THeatModel1D.NodeDepth(Index: Integer): Double;
begin
  Result := Index * Dx;
end;

procedure THeatModel1D.Step;
var
  i, Sub, NSub: Integer;
  SubDt, R: Double;
begin
  NSub := SubstepCount;
  SubDt := Dt / NSub;
  R := Diffusivity * SubDt / Sqr(Dx);

  for Sub := 1 to NSub do
  begin
    FTime := FTime + SubDt;

    FTNew[0] := BoundaryTemperature(FTime);
    for i := 1 to FNodeCount - 2 do
      FTNew[i] := FT[i] + R * (FT[i - 1] - 2 * FT[i] + FT[i + 1]);
    FTNew[FNodeCount - 1] := TInit;

    for i := 0 to FNodeCount - 1 do
      FT[i] := FTNew[i];
  end;

  Inc(FStepCount);
  for i := 0 to FNodeCount - 1 do
  begin
    FTMin[i] := Min(FTMin[i], FT[i]);
    FTMax[i] := Max(FTMax[i], FT[i]);
  end;
end;

function THeatModel1D.GetT(Index: Integer): Double;
begin
  Result := FT[Index];
end;

function THeatModel1D.GetTMin(Index: Integer): Double;
begin
  Result := FTMin[Index];
end;

function THeatModel1D.GetTMax(Index: Integer): Double;
begin
  Result := FTMax[Index];
end;

end.
