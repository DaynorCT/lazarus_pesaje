unit PesajeIntegrado;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, Forms, Controls, Dialogs, StdCtrls, ExtCtrls,
  Menus, sqldb, DataModule, Theme, LoginForm, SyncService, LMessages,
  ConfigBalanzaFrame, AppDialog;

type
  TfrmPesajeIntegrado = class(TForm)
  published
    pnlTop: TPanel;
    lblTitulo: TLabel;
    btnSincronizar: TButton;
    lblEstado: TLabel;
    pnlContenido: TPanel;
    pnlRegistro: TPanel;
    lblRegistroTitle: TLabel;
    pnlDisplay: TPanel;
    lblPesoDisplay: TLabel;
    lblConexion: TLabel;
    btnConectar: TButton;
    btnCapturar: TButton;
    lblPesoCapturado: TLabel;
    btnEnviar: TButton;
    btnEngranaje: TButton;
    PopupEngranaje: TPopupMenu;
    miSistemaCompleto: TMenuItem;
    miSeparador1: TMenuItem;
    miConfigurarBalanza: TMenuItem;
    miSeparador2: TMenuItem;
    miCerrarSesion: TMenuItem;
    TimerLectura: TTimer;
    TimerEstado: TTimer;
    procedure btnConectarClick(Sender: TObject);
    procedure btnCapturarClick(Sender: TObject);
    procedure btnEnviarClick(Sender: TObject);
    procedure btnSincronizarClick(Sender: TObject);
    procedure btnEngranajeClick(Sender: TObject);
    procedure miSistemaCompletoClick(Sender: TObject);
    procedure miConfigurarBalanzaClick(Sender: TObject);
    procedure miCerrarSesionClick(Sender: TObject);
    procedure TimerLecturaTimer(Sender: TObject);
    procedure TimerEstadoTimer(Sender: TObject);
    procedure FormShowHandler(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  protected
    procedure WMCloseQuery(var Message: TLMessage); message LM_CLOSEQUERY;
  private
    FConectado: Boolean;
    FMetodoLectura: string;
    FPosInicio, FPosLongitud: Integer;
    FModoPrueba: Boolean;
    FPesoCapturado: Integer;
    procedure ProcesarTrama(const Trama: string);
    function ExtraerPeso(const Trama: string): string;
    procedure ActualizarEstadoSync;
  end;

var
  frmPesajeIntegrado: TfrmPesajeIntegrado;

implementation

{$R *.lfm}

function PesoDesdeDisplay(const ACaption: string): Integer;
var S: string;
begin
  S := Trim(ACaption);
  if EndsText(' kg', S) then Delete(S, Length(S) - 2, 3);
  Result := StrToIntDef(S, 0);
end;

constructor TfrmPesajeIntegrado.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Randomize;
  FConectado := False;
  FMetodoLectura := 'AUTO';
  FPosInicio := 8;
  FPosLongitud := 5;
  FModoPrueba := False;
  FPesoCapturado := 0;
  btnCapturar.Enabled := False;
  btnEnviar.Enabled := False;
  TimerEstado.Enabled := True;
  lblPesoDisplay.Caption := '0 kg';
  lblPesoCapturado.Caption := 'Peso capturado: 0 kg';
  ActualizarEstadoSync;
end;

destructor TfrmPesajeIntegrado.Destroy;
begin
  if TimerLectura <> nil then TimerLectura.Enabled := False;
  if TimerEstado <> nil then TimerEstado.Enabled := False;
  if FConectado and (DM <> nil) then DM.DesconectarSerial;
  inherited Destroy;
end;

procedure TfrmPesajeIntegrado.FormShowHandler(Sender: TObject);
begin
  if SyncSvc <> nil then
  begin
    Screen.Cursor := crHourGlass;
    try SyncSvc.SincronizarAhora;
    finally Screen.Cursor := crDefault; end;
  end;
  ActualizarEstadoSync;
end;

procedure TfrmPesajeIntegrado.ActualizarEstadoSync;
var Texto: string;
begin
  if SyncSvc = nil then
  begin
    lblEstado.Caption := 'Sin servicio de sincronizacion';
    Exit;
  end;
  if SyncSvc.Conectado then
  begin
    lblEstado.Font.Color := CLR_SUCCESS;
    Texto := '● Conectado';
  end
  else
  begin
    lblEstado.Font.Color := CLR_DESTRUCTIVE;
    Texto := '○ Sin conexion';
  end;
  Texto := Texto + '   Pendientes: ' + IntToStr(SyncSvc.Pendientes);
  if SyncSvc.UltimaSync <> '' then Texto := Texto + '   Ultima: ' + Copy(SyncSvc.UltimaSync, 12, 5);
  if SyncSvc.UltimoError <> '' then Texto := Texto + '   ' + SyncSvc.UltimoError;
  lblEstado.Caption := Texto;
end;

procedure TfrmPesajeIntegrado.TimerEstadoTimer(Sender: TObject);
begin
  ActualizarEstadoSync;
end;

procedure TfrmPesajeIntegrado.btnSincronizarClick(Sender: TObject);
begin
  if SyncSvc = nil then Exit;
  Screen.Cursor := crHourGlass;
  try SyncSvc.SincronizarAhora;
  finally Screen.Cursor := crDefault; end;
  ActualizarEstadoSync;
end;

procedure TfrmPesajeIntegrado.btnEngranajeClick(Sender: TObject);
begin
  PopupEngranaje.PopUp(Mouse.CursorPos.X, Mouse.CursorPos.Y);
end;

procedure TfrmPesajeIntegrado.miSistemaCompletoClick(Sender: TObject);
begin
  if ConfirmarContrasenaActual('Acceso al sistema completo') then ModalResult := mrYes;
end;

procedure TfrmPesajeIntegrado.miConfigurarBalanzaClick(Sender: TObject);
var F: TForm; Frame: TFrameConfigBalanza;
begin
  F := TForm.Create(nil);
  try
    F.Caption := 'Configuracion balanza RS232';
    F.Width := 900;
    F.Height := 700;
    F.Position := poMainFormCenter;
    F.BorderStyle := bsDialog;
    F.Color := CLR_BG;
    Frame := TFrameConfigBalanza.Create(F);
    Frame.Parent := F;
    Frame.Align := alClient;
    F.ShowModal;
  finally F.Free; end;
end;

procedure TfrmPesajeIntegrado.miCerrarSesionClick(Sender: TObject);
begin
  if ConfirmarDialogo('Cerrar sesion', 'Seguro que desea cerrar sesion?') then
    ModalResult := mrCancel;
end;

procedure TfrmPesajeIntegrado.WMCloseQuery(var Message: TLMessage);
begin
  ModalResult := mrAbort;
  Message.Result := 0;
end;

procedure TfrmPesajeIntegrado.btnConectarClick(Sender: TObject);
var Q: TSQLQuery; Puerto: string; Baud, Bits, Stop: Integer; ParidadChar: Char;
begin
  if FConectado then
  begin
    TimerLectura.Enabled := False;
    DM.DesconectarSerial;
    FConectado := False;
    FModoPrueba := False;
    btnCapturar.Enabled := False;
    lblConexion.Caption := 'Desconectada';
    btnConectar.Caption := 'Conectar';
    if SyncSvc <> nil then SyncSvc.EnviarPesoVivo(0);
    Exit;
  end;
  Q := DM.AbrirQuery('SELECT puerto_com, baudrate, databits, paridad, stopbits, metodo_lectura, posicion_inicio, posicion_longitud ' +
    'FROM config_balanza ORDER BY id DESC LIMIT 1');
  try
    if Q.EOF then
    begin
      FConectado := True; FModoPrueba := True;
      btnCapturar.Enabled := True; TimerLectura.Enabled := True;
      lblConexion.Caption := 'Prueba'; btnConectar.Caption := 'Desconectar';
      MostrarInfoDialogo('Balanza', 'No hay balanza configurada. Se activa MODO PRUEBA con pesos simulados.');
      Exit;
    end;
    Puerto := Q.Fields[0].AsString; Baud := Q.Fields[1].AsInteger; Bits := Q.Fields[2].AsInteger;
    if Q.Fields[3].AsString = 'E' then ParidadChar := 'E'
    else if Q.Fields[3].AsString = 'O' then ParidadChar := 'O' else ParidadChar := 'N';
    Stop := Q.Fields[4].AsInteger; FMetodoLectura := Q.Fields[5].AsString;
    FPosInicio := Q.Fields[6].AsInteger; FPosLongitud := Q.Fields[7].AsInteger;
  finally Q.Close; end;
  if DM.ConectarSerial(Puerto, Baud, Bits, ParidadChar, Stop) then
  begin
    FConectado := True; FModoPrueba := False;
    btnCapturar.Enabled := True; TimerLectura.Enabled := True;
    lblConexion.Caption := 'Conectada';
  end
  else
  begin
    FConectado := True; FModoPrueba := True;
    btnCapturar.Enabled := True; TimerLectura.Enabled := True;
    lblConexion.Caption := 'Prueba';
    MostrarInfoDialogo('Balanza', 'No se pudo conectar al puerto ' + Puerto + '. Se activa MODO PRUEBA con pesos simulados.');
  end;
  btnConectar.Caption := 'Desconectar';
end;

procedure TfrmPesajeIntegrado.TimerLecturaTimer(Sender: TObject);
var Trama: string; PesoSimulado: Integer;
begin
  if not FConectado then Exit;
  if FModoPrueba then
  begin
    PesoSimulado := Random(4001) + 1000;
    lblPesoDisplay.Caption := IntToStr(PesoSimulado) + ' kg';
    Exit;
  end;
  if not DM.PuertoConectado then
  begin
    FConectado := False; TimerLectura.Enabled := False;
    btnCapturar.Enabled := False; lblConexion.Caption := 'Desconectada';
    btnConectar.Caption := 'Conectar'; Exit;
  end;
  Trama := DM.LeerPuertoSerial;
  if Trama <> '' then ProcesarTrama(Trama);
end;

function TfrmPesajeIntegrado.ExtraerPeso(const Trama: string): string;
var I: Integer; NumStr: string;
begin
  Result := '';
  if FMetodoLectura = 'POSICION' then
  begin
    if (FPosInicio > 0) and (FPosInicio + FPosLongitud - 1 <= Length(Trama)) then
      Result := Trim(Copy(Trama, FPosInicio, FPosLongitud));
    Exit;
  end;
  NumStr := '';
  for I := 1 to Length(Trama) do
    if Trama[I] in ['0'..'9'] then NumStr := NumStr + Trama[I]
    else if NumStr <> '' then
    begin
      if Length(NumStr) >= 4 then begin Result := NumStr; Exit; end;
      NumStr := '';
    end;
  if (Result = '') and (Length(NumStr) >= 4) then Result := NumStr;
end;

procedure TfrmPesajeIntegrado.ProcesarTrama(const Trama: string);
var PesoStr: string; PesoVal: Integer;
begin
  PesoStr := ExtraerPeso(Trama);
  if PesoStr = '' then Exit;
  PesoVal := StrToIntDef(PesoStr, 0);
  lblPesoDisplay.Caption := IntToStr(PesoVal) + ' kg';
end;

procedure TfrmPesajeIntegrado.btnCapturarClick(Sender: TObject);
var Peso: Integer;
begin
  if not FConectado then begin MostrarInfoDialogo('Balanza', 'Conecte la balanza primero'); Exit; end;
  Peso := PesoDesdeDisplay(lblPesoDisplay.Caption);
  if Peso <= 0 then begin MostrarInfoDialogo('Peso', 'Peso invalido'); Exit; end;
  FPesoCapturado := Peso;
  lblPesoCapturado.Caption := 'Peso capturado: ' + IntToStr(Peso) + ' kg';
  btnEnviar.Enabled := True;
end;

procedure TfrmPesajeIntegrado.btnEnviarClick(Sender: TObject);
begin
  if FPesoCapturado <= 0 then begin MostrarInfoDialogo('Peso', 'Capture el peso primero'); Exit; end;
  if SyncSvc = nil then begin MostrarInfoDialogo('Sincronizacion', 'Servicio de sincronizacion no disponible'); Exit; end;
  Screen.Cursor := crHourGlass;
  try
    if SyncSvc.EnviarPesoVivo(FPesoCapturado) then
      MostrarInfoDialogo('Envio', 'Peso ' + IntToStr(FPesoCapturado) + ' kg enviado a la web.', dtExito)
    else MostrarInfoDialogo('Envio', 'No se pudo enviar el peso. Revise la conexion con el sistema web.', dtError);
  finally Screen.Cursor := crDefault; end;
  ActualizarEstadoSync;
end;

end.
