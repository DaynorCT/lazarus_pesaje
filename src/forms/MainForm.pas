unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, AuthService, DataModule, LoginForm, LMessages,
  PesajeFrame, DashboardFrame, VehiculosFrame, ChoferesFrame,
  ProveedoresFrame, UsuariosFrame, EmpresasFrame, ProductosFrame,
  OrigenesFrame, DestinosFrame, AbmSimpleFrame, ReportesFrame,
  BoletaConfigFrame, Theme, base64, SQLDB, ConfigBalanzaFrame, AppDialog;

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
  protected
    procedure WMCloseQuery(var Message: TLMessage); message LM_CLOSEQUERY;
  private
    FActiveFrame: TFrame;
    FNavItems: array of TPanel;
    FActiveNav: TPanel;
    FActiveSub: TPanel;
    FSubCatalogo, FSubConfig, FUserMenu: TPanel;
    FUserBtn: TPanel;
    imgLogo: TImage;
    pnlLogoFallback: TPanel;
    lblLogoFallback: TLabel;

    procedure LogoClick(Sender: TObject);
    procedure NavPaint(Sender: TObject);
    procedure SubMenuPaint(Sender: TObject);
    procedure SubPaint(Sender: TObject);
    function CrearNavItem(AIconCode: Word; const ATitle: string; ATag: Integer; X: Integer): TPanel;
    procedure NavClick(Sender: TObject);
    procedure NavMouseEnter(Sender: TObject);
    procedure NavMouseLeave(Sender: TObject);
    procedure SubItemClick(Sender: TObject);
    procedure SubMouseEnter(Sender: TObject);
    procedure SubMouseLeave(Sender: TObject);
    procedure UserBtnClick(Sender: TObject);
    procedure CrearSubItem(AParent: TPanel; AIconCode: Word; const ACaption: string; ATag, Y: Integer);
    procedure ResetNavItems(KeepActive: TPanel);
    procedure CerrarSubmenus;
    procedure ToggleSubmenu(Btn: TSpeedButton; SubPanel: TPanel);
    procedure NavigateTo(TagVal: Integer);
    procedure LoadFrame(FrameClass: TFrameClass; const Title: string);
    procedure LoadFrameInstance(NewFrame: TFrame; const Title: string);
    procedure LogoutClick(Sender: TObject);
    procedure VolverPesajeClick(Sender: TObject);
  public
    procedure CargarLogo;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
var
  I, XPos: Integer;
  Items: array[0..8] of record IconCode: Word; Title: string; Tag: Integer; HasSub: Boolean; end;
  Pnl: TPanel;
