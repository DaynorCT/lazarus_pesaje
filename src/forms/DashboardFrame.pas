unit DashboardFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, ExtCtrls, StdCtrls,
  sqldb, DataModule, Utils, Theme;

type
  { TFrameDashboard }

  TFrameDashboard = class(TFrame)
    TimerRefresh: TTimer;
    constructor Create(AOwner: TComponent); override;
    procedure TimerRefreshTimer(Sender: TObject);
  private
    pnlMain: TPanel;
    CardPesajesHoy: TPanel;
    CardPesoTotal: TPanel;
    CardVehiculosHoy: TPanel;
    CardUltimoPesaje: TPanel;
    procedure CrearDashboard;
    function CrearCard(const ATitulo, AValor: string;
      AColor, ATop, ALeft: Integer): TPanel;
    procedure ActualizarStats;
  end;

implementation

{$R *.lfm}

constructor TFrameDashboard.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  CrearDashboard;
  TimerRefresh := TTimer.Create(Self);
  TimerRefresh.Interval := 30000;
  TimerRefresh.OnTimer := @TimerRefreshTimer;
  TimerRefresh.Enabled := True;
  ActualizarStats;
end;

procedure TFrameDashboard.TimerRefreshTimer(Sender: TObject);
begin
  ActualizarStats;
end;

procedure TFrameDashboard.CrearDashboard;
begin
  pnlMain := TPanel.Create(Self);
  pnlMain.Parent := Self;
  pnlMain.Align := alClient;
  pnlMain.BevelOuter := bvNone;
  pnlMain.Color := CLR_BG;
  pnlMain.Caption := '';

  CrearCard('Pesajes Hoy', '0', CLR_PRIMARY, 20, 20);
  CrearCard('Peso Total', '0 kg', CLR_PRIMARY, 20, 280);
  CrearCard('Vehiculos Hoy', '0', CLR_PRIMARY, 20, 540);
  CrearCard('Ultimo Pesaje', 'Sin registros', CLR_PRIMARY, 160, 20);
end;

function TFrameDashboard.CrearCard(const ATitulo, AValor: string;
  AColor, ATop, ALeft: Integer): TPanel;
var
  LblTitulo, LblValor: TLabel;
  Barra: TPanel;
begin
  Result := TPanel.Create(Self);
  Result.Parent := pnlMain;
  Result.Top := ATop;
  Result.Left := ALeft;
  Result.Width := 240;
  Result.Height := 110;
  Result.BevelOuter := bvNone;
  Result.Color := CLR_CARD;

  Barra := TPanel.Create(Result);
  Barra.Parent := Result;
  Barra.Left := 0; Barra.Top := 0;
  Barra.Width := 4; Barra.Height := 110;
  Barra.BevelOuter := bvNone;
  Barra.Color := AColor;

  LblTitulo := TLabel.Create(Result);
  LblTitulo.Parent := Result;
  LblTitulo.Top := 16; LblTitulo.Left := 20;
  LblTitulo.Caption := ATitulo;
  LblTitulo.Font.Color := CLR_TEXT_SLATE;
  LblTitulo.Font.Height := -12;
  LblTitulo.ParentFont := False;

  LblValor := TLabel.Create(Result);
  LblValor.Parent := Result;
  LblValor.Top := 44; LblValor.Left := 20;
  LblValor.Width := 200;
  LblValor.Caption := AValor;
  LblValor.Font.Color := CLR_TEXT_HEADING;
  LblValor.Font.Height := -27;
  LblValor.Font.Style := [fsBold];
  LblValor.ParentFont := False;
  LblValor.Tag := 99;

  // Asignar referencia segun posicion (orden de creacion)
  if CardPesajesHoy = nil then CardPesajesHoy := Result
  else if CardPesoTotal = nil then CardPesoTotal := Result
  else if CardVehiculosHoy = nil then CardVehiculosHoy := Result
  else CardUltimoPesaje := Result;
end;

procedure TFrameDashboard.ActualizarStats;
var
  Q: TSQLQuery;
  FechaHoy: string;

  procedure SetCardValue(CardPanel: TPanel; const Value: string);
  var
    i: Integer;
  begin
    for i := 0 to CardPanel.ControlCount - 1 do
      if CardPanel.Controls[i] is TLabel then
        if TLabel(CardPanel.Controls[i]).Tag = 99 then
          TLabel(CardPanel.Controls[i]).Caption := Value;
  end;

begin
  if DM = nil then Exit;
  if not DM.Conexion.Connected then Exit;

  FechaHoy := FormatDateTime('yyyy-mm-dd', Now);

  Q := DM.AbrirQuery(
    'SELECT COUNT(*) AS total FROM pesajes ' +
    'WHERE fecha_creacion LIKE ''' + FechaHoy + '%'''
  );
  SetCardValue(CardPesajesHoy, Q.FieldByName('total').AsString);
  Q.Close;

  Q := DM.AbrirQuery(
    'SELECT COALESCE(SUM(peso_neto), 0) AS total FROM pesajes ' +
    'WHERE fecha_creacion LIKE ''' + FechaHoy + '%'''
  );
  SetCardValue(CardPesoTotal, FormatearPeso(Q.FieldByName('total').AsInteger));
  Q.Close;

  Q := DM.AbrirQuery(
    'SELECT COUNT(DISTINCT vehiculo_id) AS total FROM pesajes ' +
    'WHERE fecha_creacion LIKE ''' + FechaHoy + '%'''
  );
  SetCardValue(CardVehiculosHoy, Q.FieldByName('total').AsString);
  Q.Close;

  Q := DM.AbrirQuery(
    'SELECT p.peso_neto, v.placa ' +
    'FROM pesajes p ' +
    'LEFT JOIN vehiculos v ON v.id = p.vehiculo_id ' +
    'ORDER BY p.id DESC LIMIT 1'
  );
  if Q.EOF then
    SetCardValue(CardUltimoPesaje, 'Sin registros')
  else
    SetCardValue(CardUltimoPesaje,
      Q.FieldByName('placa').AsString + ' - ' +
      FormatearPeso(Q.FieldByName('peso_neto').AsInteger));
  Q.Close;
end;

end.
