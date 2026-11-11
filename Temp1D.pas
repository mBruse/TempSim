unit Temp1D;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math,
  System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Themes,
  VCLTee.TeEngine, VCLTee.Series, VCLTee.TeeProcs, VCLTee.Chart,
  VCLTee.TeeGDIPlus, Temp1DModel, Temp1DContour;

type
  // Zahlenfeld: Eingabe mit Grenzen, Dezimalkomma oder -punkt
  TNumField = record
    Edit: TEdit;
    MinValue, MaxValue, Default: Double;
    Decimals: Integer;
  end;

  TfrmTemp1D = class(TForm)
    pnlSettings: TPanel;
    lblHeader: TLabel;
    gbMaterial: TGroupBox;
    cbMaterial: TComboBox;
    lblTlf: TLabel;
    edTlf: TEdit;
    gbGrid: TGroupBox;
    lblNodes: TLabel;
    edNodes: TEdit;
    lblDx: TLabel;
    edDx: TEdit;
    gbBoundary: TGroupBox;
    lblTinit: TLabel;
    edTinit: TEdit;
    lblAmplitude: TLabel;
    edAmplitude: TEdit;
    lblPeriod: TLabel;
    edPeriod: TEdit;
    gbTime: TGroupBox;
    lblDt: TLabel;
    edDt: TEdit;
    lblSteps: TLabel;
    edSteps: TEdit;
    cbAutoSubstep: TCheckBox;
    lblStability: TLabel;
    pnlButtons: TPanel;
    btStart: TButton;
    btEinzelschritt: TButton;
    btExport: TButton;
    lblStyle: TLabel;
    cbStyle: TComboBox;
    pnlMain: TPanel;
    pnlSystem: TPanel;
    pbSystem: TPaintBox;
    PageControl1: TPageControl;
    tsTime: TTabSheet;
    ChartTime: TChart;
    tsProfile: TTabSheet;
    ChartProfile: TChart;
    tsIsopleth: TTabSheet;
    pbIsopleth: TPaintBox;
    tsInfo: TTabSheet;
    Memo1: TMemo;
    StatusBar: TStatusBar;
    SaveDialog: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btStartClick(Sender: TObject);
    procedure btEinzelschrittClick(Sender: TObject);
    procedure btExportClick(Sender: TObject);
    procedure cbMaterialChange(Sender: TObject);
    procedure edTlfChange(Sender: TObject);
    procedure FieldExit(Sender: TObject);
    procedure cbStyleChange(Sender: TObject);
    procedure ParamChanged(Sender: TObject);
    procedure pbSystemPaint(Sender: TObject);
    procedure pbIsoplethPaint(Sender: TObject);
  private
    FModel: THeatModel1D;
    FFields: array of TNumField;
    FTimeSeries: array of TLineSeries;
    FProfileSeries, FMinSeries, FMaxSeries: THorizLineSeries;
    FStarted: Boolean;
    FUpdating: Boolean;
    FIsoBitmap: TBitmap;
    FIsoDirty: Boolean;
    procedure SetupField(Edit: TEdit; AValue, AMin, AMax: Double;
      ADecimals: Integer);
    function FieldIndex(Edit: TEdit): Integer;
    function FieldValue(Edit: TEdit): Double;
    function FieldInt(Edit: TEdit): Integer;
    procedure SetFieldValue(Edit: TEdit; AValue: Double);
    procedure SetupCharts;
    procedure FillStyles;
    procedure FillInfoText;
    procedure ReadParams;
    procedure BuildSeries;
    procedure AddTimePoints;
    procedure RunSteps(Count: Integer);
    function ModelDiverged: Boolean;
    procedure UpdateProfile;
    procedure UpdateStability;
    procedure UpdateStatus;
    procedure UpdateButtons;
    procedure InvalidateIsopleth;
    function BuildIsoplethGrid(MaxRows: Integer; out TimeMax: Double): TGrid;
    procedure RenderIsopleth(W, H: Integer);
  end;

var
  frmTemp1D: TfrmTemp1D;

implementation

{$R *.dfm}

const
  // Farbverlauf für die Knoten (nach Tiefe): rot -> orange -> türkis -> blau
  DepthStops: array[0..3] of TColor = ($002626DC, $000C58EA, $0088940D, $00EB6325);
  ColdColor = TColor($00F6823B);
  NeutralColor = TColor($00F6F4F3);
  WarmColor = TColor($004444EF);
  OkColor = TColor($004AA316);
  WarnColor = TColor($000953B4);
  ErrorColor = TColor($002626DC);
  DivergenceLimit = 1E4;

function LerpColor(C1, C2: TColor; F: Double): TColor;
var
  RGB1, RGB2: Longint;