begin
  FActiveFrame := nil;
  FActiveNav := nil;
  FActiveSub := nil;
  Caption := 'Sistema de Pesaje';

  pnlTop.Height := FRAME_HEADER_H;
  Constraints.MinWidth := APP_MIN_WIDTH;
  Constraints.MinHeight := APP_MIN_HEIGHT;
  pnlTop.Color := CLR_CARD;

  // Borde inferior
  with TPanel.Create(pnlTop) do
  begin
    Parent := pnlTop;
    Align := alBottom;
    Height := 1;
    BevelOuter := bvNone;
    Color := CLR_TOPBAR_BORDER;
  end;

  lblLogo.Visible := False;

  pnlContent.Color := CLR_BG;
  pnlContent.OnClick := @ContentClick;

  CargarLogo;

  // Orden del sistema web
  Items[0].IconCode := FA_HOME;      Items[0].Title := 'Inicio';      Items[0].Tag := 0;   Items[0].HasSub := False;
  Items[1].IconCode := FA_USERS;     Items[1].Title := 'Usuarios';    Items[1].Tag := 10;  Items[1].HasSub := False;
  Items[2].IconCode := FA_BUILDING;  Items[2].Title := 'Empresas';    Items[2].Tag := 2;   Items[2].HasSub := False;
  Items[3].IconCode := FA_USER;      Items[3].Title := 'Choferes';    Items[3].Tag := 3;   Items[3].HasSub := False;
  Items[4].IconCode := FA_INDUSTRY;  Items[4].Title := 'Proveedores'; Items[4].Tag := 4;   Items[4].HasSub := False;
  Items[5].IconCode := FA_SCALE;     Items[5].Title := 'Pesaje';      Items[5].Tag := 1;   Items[5].HasSub := False;
  Items[6].IconCode := FA_LIST;      Items[6].Title := 'Catalogo ▼';  Items[6].Tag := 100; Items[6].HasSub := True;
  Items[7].IconCode := FA_CHART_BAR; Items[7].Title := 'Reportes';    Items[7].Tag := 11;  Items[7].HasSub := False;
  Items[8].IconCode := FA_COG;       Items[8].Title := 'Config ▼';    Items[8].Tag := 200; Items[8].HasSub := True;

  SetLength(FNavItems, 9);
  XPos := 100;

  for I := 0 to 8 do
  begin
    Pnl := CrearNavItem(Items[I].IconCode, Items[I].Title, Items[I].Tag, XPos);
    FNavItems[I] := Pnl;
    XPos := XPos + Pnl.Width + 12;
  end;

  // Submenu Catálogo
  FSubCatalogo := TPanel.Create(Self);
  FSubCatalogo.Parent := Self;
  FSubCatalogo.Visible := False;
  FSubCatalogo.Color := CLR_CARD;
  FSubCatalogo.BevelOuter := bvNone;
  FSubCatalogo.BorderStyle := bsNone;
  FSubCatalogo.ParentBackground := False;
  FSubCatalogo.ParentColor := False;
  FSubCatalogo.OnPaint := @SubMenuPaint;
  FSubCatalogo.Width := 220;
  FSubCatalogo.Height := 186;

  CrearSubItem(FSubCatalogo, FA_TRUCK,    'Vehiculos', 6, 8);
  CrearSubItem(FSubCatalogo, FA_BOX,      'Productos', 5, 52);
  CrearSubItem(FSubCatalogo, FA_MAP_PIN,  'Origenes',  7, 96);
  CrearSubItem(FSubCatalogo, FA_BULLSEYE, 'Destinos',  8, 140);

  // Submenu Configuración
  FSubConfig := TPanel.Create(Self);
  FSubConfig.Parent := Self;
  FSubConfig.Visible := False;
  FSubConfig.Color := CLR_CARD;
  FSubConfig.BevelOuter := bvNone;
  FSubConfig.BorderStyle := bsNone;
  FSubConfig.ParentBackground := False;
  FSubConfig.ParentColor := False;
  FSubConfig.OnPaint := @SubMenuPaint;
  FSubConfig.Width := 220;
  FSubConfig.Height := 98;

  CrearSubItem(FSubConfig, FA_FILE,  'Boleta',  12, 8);
  CrearSubItem(FSubConfig, FA_SCALE, 'Balanza', 13, 52);

  // Botón usuario (mismo estilo que el engranaje del módulo pesaje)
  FUserBtn := TPanel.Create(pnlTop);
  FUserBtn.Parent := pnlTop;
  FUserBtn.Align := alRight;
  FUserBtn.Width := 40;
  FUserBtn.Height := 40;
  FUserBtn.Top := (FRAME_HEADER_H - 40) div 2;
  FUserBtn.BevelOuter := bvNone;
  FUserBtn.Color := CLR_CARD;
  FUserBtn.ParentBackground := False;
  FUserBtn.ParentColor := False;
  FUserBtn.Cursor := crHandPoint;
  FUserBtn.OnPaint := @NavPaint;
  FUserBtn.OnClick := @UserBtnClick;
  FUserBtn.BorderSpacing.Right := 12;

  with TLabel.Create(FUserBtn) do
  begin
    Parent := FUserBtn;
    Align := alClient;
    Alignment := taCenter;
    Layout := tlCenter;
    Caption := FAIconoStr(FA_USER, '👤');
    Font.Size := 16;
    Font.Name := FA_FONT_NAME;
    Font.Color := CLR_PRIMARY;
    Transparent := True;
    Cursor := crHandPoint;
    OnClick := @UserBtnClick;
  end;

  // Menú usuario
  FUserMenu := TPanel.Create(Self);
  FUserMenu.Parent := Self;
  FUserMenu.Visible := False;
  FUserMenu.Color := CLR_CARD;
  FUserMenu.BevelOuter := bvNone;
  FUserMenu.BorderStyle := bsNone;
  FUserMenu.ParentBackground := False;
  FUserMenu.ParentColor := False;
  FUserMenu.OnPaint := @SubMenuPaint;
  FUserMenu.Width := 240;
  FUserMenu.Height := 164;
end;

