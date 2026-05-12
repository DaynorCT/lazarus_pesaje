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
    pnlCard: TPanel;
    pnlLogoBox: TPanel;
    lblLogoIcon: TLabel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    pnlDiv1: TPanel;
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
  ActiveControl := edtUsuario;
end;

procedure TfrmLogin.FormResize(Sender: TObject);
begin
  pnlCard.Left := (ClientWidth - pnlCard.Width) div 2;
  pnlCard.Top := (ClientHeight - pnlCard.Height) div 2;
end;

procedure TfrmLogin.btnIngresarClick(Sender: TObject);
var
  Resultado: TAuthResult;
begin
  if Trim(edtUsuario.Text) = '' then
  begin
    lblError.Caption := 'Ingrese su usuario';
    edtUsuario.SetFocus;
    Exit;
  end;

  if Trim(edtContrasena.Text) = '' then
  begin
    lblError.Caption := 'Ingrese su contraseña';
    edtContrasena.SetFocus;
    Exit;
  end;

  lblError.Caption := '';
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
      lblError.Caption := 'Usuario no registrado';
    arInvalidPassword:
      lblError.Caption := 'Contraseña incorrecta';
    arInactiveUser:
      lblError.Caption := 'Usuario inactivo';
    arError:
      lblError.Caption := 'Error de conexión con la base de datos';
  end;
end;

procedure TfrmLogin.lblSalirClick(Sender: TObject);
begin
  Application.Terminate;
end;

end.