begin
  F := EnsureRange(F, 0, 1);
  RGB1 := ColorToRGB(C1);
  RGB2 := ColorToRGB(C2);
  Result := TColor(RGB(
    Round(GetRValue(RGB1) + (GetRValue(RGB2) - GetRValue(RGB1)) * F),
    Round(GetGValue(RGB1) + (GetGValue(RGB2) - GetGValue(RGB1)) * F),
    Round(GetBValue(RGB1) + (GetBValue(RGB2) - GetBValue(RGB1)) * F)));
end;

function RainbowColor(F: Double): TColor;
const
  // violett -> blau -> cyan -> grün -> gelb -> orange -> rot
  Stops: array[0..6] of TColor = ($00DC3C8C, $00F05A46, $00F0C83C, $0078DC6E,
    $005AF0FA, $005AAAFA, $003C3CF0);
var
  Pos: Double;
  k: Integer;
begin
  Pos := EnsureRange(F, 0, 1) * High(Stops);
  k := Min(Floor(Pos), High(Stops) - 1);
  Result := LerpColor(Stops[k], Stops[k + 1], Pos - k);
end;

function DepthColor(Index, Count: Integer): TColor;
var
  Pos: Double;
  k: Integer;
begin
  if Count <= 1 then
    Exit(DepthStops[0]);
  Pos := Index / (Count - 1) * High(DepthStops);
  k := Min(Floor(Pos), High(DepthStops) - 1);
  Result := LerpColor(DepthStops[k], DepthStops[k + 1], Pos - k);
end;

function TemperatureColor(T, TMid, Amp: Double): TColor;
var
  F: Double;
begin
  if Amp <= 0 then
    Amp := 1;
  F := EnsureRange((T - TMid) / Amp, -1, 1);
  if F < 0 then
    Result := LerpColor(NeutralColor, ColdColor, -F)
  else
    Result := LerpColor(NeutralColor, WarmColor, F);
end;

{ TfrmTemp1D }

procedure TfrmTemp1D.FormCreate(Sender: TObject);
var
  M: TMaterial;
begin
  FModel := THeatModel1D.Create;

  FUpdating := True;
  try
    cbMaterial.Items.Clear;
    for M in Materials do
      cbMaterial.Items.Add(Format('%s  (%s mm²/s)',
        [M.Name, FormatFloat('0.###', M.Diffusivity)]));
    cbMaterial.Items.Add('Benutzerdefiniert');
    cbMaterial.ItemIndex := 3; // Sand feucht

    SetupField(edTlf, Materials[3].Diffusivity, 0.001, 1000, 3);
    SetupField(edNodes, 6, MinNodes, MaxNodes, 0);
    SetupField(edDx, 1, 0.1, 100, 2);
    SetupField(edTinit, 20, -50, 100, 1);
    SetupField(edAmplitude, 5, 0, 50, 1);
    SetupField(edPeriod, 24, 0.1, 24, 2);
    SetupField(edDt, 1, 0.01, 1440, 2);
    SetupField(edSteps, 1440, 1, 100000, 0);
    cbAutoSubstep.Checked := True;
  finally
    FUpdating := False;
  end;

  // Stabilitätshinweis soll seine Farbe auch unter VCL-Styles behalten
  lblStability.StyleElements := [seClient, seBorder];

  SetupCharts;
  FillStyles;
  FillInfoText;

  ReadParams;
  FModel.NodeCount := FieldInt(edNodes);
  BuildSeries;
  UpdateProfile;
  UpdateStability;
  UpdateStatus;
  UpdateButtons;
  PageControl1.ActivePage := tsTime;
end;

procedure TfrmTemp1D.FormDestroy(Sender: TObject);
begin
  FIsoBitmap.Free;
  FModel.Free;
end;

procedure TfrmTemp1D.SetupField(Edit: TEdit; AValue, AMin, AMax: Double;
  ADecimals: Integer);
var
  F: TNumField;
begin
  F.Edit := Edit;
  F.MinValue := AMin;
  F.MaxValue := AMax;
  F.Default := AValue;
  F.Decimals := ADecimals;
  SetLength(FFields, Length(FFields) + 1);
  FFields[High(FFields)] := F;
  // Schriftfarbe selbst setzen (rot bei ungültiger Eingabe), auch unter VCL-Styles
  Edit.StyleElements := [seClient, seBorder];
  Edit.Alignment := taRightJustify;
  SetFieldValue(Edit, AValue);
end;

function TfrmTemp1D.FieldIndex(Edit: TEdit): Integer;
var
  i: Integer;
begin
  for i := 0 to High(FFields) do
    if FFields[i].Edit = Edit then
      Exit(i);
  raise Exception.CreateFmt('Kein Zahlenfeld: %s', [Edit.Name]);
end;

function TfrmTemp1D.FieldValue(Edit: TEdit): Double;
var
  F: TNumField;
  Parsed, Valid: Boolean;