function TfrmMain.CrearNavItem(AIconCode: Word; const ATitle: string; ATag: Integer; X: Integer): TPanel;
var
  IconLbl, TitleLbl: TLabel;
  W, IconW, TitleW: Integer;
  IconStr: string;
  TmpCanvas: TCanvas;
begin
  Result := TPanel.Create(pnlTop);
  Result.Parent := pnlTop;
  Result.Tag := ATag;

  IconStr := FAChar(AIconCode);
  if IconStr <> '' then
    IconW := 28
  else
    IconW := 0;

  // FIX: medir el texto con la fuente correcta (Size=12) antes de fijar el ancho
  TmpCanvas := Result.Canvas;
  TmpCanvas.Font.Size := 12;
  TmpCanvas.Font.Style := [];
  TitleW := TmpCanvas.TextWidth(ATitle);

  W := TitleW + 24 + IconW;
  Result.SetBounds(X, (FRAME_HEADER_H - 40) div 2, W, 40);
  Result.BevelOuter := bvNone;
  Result.Color := CLR_CARD;
  Result.Cursor := crHandPoint;
  Result.OnPaint := @NavPaint;
  Result.OnClick := @NavClick;
  Result.OnMouseEnter := @NavMouseEnter;
  Result.OnMouseLeave := @NavMouseLeave;

  if IconStr <> '' then
  begin
    IconLbl := TLabel.Create(Result);
    IconLbl.Parent := Result;
    IconLbl.SetBounds(6, 0, IconW, 40);
    IconLbl.Alignment := taCenter;
    IconLbl.Layout := tlCenter;
    IconLbl.Caption := IconStr;
    IconLbl.Font.Size := 12;
    IconLbl.Font.Name := FA_FONT_NAME;
    IconLbl.Font.Color := CLR_PRIMARY;
    IconLbl.ControlStyle := IconLbl.ControlStyle + [csNoStdEvents];
    IconLbl.OnClick := @NavClick;
  end;

  TitleLbl := TLabel.Create(Result);
  TitleLbl.Parent := Result;
  TitleLbl.SetBounds(6 + IconW, 0, TitleW + 6, 40);
  TitleLbl.Alignment := taLeftJustify;
  TitleLbl.Layout := tlCenter;
  TitleLbl.Caption := ATitle;
  TitleLbl.Font.Size := 12;
  TitleLbl.Font.Color := CLR_TEXT;
  TitleLbl.Font.Style := [];
  TitleLbl.ControlStyle := TitleLbl.ControlStyle + [csNoStdEvents];
  TitleLbl.OnClick := @NavClick;
end;

procedure TfrmMain.NavClick(Sender: TObject);
var
  Pnl: TPanel;
  TagVal: Integer;
begin
  if Sender is TPanel then
    Pnl := TPanel(Sender)
  else if Sender is TLabel then
    Pnl := TPanel(TLabel(Sender).Parent)
  else
    Exit;

  TagVal := Pnl.Tag;

  if TagVal = 100 then
  begin
    CerrarSubmenus;
    FSubCatalogo.Left := Pnl.Left;
    FSubCatalogo.Top := pnlTop.Height + 2;
    FSubCatalogo.Visible := not FSubCatalogo.Visible;
    FSubCatalogo.BringToFront;
    FSubCatalogo.Invalidate;
    Exit;
  end;
  if TagVal = 200 then
  begin
    CerrarSubmenus;
    FSubConfig.Left := Pnl.Left;
    FSubConfig.Top := pnlTop.Height + 2;
    FSubConfig.Visible := not FSubConfig.Visible;
    FSubConfig.BringToFront;
    FSubConfig.Invalidate;
    Exit;
  end;

  CerrarSubmenus;
  ResetNavItems(Pnl);
  FActiveNav := Pnl;

  if FActiveSub <> nil then
  begin
    FActiveSub.Color := CLR_CARD;
    FActiveSub := nil;
  end;

  NavigateTo(TagVal);
end;

procedure TfrmMain.SubItemClick(Sender: TObject);
var
  Pnl: TPanel;
  parentTag: Integer;
  I: Integer;
