program Temperatur1D;

uses
  Vcl.Forms,
  Vcl.Themes,
  Vcl.Styles,
  Temp1DModel in 'Temp1DModel.pas',
  Temp1D in 'Temp1D.pas' {frmTemp1D};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Temperatur1D';
  // Moderner Windows-11-Look, sofern der Style unter
  // Projekt > Optionen > Anwendung > Erscheinungsbild eingebunden ist.
  TStyleManager.TrySetStyle('Windows11 Modern Light', False);
  Application.CreateForm(TfrmTemp1D, frmTemp1D);
  Application.Run;
end.
