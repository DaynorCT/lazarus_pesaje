unit ReportesFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Grids, sqldb, LCLIntf, DataModule, Utils, Theme, ReportePesaje;

type
  TFrameReportes = class(TFrame)
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  private
    Grid: TStringGrid;
    pnlCard: TPanel;
    pnlPDF: TPanel;
    lblPDF: TLabel;
    edtFechaDesde, edtFechaHasta, edtPlaca: TEdit;
    FHoverRow: Integer;
    procedure Refrescar(Sender: TObject);
    procedure FechaExit(Sender: TObject);
    procedure btnPDFClick(Sender: TObject);
    procedure GridDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
    procedure GridMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure PaintRounded(Sender: TObject);
  end;

implementation

{$R *.lfm}

procedure TFrameReportes.PaintRounded(Sender: TObject);
var Pnl: TPanel;
begin
  Pnl := TPanel(Sender);
  Pnl.Canvas.Brush.Color := CLR_BG;
  Pnl.Canvas.FillRect(0, 0, Pnl.Width, Pnl.Height);
  Pnl.Canvas.Brush.Color := Pnl.Color;
  Pnl.Canvas.Pen.Style := psClear;
  Pnl.Canvas.RoundRect(0, 0, Pnl.Width, Pnl.Height, 8, 8);
end;

constructor TFrameReportes.Create(AOwner: TComponent);
var
  Pnl: TPanel;
  Lbl: TLabel;
  pnlOuter, pnlInner: TPanel;
