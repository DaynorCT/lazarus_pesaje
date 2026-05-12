unit LoginForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, AuthService, DataModule, Theme;

type
  TUserRecord = DataModule.TUserRecord;

  { TfrmLogin }

  TfrmLogin = class(TForm)
    pnlBG: TPanel;
    pnlCard: TPanel;
    pnlLogoBox: TPanel;
    lblLogoIcon: TLabel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    pnlDiv1: TPanel;
    pnlError: TPanel;
    lblError: TLabel;
    lblUsuario: TLabel;
    edtUsuario: TEdit;
    lblContrasena: TLabel;
    edtContrasena: TEdit;
    pnlDiv2: TPanel;
    pnlIngresar: TPanel;
    lblIngresar: TLabel;
    lblSalir: TLabel;
    procedure btnIngresarClick(Sender: TObject);
    procedure lblSalirClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    FUser: TUserRecord;
  public
    property User: TUserRecord read FUser;
  end;

var
  frmLogin: TfrmLogin;
  UsuarioActual: TUserRecord;

implementation

{$R *.lfm}

procedure TfrmLogin.FormCreate(Sender: TObject);
begin
  FillChar(FUser, SizeOf(FUser), 0);
  lblError.Caption := '';
  pnlError.Visible := False;

  pnlBG.Color := CLR_LOGIN_BG;

  pnlLogoBox.Color := CLR_LOGIN_ICON_BG;
  lblLogoIcon.Font.Color := CLR_LOGIN_ICON_FG;

  ActiveControl := edtUsuario;
end;

procedure TfrmLogin.FormResize(Sender: TObject);
begin
  pnlCard.Left := (pnlBG.ClientWidth - pnlCard.Width) div 2;
  pnlCard.Top := (pnlBG.ClientHeight - pnlCard.Height) div 2;
end;

procedure TfrmLogin.btnIngresarClick(Sender: TObject);
var
  Resultado: TAuthResult;
begin
  if Trim(edtUsuario.Text) = '' then
  begin
    lblError.Caption := 'Ingrese su usuario';
    pnlError.Visible := True;
    edtUsuario.SetFocus;
    Exit;
  end;

  if Trim(edtContrasena.Text) = '' then
  begin
    lblError.Caption := 'Ingrese su contraseña';
    pnlError.Visible := True;
    edtContrasena.SetFocus;
    Exit;
  end;

  lblError.Caption := '';
  pnlError.Visible := False;
  Screen.Cursor := crHourGlass;
  try
    Resultado := TAuthService.Login(Trim(edtUsuario.Text), Trim(edtContrasena.Text), FUser);
  finally
    Screen.Cursor := crDefault;
  end;

  case Resultado of
    arSuccess:
      begin
        UsuarioActual := FUser;
        ModalResult := mrOK;
      end;
    arInvalidEmail:
      begin
        lblError.Caption := 'Usuario no registrado';
        pnlError.Visible := True;
      end;
    arInvalidPassword:
      begin
        lblError.Caption := 'Contraseña incorrecta';
        pnlError.Visible := True;
      end;
    arInactiveUser:
      begin
        lblError.Caption := 'Usuario inactivo';
        pnlError.Visible := True;
      end;
    arError:
      begin
        lblError.Caption := 'Error de conexión con la base de datos';
        pnlError.Visible := True;
      end;
  end;
end;

procedure TfrmLogin.lblSalirClick(Sender: TObject);
begin
  Application.Terminate;
end;

end.
