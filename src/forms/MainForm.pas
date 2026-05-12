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
    procedure ContentClick(Sender: TObject);
  private
    FActiveFrame: TFrame;
    FNavBtns: array of TSpeedButton;
    FSubCatalogo, FSubConfig: TPanel;
    FLblUser, FBtnLogout: TLabel;

    function CrearNavBtn(const ACaption: string; ATag: Integer; X: Integer): TSpeedButton;
    procedure NavBtnClick(Sender: TObject);
    procedure SubItemClick(Sender: TObject);
    procedure ResetNavButtons;
    procedure SetActiveNav(ABtn: TSpeedButton);
    procedure CerrarSubmenus;
    procedure ToggleSubmenu(ParentBtn: TSpeedButton; SubPanel: TPanel);
    procedure NavigateTo(TagVal: Integer);
    procedure CrearSubItem(AParent: TPanel; const ACaption: string; ATag, Y: Integer);
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
var
  I, XPos: Integer;
  Items: array[0..8] of record Emoji, Title: string; Tag: Integer; HasSub: Boolean; end;
  Btn: TSpeedButton;
begin
  FActiveFrame := nil;
  Caption := 'Sistema de Pesaje';

  pnlTop.Height := 48;
  pnlTop.Color := CLR_CARD;

  pnlContent.Color := CLR_BG;
  pnlContent.OnClick := @ContentClick;

  lblLogo.Caption := 'SISTEMA DE PESAJE';
  lblLogo.Font.Color := CLR_TEXT_HEADING;
  lblLogo.Font.Style := [fsBold];
  lblLogo.Font.Size := 11;

  // Orden exacto del sistema web
  Items[0].Emoji := '📊'; Items[0].Title := 'Dashboard';   Items[0].Tag := 0;
  Items[1].Emoji := '👥'; Items[1].Title := 'Usuarios';     Items[1].Tag := 10;
  Items[2].Emoji := '🏢'; Items[2].Title := 'Empresas';     Items[2].Tag := 2;
  Items[3].Emoji := '👤'; Items[3].Title := 'Choferes';     Items[3].Tag := 3;
  Items[4].Emoji := '🏭'; Items[4].Title := 'Proveedores';   Items[4].Tag := 4;
  Items[5].Emoji := '⚖️';   Items[5].Title := 'Pesaje';      Items[5].Tag := 1;
  Items[6].Emoji := '📦'; Items[6].Title := 'Catalogo ▼';   Items[6].Tag := 100; Items[6].HasSub := True;
  Items[7].Emoji := '📄'; Items[7].Title := 'Reportes';     Items[7].Tag := 11;
  Items[8].Emoji := '⚙️';   Items[8].Title := 'Config ▼';    Items[8].Tag := 200; Items[8].HasSub := True;

  SetLength(FNavBtns, 9);
  XPos := 230;

  for I := 0 to 8 do
  begin
    Btn := CrearNavBtn(Items[I].Emoji + ' ' + Items[I].Title, Items[I].Tag, XPos);
    FNavBtns[I] := Btn;
    XPos := XPos + Btn.Width + 4;
  end;

  // Submenu Catálogo
  FSubCatalogo := TPanel.Create(Self);
  FSubCatalogo.Parent := Self;
  FSubCatalogo.Visible := False;
  FSubCatalogo.Color := CLR_CARD;
  FSubCatalogo.BevelOuter := bvNone;
  FSubCatalogo.BorderStyle := bsSingle;
  FSubCatalogo.Width := 180;
  FSubCatalogo.Height := 152;

  CrearSubItem(FSubCatalogo, '🚛 Vehiculos', 6, 0);
  CrearSubItem(FSubCatalogo, '📦 Productos', 5, 36);
  CrearSubItem(FSubCatalogo, '📍 Origenes', 7, 72);
  CrearSubItem(FSubCatalogo, '🎯 Destinos', 8, 108);

  // Submenu Configuración
  FSubConfig := TPanel.Create(Self);
  FSubConfig.Parent := Self;
  FSubConfig.Visible := False;
  FSubConfig.Color := CLR_CARD;
  FSubConfig.BevelOuter := bvNone;
  FSubConfig.BorderStyle := bsSingle;
  FSubConfig.Width := 180;
  FSubConfig.Height := 40;

  CrearSubItem(FSubConfig, '📋 Boleta', 12, 0);

  // User + logout
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