begin
  inherited Create(AOwner);
  FHoverRow := 0;
  Self.Color := CLR_BG;

  // ═══ Header ═══
  Pnl := TPanel.Create(Self);
  Pnl.Parent := Self;
  Pnl.Align := alTop;
  Pnl.Height := 64;
  Pnl.BevelOuter := bvNone;
  Pnl.Color := CLR_BG;
  Pnl.BorderSpacing.Top := 15;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := Pnl;
  Lbl.SetBounds(24, 18, 200, 28);
  Lbl.Caption := 'Reportes';
  Lbl.Font.Height := -24;
  Lbl.Font.Style := [fsBold];
  Lbl.Font.Color := CLR_TEXT_HEADING;

  // Fecha Desde
  Lbl := TLabel.Create(Self);
  Lbl.Parent := Pnl;
  Lbl.SetBounds(240, 28, 150, 16);
  Lbl.Caption := 'Desde (dia-mes-año)';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_TEXT_MUTED;

  pnlOuter := TPanel.Create(Pnl);
  pnlOuter.Parent := Pnl;
  pnlOuter.SetBounds(395, 19, 150, 40);
  pnlOuter.BevelOuter := bvNone;
  pnlOuter.Color := CLR_BORDER;

  pnlInner := TPanel.Create(pnlOuter);
  pnlInner.Parent := pnlOuter;
  pnlInner.SetBounds(1, 1, 148, 38);
  pnlInner.BevelOuter := bvNone;
  pnlInner.Color := CLR_WHITE;
  pnlInner.BorderWidth := 8;

  edtFechaDesde := TEdit.Create(pnlInner);
  edtFechaDesde.Parent := pnlInner;
  edtFechaDesde.Align := alClient;
  edtFechaDesde.BorderStyle := bsNone;
  edtFechaDesde.Font.Size := 11;
  edtFechaDesde.Font.Color := CLR_TEXT;
  edtFechaDesde.Color := CLR_WHITE;
  edtFechaDesde.OnChange := @Refrescar;
  edtFechaDesde.OnExit := @FechaExit;

  // Fecha Hasta
  Lbl := TLabel.Create(Self);
  Lbl.Parent := Pnl;
  Lbl.SetBounds(565, 28, 150, 16);
  Lbl.Caption := 'Hasta (dia-mes-año)';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_TEXT_MUTED;

  pnlOuter := TPanel.Create(Pnl);
  pnlOuter.Parent := Pnl;
  pnlOuter.SetBounds(720, 19, 150, 40);
  pnlOuter.BevelOuter := bvNone;
  pnlOuter.Color := CLR_BORDER;

  pnlInner := TPanel.Create(pnlOuter);
  pnlInner.Parent := pnlOuter;
  pnlInner.SetBounds(1, 1, 148, 38);
  pnlInner.BevelOuter := bvNone;
  pnlInner.Color := CLR_WHITE;
  pnlInner.BorderWidth := 8;

  edtFechaHasta := TEdit.Create(pnlInner);
  edtFechaHasta.Parent := pnlInner;
  edtFechaHasta.Align := alClient;
  edtFechaHasta.BorderStyle := bsNone;
  edtFechaHasta.Font.Size := 11;
  edtFechaHasta.Font.Color := CLR_TEXT;
  edtFechaHasta.Color := CLR_WHITE;
  edtFechaHasta.OnChange := @Refrescar;
  edtFechaHasta.OnExit := @FechaExit;

  // Placa
  Lbl := TLabel.Create(Self);
  Lbl.Parent := Pnl;
  Lbl.SetBounds(890, 28, 50, 16);
  Lbl.Caption := 'Placa';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_TEXT_MUTED;

  pnlOuter := TPanel.Create(Pnl);
  pnlOuter.Parent := Pnl;
  pnlOuter.SetBounds(945, 19, 130, 40);
  pnlOuter.BevelOuter := bvNone;
  pnlOuter.Color := CLR_BORDER;

  pnlInner := TPanel.Create(pnlOuter);
  pnlInner.Parent := pnlOuter;
  pnlInner.SetBounds(1, 1, 128, 38);
  pnlInner.BevelOuter := bvNone;
  pnlInner.Color := CLR_WHITE;
  pnlInner.BorderWidth := 8;

  edtPlaca := TEdit.Create(pnlInner);
  edtPlaca.Parent := pnlInner;
  edtPlaca.Align := alClient;
  edtPlaca.BorderStyle := bsNone;
  edtPlaca.Font.Size := 11;
  edtPlaca.Font.Color := CLR_TEXT;
  edtPlaca.Color := CLR_WHITE;
  edtPlaca.OnChange := @Refrescar;

  // Boton GENERAR PDF
  pnlPDF := TPanel.Create(Self);
  pnlPDF.Parent := Pnl;
  pnlPDF.Width := 140;
  pnlPDF.Height := 36;
  pnlPDF.Top := 14;
  pnlPDF.Anchors := [akTop, akRight];
  pnlPDF.BorderSpacing.Right := 8;
  pnlPDF.BevelOuter := bvNone;
  pnlPDF.Color := CLR_PRIMARY;
  pnlPDF.ParentBackground := False;
  pnlPDF.ParentColor := False;
  pnlPDF.Cursor := crHandPoint;
  pnlPDF.OnClick := @btnPDFClick;
  pnlPDF.OnPaint := @PaintRounded;

  lblPDF := TLabel.Create(Self);
  lblPDF.Parent := pnlPDF;
  lblPDF.Align := alClient;
  lblPDF.Alignment := taCenter;
  lblPDF.Layout := tlCenter;
  lblPDF.Caption := 'Generar PDF';
  lblPDF.Font.Size := 12;
  lblPDF.Font.Style := [];
  lblPDF.Font.Color := CLR_WHITE;
  lblPDF.Transparent := True;
  lblPDF.ParentColor := False;
  lblPDF.OnClick := @btnPDFClick;

  // ═══ Card contenedor ═══
  pnlCard := TPanel.Create(Self);
  pnlCard.Parent := Self;
  pnlCard.Align := alClient;
  pnlCard.BorderSpacing.Top := 30;
  pnlCard.BorderSpacing.Left := 24;
  pnlCard.BorderSpacing.Right := 24;
  pnlCard.BorderSpacing.Bottom := 24;
  pnlCard.BevelOuter := bvLowered;
  pnlCard.BevelInner := bvNone;
  pnlCard.BevelWidth := 1;
  pnlCard.Color := CLR_CARD;

  // ═══ Grid ═══
  Grid := TStringGrid.Create(Self);
  Grid.Parent := pnlCard;
  Grid.Align := alClient;
  Grid.BorderSpacing.Around := 2;
  Grid.ScrollBars := ssAutoBoth;
  Grid.ColCount := 15;
  Grid.RowCount := 2;
  Grid.FixedRows := 1;
  Grid.FixedCols := 0;
  Grid.Options := Grid.Options + [goRowSelect];
  Grid.DefaultRowHeight := 36;
  Grid.RowHeights[0] := 40;
  Grid.Color := CLR_CARD;
  Grid.FixedColor := CLR_CARD;
  Grid.Font.Height := -12;
  Grid.Font.Color := CLR_TEXT_HEADING;
  Grid.TitleFont.Height := -10;
  Grid.TitleFont.Style := [fsBold];
  Grid.TitleFont.Color := CLR_TEXT_SLATE;
  Grid.GridLineWidth := 0;
  Grid.GridLineColor := CLR_BORDER_LIGHT;
  Grid.Flat := True;
  Grid.FocusRectVisible := False;
  Grid.BorderStyle := bsNone;

  Grid.Cells[0, 0] := 'ID';
  Grid.Cells[1, 0] := 'Fecha';
  Grid.Cells[2, 0] := 'Hora';
  Grid.Cells[3, 0] := 'Chofer';
  Grid.Cells[4, 0] := 'Placa';
  Grid.Cells[5, 0] := 'Proveedor';
  Grid.Cells[6, 0] := 'Producto';
  Grid.Cells[7, 0] := 'Origen';
  Grid.Cells[8, 0] := 'Destino';
  Grid.Cells[9, 0] := 'P. Bruto';
  Grid.Cells[10, 0] := 'P. Tara';
  Grid.Cells[11, 0] := 'P. Neto';
  Grid.Cells[12, 0] := 'Costo';
  Grid.Cells[13, 0] := 'Flete';
  Grid.Cells[14, 0] := 'Estado';

  Grid.ColWidths[0] := 50;
  Grid.ColWidths[1] := 75;
  Grid.ColWidths[2] := 55;
  Grid.ColWidths[3] := 160;
  Grid.ColWidths[4] := 90;
  Grid.ColWidths[5] := 160;
  Grid.ColWidths[6] := 140;
  Grid.ColWidths[7] := 140;
  Grid.ColWidths[8] := 140;
  Grid.ColWidths[9] := 85;
  Grid.ColWidths[10] := 85;
  Grid.ColWidths[11] := 85;
  Grid.ColWidths[12] := 85;
  Grid.ColWidths[13] := 85;
  Grid.ColWidths[14] := 110;

  Grid.OnDrawCell := @GridDrawCell;
  Grid.OnMouseMove := @GridMouseMove;

  Refrescar(nil);
