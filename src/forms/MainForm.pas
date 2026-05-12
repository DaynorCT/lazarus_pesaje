unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, AuthService, DataModule, LoginForm,
  PesajeFrame, DashboardFrame, VehiculosFrame, ChoferesFrame,
  ProveedoresFrame, UsuariosFrame, AbmSimpleFrame, Theme;

type
  TFrameClass = class of TFrame;

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    pnlContent: TPanel;
    lblLogo: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FActiveFrame: TFrame;
    FNavBtns: array of TSpeedButton;
    FLblUser, FBtnLogout: TLabel;
    procedure BuildNav;
    function CrearNavBtn(const ACaption: string; ATag: Integer; X: Integer): TSpeedButton;
    procedure NavBtnClick(Sender: TObject);
    procedure ResetNavButtons;
    procedure SetActiveNav(ABtn: TSpeedButton);
    procedure LoadFrame(FrameClass: TFrameClass; const Title: string);
    procedure LoadFrameInstance(NewFrame: TFrame; const Title: string);
    procedure LogoutClick(Sender: TObject);
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FActiveFrame := nil;
  Caption := 'Sistema de Pesaje';

  pnlTop.Height := 48;
  pnlTop.Color := CLR_CARD;

  pnlContent.Color := CLR_BG;

  lblLogo.Caption := 'SISTEMA DE PESAJE';
  lblLogo.Font.Color := CLR_TEXT_HEADING;
  lblLogo.Font.Style := [fsBold];
  lblLogo.Font.Size := 11;

  BuildNav;

  FLblUser := TLabel.Create(Self);
  FLblUser.Parent := pnlTop;
  FLblUser.Align := alRight;
  FLblUser.Alignment := taRightJustify;
  FLblUser.Font.Color := CLR_TEXT_SLATE;
  FLblUser.Font.Size := 11;
  FLblUser.BorderSpacing.Right := 12;
  FLblUser.BorderSpacing.Top := 16;

  FBtnLogout := TLabel.Create(Self);
  FBtnLogout.Parent := pnlTop;
  FBtnLogout.Align := alRight;
  FBtnLogout.Caption := 'Cerrar Sesion';
  FBtnLogout.Font.Color := CLR_TEXT_MUTED;
  FBtnLogout.Font.Size := 11;
  FBtnLogout.Cursor := crHandPoint;
  FBtnLogout.BorderSpacing.Right := 8;
  FBtnLogout.BorderSpacing.Top := 16;
  FBtnLogout.OnClick := @LogoutClick;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  FLblUser.Caption := UsuarioActual.PersonaNombre + ' | ' + UsuarioActual.Rol;
  LoadFrame(TFrameDashboard, 'Dashboard');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if FActiveFrame <> nil then
    FreeAndNil(FActiveFrame);
end;

