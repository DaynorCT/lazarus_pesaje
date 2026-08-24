unit LoginForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SQLDB, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, AuthService, DataModule, Theme;

type
  TUserRecord = DataModule.TUserRecord;

  { TfrmLogin }

  TfrmLogin = class(TForm)
    pnlBG: TPanel;
    pnlCard: TPanel;
    pnlLogoBox: TPanel;

    imgLogo: TImage;

    lblTitulo: TLabel;
    lblSubtitulo: TLabel;

    pnlDiv1: TPanel;

    pnlError: TPanel;
    lblError: TLabel;

    lblUsuario: TLabel;
    pnlOuterUsuario: TPanel;
    pnlInnerUsuario: TPanel;
    edtUsuario: TEdit;

    lblContrasena: TLabel;
    pnlOuterContrasena: TPanel;
    pnlInnerContrasena: TPanel;
    edtContrasena: TEdit;

    pnlDiv2: TPanel;

    pnlIngresar: TPanel;
    lblIngresar: TLabel;

    lblSalir: TLabel;

    SQLScript1: TSQLScript;

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
  UltimaContrasena: string;

function ConfirmarContrasenaActual(const Titulo: string): Boolean;

implementation

{$R *.lfm}

procedure TfrmLogin.FormCreate(Sender: TObject);
begin
  Constraints.MinWidth := APP_MIN_WIDTH;
  Constraints.MinHeight := APP_MIN_HEIGHT;

  FillChar(FUser, SizeOf(FUser), 0);

  lblError.Caption := '';
  pnlError.Visible := False;
  pnlError.Top := 10;
  pnlError.Left := 40;

  pnlBG.Color := CLR_LOGIN_BG;

  pnlCard.Color := CLR_LOGIN_BG;
  pnlCard.ParentColor := True;
  pnlCard.ParentBackground := True;

  pnlLogoBox.Color := CLR_LOGIN_ICON_BG;

  // =========================
  // LOGO PNG
  // =========================
  imgLogo.Picture.LoadFromFile(
    ExtractFilePath(Application.ExeName) +
    'assets/logo_pesaje.png'
  );

  imgLogo.Stretch := True;
  imgLogo.Proportional := True;
  imgLogo.Center := True;

  // =========================
  // INPUTS
  // =========================
  pnlOuterUsuario.Color := CLR_BORDER;
  pnlInnerUsuario.Color := CLR_WHITE;

  edtUsuario.Color := CLR_WHITE;
  edtUsuario.Font.Color := CLR_TEXT;

  pnlOuterContrasena.Color := CLR_BORDER;
  pnlInnerContrasena.Color := CLR_WHITE;

  edtContrasena.Color := CLR_WHITE;
  edtContrasena.Font.Color := CLR_TEXT;

  // =========================
  // POSICIONES
  // =========================
  lblUsuario.Font.Height := -14;
  lblUsuario.Top := 248;

  pnlOuterUsuario.Top := 270;

  lblContrasena.Font.Height := -14;
  lblContrasena.Top := 338;

  pnlOuterContrasena.Top := 360;

  pnlDiv2.Top := 428;

  pnlIngresar.Top := 449;

  lblSalir.Top := 509;

  ActiveControl := edtUsuario;
end;

procedure TfrmLogin.FormResize(Sender: TObject);
begin
  pnlLogoBox.SetBounds(170, 70, 96, 96);

  lblTitulo.Left :=
    (pnlCard.ClientWidth - lblTitulo.Width) div 2;

  lblSubtitulo.Left :=
    (pnlCard.ClientWidth - lblSubtitulo.Width) div 2;

  pnlCard.Left :=
    (pnlBG.ClientWidth - pnlCard.Width) div 2;

  pnlCard.Top :=
    (pnlBG.ClientHeight - pnlCard.Height) div 2;
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
    Resultado := TAuthService.Login(
      Trim(edtUsuario.Text),
      Trim(edtContrasena.Text),
      FUser
    );
  finally
    Screen.Cursor := crDefault;
  end;

  case Resultado of

    arSuccess:
      begin
        UsuarioActual := FUser;
        UltimaContrasena := Trim(edtContrasena.Text);
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
        lblError.Caption :=
          'Error de conexión con la base de datos';

        pnlError.Visible := True;
      end;
  end;
end;

procedure TfrmLogin.lblSalirClick(Sender: TObject);
begin
  Application.Terminate;
end;

// ══════════════════════════════════════════════════════════════
// Diálogo de confirmación de contraseña — usado para cambiar de
// modo (solo pesaje <-> sistema completo). Valida contra el
// usuario local con TAuthService.VerificarContrasena.
// ══════════════════════════════════════════════════════════════

type
  { TfrmConfirmarContrasena }

  TfrmConfirmarContrasena = class(TForm)
    edtPass: TEdit;
    lblInfo: TLabel;
    constructor Create(AOwner: TComponent); override;
    procedure CerrarClick(Sender: TObject);
    procedure AceptarClick(Sender: TObject);
  end;

