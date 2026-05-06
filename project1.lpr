program project1;

{$mode objfpc}{$H+}
{$linkframework UserNotifications}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, Main
  { you can add units after this };

begin
  Application.Title:='Capturador de Peso';
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.