procedure TfrmMain.LogoutClick(Sender: TObject);
begin
  if MessageDlg('Cerrar sesion', 'Seguro que desea cerrar sesion?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    ModalResult := mrCancel;
    Close;
  end;
end;

procedure TfrmMain.BuildNav;
var
  I, XPos: Integer;
  Items: array[0..9] of record Emoji, Title: string; Tag: Integer; end;
begin
  Items[0].Emoji := '📊'; Items[0].Title := 'Dashboard'; Items[0].Tag := 0;
  Items[1].Emoji := '👥'; Items[1].Title := 'Usuarios';   Items[1].Tag := 10;
  Items[2].Emoji := '👤'; Items[2].Title := 'Choferes';    Items[2].Tag := 3;
  Items[3].Emoji := '🏭'; Items[3].Title := 'Proveedores';  Items[3].Tag := 4;
  Items[4].Emoji := '⚖️';  Items[4].Title := 'Pesaje';      Items[4].Tag := 1;
  Items[5].Emoji := '🚛'; Items[5].Title := 'Vehiculos';   Items[5].Tag := 6;
  Items[6].Emoji := '📦'; Items[6].Title := 'Productos';   Items[6].Tag := 5;
  Items[7].Emoji := '📍'; Items[7].Title := 'Origenes';    Items[7].Tag := 7;
  Items[8].Emoji := '🎯'; Items[8].Title := 'Destinos';    Items[8].Tag := 8;
  Items[9].Emoji := '⚙️';  Items[9].Title := 'Config';      Items[9].Tag := 12;

  SetLength(FNavBtns, 10);
  XPos := 230;

  for I := 0 to 9 do
  begin
    FNavBtns[I] := CrearNavBtn(Items[I].Emoji + ' ' + Items[I].Title, Items[I].Tag, XPos);
    XPos := XPos + FNavBtns[I].Width + 4;
  end;
end;

function TfrmMain.CrearNavBtn(const ACaption: string; ATag: Integer; X: Integer): TSpeedButton;
begin
  Result := TSpeedButton.Create(pnlTop);
  Result.Parent := pnlTop;
  Result.Caption := ACaption;
  Result.Tag := ATag;
  Result.Left := X;
  Result.Top := 8;
  Result.Height := 32;
  Result.Width := Result.Canvas.TextWidth(Caption) + 20;
  Result.Flat := True;
  Result.Font.Size := 12;
  Result.Font.Color := CLR_TEXT_SLATE;
  Result.Font.Style := [];
  Result.OnClick := @NavBtnClick;
end;

procedure TfrmMain.NavBtnClick(Sender: TObject);
var
  FrameP, FrameD: TFrameAbmSimple;
begin
  ResetNavButtons;
  SetActiveNav(TSpeedButton(Sender));

  case TSpeedButton(Sender).Tag of
    0: LoadFrame(TFrameDashboard, 'Dashboard');
    1: LoadFrame(TFramePesaje, 'Pesaje');
    3: LoadFrame(TFrameChoferes, 'Choferes');
    4: LoadFrame(TFrameProveedores, 'Proveedores');
    5: begin
      FrameP := TFrameAbmSimple.CreateWithConfig(Self, ConfigProductos);
      LoadFrameInstance(FrameP, 'Productos');
    end;
    6: LoadFrame(TFrameVehiculos, 'Vehiculos');
    7: begin
      FrameP := TFrameAbmSimple.CreateWithConfig(Self, ConfigOrigenes);
      LoadFrameInstance(FrameP, 'Origenes');
    end;
    8: begin
      FrameD := TFrameAbmSimple.CreateWithConfig(Self, ConfigDestinos);
      LoadFrameInstance(FrameD, 'Destinos');
    end;
    10: LoadFrame(TFrameUsuarios, 'Usuarios');
    else ShowMessage('Modulo en desarrollo - Fase 3');
  end;
end;

procedure TfrmMain.ResetNavButtons;
var
  I: Integer;
begin
  for I := 0 to High(FNavBtns) do
  begin
    FNavBtns[I].Font.Color := CLR_TEXT_SLATE;
    FNavBtns[I].Font.Style := [];
  end;
end;

procedure TfrmMain.SetActiveNav(ABtn: TSpeedButton);
begin
  ABtn.Font.Color := CLR_PRIMARY;
  ABtn.Font.Style := [fsBold];
end;

procedure TfrmMain.LoadFrame(FrameClass: TFrameClass; const Title: string);
begin
  if (FActiveFrame <> nil) and (FActiveFrame.ClassType = FrameClass) then
    Exit;
  LoadFrameInstance(FrameClass.Create(Self), Title);
end;

procedure TfrmMain.LoadFrameInstance(NewFrame: TFrame; const Title: string);
begin
  if FActiveFrame <> nil then
    FreeAndNil(FActiveFrame);

  NewFrame.Parent := pnlContent;
  NewFrame.Align := alClient;
  NewFrame.Visible := True;
  FActiveFrame := NewFrame;
  Caption := 'Sistema de Pesaje - ' + Title;
end;

end.
