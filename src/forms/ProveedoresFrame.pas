unit ProveedoresFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Grids, sqldb, DataModule, Utils, Theme;

type
  { TFrameProveedores }

  TFrameProveedores = class(TFrame)
    constructor Create(AOwner: TComponent); override;
  private
    Grid: TStringGrid;
    edtBuscar: TEdit;
    btnNuevo, btnEditar, btnEliminar: TButton;
    procedure Refrescar(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnEliminarClick(Sender: TObject);
    procedure GridSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    function GetSelectedID: Integer;
  end;

implementation

{$R *.lfm}

constructor TFrameProveedores.Create(AOwner: TComponent);
var Pnl: TPanel; Lbl: TLabel;
begin
  inherited Create(AOwner);
  Self.Color := CLR_BG;
  Pnl := TPanel.Create(Self); Pnl.Parent := Self; Pnl.Align := alTop;
  Pnl.Height := 56; Pnl.BevelOuter := bvNone; Pnl.Color := CLR_CARD;

  Lbl := TLabel.Create(Self); Lbl.Parent := Pnl;
  Lbl.SetBounds(24, 14, 200, 28); Lbl.Caption := 'Proveedores';
  Lbl.Font.Height := -18; Lbl.Font.Style := [fsBold]; Lbl.Font.Color := $333333;
  

  edtBuscar := TEdit.Create(Self); edtBuscar.Parent := Pnl;
  edtBuscar.SetBounds(240, 14, 250, 28); edtBuscar.Font.Size := 12;
  edtBuscar.TextHint := 'Buscar por nombre o empresa...';
  edtBuscar.OnChange := @Refrescar;

  btnNuevo := TButton.Create(Self); btnNuevo.Parent := Pnl;
  btnNuevo.SetBounds(500, 12, 100, 32);
  btnNuevo.Caption := '+ Nuevo'; btnNuevo.Font.Style := [fsBold];
  btnNuevo.Font.Color := CLR_PRIMARY;
  
  btnNuevo.OnClick := @btnNuevoClick;

  Grid := TStringGrid.Create(Self); Grid.Parent := Self;
  Grid.SetBounds(24, 72, Self.ClientWidth - 48, Self.ClientHeight - 152);
  Grid.Anchors := [akTop,akLeft,akRight,akBottom];
  Grid.ColCount := 5; Grid.RowCount := 2; Grid.FixedRows := 1;
  Grid.FixedCols := 0; Grid.Options := Grid.Options + [goRowSelect];
  Grid.Color := CLR_CARD;
  Grid.FixedColor := CLR_TABLE_HEADER;
  Grid.ParentFont := False;
  Grid.Font.Color := CLR_TEXT;
  Grid.DefaultRowHeight := 26;
  Grid.Cells[0,0]:='ID'; Grid.Cells[1,0]:='Nombre'; Grid.Cells[2,0]:='Empresa';
  Grid.Cells[3,0]:='CI'; Grid.Cells[4,0]:='Estado';
  Grid.ColWidths[0]:=50; Grid.ColWidths[1]:=200; Grid.ColWidths[2]:=250;
  Grid.ColWidths[3]:=120;
  Grid.OnSelectCell := @GridSelectCell;

  btnEditar := TButton.Create(Self); btnEditar.Parent := Self;
  btnEditar.SetBounds(24, Self.ClientHeight - 60, 100, 32);
  btnEditar.Anchors := [akLeft,akBottom]; btnEditar.Caption := 'Editar';
  btnEditar.Enabled := False;

  btnEliminar := TButton.Create(Self); btnEliminar.Parent := Self;
  btnEliminar.SetBounds(132, Self.ClientHeight - 60, 160, 32);
  btnEliminar.Anchors := [akLeft,akBottom]; btnEliminar.Caption := 'Activar/Desactivar';
  btnEliminar.Enabled := False; btnEliminar.OnClick := @btnEliminarClick;

  Refrescar(nil);
end;

procedure TFrameProveedores.Refrescar(Sender: TObject);
var Q: TSQLQuery; Filtro: string; Row: Integer;
begin
  if (DM=nil)or(not DM.Conexion.Connected) then Exit;
  Filtro := Trim(edtBuscar.Text);
  if Filtro<>'' then
    Filtro := ' AND (p.nombre LIKE ''%'+StringReplace(Filtro,'''','''''',[rfReplaceAll])+
      '%'' OR pr.nombre_empresa LIKE ''%'+StringReplace(Filtro,'''','''''',[rfReplaceAll])+'%'') '
  else Filtro := '';
  Q := DM.AbrirQuery(
    'SELECT pr.id, p.nombre||'' ''||COALESCE(p.apellido_paterno,''''), '+
    'COALESCE(pr.nombre_empresa,''''), COALESCE(p.ci,''''), pr.estado '+
    'FROM proveedores pr INNER JOIN personas p ON p.id=pr.persona_id '+
    'WHERE pr.estado=''ACTIVO'''+Filtro+' ORDER BY p.nombre');
  Grid.RowCount := Q.RecordCount+1; Row:=1;
  while not Q.EOF do begin
    Grid.Cells[0,Row]:=Q.Fields[0].AsString; Grid.Cells[1,Row]:=Q.Fields[1].AsString;
    Grid.Cells[2,Row]:=Q.Fields[2].AsString; Grid.Cells[3,Row]:=Q.Fields[3].AsString;
    Grid.Cells[4,Row]:=Q.Fields[4].AsString;
    Q.Next; Inc(Row);
  end; Q.Close;
end;

procedure TFrameProveedores.GridSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
begin
  btnEditar.Enabled:=(aRow>=1)and(Grid.Cells[0,aRow]<>'');
  btnEliminar.Enabled:=btnEditar.Enabled;
end;

function TFrameProveedores.GetSelectedID: Integer;
begin Result:=StrToIntDef(Grid.Cells[0,Grid.Row],0); end;

procedure TFrameProveedores.btnNuevoClick(Sender: TObject);
var
  F: TForm; Lbl: TLabel;
  eNom, ePat, eCI, eEmp, eTel: TEdit;
begin
  F := TForm.Create(nil);
  try
    F.Caption:='Nuevo Proveedor'; F.Width:=440; F.Height:=340;
    F.Position:=poOwnerFormCenter; F.BorderStyle:=bsDialog;

    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(24,16,200,16);
    Lbl.Caption:='Nombre *'; Lbl.Font.Style:=[fsBold];
    eNom:=TEdit.Create(F); eNom.Parent:=F; eNom.SetBounds(24,36,190,32); eNom.Font.Size:=12;

    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(226,16,200,16);
    Lbl.Caption:='Apellido'; Lbl.Font.Style:=[fsBold];
    ePat:=TEdit.Create(F); ePat.Parent:=F; ePat.SetBounds(226,36,190,32); ePat.Font.Size:=12;

    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(24,76,200,16);
    Lbl.Caption:='CI'; Lbl.Font.Style:=[fsBold];
    eCI:=TEdit.Create(F); eCI.Parent:=F; eCI.SetBounds(24,96,190,32); eCI.Font.Size:=12;

    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(226,76,200,16);
    Lbl.Caption:='Telefono'; Lbl.Font.Style:=[fsBold];
    eTel:=TEdit.Create(F); eTel.Parent:=F; eTel.SetBounds(226,96,190,32); eTel.Font.Size:=12;

    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(24,140,200,16);
    Lbl.Caption:='Nombre Empresa'; Lbl.Font.Style:=[fsBold];
    eEmp:=TEdit.Create(F); eEmp.Parent:=F; eEmp.SetBounds(24,160,380,32); eEmp.Font.Size:=12;

    with TButton.Create(F) do begin Parent:=F; SetBounds(140,280,100,36);
      Caption:='Guardar'; Font.Style:=[fsBold]; ModalResult:=mrOK; end;
    with TButton.Create(F) do begin Parent:=F; SetBounds(250,280,100,36);
      Caption:='Cancelar'; ModalResult:=mrCancel; end;

    if F.ShowModal=mrOK then begin
      if Trim(eNom.Text)='' then begin ShowMessage('Nombre obligatorio'); Exit; end;
      DM.Transaccion.StartTransaction;
      try
        DM.EjecutarSQL('INSERT INTO personas (nombre, apellido_paterno, ci, telefono, estado, fecha_creacion, fecha_modificacion) VALUES ('+
          QuotedStr(Trim(eNom.Text))+', '+QuotedStr(Trim(ePat.Text))+', '+
          QuotedStr(Trim(eCI.Text))+', '+QuotedStr(Trim(eTel.Text))+
          ', ''ACTIVO'', '''+FechaHoraActual+''', '''+FechaHoraActual+''')');
        DM.EjecutarSQL('INSERT INTO proveedores (persona_id, nombre_empresa, estado, fecha_creacion, fecha_modificacion) VALUES ('+
          IntToStr(DM.ObtenerUltimoID)+', '+QuotedStr(Trim(eEmp.Text))+
          ', ''ACTIVO'', '''+FechaHoraActual+''', '''+FechaHoraActual+''')');
        DM.Transaccion.Commit; Refrescar(nil);
      except DM.Transaccion.Rollback; end;
    end;
  finally F.Free; end;
end;

procedure TFrameProveedores.btnEliminarClick(Sender: TObject);
var ID: Integer;
begin
  ID:=GetSelectedID; if ID=0 then Exit;
  if MessageDlg('Confirmar','Desactivar proveedor #'+IntToStr(ID)+'?',
    mtConfirmation,[mbYes,mbNo],0)<>mrYes then Exit;
  DM.EjecutarSQL('UPDATE proveedores SET estado=''INACTIVO'', fecha_modificacion='''+
    FechaHoraActual+''' WHERE id='+IntToStr(ID));
  Refrescar(nil);
end;

end.
