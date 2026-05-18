unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, AuthService, DataModule, LoginForm,
  PesajeFrame, DashboardFrame, VehiculosFrame, ChoferesFrame,
  ProveedoresFrame, UsuariosFrame, EmpresasFrame, ProductosFrame,
  OrigenesFrame, DestinosFrame, AbmSimpleFrame, Theme, base64, SQLDB;

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
    FNavItems: array of TPanel;
    FActiveNav: TPanel;
    FActiveSub: TPanel;
    FSubCatalogo, FSubConfig, FUserMenu: TPanel;
    FUserBtn: TSpeedButton;
    imgLogo: TImage;
    pnlLogoFallback: TPanel;
    lblLogoFallback: TLabel;

    procedure LogoClick(Sender: TObject);
    procedure NavPaint(Sender: TObject);
    function CrearNavItem(const ACaption: string; ATag: Integer; X: Integer): TPanel;
    procedure NavClick(Sender: TObject);
    procedure NavMouseEnter(Sender: TObject);
    procedure NavMouseLeave(Sender: TObject);
    procedure SubItemClick(Sender: TObject);
    procedure SubMouseEnter(Sender: TObject);
    procedure SubMouseLeave(Sender: TObject);
    procedure UserBtnClick(Sender: TObject);
    procedure CrearSubItem(AParent: TPanel; const ACaption: string; ATag, Y: Integer);
    procedure ResetNavItems(KeepActive: TPanel);
    procedure CerrarSubmenus;
    procedure ToggleSubmenu(Btn: TSpeedButton; SubPanel: TPanel);
    procedure NavigateTo(TagVal: Integer);
    procedure LoadFrame(FrameClass: TFrameClass; const Title: string);
    procedure LoadFrameInstance(NewFrame: TFrame; const Title: string);
    procedure LogoutClick(Sender: TObject);
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
  Items: array[0..8] of record Emoji, Title: string; Tag: Integer; HasSub: Boolean; end;
  Pnl: TPanel;
begin
  FActiveFrame := nil;
  FActiveNav := nil;
  FActiveSub := nil;
  Caption := 'Sistema de Pesaje';

  pnlTop.Height := 80;
  pnlTop.Color := CLR_CARD;

  // Borde inferior (border-bottom: 1px #E2E8F0)
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

  // Orden exacto del sistema web
  Items[0].Emoji := '📊'; Items[0].Title := 'Inicio';       Items[0].Tag := 0;
  Items[1].Emoji := '👥'; Items[1].Title := 'Usuarios';     Items[1].Tag := 10;
  Items[2].Emoji := '🏢'; Items[2].Title := 'Empresas';     Items[2].Tag := 2;
  Items[3].Emoji := '👤'; Items[3].Title := 'Choferes';     Items[3].Tag := 3;
  Items[4].Emoji := '🏭'; Items[4].Title := 'Proveedores';  Items[4].Tag := 4;
  Items[5].Emoji := '⚖️';  Items[5].Title := 'Pesaje';      Items[5].Tag := 1;
  Items[6].Emoji := '📦'; Items[6].Title := 'Catalogo ▼';   Items[6].Tag := 100; Items[6].HasSub := True;
  Items[7].Emoji := '📄'; Items[7].Title := 'Reportes';     Items[7].Tag := 11;
  Items[8].Emoji := '⚙️';  Items[8].Title := 'Config ▼';     Items[8].Tag := 200; Items[8].HasSub := True;

  SetLength(FNavItems, 9);
  XPos := 230;

  for I := 0 to 8 do
  begin
    Pnl := CrearNavItem(Items[I].Emoji + '  ' + Items[I].Title, Items[I].Tag, XPos);
    FNavItems[I] := Pnl;
    XPos := XPos + Pnl.Width + 16;
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
  CrearSubItem(FSubCatalogo, '📦 Productos', 5, 38);
  CrearSubItem(FSubCatalogo, '📍 Origenes', 7, 76);
  CrearSubItem(FSubCatalogo, '🎯 Destinos', 8, 114);

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

  // Botón usuario (TPanel, igual que nav modules)
  // Botón usuario
  FUserBtn := TSpeedButton.Create(pnlTop);
  FUserBtn.Parent := pnlTop;
  FUserBtn.Align := alRight;
  FUserBtn.Width := 40; FUserBtn.Height := 40;
  FUserBtn.Top := 20;
  FUserBtn.Caption := '👤';
  FUserBtn.Flat := True;
  FUserBtn.Font.Size := 18;
  FUserBtn.BorderSpacing.Right := 12;
  FUserBtn.OnClick := @UserBtnClick;

  // Menú usuario
  FUserMenu := TPanel.Create(Self);
  FUserMenu.Parent := Self;
  FUserMenu.Visible := False;
  FUserMenu.Color := CLR_CARD;
  FUserMenu.BevelOuter := bvNone;
  FUserMenu.BorderStyle := bsSingle;
  FUserMenu.Width := 200;
  FUserMenu.Height := 130;