end;

destructor TFrameReportes.Destroy;
begin
  inherited Destroy;
end;

procedure TFrameReportes.Refrescar(Sender: TObject);
var
  Q: TSQLQuery;
  SQL, Filtro, FechaDesde, FechaHasta, Placa, FechaStr: string;
  Row: Integer;
begin
  if (DM = nil) or (not DM.Conexion.Connected) then Exit;

  FechaDesde := ConvertirFechaISO(Trim(edtFechaDesde.Text));
  FechaHasta := ConvertirFechaISO(Trim(edtFechaHasta.Text));
  Placa := Trim(edtPlaca.Text);

  SQL :=
    'SELECT p.id, p.fecha_creacion, ' +
    'COALESCE(pe.nombre,'''') as chofer_nombre, ' +
    'COALESCE(pe.apellido_paterno,'''') as chofer_ap, ' +
    'COALESCE(pe.apellido_materno,'''') as chofer_am, ' +
    'COALESCE(v.placa,'''') as vehiculo_placa, ' +
    'COALESCE(pr.nombre||'' ''||pr.apellido_paterno||'' ''||pr.apellido_materno,'''') as proveedor_nombre, ' +
    'COALESCE(prod.nombre,'''') as producto_nombre, ' +
    'COALESCE(o.nombre,'''') as origen_nombre, ' +
    'COALESCE(d.nombre,'''') as destino_nombre, ' +
    'p.peso_bruto, p.tara, p.peso_neto, p.costo_bs, p.flete_bs_pendiente, ' +
    'p.estado ' +
    'FROM pesajes p ' +
    'LEFT JOIN vehiculos v ON v.id=p.vehiculo_id ' +
    'LEFT JOIN choferes ch ON ch.id=p.chofer_id ' +
    'LEFT JOIN personas pe ON pe.id=ch.persona_id ' +
    'LEFT JOIN personas pr ON pr.id=(SELECT persona_id FROM proveedores WHERE id=p.proveedor_id) ' +
    'LEFT JOIN productos prod ON prod.id=p.producto_id ' +
    'LEFT JOIN origenes o ON o.id=p.id_origen ' +
    'LEFT JOIN destinos d ON d.id=p.id_destino ' +
    'WHERE 1=1';

  if FechaDesde <> '' then
    SQL := SQL + ' AND p.fecha_creacion >= ''' + FechaDesde + ' 00:00:00''';
  if FechaHasta <> '' then
    SQL := SQL + ' AND p.fecha_creacion <= ''' + FechaHasta + ' 23:59:59''';
  if Placa <> '' then
    SQL := SQL + ' AND UPPER(v.placa) LIKE ''%' +
      StringReplace(UpperCase(Placa), '''', '''''', [rfReplaceAll]) + '%''';

  SQL := SQL + ' ORDER BY p.id DESC';

  Q := DM.AbrirQuery(SQL);
  try
    Grid.RowCount := Q.RecordCount + 1;
    if Q.RecordCount = 0 then Exit;
    Row := 1;
    while not Q.EOF do
    begin
      Grid.Objects[0, Row] := TObject(PtrInt(Q.Fields[0].AsInteger));

      Grid.Cells[0, Row] := Q.Fields[0].AsString;

      FechaStr := Q.Fields[1].AsString;
      if Length(FechaStr) >= 16 then
      begin
        Grid.Cells[1, Row] := Copy(FechaStr, 9, 2) + '/' + Copy(FechaStr, 6, 2) + '/' + Copy(FechaStr, 1, 4);
        Grid.Cells[2, Row] := Copy(FechaStr, 12, 5);
      end
      else
      begin
        Grid.Cells[1, Row] := Copy(FechaStr, 1, 10);
        Grid.Cells[2, Row] := '';
      end;

      Grid.Cells[3, Row]  := UpperCase(Trim(Q.Fields[2].AsString + ' ' +
        Q.Fields[3].AsString + ' ' + Q.Fields[4].AsString));
      Grid.Cells[4, Row]  := UpperCase(Q.Fields[5].AsString);
      Grid.Cells[5, Row]  := UpperCase(Q.Fields[6].AsString);
      Grid.Cells[6, Row]  := UpperCase(Q.Fields[7].AsString);
      Grid.Cells[7, Row]  := UpperCase(Q.Fields[8].AsString);
      Grid.Cells[8, Row]  := UpperCase(Q.Fields[9].AsString);
      Grid.Cells[9, Row]  := FormatFloat('#,##0.00', Q.Fields[10].AsInteger) + ' kg';
      Grid.Cells[10, Row] := FormatFloat('#,##0.00', Q.Fields[11].AsInteger) + ' kg';
      Grid.Cells[11, Row] := FormatFloat('#,##0.00', Q.Fields[12].AsInteger) + ' kg';
      Grid.Cells[12, Row] := 'Bs ' + FormatFloat('#,##0.00', Q.Fields[13].AsInteger);
      Grid.Cells[13, Row] := 'Bs ' + FormatFloat('#,##0.00', Q.Fields[14].AsInteger);
      Grid.Cells[14, Row] := UpperCase(Q.Fields[15].AsString);

      Q.Next;
      Inc(Row);
    end;
  finally
    Q.Close;
  end;
end;

procedure TFrameReportes.FechaExit(Sender: TObject);
var
  Ed: TEdit;
begin
  Ed := TEdit(Sender);
  if Trim(Ed.Text) <> '' then
  begin
    Ed.Text := ConvertirFechaISO(Ed.Text);
    Refrescar(nil);
  end;
end;

procedure TFrameReportes.btnPDFClick(Sender: TObject);
var
  Stream: TMemoryStream;
  Ruta: string;
begin
  if Grid.RowCount <= 1 then
  begin
    ShowMessage('No hay resultados para generar el reporte.');
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    Stream := TMemoryStream.Create;
    try
      if not GenerarReportePDF(edtFechaDesde.Text, edtFechaHasta.Text, edtPlaca.Text, Stream) then
      begin
        ShowMessage('No se pudo generar el reporte.');
        Exit;
      end;
      Ruta := '/tmp/reporte-pesaje.pdf';
      Stream.SaveToFile(Ruta);
      OpenDocument(Ruta);
    finally
      Stream.Free;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TFrameReportes.GridDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var
  Ts: TTextStyle;
  IsSelected: Boolean;
  BadgeText: string;
begin
  if aRow = 0 then
  begin
    Grid.Canvas.Brush.Color := CLR_CARD;
    Grid.Canvas.FillRect(aRect);
    Grid.Canvas.Pen.Color := CLR_SIDEBAR_BORDER;
    Grid.Canvas.Line(aRect.Left, aRect.Bottom - 1, aRect.Right, aRect.Bottom - 1);
    Ts := Grid.Canvas.TextStyle;
    Ts.Alignment := taCenter;
    Ts.Layout := tlCenter;
    Grid.Canvas.TextRect(aRect, aRect.Left, aRect.Top + 2, Grid.Cells[aCol, aRow], Ts);
    Exit;
  end;

  IsSelected := gdSelected in aState;

  // Columna Estado: badge coloreado centrado
  if aCol = 14 then
  begin
    if IsSelected then
      Grid.Canvas.Brush.Color := CLR_TABLE_ROW_HOVER
    else
      Grid.Canvas.Brush.Color := CLR_CARD;
    Grid.Canvas.FillRect(aRect);

    BadgeText := Grid.Cells[14, aRow];
    if BadgeText = 'ACTIVO' then
    begin
      Grid.Canvas.Brush.Color := CLR_SUCCESS_BG;
      Grid.Canvas.Font.Color := CLR_TEAL;
    end
    else
    begin
      Grid.Canvas.Brush.Color := CLR_DESTRUCTIVE_BG;
      Grid.Canvas.Font.Color := CLR_DESTRUCTIVE;
    end;

    Grid.Canvas.Pen.Style := psClear;
    Grid.Canvas.RoundRect(
      aRect.Left + 8, aRect.Top + 6,
      aRect.Right - 8, aRect.Top + 30,
      12, 12);

    Grid.Canvas.Font.Height := -11;
    Grid.Canvas.Font.Style := [fsBold];
    Ts := Grid.Canvas.TextStyle;
    Ts.Alignment := taCenter;
    Ts.Layout := tlCenter;
    Grid.Canvas.TextRect(aRect, aRect.Left, aRect.Top, BadgeText, Ts);
    Exit;
  end;

  if IsSelected then
    Grid.Canvas.Brush.Color := CLR_TABLE_ROW_HOVER
  else
    Grid.Canvas.Brush.Color := CLR_CARD;

  Grid.Canvas.FillRect(aRect);

  Ts := Grid.Canvas.TextStyle;
  Ts.Alignment := taCenter;
  Ts.Layout := tlCenter;
  Grid.Canvas.Font.Height := -12;
  Grid.Canvas.Font.Color := CLR_TEXT_HEADING;
  Grid.Canvas.Font.Style := [];
  Grid.Canvas.TextRect(aRect, aRect.Left + 4, aRect.Top + 2, Grid.Cells[aCol, aRow], Ts);

  if aCol = 0 then
  begin
    Grid.Canvas.Pen.Color := CLR_SIDEBAR_BORDER;
    Grid.Canvas.Line(aRect.Left, aRect.Bottom - 1, aRect.Right, aRect.Bottom - 1);
  end;
end;

procedure TFrameReportes.GridMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var Col, Row: Integer;
begin
  Grid.MouseToCell(X, Y, Col, Row);
  if (Row < 1) or (Row >= Grid.RowCount) then Row := 0;
  if FHoverRow <> Row then
  begin
    if (FHoverRow > 0) and (FHoverRow < Grid.RowCount) then
      Grid.InvalidateRow(FHoverRow);
    FHoverRow := Row;
    if Row > 0 then
      Grid.InvalidateRow(Row);
  end;
end;

end.
