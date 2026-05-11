unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, ComCtrls, Menus, AuthService, DataModule, LoginForm,
  PesajeFrame, DashboardFrame, VehiculosFrame, ChoferesFrame,
  ProveedoresFrame, UsuariosFrame, AbmSimpleFrame;

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
  pnlLeft.Width := 200;
  pnlLeft.Color := $2D4A6F;
  pnlTop.Color := $1E3A5F;
  pnlTop.Height := 48;
  pnlContent.Color := $F0F2F5;

  lblAppTitle.Caption := 'SISTEMA DE PESAJE';
  lblAppTitle.Font.Color := clWhite;
  lblAppTitle.Font.Style := [fsBold];

  lblUserInfo := TLabel.Create(Self);
  lblUserInfo.Parent := pnlTop;
  lblUserInfo.Align := alRight;
  lblUserInfo.Alignment := taRightJustify;
  lblUserInfo.Font.Color := $CCCCCC;
  lblUserInfo.BorderSpacing.Right := 16;
  lblUserInfo.BorderSpacing.Top := 12;

  btnLogout := TSpeedButton.Create(Self);
  btnLogout.Parent := pnlTop;
  btnLogout.Align := alRight;
  btnLogout.Width := 100;
  btnLogout.Caption := 'Cerrar Sesion';
  btnLogout.Flat := True;
  btnLogout.Font.Color := $FF9999;
  btnLogout.BorderSpacing.Right := 16;
  btnLogout.BorderSpacing.Top := 8;
  btnLogout.OnClick := @btnLogoutClick;

  BuildMenu;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  lblUserInfo.Caption := UsuarioActual.PersonaNombre + '  |  ' + UsuarioActual.Rol;
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

  function CrearBoton(const Caption: string; const Tag: Integer): TSpeedButton;
  begin
    Result := TSpeedButton.Create(sbMenu);
    Result.Parent := sbMenu;
    Result.Caption := Caption;
    Result.Tag := Tag;
    Result.Align := alTop;
    Result.Height := 42;
    Result.Flat := True;
    Result.Font.Color := $DDDDDD;
    Result.Font.Height := -13;
    Result.GroupIndex := 1;
    Result.AllowAllUp := True;
    Result.OnClick := @SidebarButtonClick;
  end;

begin
  sbMenu.Parent := pnlLeft;
  sbMenu.Align := alClient;
  sbMenu.Color := pnlLeft.Color;
  sbMenu.BorderStyle := bsNone;

  CrearBoton('  Dashboard', 0);
  CrearBoton('  Pesaje', 1).Down := True;
  CrearBoton('  Vehiculos', 2);
  CrearBoton('  Choferes', 3);
  CrearBoton('  Proveedores', 4);
  CrearBoton('  Productos', 5);
  CrearBoton('  Origenes', 6);
  CrearBoton('  Destinos', 7);
  CrearBoton('  Bodegas', 8);
  CrearBoton('  Empresas', 9);
  CrearBoton('  Usuarios', 10);
  CrearBoton('  Reportes', 11);
  CrearBoton('  Configuracion', 12);
end;

procedure TfrmMain.SidebarButtonClick(Sender: TObject);
var
  MenuTag: Integer;
  FrameP, FrameD, FrameO: TFrameAbmSimple;
begin
  MenuTag := TSpeedButton(Sender).Tag;

  case MenuTag of
    0: LoadFrame(TFrameDashboard, 'Dashboard');
    1: LoadFrame(TFramePesaje, 'Pesaje');
    2: LoadFrame(TFrameVehiculos, 'Vehiculos');
    3: LoadFrame(TFrameChoferes, 'Choferes');
    4: LoadFrame(TFrameProveedores, 'Proveedores');
    5: begin
      FrameP := TFrameAbmSimple.CreateWithConfig(Self, ConfigProductos);
      LoadFrameInstance(FrameP, 'Productos');
    end;
    6: begin
      FrameO := TFrameAbmSimple.CreateWithConfig(Self, ConfigOrigenes);
      LoadFrameInstance(FrameO, 'Origenes');
    end;
    7: begin
      FrameD := TFrameAbmSimple.CreateWithConfig(Self, ConfigDestinos);
      LoadFrameInstance(FrameD, 'Destinos');
    end;
    8: begin
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