begin
  F := FFields[FieldIndex(Edit)];
  Parsed := TryParseNumber(Edit.Text, Result) and not IsNan(Result);
  Valid := Parsed and (Result >= F.MinValue) and (Result <= F.MaxValue);
  if not Parsed then
    Result := F.Default
  else if not Valid then
    Result := EnsureRange(Result, F.MinValue, F.MaxValue);

  if Valid then
    Edit.Font.Color := StyleServices.GetSystemColor(clWindowText)
  else
    Edit.Font.Color := ErrorColor;
end;

function TfrmTemp1D.FieldInt(Edit: TEdit): Integer;
begin
  Result := Round(FieldValue(Edit));
end;

procedure TfrmTemp1D.SetFieldValue(Edit: TEdit; AValue: Double);
var
  F: TNumField;
  Fmt: string;
begin
  F := FFields[FieldIndex(Edit)];
  if F.Decimals > 0 then
    Fmt := '0.' + StringOfChar('#', F.Decimals)
  else
    Fmt := '0';
  Edit.Text := FormatFloat(Fmt, EnsureRange(AValue, F.MinValue, F.MaxValue));
end;

procedure TfrmTemp1D.FieldExit(Sender: TObject);
var
  Edit: TEdit;
begin
  // Beim Verlassen auf den gültigen (ggf. begrenzten) Wert normieren
  Edit := Sender as TEdit;
  SetFieldValue(Edit, FieldValue(Edit));
end;

procedure TfrmTemp1D.SetupCharts;

  function NewProfileSeries(const ATitle: string; AColor: TColor;
    AWidth: Integer; AStyle: TPenStyle): THorizLineSeries;
  begin
    Result := THorizLineSeries.Create(Self);
    Result.ParentChart := ChartProfile;
    Result.Title := ATitle;
    Result.SeriesColor := AColor;
    Result.LinePen.Width := AWidth;
    Result.LinePen.Style := AStyle;
  end;

begin
  ChartTime.Title.Text.Text := 'Temperaturschwingungen';
  ChartTime.BottomAxis.Title.Caption := 'Zeit (min)';
  ChartTime.LeftAxis.Title.Caption := 'Temperatur (°C)';

  ChartProfile.Title.Text.Text := 'Tiefenprofil und Schwankungsbreite';
  ChartProfile.BottomAxis.Title.Caption := 'Temperatur (°C)';
  ChartProfile.LeftAxis.Title.Caption := 'Tiefe (cm)';
  ChartProfile.LeftAxis.Inverted := True;

  FMaxSeries := NewProfileSeries('Maximum', WarmColor, 2, psDash);
  FMinSeries := NewProfileSeries('Minimum', ColdColor, 2, psDash);
  FProfileSeries := NewProfileSeries('Aktuell', clGray, 3, psSolid);
  FProfileSeries.Pointer.Visible := True;
  FProfileSeries.Pointer.Style := psCircle;
end;

procedure TfrmTemp1D.FillStyles;
var
  S: string;
begin
  cbStyle.Items.Clear;
  for S in TStyleManager.StyleNames do
    cbStyle.Items.Add(S);
  cbStyle.ItemIndex := cbStyle.Items.IndexOf(TStyleManager.ActiveStyle.Name);
  // Nur anzeigen, wenn im Projekt zusätzliche VCL-Styles eingebunden sind
  lblStyle.Visible := cbStyle.Items.Count > 1;
  cbStyle.Visible := cbStyle.Items.Count > 1;
end;

procedure TfrmTemp1D.FillInfoText;
var
  L: TStrings;
