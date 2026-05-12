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
    FSubCatalogo, FSubConfig, FUserMenu: TPanel;
    FUserBtn: TSpeedButton;

    function CrearNavBtn(const ACaption: string; ATag: Integer; X: Integer): TSpeedButton;
    procedure NavBtnClick(Sender: TObject);
    procedure SubItemClick(Sender: TObject);
    procedure UserBtnClick(Sender: TObject);
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

  pnlTop.Height := 56;
  pnlTop.Color := CLR_CARD;

  pnlContent.Color := CLR_BG;
  pnlContent.OnClick := @ContentClick;

  lblLogo.Caption := 'SISTEMA DE PESAJE';
  lblLogo.Font.Color := CLR_PRIMARY;
  lblLogo.Font.Style := [fsBold];
  lblLogo.Font.Size := 14;

  // Orden exacto del sistema web
  Items[0].Emoji := '📊'; Items[0].Title := 'Inicio';       Items[0].Tag := 0;
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
    XPos := XPos + Btn.Width + 14;
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

  // Botón usuario (derecha)
  FUserBtn := TSpeedButton.Create(pnlTop);
  FUserBtn.Parent := pnlTop;
  FUserBtn.Align := alRight;
  FUserBtn.Width := 36; FUserBtn.Height := 36;
  FUserBtn.Top := 10;
  FUserBtn.Caption := '👤';
  FUserBtn.Flat := True;
  FUserBtn.Font.Size := 18;
  FUserBtn.BorderSpacing.Right := 12;
  FUserBtn.BorderSpacing.Top := 0;
  FUserBtn.OnClick := @UserBtnClick;

  // Menú desplegable usuario
  FUserMenu := TPanel.Create(Self);
  FUserMenu.Parent := Self;
  FUserMenu.Visible := False;
  FUserMenu.Color := CLR_CARD;
  FUserMenu.BevelOuter := bvNone;
  FUserMenu.BorderStyle := bsSingle;
  FUserMenu.Width := 200;
  FUserMenu.Height := 130;
end;

procedure TfrmMain.UserBtnClick(Sender: TObject);
var
  Lbl: TLabel;
  YPos: Integer;
begin
  // Cerrar otros submenús
  CerrarSubmenus;

  if FUserMenu.Visible then
  begin
    FUserMenu.Visible := False;
    Exit;
  end;

  // Limpiar y reconstruir menú de usuario
  FUserMenu.DestroyComponents;
  FUserMenu.Left := FUserBtn.Left + FUserBtn.Width - FUserMenu.Width;
  FUserMenu.Top := pnlTop.Height + 2;
  YPos := 8;

  Lbl := TLabel.Create(FUserMenu); Lbl.Parent := FUserMenu;
  Lbl.SetBounds(12, YPos, 176, 16);
  Lbl.Caption := UsuarioActual.PersonaNombre;
  Lbl.Font.Size := 12; Lbl.Font.Style := [fsBold]; Lbl.Font.Color := CLR_TEXT_HEADING;
  YPos := YPos + 22;

  Lbl := TLabel.Create(FUserMenu); Lbl.Parent := FUserMenu;
  Lbl.SetBounds(12, YPos, 176, 14);
  Lbl.Caption := UsuarioActual.Email;
  Lbl.Font.Size := 10; Lbl.Font.Color := CLR_TEXT_SLATE;
  YPos := YPos + 24;

  // Separador
  with TPanel.Create(FUserMenu) do begin
    Parent := FUserMenu; SetBounds(8, YPos, 184, 1); Color := CLR_BORDER; BevelOuter := bvNone;
  end;
  YPos := YPos + 8;

  Lbl := TLabel.Create(FUserMenu); Lbl.Parent := FUserMenu;
  Lbl.SetBounds(12, YPos, 176, 14);
  Lbl.Caption := 'Rol: ' + UsuarioActual.Rol;
  Lbl.Font.Size := 10; Lbl.Font.Color := CLR_TEXT_SLATE;
  YPos := YPos + 22;

  // Separador
  with TPanel.Create(FUserMenu) do begin
    Parent := FUserMenu; SetBounds(8, YPos, 184, 1); Color := CLR_BORDER; BevelOuter := bvNone;
  end;
  YPos := YPos + 8;

  Lbl := TLabel.Create(FUserMenu); Lbl.Parent := FUserMenu;
  Lbl.SetBounds(12, YPos, 176, 16);
  Lbl.Caption := 'Cerrar Sesion';
  Lbl.Font.Size := 12; Lbl.Font.Color := CLR_DESTRUCTIVE;
  Lbl.Cursor := crHandPoint;
  Lbl.OnClick := @LogoutClick;

  FUserMenu.Visible := True;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  LoadFrame(TFrameDashboard, 'Inicio');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if FActiveFrame <> nil then
    FreeAndNil(FActiveFrame);
end;

procedure TfrmMain.ContentClick(Sender: TObject);
begin
  CerrarSubmenus;
  FUserMenu.Visible := False;
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
  Result.Top := 10;
  Result.Height := 36;
  Result.Width := Result.Canvas.TextWidth(ACaption) + 28;
  Result.Flat := True;
  Result.Font.Size := 13;
    Result.Font.Color := CLR_TEXT;
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
  Btn.Font.Color := CLR_TEXT;
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
    FNavBtns[I].Font.Color := CLR_TEXT;
    FNavBtns[I].Font.Style := [];
  end;
end;

procedure TfrmMain.SetActiveNav(ABtn: TSpeedButton);
begin
  ABtn.Font.Color := CLR_TEXT;
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
