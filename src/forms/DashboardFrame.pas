unit DashboardFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, ExtCtrls, StdCtrls,
  sqldb, DataModule, Utils;

type
  { TFrameDashboard }

  TFrameDashboard = class(TFrame)
    TimerRefresh: TTimer;
    procedure FrameCreate(Sender: TObject);
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

procedure TFrameDashboard.FrameCreate(Sender: TObject);
begin
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
  pnlMain.Color := $F0F2F5;
  pnlMain.Caption := '';

  CrearCard('Pesajes Hoy', '0', $2D6A4F, 24, 24);
  CrearCard('Peso Total (kg)', '0', $1B4332, 24, 280);
  CrearCard('Vehículos Hoy', '0', $40916C, 24, 536);
  CrearCard('Último Pesaje', 'Sin registros', $52796F, 170, 24);
end;

function TFrameDashboard.CrearCard(const ATitulo, AValor: string;
  AColor, ATop, ALeft: Integer): TPanel;
var
  LblTitulo, LblValor: TLabel;
begin
  Result := TPanel.Create(Self);
  Result.Parent := pnlMain;
  Result.Top := ATop;
  Result.Left := ALeft;
  Result.Width := 232;
  Result.Height := 120;
  Result.BevelOuter := bvNone;
  Result.Color := AColor;

  LblTitulo := TLabel.Create(Result);
  LblTitulo.Parent := Result;
  LblTitulo.Top := 16;
  LblTitulo.Left := 20;
  LblTitulo.Width := 192;
  LblTitulo.Caption := ATitulo;
  LblTitulo.Font.Color := $CCDDCC;
  LblTitulo.Font.Height := -13;
  LblTitulo.ParentFont := False;

  LblValor := TLabel.Create(Result);
  LblValor.Parent := Result;
  LblValor.Top := 48;
  LblValor.Left := 20;
  LblValor.Width := 192;
  LblValor.Caption := AValor;
  LblValor.Font.Color := clWhite;
  LblValor.Font.Height := -27;
  LblValor.Font.Style := [fsBold];
  LblValor.ParentFont := False;
  LblValor.Tag := 99;

  case AColor of
    $2D6A4F: CardPesajesHoy := Result;
    $1B4332: CardPesoTotal := Result;
    $40916C: CardVehiculosHoy := Result;
    $52796F: CardUltimoPesaje := Result;
  end;
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