procedure TfrmMain.ContentClick(Sender: TObject);
begin
  CerrarSubmenus;
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

function TfrmMain.CrearNavBtn(const ACaption: string; ATag: Integer; X: Integer): TSpeedButton;
begin
  Result := TSpeedButton.Create(pnlTop);
  Result.Parent := pnlTop;
  Result.Caption := ACaption;
  Result.Tag := ATag;
  Result.Left := X;
  Result.Top := 7;
  Result.Height := 34;
  Result.Width := Result.Canvas.TextWidth(ACaption) + 18;
  Result.Flat := True;
  Result.Font.Size := 12;
  Result.Font.Color := CLR_TEXT_SLATE;
  Result.Font.Style := [];
  Result.OnClick := @NavBtnClick;
end;

procedure TfrmMain.CrearSubItem(AParent: TPanel; const ACaption: string; ATag, Y: Integer);
var
  Btn: TSpeedButton;
begin
  Btn := TSpeedButton.Create(AParent);
  Btn.Parent := AParent;
  Btn.Caption := '  ' + ACaption;
  Btn.Tag := ATag;
  Btn.SetBounds(0, Y, 180, 36);
  Btn.Flat := True;
  Btn.Font.Size := 12;
  Btn.Font.Color := CLR_TEXT_SLATE;
  Btn.Font.Style := [];
  Btn.Alignment := taLeftJustify;
  Btn.OnClick := @SubItemClick;
end;

procedure TfrmMain.NavBtnClick(Sender: TObject);
var
  Btn: TSpeedButton;
  TagVal: Integer;
begin
  Btn := TSpeedButton(Sender);
  TagVal := Btn.Tag;

  // Submenus
  if TagVal = 100 then
  begin
    CerrarSubmenus;
    ToggleSubmenu(Btn, FSubCatalogo);
    Exit;
  end;
  if TagVal = 200 then
  begin
    CerrarSubmenus;
    ToggleSubmenu(Btn, FSubConfig);
    Exit;
  end;

  CerrarSubmenus;
  ResetNavButtons;
  SetActiveNav(Btn);

  NavigateTo(TagVal);
end;

procedure TfrmMain.SubItemClick(Sender: TObject);
var
  Btn: TSpeedButton;
begin
  Btn := TSpeedButton(Sender);
  CerrarSubmenus;
  ResetNavButtons;
  // Marcar el padre como activo
  NavigateTo(Btn.Tag);
end;

procedure TfrmMain.NavigateTo(TagVal: Integer);
var
  FrameP, FrameD: TFrameAbmSimple;
begin
  case TagVal of
    0: LoadFrame(TFrameDashboard, 'Dashboard');
    1: LoadFrame(TFramePesaje, 'Pesaje');
    2: ShowMessage('Empresas - Fase 3');
    3: LoadFrame(TFrameChoferes, 'Choferes');
    4: LoadFrame(TFrameProveedores, 'Proveedores');
    5: begin FrameP := TFrameAbmSimple.CreateWithConfig(Self, ConfigProductos); LoadFrameInstance(FrameP, 'Productos'); end;
    6: LoadFrame(TFrameVehiculos, 'Vehiculos');
    7: begin FrameP := TFrameAbmSimple.CreateWithConfig(Self, ConfigOrigenes); LoadFrameInstance(FrameP, 'Origenes'); end;
    8: begin FrameD := TFrameAbmSimple.CreateWithConfig(Self, ConfigDestinos); LoadFrameInstance(FrameD, 'Destinos'); end;
    10: LoadFrame(TFrameUsuarios, 'Usuarios');
    11: ShowMessage('Reportes - Fase 3');
    12: ShowMessage('Configuracion Boleta - Fase 3');
    else ShowMessage('Modulo en desarrollo - Fase 3');
  end;
end;

procedure TfrmMain.ToggleSubmenu(ParentBtn: TSpeedButton; SubPanel: TPanel);
begin
  SubPanel.Left := ParentBtn.Left;
  SubPanel.Top := pnlTop.Height + 2;
  SubPanel.Visible := not SubPanel.Visible;
end;

procedure TfrmMain.CerrarSubmenus;
begin
  FSubCatalogo.Visible := False;
  FSubConfig.Visible := False;
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
