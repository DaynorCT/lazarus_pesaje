unit BoletaConfigFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Grids, sqldb, DataModule, Utils, Theme;

type
  { TFrameBoletaConfig }

  TFrameBoletaConfig = class(TFrame)
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  private
    Grid: TStringGrid;
    pnlCard: TPanel;
    FEditingID: Integer;
    FModalForm: TForm;
    FHoverRow: Integer;
    FHoverZone: Integer;
    FHintWindow: THintWindow;
    FHintTimer: TTimer;
    FHintActive: Boolean;
    procedure Refrescar(Sender: TObject);
    procedure GridDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
    procedure GridMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure GridMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure HintTimerTick(Sender: TObject);
    procedure MostrarHintAccion(const Texto: string);
    procedure PaintRounded(Sender: TObject);
    procedure GuardarClick(Sender: TObject);
    procedure CancelarClick(Sender: TObject);
    procedure ShowConfigForm(ID: Integer);
  end;

implementation

{$R *.lfm}

constructor TFrameBoletaConfig.Create(AOwner: TComponent);
var
  Pnl: TPanel;
  Lbl: TLabel;
begin
  inherited Create(AOwner);
  FEditingID := 0;
  Self.Color := CLR_BG;

  // Header
  Pnl := TPanel.Create(Self);
  Pnl.Parent := Self;
  Pnl.Align := alTop;
  Pnl.Height := 64;
  Pnl.BevelOuter := bvNone;
  Pnl.Color := CLR_BG;
  Pnl.BorderSpacing.Top := 15;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := Pnl;
  Lbl.SetBounds(24, 18, 400, 28);
  Lbl.Caption := 'Configuración Boleta';
  Lbl.Font.Height := -24;
  Lbl.Font.Style := [fsBold];
  Lbl.Font.Color := CLR_TEXT_HEADING;

  // Card contenedor de la tabla
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

  // Grid
  Grid := TStringGrid.Create(Self);
  Grid.Parent := pnlCard;
  Grid.Align := alClient;
  Grid.BorderSpacing.Around := 2;
  Grid.ScrollBars := ssAutoBoth;
  Grid.ColCount := 8;
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

  Grid.Cells[0, 0] := 'Título Superior';
  Grid.Cells[1, 0] := 'Título Documento';
  Grid.Cells[2, 0] := 'Marca';
  Grid.Cells[3, 0] := 'Salida';
  Grid.Cells[4, 0] := 'Ciudad';
  Grid.Cells[5, 0] := 'Celular';
  Grid.Cells[6, 0] := 'Acciones';
  Grid.Cells[7, 0] := 'ID';

  Grid.ColWidths[0] := 260;
  Grid.ColWidths[1] := 200;
  Grid.ColWidths[2] := 140;
  Grid.ColWidths[3] := 180;
  Grid.ColWidths[4] := 180;
  Grid.ColWidths[5] := 140;
  Grid.ColWidths[6] := 120;
  Grid.ColWidths[7] := 0;

  Grid.OnDrawCell := @GridDrawCell;
  Grid.OnMouseDown := @GridMouseDown;
  Grid.OnMouseMove := @GridMouseMove;
  FHintTimer := TTimer.Create(Self);
  FHintTimer.Interval := 400; FHintTimer.OnTimer := @HintTimerTick;
  FHintTimer.Enabled := False;
  FHintActive := False;

  Refrescar(nil);
end;

procedure TFrameBoletaConfig.Refrescar(Sender: TObject);
var
  Q: TSQLQuery;
  Row, ID: Integer;
