unit VehiculosFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Grids, sqldb, DataModule, Utils, Theme;

type
  { TFrameVehiculos }

  TFrameVehiculos = class(TFrame)
    constructor Create(AOwner: TComponent); override;
  private
    Grid: TStringGrid;
    edtBuscar: TEdit;
    btnNuevo, btnEditar, btnEliminar: TButton;
    procedure Refrescar(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnEditarClick(Sender: TObject);
    procedure btnEliminarClick(Sender: TObject);
    procedure GridSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    function GetSelectedID: Integer;
  end;

implementation

{$R *.lfm}

constructor TFrameVehiculos.Create(AOwner: TComponent);
var
  PnlTop: TPanel;
  Lbl: TLabel;
begin
  inherited Create(AOwner);
  Self.Color := CLR_BG;

  PnlTop := TPanel.Create(Self);
  PnlTop.Parent := Self;
  PnlTop.Align := alTop;
  PnlTop.Height := 56;
  PnlTop.BevelOuter := bvNone;
  PnlTop.Color := CLR_CARD;

  Lbl := TLabel.Create(Self); Lbl.Parent := PnlTop;
  Lbl.SetBounds(24, 14, 200, 28);
  Lbl.Caption := 'Vehículos'; Lbl.Font.Height := -18;
  Lbl.Font.Style := [fsBold]; Lbl.Font.Color := $333333;

  edtBuscar := TEdit.Create(Self); edtBuscar.Parent := PnlTop;
  edtBuscar.SetBounds(240, 14, 250, 28); edtBuscar.Font.Size := 12;
  edtBuscar.TextHint := 'Buscar por placa o tipo...';
  edtBuscar.OnChange := @Refrescar;

  btnNuevo := TButton.Create(Self); btnNuevo.Parent := PnlTop;
  btnNuevo.SetBounds(500, 12, 100, 32);
  btnNuevo.Caption := '+ Nuevo'; btnNuevo.Font.Style := [fsBold];
  btnNuevo.OnClick := @btnNuevoClick;

  Grid := TStringGrid.Create(Self); Grid.Parent := Self;
  Grid.SetBounds(24, 72, Self.ClientWidth - 48, Self.ClientHeight - 152);
  Grid.Anchors := [akTop, akLeft, akRight, akBottom];
  Grid.ColCount := 5; Grid.RowCount := 2; Grid.FixedRows := 1;
  Grid.FixedCols := 0; Grid.Options := Grid.Options + [goRowSelect];
  Grid.DefaultRowHeight := 26;
  Grid.Cells[0, 0] := 'ID'; Grid.Cells[1, 0] := 'Placa';
  Grid.Cells[2, 0] := 'Tipo'; Grid.Cells[3, 0] := 'Tara (kg)';
  Grid.Cells[4, 0] := 'Estado';
  Grid.ColWidths[0] := 50; Grid.ColWidths[1] := 130;
  Grid.ColWidths[2] := 250; Grid.ColWidths[3] := 100;
  Grid.OnSelectCell := @GridSelectCell;

  btnEditar := TButton.Create(Self); btnEditar.Parent := Self;
  btnEditar.SetBounds(24, Self.ClientHeight - 60, 100, 32);
  btnEditar.Anchors := [akLeft,akBottom]; btnEditar.Caption := 'Editar';
  btnEditar.Enabled := False; btnEditar.OnClick := @btnEditarClick;

  btnEliminar := TButton.Create(Self); btnEliminar.Parent := Self;
  btnEliminar.SetBounds(132, Self.ClientHeight - 60, 160, 32);
  btnEliminar.Anchors := [akLeft,akBottom]; btnEliminar.Caption := 'Activar/Desactivar';
  btnEliminar.Enabled := False; btnEliminar.OnClick := @btnEliminarClick;

  Refrescar(nil);
end;

procedure TFrameVehiculos.Refrescar(Sender: TObject);
var
  Q: TSQLQuery;
  Filtro: string;
  Row: Integer;
begin
  if (DM = nil) or (not DM.Conexion.Connected) then Exit;

  Filtro := Trim(edtBuscar.Text);
  if Filtro <> '' then
    Filtro := ' WHERE (placa LIKE ''%' + StringReplace(Filtro, '''', '''''', [rfReplaceAll]) +
      '%'' OR tipo_vehiculo LIKE ''%' + StringReplace(Filtro, '''', '''''', [rfReplaceAll]) + '%'') '
  else
    Filtro := ' WHERE 1=1 ';

  Q := DM.AbrirQuery('SELECT id, placa, tipo_vehiculo, tara, estado FROM vehiculos' + Filtro + ' ORDER BY id DESC');
  Grid.RowCount := Q.RecordCount + 1;
  Row := 1;
  while not Q.EOF do
  begin
    Grid.Cells[0, Row] := Q.Fields[0].AsString;
    Grid.Cells[1, Row] := Q.Fields[1].AsString;
    Grid.Cells[2, Row] := Q.Fields[2].AsString;
    Grid.Cells[3, Row] := Q.Fields[3].AsString;
    Grid.Cells[4, Row] := Q.Fields[4].AsString;
    Q.Next; Inc(Row);
  end;
  Q.Close;
  btnEditar.Enabled := False; btnEliminar.Enabled := False;
end;

procedure TFrameVehiculos.GridSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
begin
  btnEditar.Enabled := (aRow >= 1) and (Grid.Cells[0, aRow] <> '');
  btnEliminar.Enabled := btnEditar.Enabled;
end;

function TFrameVehiculos.GetSelectedID: Integer;
begin
  Result := StrToIntDef(Grid.Cells[0, Grid.Row], 0);
end;

procedure TFrameVehiculos.btnNuevoClick(Sender: TObject);
var
  F: TForm;
  edtPlaca, edtTipo, edtTara: TEdit;
  BtnOK, BtnCancel: TButton;
  Lbl: TLabel;
begin
  F := TForm.Create(nil);
  try
    F.Caption := 'Nuevo Vehículo'; F.Width := 400; F.Height := 300;
    F.Position := poOwnerFormCenter; F.BorderStyle := bsDialog;

    Lbl := TLabel.Create(F); Lbl.Parent := F;
    Lbl.SetBounds(24, 16, 100, 16); Lbl.Caption := 'Placa *'; Lbl.Font.Style := [fsBold];
    edtPlaca := TEdit.Create(F); edtPlaca.Parent := F;
    edtPlaca.SetBounds(24, 36, 340, 32); edtPlaca.Font.Size := 12;

    Lbl := TLabel.Create(F); Lbl.Parent := F;
    Lbl.SetBounds(24, 76, 100, 16); Lbl.Caption := 'Tipo'; Lbl.Font.Style := [fsBold];
    edtTipo := TEdit.Create(F); edtTipo.Parent := F;
    edtTipo.SetBounds(24, 96, 340, 32); edtTipo.Font.Size := 12;

    Lbl := TLabel.Create(F); Lbl.Parent := F;
    Lbl.SetBounds(24, 136, 100, 16); Lbl.Caption := 'Tara (kg)'; Lbl.Font.Style := [fsBold];
    edtTara := TEdit.Create(F); edtTara.Parent := F;
    edtTara.SetBounds(24, 156, 120, 32); edtTara.Font.Size := 12; edtTara.Text := '0';

    BtnOK := TButton.Create(F); BtnOK.Parent := F;
    BtnOK.SetBounds(100, 210, 100, 36); BtnOK.Caption := 'Guardar';
    BtnOK.Font.Style := [fsBold]; BtnOK.ModalResult := mrOK;

    BtnCancel := TButton.Create(F); BtnCancel.Parent := F;
    BtnCancel.SetBounds(210, 210, 100, 36); BtnCancel.Caption := 'Cancelar';
    BtnCancel.ModalResult := mrCancel;

    if F.ShowModal = mrOK then
    begin
      if Trim(edtPlaca.Text) = '' then
      begin ShowMessage('La placa es obligatoria'); Exit; end;
      DM.EjecutarSQL('INSERT INTO vehiculos (placa, tipo_vehiculo, tara, estado, ' +
        'fecha_creacion, fecha_modificacion) VALUES (' +
        QuotedStr(Trim(edtPlaca.Text)) + ', ' +
        QuotedStr(Trim(edtTipo.Text)) + ', ' + edtTara.Text +
        ', ''ACTIVO'', ''' + FechaHoraActual + ''', ''' + FechaHoraActual + ''')');
      Refrescar(nil);
    end;
  finally
    F.Free;
  end;
end;

procedure TFrameVehiculos.btnEditarClick(Sender: TObject);
var
  ID: Integer;
  F: TForm;
  Lbl: TLabel;
  edtPlaca, edtTipo, edtTara: TEdit;
  Q: TSQLQuery;
begin
  ID := GetSelectedID; if ID = 0 then Exit;

  Q := DM.AbrirQuery('SELECT placa, tipo_vehiculo, tara FROM vehiculos WHERE id=' + IntToStr(ID));
  if Q.EOF then begin Q.Close; Exit; end;

  F := TForm.Create(nil);
  try
    F.Caption := 'Editar Vehículo #' + IntToStr(ID);
    F.Width := 400; F.Height := 300;
    F.Position := poOwnerFormCenter; F.BorderStyle := bsDialog;

    Lbl := TLabel.Create(F); Lbl.Parent := F;
    Lbl.SetBounds(24, 16, 100, 16); Lbl.Caption := 'Placa'; Lbl.Font.Style := [fsBold];
    edtPlaca.SetBounds(24, 36, 340, 32); edtPlaca.Font.Size := 12;
    edtPlaca.Text := Q.FieldByName('placa').AsString;

    edtTipo := TEdit.Create(F); edtTipo.Parent := F;
    edtTipo.SetBounds(24, 96, 340, 32); edtTipo.Font.Size := 12;
    edtTipo.Text := Q.FieldByName('tipo_vehiculo').AsString;

    edtTara := TEdit.Create(F); edtTara.Parent := F;
    edtTara.SetBounds(24, 156, 120, 32); edtTara.Font.Size := 12;
    edtTara.Text := Q.FieldByName('tara').AsString;
    Q.Close;

    with TButton.Create(F) do begin Parent := F; SetBounds(100, 210, 100, 36);
      Caption := 'Guardar'; Font.Style := [fsBold]; ModalResult := mrOK; end;
    with TButton.Create(F) do begin Parent := F; SetBounds(210, 210, 100, 36);
      Caption := 'Cancelar'; ModalResult := mrCancel; end;

    if F.ShowModal = mrOK then
    begin
      if Trim(edtPlaca.Text) = '' then
      begin ShowMessage('La placa es obligatoria'); Exit; end;
      DM.EjecutarSQL('UPDATE vehiculos SET placa=' + QuotedStr(Trim(edtPlaca.Text)) +
        ', tipo_vehiculo=' + QuotedStr(Trim(edtTipo.Text)) +
        ', tara=' + edtTara.Text + ', fecha_modificacion=''' + FechaHoraActual +
        ''' WHERE id=' + IntToStr(ID));
      Refrescar(nil);
    end;
  finally
    F.Free;
  end;
end;

procedure TFrameVehiculos.btnEliminarClick(Sender: TObject);
var
  ID: Integer;
  Est, Msg, NuevoEst: string;
begin
  ID := GetSelectedID; if ID = 0 then Exit;
  Est := Grid.Cells[4, Grid.Row];
  if Est = 'ACTIVO' then begin Msg := 'Desactivar #' + IntToStr(ID) + '?'; NuevoEst := 'INACTIVO'; end
  else begin Msg := 'Reactivar #' + IntToStr(ID) + '?'; NuevoEst := 'ACTIVO'; end;
  if MessageDlg('Confirmar', Msg, mtConfirmation, [mbYes,mbNo], 0) <> mrYes then Exit;
  DM.EjecutarSQL('UPDATE vehiculos SET estado=''' + NuevoEst +
    ''', fecha_modificacion=''' + FechaHoraActual + ''' WHERE id=' + IntToStr(ID));
  Refrescar(nil);
end;

end.
