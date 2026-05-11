program Pesaje;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, Forms, Controls, SysUtils,
  DataModule in 'src/database/DataModule.pas' {DM: TDM},
  AuthService in 'src/auth/AuthService.pas',
  LoginForm in 'src/auth/LoginForm.pas' {frmLogin: TfrmLogin},
  MainForm in 'src/forms/MainForm.pas' {frmMain: TfrmMain},
  PesajeFrame in 'src/forms/PesajeFrame.pas' {FramePesaje: TFramePesaje},
  DashboardFrame in 'src/forms/DashboardFrame.pas' {FrameDashboard: TFrameDashboard},
  Utils in 'src/utils/Utils.pas';

{$linkframework UserNotifications}

begin
  Randomize;
  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Title := 'Sistema de Pesaje';
  Application.Initialize;

  // Crear DataModule
  DM := TDM.Create(nil);
  try
    if not DM.Conexion.Connected then
    begin
      WriteLn('Error: No se pudo conectar a la base de datos');
      Application.Terminate;
      Exit;
    end;

    // Crear usuario admin si no existe
    TAuthService.SeedAdminUser;

    // Login
    frmLogin := TfrmLogin.Create(nil);
    try
      if frmLogin.ShowModal <> mrOK then
      begin
        Application.Terminate;
        Exit;
      end;
    finally
      frmLogin.Free;
    end;

    // Main form
    Application.CreateForm(TfrmMain, frmMain);
    Application.Run;

  finally
    DM.Free;
  end;
end.