begin
  if Sender is TPanel then
    Pnl := TPanel(Sender)
  else if Sender is TLabel then
    Pnl := TPanel(TLabel(Sender).Parent)
  else
    Exit;

  if (FActiveSub <> nil) and (FActiveSub <> Pnl) then
    FActiveSub.Color := CLR_CARD;

  FActiveSub := Pnl;
  Pnl.Color := CLR_SIDEBAR_ACTIVE;

  if Pnl.Parent = FSubCatalogo then
    parentTag := 100
  else
    parentTag := 200;

  for I := 0 to High(FNavItems) do
  begin
    if FNavItems[I].Tag = parentTag then
    begin
      ResetNavItems(FNavItems[I]);
      FActiveNav := FNavItems[I];
      Break;
    end;
  end;

  CerrarSubmenus;
  NavigateTo(Pnl.Tag);
end;

procedure TfrmMain.SubMouseEnter(Sender: TObject);
var
  Pnl: TPanel;
begin
  if Sender is TPanel then
    Pnl := TPanel(Sender)
  else if Sender is TLabel then
    Pnl := TPanel(TLabel(Sender).Parent)
  else
    Exit;
  if Pnl <> FActiveSub then
    Pnl.Color := CLR_SIDEBAR_ACTIVE;
end;

procedure TfrmMain.SubMouseLeave(Sender: TObject);
var
  Pnl: TPanel;
begin
  if Sender is TPanel then
    Pnl := TPanel(Sender)
  else if Sender is TLabel then
    Pnl := TPanel(TLabel(Sender).Parent)
  else
    Exit;
  if Pnl <> FActiveSub then
    Pnl.Color := CLR_CARD;
end;

procedure TfrmMain.NavMouseEnter(Sender: TObject);
var
  Pnl: TPanel;
begin
  if Sender is TPanel then
    Pnl := TPanel(Sender)
  else
    Exit;
  if Pnl <> FActiveNav then
    Pnl.Color := CLR_SIDEBAR_ACTIVE;
end;

procedure TfrmMain.NavMouseLeave(Sender: TObject);
var
  Pnl: TPanel;
begin
  if Sender is TPanel then
    Pnl := TPanel(Sender)
  else
    Exit;
  if Pnl <> FActiveNav then
    Pnl.Color := CLR_CARD;
end;

procedure TfrmMain.NavPaint(Sender: TObject);
var
  Pnl: TPanel;
begin
  Pnl := TPanel(Sender);
  Pnl.Canvas.Brush.Color := CLR_CARD;
  Pnl.Canvas.FillRect(0, 0, Pnl.Width, Pnl.Height);
  Pnl.Canvas.Brush.Color := Pnl.Color;
  Pnl.Canvas.Pen.Style := psClear;
  Pnl.Canvas.RoundRect(0, 0, Pnl.Width, Pnl.Height, 8, 8);
end;

procedure TfrmMain.CrearSubItem(AParent: TPanel; AIconCode: Word; const ACaption: string; ATag, Y: Integer);
var
  Pnl: TPanel;
  IconLbl, TitleLbl: TLabel;
  IconStr: string;
  TitleX: Integer;
begin
  Pnl := TPanel.Create(AParent);
  Pnl.Parent := AParent;
  Pnl.Tag := ATag;
  Pnl.SetBounds(8, Y, AParent.Width - 16, 38);
  Pnl.BevelOuter := bvNone;
  Pnl.Color := CLR_CARD;
  Pnl.Cursor := crHandPoint;
  Pnl.OnPaint := @SubPaint;
  Pnl.OnClick := @SubItemClick;
  Pnl.OnMouseEnter := @SubMouseEnter;
  Pnl.OnMouseLeave := @SubMouseLeave;

  IconStr := FAChar(AIconCode);
  if IconStr <> '' then
  begin
    IconLbl := TLabel.Create(Pnl);
    IconLbl.Parent := Pnl;
    IconLbl.SetBounds(12, 0, 24, 38);
    IconLbl.Alignment := taCenter;
    IconLbl.Layout := tlCenter;
    IconLbl.Caption := IconStr;
    IconLbl.Font.Size := 12;
    IconLbl.Font.Name := FA_FONT_NAME;
    IconLbl.Font.Color := CLR_PRIMARY;
    IconLbl.ControlStyle := IconLbl.ControlStyle + [csNoStdEvents];
    IconLbl.OnClick := @SubItemClick;
    IconLbl.OnMouseEnter := @SubMouseEnter;
    IconLbl.OnMouseLeave := @SubMouseLeave;
    TitleX := 42;
  end
  else
    TitleX := 14;

  TitleLbl := TLabel.Create(Pnl);
  TitleLbl.Parent := Pnl;
  TitleLbl.SetBounds(TitleX, 0, Pnl.Width - TitleX, 38);
  TitleLbl.Alignment := taLeftJustify;
  TitleLbl.Layout := tlCenter;
  TitleLbl.Caption := ACaption;
  TitleLbl.Font.Size := 11;
  TitleLbl.Font.Color := CLR_TEXT;
  TitleLbl.Font.Style := [];
  TitleLbl.ControlStyle := TitleLbl.ControlStyle + [csNoStdEvents];
  TitleLbl.OnClick := @SubItemClick;
  TitleLbl.OnMouseEnter := @SubMouseEnter;
  TitleLbl.OnMouseLeave := @SubMouseLeave;