end;

function TfrmMain.CrearNavItem(const ACaption: string; ATag: Integer; X: Integer): TPanel;
var
  Lbl: TLabel;
  W: Integer;
begin
  Result := TPanel.Create(pnlTop);
  Result.Parent := pnlTop;
  Result.Tag := ATag;
  W := Result.Canvas.TextWidth(ACaption) + 24;
  Result.SetBounds(X, 20, W, 40);
  Result.BevelOuter := bvNone;
  Result.Color := CLR_CARD;
  Result.Cursor := crHandPoint;
  Result.OnPaint := @NavPaint;
  Result.OnClick := @NavClick;
  Result.OnMouseEnter := @NavMouseEnter;
  Result.OnMouseLeave := @NavMouseLeave;

  Lbl := TLabel.Create(Result);
  Lbl.Parent := Result;
  Lbl.Align := alClient;
  Lbl.Alignment := taCenter;
  Lbl.Layout := tlCenter;
  Lbl.Caption := ACaption;
  Lbl.Font.Size := 12;
  Lbl.Font.Color := CLR_TEXT;
  Lbl.Font.Style := [];
  Lbl.ControlStyle := Lbl.ControlStyle + [csNoStdEvents];
  Lbl.OnClick := @NavClick;
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

  // Submenus toggle
  if TagVal = 100 then
  begin
    CerrarSubmenus;
    FSubCatalogo.Left := Pnl.Left;
    FSubCatalogo.Top := pnlTop.Height + 2;
    FSubCatalogo.Visible := not FSubCatalogo.Visible;
    Exit;
  end;
  if TagVal = 200 then
  begin
    CerrarSubmenus;
    FSubConfig.Left := Pnl.Left;
    FSubConfig.Top := pnlTop.Height + 2;
    FSubConfig.Visible := not FSubConfig.Visible;
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
  // Rellenar todo con el fondo del navbar para que las esquinas queden "transparentes"
  Pnl.Canvas.Brush.Color := CLR_CARD;
  Pnl.Canvas.FillRect(0, 0, Pnl.Width, Pnl.Height);
  // Dibujar el panel redondeado con su propio color
  Pnl.Canvas.Brush.Color := Pnl.Color;
  Pnl.Canvas.Pen.Style := psClear;
  Pnl.Canvas.RoundRect(0, 0, Pnl.Width, Pnl.Height, 8, 8);
end;

procedure TfrmMain.CrearSubItem(AParent: TPanel; const ACaption: string; ATag, Y: Integer);
var
  Pnl: TPanel;
  Lbl: TLabel;
begin
  Pnl := TPanel.Create(AParent);
  Pnl.Parent := AParent;
  Pnl.Tag := ATag;
  Pnl.SetBounds(0, Y, 180, 36);
  Pnl.BevelOuter := bvNone;
  Pnl.Color := CLR_CARD;
  Pnl.Cursor := crHandPoint;
  Pnl.OnClick := @SubItemClick;
  Pnl.OnMouseEnter := @SubMouseEnter;
  Pnl.OnMouseLeave := @SubMouseLeave;

  Lbl := TLabel.Create(Pnl);
  Lbl.Parent := Pnl;
  Lbl.SetBounds(12, 0, 168, 36);
  Lbl.Alignment := taLeftJustify;
  Lbl.Layout := tlCenter;
  Lbl.Caption := ACaption;
  Lbl.Font.Size := 12;
  Lbl.Font.Color := CLR_TEXT;
  Lbl.Font.Style := [];
  Lbl.ControlStyle := Lbl.ControlStyle + [csNoStdEvents];
  Lbl.OnClick := @SubItemClick;
end;

