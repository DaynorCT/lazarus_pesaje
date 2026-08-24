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
  ConfigService in 'src/utils/ConfigService.pas',
  SyncService in 'src/utils/SyncService.pas',
  PesajeIntegrado in 'src/forms/PesajeIntegrado.pas' {frmPesajeIntegrado: TfrmPesajeIntegrado},
  BoletaPesaje in 'src/reports/BoletaPesaje.pas',
  ReportePesaje in 'src/reports/ReportePesaje.pas',
  ReportesFrame in 'src/forms/ReportesFrame.pas' {FrameReportes: TFrameReportes},
  BoletaConfigFrame in 'src/forms/BoletaConfigFrame.pas' {FrameBoletaConfig: TFrameBoletaConfig};

{$IFDEF DARWIN}
{$linkframework UserNotifications}
{$ENDIF}

var
  ConfigSistema: TConfigSistema;
  VistaIntegrada: Boolean;
  ResultadoVista: Integer;

begin
  Randomize;
  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Title := 'Sistema de Pesaje';
  Application.Initialize;
  Utils.RegistrarFAFuente;

  DM := TDM.Create(nil);
  DM.InicializarBaseDatos;

  try
    if not DM.Conexion.Connected then begin Application.Terminate; Exit; end;

    TAuthService.SeedAdminUser;

    ConfigSistema := CargarConfigSistema;
    SyncSvc := TSyncService.Create;

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

      SyncSvc.Configurar(UsuarioActual.Email, UltimaContrasena);
      VistaIntegrada := ConfigSistema.ModoOperacion = 'INTEGRADO';

      repeat
        if VistaIntegrada then
        begin
          frmPesajeIntegrado := TfrmPesajeIntegrado.Create(nil);
          try
            ResultadoVista := frmPesajeIntegrado.ShowModal;
          finally
            frmPesajeIntegrado.Free;
            frmPesajeIntegrado := nil;
          end;

          if ResultadoVista = mrYes then
          begin
            VistaIntegrada := False;
            ConfigSistema.ModoOperacion := 'AUTONOMO';
            GuardarConfigSistema(ConfigSistema);
          end
          else if ResultadoVista = mrCancel then
            Break
          else
          begin
            Application.Terminate;
            Exit;
          end;
        end
        else
        begin
          frmMain := TfrmMain.Create(nil);
          try
            ResultadoVista := frmMain.ShowModal;
          finally
            frmMain.Free;
            frmMain := nil;
          end;

          if ResultadoVista = mrYes then
          begin
            VistaIntegrada := True;
            ConfigSistema.ModoOperacion := 'INTEGRADO';
            GuardarConfigSistema(ConfigSistema);
          end
          else if ResultadoVista = mrCancel then
            Break
          else
          begin
            Application.Terminate;
            Exit;
          end;
        end;
      until False;
    until False;

  finally
    SyncSvc.Free;
    DM.Free;
  end;
end.