end;

procedure TfrmMain.SubMenuPaint(Sender: TObject);
var
  Pnl: TPanel;
begin
  Pnl := TPanel(Sender);
  Pnl.Canvas.Brush.Color := CLR_CARD;
  Pnl.Canvas.FillRect(0, 0, Pnl.Width, Pnl.Height);
  Pnl.Canvas.Brush.Color := CLR_CARD;
  Pnl.Canvas.Pen.Color := CLR_BORDER;
  Pnl.Canvas.Pen.Width := 1;
  Pnl.Canvas.Pen.Style := psSolid;
  Pnl.Canvas.RoundRect(0, 0, Pnl.Width - 1, Pnl.Height - 1, 10, 10);
end;

procedure TfrmMain.SubPaint(Sender: TObject);
var
  Pnl: TPanel;
begin
  Pnl := TPanel(Sender);
  Pnl.Canvas.Brush.Color := CLR_CARD;
  Pnl.Canvas.FillRect(0, 0, Pnl.Width, Pnl.Height);
  Pnl.Canvas.Brush.Color := Pnl.Color;
  Pnl.Canvas.Pen.Style := psClear;
  Pnl.Canvas.RoundRect(0, 0, Pnl.Width, Pnl.Height, 8, 8);
end;

procedure TfrmMain.UserBtnClick(Sender: TObject);
var
  Lbl, IconLbl: TLabel;
  Sep: TPanel;
  YPos: Integer;

  function CrearItem(ACaption: string; AIcon: Word; AColor: TColor;
    AClick: TNotifyEvent): TPanel;
  begin
    Result := TPanel.Create(FUserMenu);
    Result.Parent := FUserMenu;
    Result.SetBounds(8, YPos, FUserMenu.Width - 16, 40);
    Result.BevelOuter := bvNone;
    Result.Color := CLR_CARD;
    Result.ParentBackground := False;
    Result.ParentColor := False;
    Result.Cursor := crHandPoint;
    Result.OnPaint := @SubPaint;
    Result.OnClick := AClick;
    Result.OnMouseEnter := @SubMouseEnter;
    Result.OnMouseLeave := @SubMouseLeave;

    IconLbl := TLabel.Create(Result);
    IconLbl.Parent := Result;
    IconLbl.SetBounds(14, 0, 26, 40);
    IconLbl.Alignment := taCenter;
    IconLbl.Layout := tlCenter;
    IconLbl.Caption := FAIconoStr(AIcon, '•');
    IconLbl.Font.Size := 13;
    IconLbl.Font.Name := FA_FONT_NAME;
    IconLbl.Font.Color := CLR_PRIMARY;
    IconLbl.Transparent := True;
    IconLbl.Cursor := crHandPoint;
    IconLbl.OnClick := AClick;
    IconLbl.OnMouseEnter := @SubMouseEnter;
    IconLbl.OnMouseLeave := @SubMouseLeave;

    Lbl := TLabel.Create(Result);
    Lbl.Parent := Result;
    Lbl.SetBounds(46, 0, Result.Width - 52, 40);
    Lbl.Alignment := taLeftJustify;
    Lbl.Layout := tlCenter;
    Lbl.Caption := ACaption;
    Lbl.Font.Size := 12;
    Lbl.Font.Color := AColor;
    Lbl.Transparent := True;
    Lbl.Cursor := crHandPoint;
    Lbl.OnClick := AClick;
    Lbl.OnMouseEnter := @SubMouseEnter;
    Lbl.OnMouseLeave := @SubMouseLeave;
    YPos := YPos + 44;
  end;