procedure TfrmMain.UserBtnClick(Sender: TObject);
var
  Lbl: TLabel;
  YPos: Integer;
  Sep: TPanel;
begin
  // Toggle: si ya está abierto, cerrar
  if FUserMenu.Visible then
  begin
    FUserMenu.Visible := False;
    Exit;
  end;

  // Cerrar otros menús
  FSubCatalogo.Visible := False;
  FSubConfig.Visible := False;

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

  Sep := TPanel.Create(FUserMenu); Sep.Parent := FUserMenu;
  Sep.SetBounds(8, YPos, 184, 1); Sep.Color := CLR_BORDER; Sep.BevelOuter := bvNone;
  YPos := YPos + 8;

  Lbl := TLabel.Create(FUserMenu); Lbl.Parent := FUserMenu;
  Lbl.SetBounds(12, YPos, 176, 14);
  Lbl.Caption := 'Rol: ' + UsuarioActual.Rol;
  Lbl.Font.Size := 10; Lbl.Font.Color := CLR_TEXT_SLATE;
  YPos := YPos + 22;

  Sep := TPanel.Create(FUserMenu); Sep.Parent := FUserMenu;
  Sep.SetBounds(8, YPos, 184, 1); Sep.Color := CLR_BORDER; Sep.BevelOuter := bvNone;
  YPos := YPos + 8;

  Lbl := TLabel.Create(FUserMenu); Lbl.Parent := FUserMenu;
  Lbl.SetBounds(12, YPos, 176, 16);
  Lbl.Caption := 'Cerrar Sesion';
  Lbl.Font.Size := 12; Lbl.Font.Color := CLR_DESTRUCTIVE;
  Lbl.Cursor := crHandPoint;
  Lbl.OnClick := @LogoutClick;

  FUserMenu.Visible := True;
end;

procedure TfrmMain.ResetNavItems(KeepActive: TPanel);
var
  I: Integer;
begin
  for I := 0 to High(FNavItems) do
    if FNavItems[I] <> KeepActive then
    begin
      FNavItems[I].Color := CLR_CARD;
    end
    else
    begin
      FNavItems[I].Color := CLR_SIDEBAR_ACTIVE;
    end;
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
var
  FrameP, FrameD: TFrameAbmSimple;
begin
  case TagVal of
    0: LoadFrame(TFrameDashboard, 'Inicio');
    1: LoadFrame(TFramePesaje, 'Pesaje');
    2: LoadFrame(TFrameEmpresas, 'Empresas');
    3: LoadFrame(TFrameChoferes, 'Choferes');
    4: LoadFrame(TFrameProveedores, 'Proveedores');
     5: LoadFrame(TFrameProductos, 'Productos');
    6: LoadFrame(TFrameVehiculos, 'Vehiculos');
     7: LoadFrame(TFrameOrigenes, 'Origenes');
     8: LoadFrame(TFrameDestinos, 'Destinos');
    10: LoadFrame(TFrameUsuarios, 'Usuarios');
    11: ShowMessage('Reportes - Fase 3');
    12: ShowMessage('Configuracion Boleta - Fase 3');
    else ShowMessage('Modulo en desarrollo');
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
  if MessageDlg('Cerrar sesion', 'Seguro que desea cerrar sesion?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    ModalResult := mrCancel;
    Close;
  end;
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
  // Crear componentes solo la primera vez
  if pnlLogoFallback = nil then
  begin
    pnlLogoFallback := TPanel.Create(pnlTop);
    pnlLogoFallback.Parent := pnlTop;
    pnlLogoFallback.SetBounds(16, 16, 48, 48);
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
    lblLogoFallback.Font.Size := 22;
    lblLogoFallback.Font.Color := CLR_WHITE;
    lblLogoFallback.Cursor := crHandPoint;
    lblLogoFallback.OnClick := @LogoClick;

    imgLogo := TImage.Create(pnlTop);
    imgLogo.Parent := pnlTop;
    imgLogo.SetBounds(16, 12, 56, 56);
    imgLogo.Visible := False;
    imgLogo.Cursor := crHandPoint;
    imgLogo.OnClick := @LogoClick;
    imgLogo.Stretch := True;
    imgLogo.Proportional := True;
    imgLogo.Center := True;
  end;

  // Mostrar fallback por defecto
  pnlLogoFallback.Visible := True;
  imgLogo.Visible := False;

  // Consultar logo de la BD
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
end;

end.
