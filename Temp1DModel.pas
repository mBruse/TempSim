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

  TMaterial = record
    Name: string;
    Diffusivity: Double; // mm²/s
  end;

const
  Materials: array[0..7] of TMaterial = (
    (Name: 'Eisen';        Diffusivity: 22.8),
    (Name: 'Beton';        Diffusivity: 0.994),
    (Name: 'Sand trocken'; Diffusivity: 0.20),
    (Name: 'Sand feucht';  Diffusivity: 0.33),
    (Name: 'Putz';         Diffusivity: 0.58),
    (Name: 'Ziegelstein';  Diffusivity: 0.34),
    (Name: 'Luft';         Diffusivity: 20.0),
    (Name: 'Wasser';       Diffusivity: 0.14)
  );

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
  Math;

constructor THeatModel1D.Create;
begin
  inherited Create;
  Diffusivity := Materials[3].Diffusivity / 1E6;
  Dx := 0.01;
  Dt := 60;
  TInit := 20;
  Amplitude := 5;
  Period := 2 * 3600;
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