begin
  L := Memo1.Lines;
  L.BeginUpdate;
  try
    L.Clear;
    L.Add('Programm Temperatur1D');
    L.Add('');
    L.Add('Zeigt explizite Lösungen der Temperaturverteilung in einem eindimensionalen');
    L.Add('Körper aus N Knoten (Knoten 0 … N-1) im Abstand dx.');
    L.Add('');
    L.Add('Wärmeleitungsgleichung:   dT/dt = a · d²T/dx²');
    L.Add('');
    L.Add('Explizites Differenzenverfahren (FTCS):');
    L.Add('   T_i(t+dt) = T_i(t) + r · ( T_i-1(t) − 2·T_i(t) + T_i+1(t) )');
    L.Add('   mit der Fourier-Zahl  r = a · dt / dx²');
    L.Add('');
    L.Add('Randbedingungen:');
    L.Add('   T(0)   = Tinit + A · cos(2π · t / P)   (Amplitude A, Periode P)');
    L.Add('   T(N-1) = Tinit');
    L.Add('Zu Beginn haben alle inneren Knoten die Temperatur Tinit.');
    L.Add('');
    L.Add('Stabilität:');
    L.Add('   Das explizite Verfahren ist nur für r ≤ 0,5 stabil. Bei größeren Werten');
    L.Add('   wachsen Rundungsfehler exponentiell und die Lösung „explodiert“.');
    L.Add('   Ist „Stabilität sichern“ aktiviert, wird dt intern in so viele');
    L.Add('   Unterschritte geteilt, dass r ≤ 0,5 gilt. Ausgegeben wird weiterhin');
    L.Add('   nach jedem vollen Zeitschritt dt.');
    L.Add('');
    L.Add('Bedienung:');
    L.Add('   Start  – setzt das Modell zurück und rechnet die angegebene Schrittzahl.');
    L.Add('   Weiter – rechnet ab dem aktuellen Zustand weiter (geänderte Parameter');
    L.Add('            werden übernommen; eine geänderte Knotenzahl startet neu).');
    L.Add('   Tiefenprofil – aktueller Verlauf sowie Minimum/Maximum je Knoten:');
    L.Add('            zeigt die Dämpfung der Temperaturwelle mit der Tiefe.');
    L.Add('   Isoplethen – Temperatur als Farbfläche über Zeit (x) und Tiefe (y,');
    L.Add('            von oben nach unten) mit Isolinien; Werte siehe Farbskala.');
  finally
    L.EndUpdate;
  end;
end;

procedure TfrmTemp1D.ReadParams;
begin
  FModel.Diffusivity := FieldValue(edTlf) / 1E6;         // mm²/s -> m²/s
  FModel.Dx := Max(FieldValue(edDx), 0.01) / 100;        // cm -> m
  FModel.Dt := Max(FieldValue(edDt), 0.001) * 60;        // min -> s
  FModel.TInit := FieldValue(edTinit);
  FModel.Amplitude := FieldValue(edAmplitude);
  FModel.Period := FieldValue(edPeriod) * 3600;          // h -> s
  FModel.AutoSubstep := cbAutoSubstep.Checked;
end;

procedure TfrmTemp1D.BuildSeries;
var
  i, N: Integer;
  S: TLineSeries;
  Title: string;
begin
  for S in FTimeSeries do
    S.Free;

  N := FModel.NodeCount;
  SetLength(FTimeSeries, N);
  for i := 0 to N - 1 do
  begin
    Title := Format('Knoten %d', [i]);
    if i = 0 then
      Title := Title + ' – Rand'
    else if i = N - 1 then
      Title := Title + ' – Rand, konstant';

    S := TLineSeries.Create(Self);
    S.ParentChart := ChartTime;
    S.Title := Title;
    S.SeriesColor := DepthColor(i, N);
    S.LinePen.Width := 2;
    S.XValues.Order := loAscending;
    FTimeSeries[i] := S;
  end;
end;

procedure TfrmTemp1D.AddTimePoints;
var
  i: Integer;
begin
  for i := 0 to High(FTimeSeries) do
    FTimeSeries[i].AddXY(FModel.Time / 60, FModel[i]);
end;

function TfrmTemp1D.ModelDiverged: Boolean;
var
  i: Integer;
begin
  for i := 0 to FModel.NodeCount - 1 do
    if IsNan(FModel[i]) or (Abs(FModel[i]) > DivergenceLimit) then
      Exit(True);
  Result := False;
end;

procedure TfrmTemp1D.RunSteps(Count: Integer);
var
  k: Integer;
  Diverged: Boolean;
begin
  Diverged := False;
  Screen.Cursor := crHourGlass;
  ChartTime.AutoRepaint := False;
  try
    for k := 1 to Count do
    begin
      FModel.Step;
      if ModelDiverged then
      begin
        Diverged := True;
        Break;
      end;
      AddTimePoints;
    end;
  finally
    ChartTime.AutoRepaint := True;
    ChartTime.Invalidate;
    Screen.Cursor := crDefault;
  end;

  UpdateProfile;
  pbSystem.Invalidate;
  InvalidateIsopleth;
  UpdateStatus;

  if Diverged then
    MessageDlg(Format('Die Lösung ist instabil geworden (r = %s > 0,5) und ' +
      'wurde nach %d Schritten abgebrochen.' + sLineBreak + sLineBreak +
      'Zeitschritt dt verkleinern, Knotenabstand dx vergrößern oder ' +
      '„Stabilität sichern“ aktivieren.',
      [FormatFloat('0.###', FModel.FourierNumber), FModel.StepCount]),
      mtWarning, [mbOK], 0);
end;

procedure TfrmTemp1D.UpdateProfile;
var
  i: Integer;
  Depth: Double;
begin
  FProfileSeries.Clear;
  FMinSeries.Clear;
  FMaxSeries.Clear;
  for i := 0 to FModel.NodeCount - 1 do
  begin
    Depth := FModel.NodeDepth(i) * 100;
    FProfileSeries.AddXY(FModel[i], Depth);
    FMinSeries.AddXY(FModel.TMin[i], Depth);
    FMaxSeries.AddXY(FModel.TMax[i], Depth);
  end;
