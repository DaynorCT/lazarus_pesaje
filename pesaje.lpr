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
  EmpresasFrame in 'src/forms/EmpresasFrame.pas' {FrameEmpresas: TFrameEmpresas},
  ChoferesFrame in 'src/forms/ChoferesFrame.pas' {FrameChoferes: TFrameChoferes},
  Utils in 'src/utils/Utils.pas',
  BoletaPesaje in 'src/reports/BoletaPesaje.pas';

{$IFDEF DARWIN}
{$linkframework UserNotifications}
{$ENDIF}

begin
  Randomize;
  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Title := 'Sistema de Pesaje';
  Application.Initialize;

  DM := TDM.Create(nil);
  DM.InicializarBaseDatos;

  try
    if not DM.Conexion.Connected then begin Application.Terminate; Exit; end;

    TAuthService.SeedAdminUser;

    repeat
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

      frmMain := TfrmMain.Create(nil);
      try
        frmMain.ShowModal;
        if frmMain.ModalResult <> mrCancel then
          break;
      finally
        frmMain.Free;
        frmMain := nil;
      end;
    until False;

  finally
    DM.Free;
  end;
end.
