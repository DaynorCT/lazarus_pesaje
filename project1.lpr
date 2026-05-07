program project1;

{$mode objfpc}{$H+}
{$linkframework UserNotifications}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces,
  Forms,
  UnitPrincipal,
  UnitManual
  { you can add units after this };

begin
  Application.Title:='Capturador de Peso';
  Application.Initialize;
  Application.CreateForm(TFormPrincipal, FormPrincipal);
  Application.Run;
end.