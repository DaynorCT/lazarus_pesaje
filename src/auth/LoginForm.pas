unit LoginForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ExtCtrls, AuthService, DataModule;

type
  TUserRecord = DataModule.TUserRecord;

  { TfrmLogin }

  TfrmLogin = class(TForm)
    pnlMain: TPanel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    lblEmail: TLabel;
    edtEmail: TEdit;
    lblPassword: TLabel;
    edtPassword: TEdit;
    btnIngresar: TBitBtn;
    btnSalir: TBitBtn;
    lblError: TLabel;
    procedure btnIngresarClick(Sender: TObject);
    procedure btnSalirClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
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
  ActiveControl := edtEmail;
end;

procedure TfrmLogin.btnIngresarClick(Sender: TObject);
var
  Resultado: TAuthResult;
begin
  if Trim(edtEmail.Text) = '' then
  begin
    lblError.Caption := 'Ingrese su email';
    edtEmail.SetFocus;
    Exit;
  end;

  if Trim(edtPassword.Text) = '' then
  begin
    lblError.Caption := 'Ingrese su contraseña';
    edtPassword.SetFocus;
    Exit;
  end;

  lblError.Caption := '';
  Screen.Cursor := crHourGlass;
  try
    Resultado := TAuthService.Login(Trim(edtEmail.Text), Trim(edtPassword.Text), FUser);
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
      lblError.Caption := 'Email no registrado';
    arInvalidPassword:
      lblError.Caption := 'Contraseña incorrecta';
    arInactiveUser:
      lblError.Caption := 'Usuario inactivo';
    arError:
      lblError.Caption := 'Error de conexión con la base de datos';
  end;
end;

procedure TfrmLogin.btnSalirClick(Sender: TObject);
begin
  Application.Terminate;
end;

end.