end;

procedure TfrmTemp1D.UpdateStability;
var
  R: string;
begin
  R := FormatFloat('0.###', FModel.FourierNumber);
  if FModel.FourierNumber <= StabilityLimit then
  begin
    lblStability.Caption := Format('Fourier-Zahl r = a·dt/dx² = %s' + sLineBreak +
      'r ≤ 0,5: Verfahren stabil', [R]);
    lblStability.Font.Color := OkColor;
  end
  else if FModel.AutoSubstep then
  begin
    lblStability.Caption := Format('Fourier-Zahl r = a·dt/dx² = %s' + sLineBreak +
      'r > 0,5: dt wird in %d Unterschritte geteilt', [R, FModel.SubstepCount]);
    lblStability.Font.Color := WarnColor;
  end
  else
  begin
    lblStability.Caption := Format('Fourier-Zahl r = a·dt/dx² = %s' + sLineBreak +
      'r > 0,5: explizites Verfahren instabil!', [R]);
    lblStability.Font.Color := ErrorColor;
  end;
end;

procedure TfrmTemp1D.UpdateStatus;
begin
  StatusBar.Panels[0].Text := Format('Zeit: %s min (%s h)',
    [FormatFloat('0.#', FModel.Time / 60), FormatFloat('0.00', FModel.Time / 3600)]);
  StatusBar.Panels[1].Text := Format('Schritte: %d', [FModel.StepCount]);
  StatusBar.Panels[2].Text := Format('r = %s   Unterschritte je dt: %d',
    [FormatFloat('0.###', FModel.FourierNumber), FModel.SubstepCount]);
end;

procedure TfrmTemp1D.UpdateButtons;
begin
  btEinzelschritt.Enabled := FStarted;
  btExport.Enabled := FStarted;
end;

procedure TfrmTemp1D.btStartClick(Sender: TObject);
begin
  ReadParams;
  FModel.NodeCount := FieldInt(edNodes);
  FModel.Reset;
  BuildSeries;
  AddTimePoints;
  FStarted := True;
  UpdateButtons;
  RunSteps(FieldInt(edSteps));
end;

procedure TfrmTemp1D.btEinzelschrittClick(Sender: TObject);
begin
  // Ohne laufende Simulation oder bei geänderter Knotenzahl neu starten
  if not FStarted or (FieldInt(edNodes) <> FModel.NodeCount) then
  begin
    btStartClick(Sender);
    Exit;
  end;
  ReadParams;
  RunSteps(FieldInt(edSteps));
end;

procedure TfrmTemp1D.btExportClick(Sender: TObject);
var
  Lines: TStringList;
  Row: string;
  i, j: Integer;
begin
  if (Length(FTimeSeries) = 0) or not SaveDialog.Execute then
    Exit;

  Lines := TStringList.Create;
  try
    Row := 'Zeit (min)';
    for i := 0 to High(FTimeSeries) do
      Row := Row + ';' + Format('T%d (°C)', [i]);
    Lines.Add(Row);

    for j := 0 to FTimeSeries[0].Count - 1 do
    begin
      Row := FormatFloat('0.###', FTimeSeries[0].XValue[j]);
      for i := 0 to High(FTimeSeries) do
        Row := Row + ';' + FormatFloat('0.####', FTimeSeries[i].YValue[j]);
      Lines.Add(Row);
    end;

    Lines.SaveToFile(SaveDialog.FileName, TEncoding.UTF8);
  finally
    Lines.Free;
  end;
end;

procedure TfrmTemp1D.cbMaterialChange(Sender: TObject);
var
  Idx: Integer;
begin
  if FUpdating or (FModel = nil) then
    Exit;
  Idx := cbMaterial.ItemIndex;
  if (Idx >= Low(Materials)) and (Idx <= High(Materials)) then
  begin
    FUpdating := True;
    try
      SetFieldValue(edTlf, Materials[Idx].Diffusivity);
    finally
      FUpdating := False;
    end;
  end;
  ParamChanged(Sender);
end;

procedure TfrmTemp1D.edTlfChange(Sender: TObject);
var
  i: Integer;
begin
  if FUpdating or (FModel = nil) then
    Exit;
  // Passendes Material auswählen, sonst "Benutzerdefiniert"
  cbMaterial.ItemIndex := cbMaterial.Items.Count - 1;
  for i := Low(Materials) to High(Materials) do
    if SameValue(FieldValue(edTlf), Materials[i].Diffusivity, 1E-6) then
    begin
      cbMaterial.ItemIndex := i;
      Break;
    end;
  ParamChanged(Sender);
end;