begin
  if (DM = nil) or (not DM.Conexion.Connected) then Exit;

  Q := DM.AbrirQuery('SELECT * FROM boleta_config ORDER BY id LIMIT 1');

  if Q.EOF then
    Grid.RowCount := 1
  else
    Grid.RowCount := 2;

  Row := 1;
  while not Q.EOF do
  begin
    ID := Q.Fields[0].AsInteger;
    Grid.Objects[0, Row] := TObject(PtrInt(ID));
    Grid.Cells[0, Row] := UpperCase(Q.FieldByName('titulo_superior').AsString);
    Grid.Cells[1, Row] := UpperCase(Q.FieldByName('titulo_documento').AsString);
    Grid.Cells[2, Row] := UpperCase(Q.FieldByName('marca').AsString);
    Grid.Cells[3, Row] := UpperCase(Q.FieldByName('salida').AsString);
    Grid.Cells[4, Row] := UpperCase(Q.FieldByName('ciudad').AsString);
    Grid.Cells[5, Row] := UpperCase(Q.FieldByName('celular1').AsString);
    Grid.Cells[6, Row] := '✏️';
    Grid.Cells[7, Row] := IntToStr(ID);
    Q.Next;
    Inc(Row);
  end;
  Q.Close;
end;

procedure TFrameBoletaConfig.GridDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var
  Ts: TTextStyle;
  IsSelected: Boolean;
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

  // Columna Acciones: lápiz centrado
  if aCol = 6 then
  begin
    if IsSelected then
      Grid.Canvas.Brush.Color := CLR_TABLE_ROW_HOVER
    else
      Grid.Canvas.Brush.Color := CLR_CARD;
    Grid.Canvas.FillRect(aRect);

    if (aRow = FHoverRow) and (FHoverZone = 1) then
    begin
      Grid.Canvas.Brush.Color := CLR_SIDEBAR_ACTIVE;
      Grid.Canvas.Pen.Style := psClear;
      Grid.Canvas.RoundRect(aRect.Left + 12, aRect.Top + 4, aRect.Right - 12, aRect.Bottom - 4, 6, 6);
    end;

    Grid.Canvas.Font.Height := -13;
    Grid.Canvas.Font.Color := CLR_PRIMARY;
    Grid.Canvas.Font.Style := [fsBold];
    Ts := Grid.Canvas.TextStyle;
    Ts.Alignment := taCenter;
    Ts.Layout := tlCenter;
    Grid.Canvas.TextRect(aRect, aRect.Left, aRect.Top + 2, '✏️', Ts);
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
  Grid.Canvas.TextRect(aRect, aRect.Left + 6, aRect.Top + 2, Grid.Cells[aCol, aRow], Ts);

  if aCol = 0 then
  begin
    Grid.Canvas.Pen.Color := CLR_SIDEBAR_BORDER;
    Grid.Canvas.Line(aRect.Left, aRect.Bottom - 1, aRect.Right, aRect.Bottom - 1);
  end;
end;

procedure TFrameBoletaConfig.GridMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Col, Row: Integer;
  ID, TotalH, I: Integer;
begin
  if Button <> mbLeft then Exit;
  Grid.MouseToCell(X, Y, Col, Row);
  if (Row < 1) or (Row >= Grid.RowCount) then Exit;

  TotalH := 0;
  for I := 0 to Grid.RowCount - 1 do
    TotalH := TotalH + Grid.RowHeights[I];
  if Y > TotalH then Exit;

  if Col = 6 then
  begin
    ID := PtrInt(Grid.Objects[0, Row]);
    ShowConfigForm(ID);
  end;
end;

procedure TFrameBoletaConfig.GridMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  Col, Row: Integer;
  NewZone: Integer;
begin
  Grid.MouseToCell(X, Y, Col, Row);
  if (Col <> 6) or (Row < 1) or (Row >= Grid.RowCount) then
  begin
    NewZone := 0; Row := 0;
  end
  else
    NewZone := 1;

  if (FHoverRow <> Row) or (FHoverZone <> NewZone) then
  begin
    if (FHoverRow > 0) and (FHoverRow < Grid.RowCount) then
      Grid.InvalidateCell(6, FHoverRow);
    FHoverRow := Row;
    FHoverZone := NewZone;
    if (Row > 0) and (Row < Grid.RowCount) then
      Grid.InvalidateCell(6, Row);
    if FHintActive then
    begin
      FHintWindow.Hide;
      FHintActive := False;
    end;
    FHintTimer.Enabled := NewZone > 0;
  end;
end;

procedure TFrameBoletaConfig.HintTimerTick(Sender: TObject);
var
  Texto: string;
  P: TPoint;
