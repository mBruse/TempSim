unit Temp1D;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Grids, TeEngine, Series, ExtCtrls, TeeProcs, Chart, ComCtrls,
  VclTee.TeeGDIPlus;

type
  TfrmTemp1D = class(TForm)
    Panel1: TPanel;
    btStart: TButton;
    Label4: TLabel;
    TabSheet2: TTabSheet;
    Chart: TChart;
    Label1: TLabel;
    TabSheet1: TTabSheet;
    Memo1: TMemo;
    Series1: TLineSeries;
    Series2: TLineSeries;
    Series3: TLineSeries;
    Series4: TLineSeries;
    Series5: TLineSeries;
    Series6: TLineSeries;
    Label2: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    e_Tinit: TEdit;
    E_dx: TEdit;
    E_schritte: TEdit;
    pagecontrol1: TPageControl;
    TabSheet3: TTabSheet;
    btEinzelschritt: TButton;
    Label6: TLabel;
    e_dt: TEdit;
    cb_tlf: TComboBox;
    Image1: TImage;
    Image2: TImage;
    procedure btStartClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private-Deklarationen }
    procedure ReadData;
    procedure DrawData;

    var
      Anzahl_schritte: Integer;

      dt: Single;
      Tlf: Single;
      T_init: Single;
      dx: Single;
      totalTime:Single;

      T_t, T_tneu: array[0..10] of Single;
  public
    { Public-Deklarationen }
  end;

var
  frmTemp1D: TfrmTemp1D;

implementation

{$R *.DFM}

procedure TfrmTemp1D.btStartClick(Sender: TObject);
var
  a, b: Single;
  i, loop, dummy: Integer;

begin

  readData;

  if sender=btStart then begin
  Series1.Clear;
  Series2.Clear;
  Series3.Clear;
  Series4.Clear;
  Series5.Clear;
  Series6.Clear;


  // Init: Alle T Werte auf den Startwert setzen
  for loop := 0 to 5 do
    begin
    T_t[loop] := T_init;
    t_tneu[loop]:= T_init;
    end;


  TotalTime:=0;

  DrawData;
  end;

  // Hauptschleife -------------------------------------------------------------
  for var zeitschleife := 1 to Anzahl_schritte do
  begin
    totaltime:=totaltime+dt;

    // Knoten 0, Zeitschritt in h umrechen
    T_tneu[0] := cos(pi * (totaltime/(60*60))) * 5 + T_init;

    for i := 1 to 4 do
    begin
      // a und b sind zwei Hilfsvarianlen, damit der Ausdruck nicht
      // zu komplex wird
      a := Tlf * (T_t[i - 1] - T_t[i]) / dx;
      b := Tlf * (T_t[i] - T_t[i + 1]) / dx;
      T_tneu[i] := 1 / dx * (a - b) * dt + T_t[i];
    end;

    // Knoten 5
    T_tneu[5] := T_init;

    DrawData;

    // Kopieren Alt-> Neu
    for loop := 0 to 5 do
      T_t[loop] := T_tneu[loop];

  end; // Schleife
end; // prozedure

procedure TfrmTemp1D.DrawData;
begin
  // ((( Ausgaberoutinen ))) -------------------------------------------------

    // ins Diagramm zeichnen
  series1.AddXY(totalTime/60, T_tneu[0]);
  series2.AddXY(totalTime/60, T_tneu[1]);
  series3.AddXY(totalTime/60, T_tneu[2]);
  series4.AddXY(totalTime/60, T_tneu[3]);
  series5.AddXY(totalTime/60, T_tneu[4]);
  series6.AddXY(totalTime/60, T_tneu[5]);
end;

procedure TfrmTemp1D.FormCreate(Sender: TObject);
begin
  // Vorgabe einsetzen
  e_schritte.Text := '300';
  cb_tlf.ItemIndex:=3;
  e_tinit.Text := '20';
  e_dx.Text := '1';
  e_dt.Text := '1';
end;

procedure TfrmTemp1D.ReadData;
var
  dummy: Integer;
  v:Single;
begin
  // Temperaturleitfähigkeit
  Val(cb_tlf.Text, v, dummy);

  // mm2 -> m²
  tlf:=v/ sqr(1000);

  // Startwert T
  Val(e_tinit.Text, T_init, dummy);

  // Knotenabstand dx   in cm
  Val(e_dx.Text, v, dummy);
  dx:= v/100;

  // Anzahl der gewünschten Schritte
  Val(e_schritte.Text, Anzahl_schritte, Dummy);

  // Länge Zeitschritt (min)
  VAl(e_dt.Text, v, dummy);

  // min -> sec
  dt:=v*60;

end;

end.