procedure TfrmTemp1D.cbStyleChange(Sender: TObject);
begin
  if cbStyle.ItemIndex >= 0 then
    TStyleManager.TrySetStyle(cbStyle.Items[cbStyle.ItemIndex], False);
  pbSystem.Invalidate;
  InvalidateIsopleth;
end;

procedure TfrmTemp1D.ParamChanged(Sender: TObject);
begin
  if FUpdating or (FModel = nil) then
    Exit;
  ReadParams;
  UpdateProfile;
  UpdateStability;
  UpdateStatus;
  pbSystem.Invalidate;
  InvalidateIsopleth;
end;

procedure TfrmTemp1D.InvalidateIsopleth;
begin
  FIsoDirty := True;
  pbIsopleth.Invalidate;
end;

function TfrmTemp1D.BuildIsoplethGrid(MaxRows: Integer; out TimeMax: Double): TGrid;
var
  N, Count, Rows, k, i, j: Integer;
  T, X0, X1, F: Double;
begin
  // Zeitreihen auf ein zeitlich äquidistantes Gitter umrechnen
  // (dt kann sich bei "Weiter" geändert haben)
  Result := nil;
  TimeMax := 0;
  N := Length(FTimeSeries);
  if N < 2 then
    Exit;
  Count := FTimeSeries[0].Count;
  if Count < 2 then
    Exit;
  TimeMax := FTimeSeries[0].XValue[Count - 1];
  Rows := Min(Count, MaxRows);

  SetLength(Result, Rows);
  j := 0;
  for k := 0 to Rows - 1 do
  begin
    T := TimeMax * k / (Rows - 1);
    while (j < Count - 2) and (FTimeSeries[0].XValue[j + 1] < T) do
      Inc(j);
    X0 := FTimeSeries[0].XValue[j];
    X1 := FTimeSeries[0].XValue[j + 1];
    if X1 > X0 then
      F := EnsureRange((T - X0) / (X1 - X0), 0, 1)
    else
      F := 0;
    SetLength(Result[k], N);
    for i := 0 to N - 1 do
      Result[k][i] := FTimeSeries[i].YValue[j] +
        (FTimeSeries[i].YValue[j + 1] - FTimeSeries[i].YValue[j]) * F;
  end;
end;

type
  TRGBTripleRow = array[0..65535] of TRGBTriple;
  PRGBTripleRow = ^TRGBTripleRow;

procedure TfrmTemp1D.RenderIsopleth(W, H: Integer);
const
  MaxRows = 400;
var
  C: TCanvas;
  G: TGrid;
  Levels, Ticks: TDoubleArray;
  Bands: array of TColor;
  Segs: TSegmentArray;
  Bg, Fg, LineColor: TColor;
  TimeMax, TimeScale, Step, TickStep, TMin, TMax, V, GX, GY: Double;
  TimeUnit, S: string;
  N, Rows, TextH, PL, PT, PR, PB, PW, PH, X, Y, i, k, ri, ci, BarL, BarW,
    LastLabelY: Integer;
  Row: PRGBTripleRow;
  RGBValue: Longint;

  // Gitter: Spalte = Knoten (Tiefe), Zeile = Zeit.
  // Diagramm: x = Zeit (nach rechts), y = Tiefe (nach unten).
  function MapTime(GridRow: Double): Integer;
  begin
    Result := PL + Round(GridRow / (Rows - 1) * (PW - 1));
  end;

  function MapDepth(GridCol: Double): Integer;
  begin
    Result := PT + Round(GridCol / (N - 1) * (PH - 1));
  end;