begin
  FHintTimer.Enabled := False;
  if FHoverZone = 0 then Exit;
  Texto := 'Editar configuración';
  P := Mouse.CursorPos;
  MostrarHintAccion(Texto);
  FHintWindow.Top := P.Y + 20;
  FHintWindow.Left := P.X + 12;
  FHintWindow.Show;
  FHintActive := True;
end;

procedure TFrameBoletaConfig.MostrarHintAccion(const Texto: string);
var
  R: TRect;
begin
  if FHintWindow = nil then
  begin
    FHintWindow := THintWindow.Create(Self);
    FHintWindow.Color := CLR_TEXT;
    FHintWindow.Font.Size := 11;
    FHintWindow.Font.Color := CLR_WHITE;
  end;
  R := FHintWindow.CalcHintRect(250, Texto, nil);
  FHintWindow.ActivateHint(R, Texto);
end;

procedure TFrameBoletaConfig.PaintRounded(Sender: TObject);
var
  Pnl: TPanel;
begin
  Pnl := TPanel(Sender);
  Pnl.Canvas.Brush.Color := CLR_BG;
  Pnl.Canvas.FillRect(0, 0, Pnl.Width, Pnl.Height);
  Pnl.Canvas.Brush.Color := Pnl.Color;
  if Pnl.Tag = 1 then
  begin
    Pnl.Canvas.Pen.Color := CLR_INFO;
    Pnl.Canvas.Pen.Width := 1;
    Pnl.Canvas.RoundRect(1, 1, Pnl.Width - 1, Pnl.Height - 1, 8, 8);
  end
  else
  begin
    Pnl.Canvas.Pen.Style := psClear;
    Pnl.Canvas.RoundRect(0, 0, Pnl.Width, Pnl.Height, 8, 8);
  end;
end;

procedure TFrameBoletaConfig.GuardarClick(Sender: TObject);
begin
  FModalForm.ModalResult := mrOK;
end;

procedure TFrameBoletaConfig.CancelarClick(Sender: TObject);
begin
  FModalForm.ModalResult := mrCancel;
end;

procedure TFrameBoletaConfig.ShowConfigForm(ID: Integer);
var
  F: TForm;
  Lbl, LblSection: TLabel;
  eSalida, eDireccion, eCelular1, eCelular2, eCiudad: TEdit;
  eTituloSuperior, eMarca, eTituloDocumento, eAcreditacion: TEdit;
  Q: TSQLQuery;
  YPos: Integer;

  function MakeLabel(ATop, ALeft: Integer; ACaption: string): TLabel;
  begin
    Result := TLabel.Create(F);
    Result.Parent := F;
    Result.SetBounds(ALeft, ATop, 300, 16);
    Result.Caption := ACaption;
    Result.Font.Size := 11;
    Result.Font.Style := [];
    Result.Font.Color := CLR_TEXT_HEADING;
  end;

  function MakeEditConBorde(ATop, ALeft, AWidth: Integer): TEdit;
  var
    pnlOuter, pnlInner: TPanel;
  begin
    pnlOuter := TPanel.Create(F);
    pnlOuter.Parent := F;
    pnlOuter.SetBounds(ALeft, ATop, AWidth, 40);
    pnlOuter.BevelOuter := bvNone;
    pnlOuter.Color := CLR_BORDER;

    pnlInner := TPanel.Create(pnlOuter);
    pnlInner.Parent := pnlOuter;
    pnlInner.SetBounds(1, 1, AWidth - 2, 38);
    pnlInner.BevelOuter := bvNone;
    pnlInner.Color := CLR_WHITE;
    pnlInner.BorderWidth := 6;

    Result := TEdit.Create(pnlInner);
    Result.Parent := pnlInner;
    Result.Align := alClient;
    Result.BorderStyle := bsNone;
    Result.Font.Size := 11;
    Result.Font.Color := CLR_TEXT;
    Result.CharCase := ecUpperCase;
    Result.Color := CLR_WHITE;
  end;

