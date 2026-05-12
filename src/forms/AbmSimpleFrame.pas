unit AbmSimpleFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Grids, sqldb, DataModule, Utils, Theme, LoginForm;

type
  TTablaConfig = record
    Nombre: string;
    TituloSingular: string;
    TituloPlural: string;
    CamposGrid: array of string;
    AnchosGrid: array of Integer;
    CamposEdit: array of string;
    LabelsEdit: array of string;
    CampoBusqueda: string;
  end;

  { TFrameAbmSimple }

  TFrameAbmSimple = class(TFrame)
  private
    FConfig: TTablaConfig;
    FSG: TStringGrid;
    FEditBuscar: TEdit;
    FBtnNuevo, FBtnEditar, FBtnEliminar: TButton;
    FLblTitulo: TLabel;
    procedure CrearUI;
    procedure RefrescarGrid(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnEditarClick(Sender: TObject);
    procedure btnEliminarClick(Sender: TObject);
    procedure FSGSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    function GetIdSeleccionado: Integer;
    procedure AbrirEditor(EsNuevo: Boolean);
  public
    constructor CreateWithConfig(AOwner: TComponent; const AConfig: TTablaConfig);
  end;

function ConfigProductos: TTablaConfig;
function ConfigOrigenes: TTablaConfig;
function ConfigDestinos: TTablaConfig;
function ConfigBodegas: TTablaConfig;

implementation

{$R *.lfm}

function ConfigProductos: TTablaConfig;
begin
  Result.Nombre := 'productos';
  Result.TituloSingular := 'Producto';
  Result.TituloPlural := 'Productos';
  SetLength(Result.CamposGrid, 4);
  Result.CamposGrid[0] := 'ID'; Result.CamposGrid[1] := 'Nombre';
  Result.CamposGrid[2] := 'Descripcion'; Result.CamposGrid[3] := 'Estado';
  SetLength(Result.AnchosGrid, 4);
  Result.AnchosGrid[0] := 50; Result.AnchosGrid[1] := 200;
  Result.AnchosGrid[2] := 300; Result.AnchosGrid[3] := 80;
  SetLength(Result.CamposEdit, 2);
  Result.CamposEdit[0] := 'nombre'; Result.CamposEdit[1] := 'descripcion';
  SetLength(Result.LabelsEdit, 2);
  Result.LabelsEdit[0] := 'Nombre'; Result.LabelsEdit[1] := 'Descripcion';
  Result.CampoBusqueda := 'nombre';
end;

function ConfigOrigenes: TTablaConfig;
begin
  Result.Nombre := 'origenes';
  Result.TituloSingular := 'Origen';
  Result.TituloPlural := 'Origenes';
  SetLength(Result.CamposGrid, 4);
  Result.CamposGrid[0]:='ID'; Result.CamposGrid[1]:='Nombre';
  Result.CamposGrid[2]:='Descripcion'; Result.CamposGrid[3]:='Estado';
  SetLength(Result.AnchosGrid, 4);
  Result.AnchosGrid[0]:=50; Result.AnchosGrid[1]:=200;
  Result.AnchosGrid[2]:=300; Result.AnchosGrid[3]:=80;
  SetLength(Result.CamposEdit, 2);
  Result.CamposEdit[0]:='nombre'; Result.CamposEdit[1]:='descripcion';
  SetLength(Result.LabelsEdit, 2);
  Result.LabelsEdit[0]:='Nombre'; Result.LabelsEdit[1]:='Descripcion';
  Result.CampoBusqueda := 'nombre';
end;

function ConfigDestinos: TTablaConfig;
begin
  Result.Nombre := 'destinos';
  Result.TituloSingular := 'Destino';
  Result.TituloPlural := 'Destinos';
  SetLength(Result.CamposGrid, 4);
  Result.CamposGrid[0]:='ID'; Result.CamposGrid[1]:='Nombre';
  Result.CamposGrid[2]:='Descripcion'; Result.CamposGrid[3]:='Estado';
  SetLength(Result.AnchosGrid, 4);
  Result.AnchosGrid[0]:=50; Result.AnchosGrid[1]:=200;
  Result.AnchosGrid[2]:=300; Result.AnchosGrid[3]:=80;
  SetLength(Result.CamposEdit, 2);
  Result.CamposEdit[0]:='nombre'; Result.CamposEdit[1]:='descripcion';
  SetLength(Result.LabelsEdit, 2);
  Result.LabelsEdit[0]:='Nombre'; Result.LabelsEdit[1]:='Descripcion';
  Result.CampoBusqueda := 'nombre';
end;

function ConfigBodegas: TTablaConfig;
begin
  Result.Nombre := 'bodegas';
  Result.TituloSingular := 'Bodega';
  Result.TituloPlural := 'Bodegas';
  SetLength(Result.CamposGrid, 5);
  Result.CamposGrid[0]:='ID'; Result.CamposGrid[1]:='Nombre';
  Result.CamposGrid[2]:='Descripcion'; Result.CamposGrid[3]:='Ubicacion';
  Result.CamposGrid[4]:='Estado';
  SetLength(Result.AnchosGrid, 5);
  Result.AnchosGrid[0]:=50; Result.AnchosGrid[1]:=150;
  Result.AnchosGrid[2]:=200; Result.AnchosGrid[3]:=150; Result.AnchosGrid[4]:=80;
  SetLength(Result.CamposEdit, 3);
  Result.CamposEdit[0]:='nombre'; Result.CamposEdit[1]:='descripcion';
  Result.CamposEdit[2]:='ubicacion';
  SetLength(Result.LabelsEdit, 3);
  Result.LabelsEdit[0]:='Nombre'; Result.LabelsEdit[1]:='Descripcion';
  Result.LabelsEdit[2]:='Ubicacion';
  Result.CampoBusqueda := 'nombre';
end;

constructor TFrameAbmSimple.CreateWithConfig(AOwner: TComponent; const AConfig: TTablaConfig);
begin
  FConfig := AConfig;
  inherited Create(AOwner);
  CrearUI;
  RefrescarGrid(nil);
end;

procedure TFrameAbmSimple.CrearUI;
var
  PnlTop: TPanel;
  i: Integer;
begin
  Self.Color := CLR_BG;

  PnlTop := TPanel.Create(Self);
  PnlTop.Parent := Self;
  PnlTop.Align := alTop;
  PnlTop.Height := 56;
  PnlTop.BevelOuter := bvNone;
  PnlTop.Color := CLR_CARD;

  FLblTitulo := TLabel.Create(Self);
  FLblTitulo.Parent := PnlTop;
  FLblTitulo.SetBounds(24, 14, 300, 28);
  FLblTitulo.Caption := FConfig.TituloPlural;
  FLblTitulo.Font.Height := -18;
  FLblTitulo.Font.Style := [fsBold];
  
  FLblTitulo.Font.Color := $333333;

  FEditBuscar := TEdit.Create(Self);
  FEditBuscar.Parent := PnlTop;
  FEditBuscar.SetBounds(350, 14, 220, 28);
  FEditBuscar.Font.Size := 12;
  FEditBuscar.TextHint := 'Buscar...';
  FEditBuscar.OnChange := @RefrescarGrid;

  FBtnNuevo := TButton.Create(Self);
  FBtnNuevo.Parent := PnlTop;
  FBtnNuevo.SetBounds(580, 12, 100, 32);
  FBtnNuevo.Caption := '+ Nuevo';
  FBtnNuevo.Font.Style := [fsBold];
  FBtnNuevo.Font.Color := CLR_PRIMARY;
  
  FBtnNuevo.OnClick := @btnNuevoClick;

  FSG := TStringGrid.Create(Self);
  FSG.Parent := Self;
  FSG.SetBounds(24, 72, Self.ClientWidth - 48, Self.ClientHeight - 152);
  FSG.Anchors := [akTop, akLeft, akRight, akBottom];
  FSG.ColCount := Length(FConfig.CamposGrid);
  FSG.RowCount := 2;
  FSG.FixedRows := 1;
  FSG.FixedCols := 0;
  FSG.Color := CLR_CARD;
  FSG.FixedColor := CLR_TABLE_HEADER;
  FSG.ParentFont := False;
  FSG.Font.Color := CLR_TEXT;
  FSG.Options := FSG.Options + [goRowSelect];
  FSG.ScrollBars := ssAutoBoth;
  FSG.GridLineWidth := 1;
  FSG.DefaultRowHeight := 26;
  for i := 0 to High(FConfig.CamposGrid) do
    FSG.Cells[i, 0] := FConfig.CamposGrid[i];
  for i := 0 to High(FConfig.AnchosGrid) do
    if i < Length(FConfig.AnchosGrid) then
      FSG.ColWidths[i] := FConfig.AnchosGrid[i];
  FSG.OnSelectCell := @FSGSelectCell;

  FBtnEditar := TButton.Create(Self);
  FBtnEditar.Parent := Self;
  FBtnEditar.SetBounds(24, Self.ClientHeight - 60, 100, 32);
  FBtnEditar.Anchors := [akLeft, akBottom];
  FBtnEditar.Caption := 'Editar';
  FBtnEditar.Font.Size := 12;
  FBtnEditar.Enabled := False;
  FBtnEditar.OnClick := @btnEditarClick;

  FBtnEliminar := TButton.Create(Self);
  FBtnEliminar.Parent := Self;
  FBtnEliminar.SetBounds(132, Self.ClientHeight - 60, 160, 32);
  FBtnEliminar.Anchors := [akLeft, akBottom];
  FBtnEliminar.Caption := 'Activar/Desactivar';
  FBtnEliminar.Font.Size := 12;
  FBtnEliminar.Enabled := False;
  FBtnEliminar.OnClick := @btnEliminarClick;
end;

procedure TFrameAbmSimple.RefrescarGrid(Sender: TObject);
var
  Q: TSQLQuery;
  Row, i: Integer;
  Filtro, Columnas: string;
  J: Integer;
begin
  if (DM = nil) or (not DM.Conexion.Connected) then Exit;

  Columnas := '';
  for J := 0 to High(FConfig.CamposEdit) do
  begin
    Columnas := Columnas + FConfig.CamposEdit[J];
    if J < High(FConfig.CamposEdit) then Columnas := Columnas + ', ';
  end;

  Filtro := Trim(FEditBuscar.Text);
  if Filtro <> '' then
    Filtro := ' WHERE ' + FConfig.CampoBusqueda + ' LIKE ''%' +
      StringReplace(Filtro, '''', '''''', [rfReplaceAll]) + '%'''
  else
    Filtro := '';

  Q := DM.AbrirQuery('SELECT id, ' + Columnas + ', estado FROM ' +
    FConfig.Nombre + Filtro + ' ORDER BY id DESC');

  FSG.RowCount := Q.RecordCount + 1;
  Row := 1;
  while not Q.EOF do
  begin
    FSG.Cells[0, Row] := Q.Fields[0].AsString;
    for i := 0 to High(FConfig.CamposEdit) do
      FSG.Cells[i + 1, Row] := Q.Fields[i + 1].AsString;
    FSG.Cells[Length(FConfig.CamposGrid) - 1, Row] := Q.FieldByName('estado').AsString;
    Q.Next;
    Inc(Row);
  end;
  Q.Close;

  FBtnEditar.Enabled := False;
  FBtnEliminar.Enabled := False;
end;

procedure TFrameAbmSimple.FSGSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
begin
  FBtnEditar.Enabled := (aRow >= 1) and (FSG.Cells[0, aRow] <> '');
  FBtnEliminar.Enabled := FBtnEditar.Enabled;
end;

function TFrameAbmSimple.GetIdSeleccionado: Integer;
begin
  Result := StrToIntDef(FSG.Cells[0, FSG.Row], 0);
end;

procedure TFrameAbmSimple.btnNuevoClick(Sender: TObject);
begin
  AbrirEditor(True);
end;

procedure TFrameAbmSimple.btnEditarClick(Sender: TObject);
begin
  if GetIdSeleccionado > 0 then
    AbrirEditor(False);
end;

procedure TFrameAbmSimple.btnEliminarClick(Sender: TObject);
var
  ID: Integer;
  EstadoActual, NuevoEstado, Msg: string;
begin
  ID := GetIdSeleccionado;
  if ID = 0 then Exit;
  EstadoActual := FSG.Cells[Length(FConfig.CamposGrid) - 1, FSG.Row];
  if EstadoActual = 'ACTIVO' then
  begin
    NuevoEstado := 'INACTIVO';
    Msg := 'Desactivar registro #' + IntToStr(ID) + '?';
  end
  else
  begin
    NuevoEstado := 'ACTIVO';
    Msg := 'Reactivar registro #' + IntToStr(ID) + '?';
  end;

  if MessageDlg('Confirmar', Msg, mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  DM.EjecutarSQL('UPDATE ' + FConfig.Nombre + ' SET estado = ''' + NuevoEstado +
    ''', fecha_modificacion = ''' + FechaHoraActual + ''' WHERE id = ' + IntToStr(ID));
  RefrescarGrid(nil);
end;

procedure TFrameAbmSimple.AbrirEditor(EsNuevo: Boolean);
var
  EditID, i, y: Integer;
  F: TForm;
  Lbl: TLabel;
  Edits: array of TEdit;
  Q: TSQLQuery;
  SQL, NowStr: string;
  J: Integer;
begin
  if EsNuevo then EditID := 0 else EditID := GetIdSeleccionado;
  if (not EsNuevo) and (EditID = 0) then Exit;

  F := TForm.Create(nil);
  try
    if EsNuevo then
      F.Caption := 'Nuevo ' + FConfig.TituloSingular
    else
      F.Caption := 'Editar ' + FConfig.TituloSingular + ' #' + IntToStr(EditID);

    F.Width := 420;
    F.Height := 80 + Length(FConfig.CamposEdit) * 68 + 60;
    F.Position := poOwnerFormCenter;
    F.BorderStyle := bsDialog;

    y := 16;
    SetLength(Edits, Length(FConfig.CamposEdit));

    for i := 0 to High(FConfig.CamposEdit) do
    begin
      Lbl := TLabel.Create(F); Lbl.Parent := F;
      Lbl.SetBounds(24, y, 360, 16);
      Lbl.Caption := FConfig.LabelsEdit[i]; Lbl.Font.Style := [fsBold];
  
      Inc(y, 20);
      Edits[i] := TEdit.Create(F); Edits[i].Parent := F;
      Edits[i].SetBounds(24, y, 360, 32); Edits[i].Font.Size := 12;
      Inc(y, 52);
    end;

    with TButton.Create(F) do
    begin Parent := F; SetBounds(100, y + 8, 100, 36);
      Caption := 'Guardar'; Font.Style := [fsBold]; ModalResult := mrOK; end;
    with TButton.Create(F) do
    begin Parent := F; SetBounds(210, y + 8, 100, 36);
      Caption := 'Cancelar'; ModalResult := mrCancel; end;

    if EditID > 0 then
    begin
      SQL := '';
      for J := 0 to High(FConfig.CamposEdit) do
      begin
        SQL := SQL + FConfig.CamposEdit[J];
        if J < High(FConfig.CamposEdit) then SQL := SQL + ', ';
      end;
      Q := DM.AbrirQuery('SELECT ' + SQL + ' FROM ' + FConfig.Nombre + ' WHERE id=' + IntToStr(EditID));
      if not Q.EOF then
        for i := 0 to High(FConfig.CamposEdit) do
          Edits[i].Text := Q.Fields[i].AsString;
      Q.Close;
    end;

    if F.ShowModal <> mrOK then Exit;

    for i := 0 to High(Edits) do
      if Trim(Edits[i].Text) = '' then
      begin
        ShowMessage('"' + FConfig.LabelsEdit[i] + '" es obligatorio');
        Edits[i].SetFocus;
        Exit;
      end;

    NowStr := FechaHoraActual;

    if EditID > 0 then
    begin
      SQL := 'UPDATE ' + FConfig.Nombre + ' SET ';
      for J := 0 to High(FConfig.CamposEdit) do
      begin
        SQL := SQL + FConfig.CamposEdit[J] + ' = ''' +
          StringReplace(Trim(Edits[J].Text), '''', '''''', [rfReplaceAll]) + '''';
        if J < High(FConfig.CamposEdit) then SQL := SQL + ', ';
      end;
      SQL := SQL + ', fecha_modificacion = ''' + NowStr + ''' WHERE id = ' + IntToStr(EditID);
    end
    else
    begin
      SQL := 'INSERT INTO ' + FConfig.Nombre + ' (';
      for J := 0 to High(FConfig.CamposEdit) do
      begin
        SQL := SQL + FConfig.CamposEdit[J];
        if J < High(FConfig.CamposEdit) then SQL := SQL + ', ';
      end;
      SQL := SQL + ', estado, fecha_creacion, fecha_modificacion) VALUES (';
      for J := 0 to High(FConfig.CamposEdit) do
      begin
        SQL := SQL + '''' + StringReplace(Trim(Edits[J].Text), '''', '''''', [rfReplaceAll]) + '''';
        if J < High(FConfig.CamposEdit) then SQL := SQL + ', ';
      end;
      SQL := SQL + ', ''ACTIVO'', ''' + NowStr + ''', ''' + NowStr + ''')';
    end;

    DM.Transaccion.StartTransaction;
    try
      DM.EjecutarSQL(SQL);
      DM.Transaccion.Commit;
    except
      on E: Exception do
      begin
        DM.Transaccion.Rollback;
        ShowMessage('Error: ' + E.Message);
        Exit;
      end;
    end;

    RefrescarGrid(nil);
  finally
    F.Free;
  end;
end;

end.