constructor TfrmConfirmarContrasena.Create(AOwner: TComponent);
var
  pnlTop: TPanel;
  lblTitulo: TLabel;
  pnlSep: TPanel;
  pnlOk: TPanel;
  pnlCancel: TPanel;
  Lbl: TLabel;
  pO, pI: TPanel;

  procedure CrearBotonSimple(ALeft: Integer; const ACaption: string;
    AColor, AFontColor: TColor; AClick: TNotifyEvent);
  begin
    pnlCancel := TPanel.Create(Self);
    pnlCancel.Parent := Self;
    pnlCancel.SetBounds(ALeft, 180, 110, 34);
    pnlCancel.BevelOuter := bvNone;
    pnlCancel.Color := AColor;
    pnlCancel.Cursor := crHandPoint;
    pnlCancel.OnClick := AClick;
    Lbl := TLabel.Create(pnlCancel);
    Lbl.Parent := pnlCancel;
    Lbl.Align := alClient;
    Lbl.Alignment := taCenter;
    Lbl.Layout := tlCenter;
    Lbl.Caption := ACaption;
    Lbl.Font.Size := 11;
    Lbl.Font.Color := AFontColor;
    Lbl.OnClick := AClick;
  end;

begin
  inherited CreateNew(AOwner);

  Caption := '';
  Width := 420;
  Height := 300;
  Position := poMainFormCenter;
  BorderStyle := bsDialog;
  Color := CLR_BG;

  pnlTop := TPanel.Create(Self);
  pnlTop.Parent := Self;
  pnlTop.Align := alTop;
  pnlTop.Height := 52;
  pnlTop.BevelOuter := bvNone;
  pnlTop.Color := CLR_CARD;

  lblTitulo := TLabel.Create(pnlTop);
  lblTitulo.Parent := pnlTop;
  lblTitulo.SetBounds(24, 14, 380, 24);
  lblTitulo.Caption := 'Confirmacion';
  lblTitulo.Font.Size := 13;
  lblTitulo.Font.Style := [fsBold];
  lblTitulo.Font.Color := CLR_TEXT_HEADING;

  pnlSep := TPanel.Create(pnlTop);
  pnlSep.Parent := pnlTop;
  pnlSep.Align := alBottom;
  pnlSep.Height := 1;
  pnlSep.BevelOuter := bvNone;
  pnlSep.Color := CLR_BORDER;

  lblInfo := TLabel.Create(Self);
  lblInfo.Parent := Self;
  lblInfo.SetBounds(24, 76, 372, 16);
  lblInfo.Caption := 'Ingrese la contrasena de ' + UsuarioActual.Email;
  lblInfo.Font.Size := 10;
  lblInfo.Font.Color := CLR_TEXT_SLATE;

  pO := TPanel.Create(Self);
  pO.Parent := Self;
  pO.SetBounds(24, 100, 372, 40);
  pO.BevelOuter := bvNone;
  pO.Color := CLR_BORDER;
  pI := TPanel.Create(pO);
  pI.Parent := pO;
  pI.SetBounds(1, 1, 370, 38);
  pI.BevelOuter := bvNone;
  pI.Color := CLR_WHITE;
  pI.BorderWidth := 6;
  edtPass := TEdit.Create(pI);
  edtPass.Parent := pI;
  edtPass.Align := alClient;
  edtPass.BorderStyle := bsNone;
  edtPass.Font.Size := 12;
  edtPass.Font.Color := CLR_TEXT;
  edtPass.Color := CLR_WHITE;
  edtPass.PasswordChar := '*';

  CrearBotonSimple(156, 'CANCELAR', CLR_CARD, CLR_PRIMARY, @CerrarClick);
  CrearBotonSimple(278, 'ACEPTAR', CLR_PRIMARY, CLR_WHITE, @AceptarClick);
end;

procedure TfrmConfirmarContrasena.CerrarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmConfirmarContrasena.AceptarClick(Sender: TObject);
begin
  if Trim(edtPass.Text) = '' then
  begin
    edtPass.SetFocus;
    Exit;
  end;
  if TAuthService.VerificarContrasena(UsuarioActual.Email, Trim(edtPass.Text)) then
    ModalResult := mrOK
  else
  begin
    lblInfo.Caption := 'Contrasena incorrecta';
    lblInfo.Font.Color := CLR_DESTRUCTIVE;
    edtPass.Text := '';
    edtPass.SetFocus;
  end;
end;

function ConfirmarContrasenaActual(const Titulo: string): Boolean;
var
  F: TfrmConfirmarContrasena;
begin
  Result := False;
  F := TfrmConfirmarContrasena.Create(nil);
  try
    F.Caption := Titulo;
    F.lblInfo.Caption := 'Ingrese la contrasena de ' + UsuarioActual.Email;
    Result := F.ShowModal = mrOK;
  finally
    F.Free;
  end;
end;

end.