begin
  if FIsoBitmap = nil then
    FIsoBitmap := TBitmap.Create;
  FIsoBitmap.PixelFormat := pf24bit;
  FIsoBitmap.SetSize(W, H);
  FIsoDirty := False;

  C := FIsoBitmap.Canvas;
  Bg := StyleServices.GetSystemColor(clWindow);
  Fg := StyleServices.GetSystemColor(clWindowText);
  C.Brush.Style := bsSolid;
  C.Brush.Color := Bg;
  C.FillRect(Rect(0, 0, W, H));
  C.Font.Assign(Font);
  C.Font.Color := Fg;
  TextH := C.TextHeight('0');

  G := BuildIsoplethGrid(MaxRows, TimeMax);
  if Length(G) < 2 then
  begin
    S := 'Noch keine Daten – bitte „Start“ drücken.';
    C.TextOut((W - C.TextWidth(S)) div 2, (H - TextH) div 2, S);
    Exit;
  end;
  Rows := Length(G);
  N := Length(G[0]);

  // Wertebereich, Isolinien und Farbbänder
  TMin := G[0][0];
  TMax := TMin;
  for ri := 0 to Rows - 1 do
    for ci := 0 to N - 1 do
    begin
      TMin := Min(TMin, G[ri][ci]);
      TMax := Max(TMax, G[ri][ci]);
    end;
  Levels := ContourLevels(TMin, TMax, 12, Step);
  SetLength(Bands, Length(Levels) + 1);
  for k := 0 to High(Bands) do
    if Length(Bands) > 1 then
      Bands[k] := RainbowColor(k / High(Bands))
    else
      Bands[k] := RainbowColor(0.5);

  // Zeitachse in Stunden, bei kurzen Läufen in Minuten (Daten in min)
  if TimeMax >= 180 then
  begin
    TimeUnit := 'h';
    TimeScale := 1 / 60;
  end
  else
  begin
    TimeUnit := 'min';
    TimeScale := 1;
  end;

  // Layout
  PL := 16 + C.TextWidth('000.00');
  PT := 12 + 2 * TextH + 8;
  BarW := 16;
  PR := W - (24 + BarW + 8 + C.TextWidth('-000.0') + 8);
  PB := H - (12 + 2 * TextH + 8);
  BarL := PR + 24;
  PW := PR - PL;
  PH := PB - PT;
  if (PW < 40) or (PH < 40) then
    Exit;

  // Titel
  C.Brush.Style := bsClear;
  C.Font.Style := [fsBold];
  C.TextOut(PL, 8, 'Thermoisoplethen: Temperatur über Tiefe und Zeit');
  C.Font.Style := [];

  // Farbflächen (bilinear interpoliert, in Bänder gestuft)
  for Y := 0 to PH - 1 do
  begin
    Row := FIsoBitmap.ScanLine[PT + Y];
    GX := Y / Max(PH - 1, 1) * (N - 1);       // Tiefe
    for X := 0 to PW - 1 do
    begin
      GY := X / Max(PW - 1, 1) * (Rows - 1);  // Zeit
      V := BilinearValue(G, GX, GY);
      RGBValue := ColorToRGB(Bands[BandIndex(Levels, Step, V)]);
      Row[PL + X].rgbtRed := GetRValue(RGBValue);
      Row[PL + X].rgbtGreen := GetGValue(RGBValue);
      Row[PL + X].rgbtBlue := GetBValue(RGBValue);
    end;
  end;

  // Isolinien (ohne Beschriftung, Werte über die Farbskala)
  LineColor := TColor($00303030);
  C.Pen.Color := LineColor;
  C.Pen.Width := 1;
  for k := 0 to High(Levels) do
  begin
    Segs := ContourSegments(G, Levels[k]);
    for i := 0 to High(Segs) do
    begin
      C.MoveTo(MapTime(Segs[i].Y1), MapDepth(Segs[i].X1));
      C.LineTo(MapTime(Segs[i].Y2), MapDepth(Segs[i].X2));
    end;
  end;

  // Rahmen
  C.Brush.Style := bsClear;
  C.Pen.Color := LerpColor(Bg, Fg, 0.6);
  C.Rectangle(PL - 1, PT - 1, PR + 1, PB + 1);

  // x-Achse: Zeit
  C.Font.Color := Fg;
  Ticks := ContourLevels(0, TimeMax * TimeScale,
    Max(2, PW div (C.TextWidth('0000') + 24)), TickStep);
  for k := 0 to High(Ticks) do
  begin
    X := PL + Round(Ticks[k] / (TimeMax * TimeScale) * (PW - 1));
    C.MoveTo(X, PB);
    C.LineTo(X, PB + 4);
    S := FormatFloat('0.##', Ticks[k]);
    C.TextOut(X - C.TextWidth(S) div 2, PB + 6, S);
  end;
  S := 'Zeit (' + TimeUnit + ')';
  C.TextOut(PL + (PW - C.TextWidth(S)) div 2, PB + 8 + TextH, S);

  // y-Achse: Tiefe der Knoten, 0 oben
  LastLabelY := -MaxInt;
  for i := 0 to N - 1 do
  begin
    Y := MapDepth(i);
    C.MoveTo(PL - 4, Y);
    C.LineTo(PL, Y);
    S := FormatFloat('0.##', FModel.NodeDepth(i) * 100);
    if Y - TextH div 2 > LastLabelY + 2 then
    begin
      C.TextOut(PL - 6 - C.TextWidth(S), Y - TextH div 2, S);
      LastLabelY := Y + TextH div 2;
    end;
  end;
  S := 'Tiefe (cm)';
  C.TextOut(Max(4, PL - C.TextWidth(S) - 6), PT - TextH - 6, S);

  // Farbskala: hohe Werte oben
  C.Pen.Color := LerpColor(Bg, Fg, 0.6);
  for k := 0 to High(Bands) do
  begin
    C.Brush.Style := bsSolid;
    C.Brush.Color := Bands[k];
    C.FillRect(Rect(BarL, PT + Round((High(Bands) - k) / Length(Bands) * PH),
      BarL + BarW, PT + Round((High(Bands) - k + 1) / Length(Bands) * PH)));
  end;
  C.Brush.Style := bsClear;
  C.Rectangle(BarL - 1, PT - 1, BarL + BarW + 1, PB + 1);
  LastLabelY := MaxInt;
  for k := 0 to High(Levels) do
  begin
    // Grenze zwischen Band k und k+1
    Y := PT + Round((High(Bands) - k) / Length(Bands) * PH);
    if Y + TextH div 2 < LastLabelY - 2 then
    begin
      S := FormatFloat('0.##', Levels[k]);
      C.TextOut(BarL + BarW + 6, Y - TextH div 2, S);
      LastLabelY := Y - TextH div 2;
    end;
  end;
  C.TextOut(BarL, PT - TextH - 6, '°C');
