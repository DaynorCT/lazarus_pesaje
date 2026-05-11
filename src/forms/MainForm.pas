unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, ComCtrls, Menus, AuthService, DataModule, LoginForm;

type
  TFrameClass = class of TFrame;

  TMenuItemInfo = record
    Name: string;
    FrameClass: TFrameClass;
    RequiereAdmin: Boolean;
  end;

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
    procedure BuildMenu;
    procedure ShowPesaje;
    procedure ShowDashboard;
    procedure ShowChoferes;
    procedure ShowVehiculos;
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

uses
  PesajeFrame, DashboardFrame;

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

  lblUserInfo.Parent := pnlTop;
  lblUserInfo.Align := alRight;
  lblUserInfo.Alignment := taRightJustify;
  lblUserInfo.Font.Color := $CCCCCC;
  lblUserInfo.BorderSpacing.Right := 16;
  lblUserInfo.BorderSpacing.Top := 12;

  btnLogout.Parent := pnlTop;
  btnLogout.Align := alRight;
  btnLogout.Width := 100;
  btnLogout.Caption := 'Cerrar Sesión';
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
  ShowDashboard;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if FActiveFrame <> nil then
  begin
    FActiveFrame.Free;
    FActiveFrame := nil;
  end;
end;

procedure TfrmMain.btnLogoutClick(Sender: TObject);
begin
  if MessageDlg('Cerrar sesión', '¿Está seguro que desea cerrar sesión?',
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
    Result.Height := 44;
    Result.Flat := True;
    Result.Font.Color := $DDDDDD;
    Result.Font.Height := -14;
    Result.GroupIndex := 1;
    Result.AllowAllUp := True;
    Result.OnClick := @SidebarButtonClick;
    Result.Margin := 8;
  end;

begin
  sbMenu.Parent := pnlLeft;
  sbMenu.Align := alClient;
  sbMenu.Color := pnlLeft.Color;
  sbMenu.BorderStyle := bsNone;

  CrearBoton('  Dashboard', 0);
  CrearBoton('  Pesaje', 1).Down := True;
  CrearBoton('  Vehículos', 2);
  CrearBoton('  Choferes', 3);
  CrearBoton('  Proveedores', 4);
  CrearBoton('  Productos', 5);
  CrearBoton('  Orígenes', 6);
  CrearBoton('  Destinos', 7);
  CrearBoton('  Bodegas', 8);
  CrearBoton('  Empresas', 9);
  CrearBoton('  Usuarios', 10);
  CrearBoton('  Reportes', 11);
  CrearBoton('  Configuración', 12);
end;

procedure TfrmMain.SidebarButtonClick(Sender: TObject);
var
  Btn: TSpeedButton;
begin
  Btn := TSpeedButton(Sender);
  pnlContent.Caption := '';

  case Btn.Tag of
    0: ShowDashboard;
    1: ShowPesaje;
    else ShowMessage('Módulo en desarrollo (Fase 2) - Tag: ' + IntToStr(Btn.Tag));
  end;
end;

procedure TfrmMain.LoadFrame(FrameClass: TFrameClass; const Title: string);
var
  NewFrame: TFrame;
begin
  if FActiveFrame <> nil then
  begin
    if FActiveFrame.ClassType = FrameClass then
      Exit;
    FActiveFrame.Free;
    FActiveFrame := nil;
  end;

  NewFrame := FrameClass.Create(Self);
  NewFrame.Parent := pnlContent;
  NewFrame.Align := alClient;
  NewFrame.Visible := True;
  FActiveFrame := NewFrame;
  Caption := 'Sistema de Pesaje - ' + Title;
end;

procedure TfrmMain.ShowDashboard;
begin
  LoadFrame(TFrameDashboard, 'Dashboard');
end;

procedure TfrmMain.ShowPesaje;
begin
  LoadFrame(TFramePesaje, 'Pesaje');
end;

procedure TfrmMain.ShowChoferes;
begin
  ShowMessage('ABM Choferes - Fase 2');
end;

procedure TfrmMain.ShowVehiculos;
begin
  ShowMessage('ABM Vehículos - Fase 2');
end;

end.
