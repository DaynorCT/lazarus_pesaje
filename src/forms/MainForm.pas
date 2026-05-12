unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, ComCtrls, Menus, AuthService, DataModule, LoginForm,
  PesajeFrame, DashboardFrame, VehiculosFrame, ChoferesFrame,
  ProveedoresFrame, UsuariosFrame, AbmSimpleFrame, Theme;

type
  TFrameClass = class of TFrame;

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlLeft: TPanel;
    pnlTop: TPanel;
    pnlContent: TPanel;
    lblAppTitle: TLabel;
    lblUserInfo: TLabel;
    btnLogout: TSpeedButton;
    sbMenu: TScrollBox;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnLogoutClick(Sender: TObject);
  private
    FActiveFrame: TFrame;
    procedure SidebarButtonClick(Sender: TObject);
    procedure LoadFrame(FrameClass: TFrameClass; const Title: string);
    procedure LoadFrameInstance(NewFrame: TFrame; const Title: string);
    procedure BuildMenu;
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
  pnlLeft.Width := 220;
  pnlLeft.Color := CLR_SIDEBAR_BG;
  pnlTop.Color := CLR_TOPBAR_BG;
  pnlTop.Height := 48;
  pnlContent.Color := CLR_BG;

  lblAppTitle.Caption := ' SISTEMA DE PESAJE';
  lblAppTitle.Font.Color := CLR_TEXT_HEADING;
  lblAppTitle.Font.Style := [fsBold];
  lblAppTitle.Font.Size := 11;

  lblUserInfo := TLabel.Create(Self);
  lblUserInfo.Parent := pnlTop;
  lblUserInfo.Align := alRight;
  lblUserInfo.Alignment := taRightJustify;
  lblUserInfo.Font.Color := CLR_TEXT_SLATE;
  lblUserInfo.Font.Size := 11;
  lblUserInfo.BorderSpacing.Right := 16;
  lblUserInfo.BorderSpacing.Top := 14;

  btnLogout := TSpeedButton.Create(Self);
  btnLogout.Parent := pnlTop;
  btnLogout.Align := alRight;
  btnLogout.Width := 100;
  btnLogout.Caption := 'Cerrar Sesion';
  btnLogout.Flat := True;
  btnLogout.Font.Color := CLR_TEXT_MUTED;
  btnLogout.Font.Size := 11;
  btnLogout.BorderSpacing.Right := 16;
  btnLogout.BorderSpacing.Top := 8;
  btnLogout.OnClick := @btnLogoutClick;

  BuildMenu;
end;

procedure TfrmMain.FormShow(Sender: TObject);
var
  i: Integer;
  Btn: TSpeedButton;
begin
  lblUserInfo.Caption := UsuarioActual.PersonaNombre + '  |  ' + UsuarioActual.Rol;

  // Activar boton Pesaje (Tag=1) visualmente
  for i := 0 to sbMenu.ControlCount - 1 do
  begin
    if (sbMenu.Controls[i] is TSpeedButton) and (TSpeedButton(sbMenu.Controls[i]).Tag = 1) then
    begin
      Btn := TSpeedButton(sbMenu.Controls[i]);
      Btn.Font.Color := CLR_SIDEBAR_ACTIVE_TEXT;
      Break;
    end;
  end;

  LoadFrame(TFrameDashboard, 'Dashboard');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if FActiveFrame <> nil then
  begin
    FreeAndNil(FActiveFrame);
  end;
end;

procedure TfrmMain.btnLogoutClick(Sender: TObject);
begin
  if MessageDlg('Cerrar sesion', 'Esta seguro que desea cerrar sesion?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    ModalResult := mrCancel;
    Close;
  end;
end;

procedure TfrmMain.BuildMenu;
var
  Y: Integer;

  function CrearBoton(const Caption: string; const Tag: Integer): TSpeedButton;
  begin
    Result := TSpeedButton.Create(sbMenu);
    Result.Parent := sbMenu;
    Result.Caption := Caption;
    Result.Tag := Tag;
    Result.SetBounds(0, Y, 220, 38);
    Result.Anchors := [akTop, akLeft, akRight];
    Result.Flat := True;
    Result.Font.Color := CLR_SIDEBAR_TEXT;
    Result.Font.Height := -13;
    Result.GroupIndex := 1;
    Result.AllowAllUp := True;
    Result.OnClick := @SidebarButtonClick;
    Result.Margin := 6;
    Y := Y + 38;
  end;

begin
  sbMenu.Parent := pnlLeft;
  sbMenu.Align := alClient;
  sbMenu.Color := CLR_SIDEBAR_BG;
  sbMenu.BorderStyle := bsNone;

  Y := 0;
  CrearBoton('  Dashboard', 0);
  CrearBoton('  Usuarios', 10);
  CrearBoton('  Choferes', 3);
  CrearBoton('  Proveedores', 4);
  CrearBoton('  Pesaje', 1).Down := True;
  CrearBoton('  Vehiculos', 6);
  CrearBoton('  Productos', 5);
  CrearBoton('  Origenes', 7);
  CrearBoton('  Destinos', 8);
  CrearBoton('  Configuracion', 12);
end;

procedure TfrmMain.SidebarButtonClick(Sender: TObject);
var
  MenuTag: Integer;
  FrameP, FrameD, FrameO: TFrameAbmSimple;
  i: Integer;
  Btn: TSpeedButton;
begin
  // Resetear todos los botones a estilo default
  for i := 0 to sbMenu.ControlCount - 1 do
  begin
    if sbMenu.Controls[i] is TSpeedButton then
    begin
      Btn := TSpeedButton(sbMenu.Controls[i]);
      Btn.Font.Color := CLR_SIDEBAR_TEXT;
    end;
  end;

  // Activar el boton clickeado
  if Sender is TSpeedButton then
  begin
    Btn := TSpeedButton(Sender);
    Btn.Font.Color := CLR_SIDEBAR_ACTIVE_TEXT;
  end;

  MenuTag := TSpeedButton(Sender).Tag;

  case MenuTag of
    0: LoadFrame(TFrameDashboard, 'Dashboard');
    1: LoadFrame(TFramePesaje, 'Pesaje');
    2: ShowMessage('Empresas - Fase 3');
    3: LoadFrame(TFrameChoferes, 'Choferes');
    4: LoadFrame(TFrameProveedores, 'Proveedores');
    5: begin
      FrameP := TFrameAbmSimple.CreateWithConfig(Self, ConfigProductos);
      LoadFrameInstance(FrameP, 'Productos');
    end;
    6: LoadFrame(TFrameVehiculos, 'Vehiculos');
    7: begin
      FrameO := TFrameAbmSimple.CreateWithConfig(Self, ConfigOrigenes);
      LoadFrameInstance(FrameO, 'Origenes');
    end;
    8: begin
      FrameD := TFrameAbmSimple.CreateWithConfig(Self, ConfigDestinos);
      LoadFrameInstance(FrameD, 'Destinos');
    end;
    9: begin
      FrameD := TFrameAbmSimple.CreateWithConfig(Self, ConfigBodegas);
      LoadFrameInstance(FrameD, 'Bodegas');
    end;
    10: LoadFrame(TFrameUsuarios, 'Usuarios');
    else ShowMessage('Modulo en desarrollo - Fase 3');
  end;
end;

procedure TfrmMain.LoadFrame(FrameClass: TFrameClass; const Title: string);
var
  NewFrame: TFrame;
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