begin
  if FUserMenu.Visible then
  begin
    FUserMenu.Visible := False;
    Exit;
  end;

  FSubCatalogo.Visible := False;
  FSubConfig.Visible := False;

  FUserMenu.DestroyComponents;
  FUserMenu.Left := FUserBtn.Left + FUserBtn.Width - FUserMenu.Width;
  FUserMenu.Top := pnlTop.Height + 2;
  YPos := 12;

  // Encabezado: nombre, email y rol
  Lbl := TLabel.Create(FUserMenu); Lbl.Parent := FUserMenu;
  Lbl.SetBounds(16, YPos, FUserMenu.Width - 32, 16);
  Lbl.Caption := UsuarioActual.PersonaNombre;
  Lbl.Font.Size := 12; Lbl.Font.Style := [fsBold]; Lbl.Font.Color := CLR_TEXT_HEADING;
  Lbl.Transparent := True;
  YPos := YPos + 20;

  Lbl := TLabel.Create(FUserMenu); Lbl.Parent := FUserMenu;
  Lbl.SetBounds(16, YPos, FUserMenu.Width - 32, 14);
  Lbl.Caption := UsuarioActual.Email;
  Lbl.Font.Size := 10; Lbl.Font.Color := CLR_TEXT_SLATE;
  Lbl.Transparent := True;
  YPos := YPos + 18;

  Lbl := TLabel.Create(FUserMenu); Lbl.Parent := FUserMenu;
  Lbl.SetBounds(16, YPos, FUserMenu.Width - 32, 14);
  Lbl.Caption := 'Rol: ' + UsuarioActual.Rol;
  Lbl.Font.Size := 10; Lbl.Font.Color := CLR_TEXT_SLATE;
  Lbl.Transparent := True;
  YPos := YPos + 16;

  Sep := TPanel.Create(FUserMenu); Sep.Parent := FUserMenu;
  Sep.SetBounds(12, YPos, FUserMenu.Width - 24, 1); Sep.Color := CLR_BORDER; Sep.BevelOuter := bvNone;
  YPos := YPos + 8;

  CrearItem('Volver al sistema web', FA_SCALE, CLR_TEXT_HEADING, @VolverPesajeClick);

  Sep := TPanel.Create(FUserMenu); Sep.Parent := FUserMenu;
  Sep.SetBounds(12, YPos, FUserMenu.Width - 24, 1); Sep.Color := CLR_BORDER; Sep.BevelOuter := bvNone;
  YPos := YPos + 8;

  CrearItem('Cerrar Sesion', FA_TIMES, CLR_DESTRUCTIVE, @LogoutClick);

  FUserMenu.Height := YPos + 6;
  FUserMenu.BringToFront;
  FUserMenu.Invalidate;
  FUserMenu.Visible := True;
end;

procedure TfrmMain.ResetNavItems(KeepActive: TPanel);
var
  I: Integer;
begin
  for I := 0 to High(FNavItems) do
    if FNavItems[I] <> KeepActive then
      FNavItems[I].Color := CLR_CARD
    else
      FNavItems[I].Color := CLR_SIDEBAR_ACTIVE;
end;

procedure TfrmMain.CerrarSubmenus;
begin
  FSubCatalogo.Visible := False;
  FSubConfig.Visible := False;
  FUserMenu.Visible := False;
end;

procedure TfrmMain.ToggleSubmenu(Btn: TSpeedButton; SubPanel: TPanel);
begin
  SubPanel.Visible := not SubPanel.Visible;
end;

procedure TfrmMain.NavigateTo(TagVal: Integer);
begin
  case TagVal of
    0:  LoadFrame(TFrameDashboard,     'Inicio');
    1:  LoadFrame(TFramePesaje,        'Pesaje');
    2:  LoadFrame(TFrameEmpresas,      'Empresas');
    3:  LoadFrame(TFrameChoferes,      'Choferes');
    4:  LoadFrame(TFrameProveedores,   'Proveedores');
    5:  LoadFrame(TFrameProductos,     'Productos');
    6:  LoadFrame(TFrameVehiculos,     'Vehiculos');
    7:  LoadFrame(TFrameOrigenes,      'Origenes');
    8:  LoadFrame(TFrameDestinos,      'Destinos');
    10: LoadFrame(TFrameUsuarios,      'Usuarios');
    11: LoadFrame(TFrameReportes,      'Reportes');
    12: LoadFrame(TFrameBoletaConfig,  'Configuracion Boleta');
    13: LoadFrame(TFrameConfigBalanza, 'Configuracion Balanza');
    else MostrarInfoDialogo('Modulo', 'Modulo en desarrollo');
  end;
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
  FSubCatalogo.Visible := False;
  FSubConfig.Visible := False;
  FUserMenu.Visible := False;
