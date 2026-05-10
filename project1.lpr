program project1;

{$mode objfpc}{$H+}
{$linkframework UserNotifications}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces,
  Forms,
  UnitDashboard,
  UnitManual
  { you can add units after this };

begin
  Application.Title:='Capturador de Peso';
  Application.Initialize;
  Application.CreateForm(TFormDashboard, FormDashboard);
  Application.Run;
end.