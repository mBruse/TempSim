program Temperatur1D;

uses
  Forms,
  Temp1D in 'Temp1D.pas' {frmTemp1D};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TfrmTemp1D, frmTemp1D);
  Application.Run;
end.