end;

procedure TfrmMain.LogoutClick(Sender: TObject);
begin
  if ConfirmarDialogo('Cerrar sesion', 'Seguro que desea cerrar sesion?') then
  begin
    ModalResult := mrCancel;
  end;
end;

procedure TfrmMain.VolverPesajeClick(Sender: TObject);
begin
  CerrarSubmenus;
  if ConfirmarContrasenaActual('Volver al sistema web') then
  begin
    ModalResult := mrYes;
  end;
end;

// Cerrar con la X del sistema completo → volver al modo pesaje (ciclo)
procedure TfrmMain.WMCloseQuery(var Message: TLMessage);
begin
  ModalResult := mrYes;
  Message.Result := 0;
end;

procedure TfrmMain.LogoClick(Sender: TObject);
begin
  NavigateTo(2);
end;

procedure TfrmMain.CargarLogo;
var
  Q: TSQLQuery;
  LogoStr, Base64Str: string;
  Stream: TMemoryStream;
  RawBytes: RawByteString;
  P: Integer;
begin
  if pnlLogoFallback = nil then
  begin
    pnlLogoFallback := TPanel.Create(pnlTop);
    pnlLogoFallback.Parent := pnlTop;
    pnlLogoFallback.SetBounds(16, (FRAME_HEADER_H - 40) div 2, 40, 40);
    pnlLogoFallback.BevelOuter := bvNone;
    pnlLogoFallback.Color := CLR_PRIMARY;
    pnlLogoFallback.Cursor := crHandPoint;
    pnlLogoFallback.OnClick := @LogoClick;
    pnlLogoFallback.OnPaint := @NavPaint;

    lblLogoFallback := TLabel.Create(pnlLogoFallback);
    lblLogoFallback.Parent := pnlLogoFallback;
    lblLogoFallback.Align := alClient;
    lblLogoFallback.Alignment := taCenter;
    lblLogoFallback.Layout := tlCenter;
    lblLogoFallback.Caption := '🚛';
    lblLogoFallback.Font.Size := 20;
    lblLogoFallback.Font.Color := CLR_WHITE;
    lblLogoFallback.Cursor := crHandPoint;
    lblLogoFallback.OnClick := @LogoClick;

    imgLogo := TImage.Create(pnlTop);
    imgLogo.Parent := pnlTop;
    imgLogo.SetBounds(12, (FRAME_HEADER_H - 44) div 2, 44, 44);
    imgLogo.Visible := False;
    imgLogo.Cursor := crHandPoint;
    imgLogo.OnClick := @LogoClick;
    imgLogo.Stretch := True;
    imgLogo.Proportional := True;
    imgLogo.Center := True;
  end;

  pnlLogoFallback.Visible := True;
  imgLogo.Visible := False;

  if (DM = nil) or (not DM.Conexion.Connected) then Exit;

  Q := DM.AbrirQuery(
    'SELECT nombre_empresa, logo FROM empresas WHERE estado = ''ACTIVO'' ORDER BY id DESC LIMIT 1'
  );
  try
    if not Q.EOF then
    begin
      LogoStr := Q.FieldByName('logo').AsString;
      if LogoStr <> '' then
      begin
        P := Pos('base64,', LogoStr);
        if P > 0 then
        begin
          Base64Str := Copy(LogoStr, P + 7, MaxInt);
          RawBytes := DecodeStringBase64(Base64Str);
          Stream := TMemoryStream.Create;
          try
            Stream.Write(RawBytes[1], Length(RawBytes));
            Stream.Position := 0;
            imgLogo.Picture.LoadFromStream(Stream);
            imgLogo.Visible := True;
            pnlLogoFallback.Visible := False;
          finally
            Stream.Free;
          end;
        end;
      end;
    end;
  finally
    Q.Close;
  end;
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

  if NewFrame is TFramePesaje then
    TFramePesaje(NewFrame).AjustarLayoutCards;
end;

end.