end;

procedure TfrmTemp1D.pbIsoplethPaint(Sender: TObject);
begin
  if FModel = nil then
    Exit;
  if FIsoDirty or (FIsoBitmap = nil) or (FIsoBitmap.Width <> pbIsopleth.Width) or
    (FIsoBitmap.Height <> pbIsopleth.Height) then
    RenderIsopleth(pbIsopleth.Width, pbIsopleth.Height);
  pbIsopleth.Canvas.Draw(0, 0, FIsoBitmap);
end;

procedure TfrmTemp1D.pbSystemPaint(Sender: TObject);
var
  C: TCanvas;
  W, H, N, i, X, Y, D, Margin, TextH: Integer;
  Spacing: Double;
  Bg, Fg: TColor;
  S: string;
  IsBoundary: Boolean;
begin
  if FModel = nil then
    Exit;
  C := pbSystem.Canvas;
  W := pbSystem.Width;
  H := pbSystem.Height;
  N := FModel.NodeCount;

  Bg := StyleServices.GetSystemColor(clWindow);
  Fg := StyleServices.GetSystemColor(clWindowText);

  C.Brush.Style := bsSolid;
  C.Brush.Color := Bg;
  C.FillRect(Rect(0, 0, W, H));

  C.Font.Assign(Font);
  C.Font.Color := Fg;
  TextH := C.TextHeight('0');

  // Überschrift und Legende
  C.Brush.Style := bsClear;
  C.Font.Style := [fsBold];
  S := Format('System: %d Knoten, dx = %s cm, Gesamttiefe %s cm',
    [N, FormatFloat('0.##', FModel.Dx * 100),
     FormatFloat('0.##', FModel.NodeDepth(N - 1) * 100)]);
  C.TextOut(12, 6, S);
  C.Font.Style := [];
  S := 'Quadrat = Randknoten,  Füllfarbe = Temperatur (blau kalt, rot warm)';
  C.Font.Color := LerpColor(Fg, Bg, 0.4);
  C.TextOut(W - C.TextWidth(S) - 12, 6, S);
  C.Font.Color := Fg;

  Margin := Max(40, W div 20);
  Spacing := (W - 2 * Margin) / Max(N - 1, 1);
  D := Max(8, Min(Integer(Round(H * 0.24)), Integer(Round(Spacing * 0.7))));
  Y := 6 + TextH + (H - 6 - TextH) div 2;

  // Balken (der Körper)
  C.Brush.Style := bsSolid;
  C.Brush.Color := LerpColor(Bg, Fg, 0.06);
  C.Pen.Color := LerpColor(Bg, Fg, 0.3);
  C.Pen.Width := 1;
  C.RoundRect(Margin - D div 2 - 10, Y - D div 2 - 8,
    W - Margin + D div 2 + 10, Y + D div 2 + 8, 12, 12);

  for i := 0 to N - 1 do
  begin
    X := Margin + Round(i * Spacing);
    IsBoundary := (i = 0) or (i = N - 1);

    C.Brush.Style := bsSolid;
    C.Brush.Color := TemperatureColor(FModel[i], FModel.TInit, FModel.Amplitude);
    C.Pen.Color := DepthColor(i, N);
    C.Pen.Width := Max(2, D div 10);
    if IsBoundary then
      C.RoundRect(X - D div 2, Y - D div 2, X + D div 2, Y + D div 2, D div 3, D div 3)
    else
      C.Ellipse(X - D div 2, Y - D div 2, X + D div 2, Y + D div 2);

    C.Brush.Style := bsClear;
    S := IntToStr(i);
    C.TextOut(X - C.TextWidth(S) div 2, Y - D div 2 - 10 - TextH, S);

    S := FormatFloat('0.0', FModel[i]) + ' °C';
    if C.TextWidth(S) < Spacing - 4 then
      C.TextOut(X - C.TextWidth(S) div 2, Y + D div 2 + 10, S);
  end;
  C.Pen.Width := 1;
end;

end.