begin
  Q := DM.AbrirQuery('SELECT * FROM boleta_config WHERE id = ' + IntToStr(ID));
  try
    if Q.EOF then
    begin
      Q.Close;
      Exit;
    end;

    F := TForm.Create(nil);
    FModalForm := F;
    try
      F.Caption := '';
      F.Width := 600;
      F.Position := poOwnerFormCenter;
      F.BorderStyle := bsDialog;
      F.Color := CLR_WHITE;

      // Header del modal
      with TPanel.Create(F) do
      begin
        Parent := F;
        Align := alTop;
        Height := 60;
        BevelOuter := bvNone;
        Color := CLR_WHITE;
        with TLabel.Create(F) do
        begin
          Parent := TPanel(F.Controls[F.ControlCount - 1]);
          SetBounds(24, 14, 400, 24);
          Caption := 'Editar configuración de boleta';
          Font.Size := 14;
          Font.Style := [];
          Font.Color := CLR_TEXT_HEADING;
        end;
        with TPanel.Create(F) do
        begin
          Parent := TPanel(F.Controls[F.ControlCount - 1]);
          Align := alBottom;
          Height := 1;
          BevelOuter := bvNone;
          Color := CLR_BORDER;
        end;
      end;

      YPos := 80;

      // Sección: Encabezado de boleta
      LblSection := TLabel.Create(F);
      LblSection.Parent := F;
      LblSection.SetBounds(24, YPos, 300, 20);
      LblSection.Caption := 'Encabezado de boleta';
      LblSection.Font.Size := 11;
      LblSection.Font.Style := [];
      LblSection.Font.Color := CLR_TEXT_HEADING;

      YPos := YPos + 33;

      // Título Superior | Título Documento
      MakeLabel(YPos, 24, 'Título superior');
      MakeLabel(YPos, 314, 'Título documento');
      YPos := YPos + 28;

      eTituloSuperior := MakeEditConBorde(YPos, 24, 280);
      eTituloSuperior.Text := UpperCase(Q.FieldByName('titulo_superior').AsString);
      eTituloDocumento := MakeEditConBorde(YPos, 314, 260);
      eTituloDocumento.Text := UpperCase(Q.FieldByName('titulo_documento').AsString);
      YPos := YPos + 48;

      // Marca | Acreditación
      MakeLabel(YPos, 24, 'Marca');
      MakeLabel(YPos, 314, 'Acreditación');
      YPos := YPos + 28;

      eMarca := MakeEditConBorde(YPos, 24, 280);
      eMarca.Text := UpperCase(Q.FieldByName('marca').AsString);
      eAcreditacion := MakeEditConBorde(YPos, 314, 260);
      if Q.FieldByName('acreditacion').AsString <> '' then
        eAcreditacion.Text := UpperCase(Q.FieldByName('acreditacion').AsString);
      YPos := YPos + 56;

      // Sección: Datos de contacto
      LblSection := TLabel.Create(F);
      LblSection.Parent := F;
      LblSection.SetBounds(24, YPos, 300, 20);
      LblSection.Caption := 'Datos de contacto';
      LblSection.Font.Size := 11;
      LblSection.Font.Style := [];
      LblSection.Font.Color := CLR_TEXT_HEADING;

      YPos := YPos + 33;

      // Salida | Dirección
      MakeLabel(YPos, 24, 'Salida');
      MakeLabel(YPos, 314, 'Dirección');
      YPos := YPos + 28;

      eSalida := MakeEditConBorde(YPos, 24, 280);
      eSalida.Text := UpperCase(Q.FieldByName('salida').AsString);
      eDireccion := MakeEditConBorde(YPos, 314, 260);
      eDireccion.Text := UpperCase(Q.FieldByName('direccion').AsString);
      YPos := YPos + 48;

      // Celular 1 | Celular 2
      MakeLabel(YPos, 24, 'Celular 1');
      MakeLabel(YPos, 314, 'Celular 2');
      YPos := YPos + 28;

      eCelular1 := MakeEditConBorde(YPos, 24, 280);
      eCelular1.Text := UpperCase(Q.FieldByName('celular1').AsString);
      eCelular2 := MakeEditConBorde(YPos, 314, 260);
      eCelular2.Text := UpperCase(Q.FieldByName('celular2').AsString);
      YPos := YPos + 48;

      // Ciudad
      MakeLabel(YPos, 24, 'Ciudad');
      YPos := YPos + 28;

      eCiudad := MakeEditConBorde(YPos, 24, 280);
      eCiudad.Text := UpperCase(Q.FieldByName('ciudad').AsString);
      YPos := YPos + 56;

      // Línea divisora
      with TPanel.Create(F) do
      begin
        Parent := F;
        SetBounds(24, YPos, 556, 1);
        BevelOuter := bvNone;
        Color := CLR_BORDER;
      end;
      YPos := YPos + 16;

      F.Height := YPos + 70;

      // CANCELAR
      with TPanel.Create(F) do
      begin
        Parent := F;
        SetBounds(310, YPos, 130, 36);
        BevelOuter := bvNone;
        Color := CLR_WHITE;
        Tag := 1;
        Cursor := crHandPoint;
        OnPaint := @PaintRounded;
        OnClick := @CancelarClick;
        with TLabel.Create(F) do
        begin
          Parent := TPanel(F.Controls[F.ControlCount - 1]);
          Align := alClient;
          Alignment := taCenter;
          Layout := tlCenter;
          Caption := 'CANCELAR';
          Font.Size := 12;
          Font.Style := [];
          Font.Color := CLR_PRIMARY;
          OnClick := @CancelarClick;
        end;
      end;

      // GUARDAR
      with TPanel.Create(F) do
      begin
        Parent := F;
        SetBounds(450, YPos, 130, 36);
        BevelOuter := bvNone;
        Color := CLR_PRIMARY;
        Cursor := crHandPoint;
        OnPaint := @PaintRounded;
        OnClick := @GuardarClick;
        with TLabel.Create(F) do
        begin
          Parent := TPanel(F.Controls[F.ControlCount - 1]);
          Align := alClient;
          Alignment := taCenter;
          Layout := tlCenter;
          Caption := 'GUARDAR';
          Font.Size := 12;
          Font.Style := [];
          Font.Color := CLR_WHITE;
          OnClick := @GuardarClick;
        end;
      end;

      if F.ShowModal = mrOK then
      begin
        if DM.Transaccion.Active then
          DM.Transaccion.Rollback;
        DM.Transaccion.StartTransaction;
        try
          DM.EjecutarSQL(
            'UPDATE boleta_config SET ' +
            'salida = '             + QuotedStr(UpperCase(Trim(eSalida.Text))) + ', ' +
            'direccion = '          + QuotedStr(UpperCase(Trim(eDireccion.Text))) + ', ' +
            'celular1 = '           + QuotedStr(UpperCase(Trim(eCelular1.Text))) + ', ' +
            'celular2 = '           + QuotedStr(UpperCase(Trim(eCelular2.Text))) + ', ' +
            'ciudad = '             + QuotedStr(UpperCase(Trim(eCiudad.Text))) + ', ' +
            'titulo_superior = '    + QuotedStr(UpperCase(Trim(eTituloSuperior.Text))) + ', ' +
            'marca = '              + QuotedStr(UpperCase(Trim(eMarca.Text))) + ', ' +
            'titulo_documento = '   + QuotedStr(UpperCase(Trim(eTituloDocumento.Text))) + ', ' +
            'acreditacion = '       + QuotedStr(UpperCase(Trim(eAcreditacion.Text))) + ', ' +
            'fecha_modificacion = ''' + FechaHoraActual +
            ''' WHERE id = ' + IntToStr(ID));

          DM.Transaccion.Commit;
          Refrescar(nil);
        except
          DM.Transaccion.Rollback;
          ShowMessage('Error al guardar configuración.');
        end;
      end;
    finally
      F.Free;
    end;
  finally
    Q.Close;
  end;
end;

destructor TFrameBoletaConfig.Destroy;
begin
  if FHintWindow <> nil then FreeAndNil(FHintWindow);
  inherited Destroy;
end;

end.
