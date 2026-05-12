unit ChoferesFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Grids, sqldb, DataModule, Utils, Theme;

type
  { TFrameChoferes }

  TFrameChoferes = class(TFrame)
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

constructor TFrameChoferes.Create(AOwner: TComponent);
var Pnl: TPanel; Lbl: TLabel;
begin
  inherited Create(AOwner);
  Self.Color := CLR_BG;
  Pnl := TPanel.Create(Self); Pnl.Parent := Self; Pnl.Align := alTop;
  Pnl.Height := 56; Pnl.BevelOuter := bvNone; Pnl.Color := CLR_CARD;

  Lbl := TLabel.Create(Self); Lbl.Parent := Pnl;
  Lbl.SetBounds(24, 14, 200, 28); Lbl.Caption := 'Choferes';
  Lbl.Font.Height := -18; Lbl.Font.Style := [fsBold]; Lbl.Font.Color := $333333;
  

  edtBuscar := TEdit.Create(Self); edtBuscar.Parent := Pnl;
  edtBuscar.SetBounds(240, 14, 250, 28); edtBuscar.Font.Size := 12;
  edtBuscar.TextHint := 'Buscar por nombre, CI o licencia...';
  edtBuscar.OnChange := @Refrescar;

  btnNuevo := TButton.Create(Self); btnNuevo.Parent := Pnl;
  btnNuevo.SetBounds(500, 12, 100, 32);
  btnNuevo.Caption := '+ Nuevo'; btnNuevo.Font.Style := [fsBold];
  btnNuevo.Font.Color := CLR_PRIMARY;
  
  btnNuevo.OnClick := @btnNuevoClick;

  Grid := TStringGrid.Create(Self); Grid.Parent := Self;
  Grid.SetBounds(24, 72, Self.ClientWidth - 48, Self.ClientHeight - 152);
  Grid.Anchors := [akTop,akLeft,akRight,akBottom];
  Grid.ColCount := 6; Grid.RowCount := 2; Grid.FixedRows := 1;
  Grid.FixedCols := 0; Grid.Options := Grid.Options + [goRowSelect];
  Grid.Color := CLR_CARD;
  Grid.FixedColor := CLR_CARD;
  Grid.ParentFont := False;
  Grid.Font.Color := CLR_TEXT;
  Grid.DefaultRowHeight := 26;
  Grid.Cells[0,0]:='ID'; Grid.Cells[1,0]:='Nombre'; Grid.Cells[2,0]:='CI';
  Grid.Cells[3,0]:='Licencia'; Grid.Cells[4,0]:='Teléfono'; Grid.Cells[5,0]:='Estado';
  Grid.ColWidths[0]:=50; Grid.ColWidths[1]:=200; Grid.ColWidths[2]:=120;
  Grid.ColWidths[3]:=140; Grid.ColWidths[4]:=120;
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

procedure TFrameChoferes.Refrescar(Sender: TObject);
var Q: TSQLQuery; Filtro: string; Row: Integer;
begin
  if (DM=nil)or(not DM.Conexion.Connected) then Exit;
  Filtro := Trim(edtBuscar.Text);
  if Filtro<>'' then
    Filtro := ' AND (p.nombre LIKE ''%'+StringReplace(Filtro,'''','''''',[rfReplaceAll])+
      '%'' OR p.ci LIKE ''%'+StringReplace(Filtro,'''','''''',[rfReplaceAll])+
      '%'' OR c.licencia LIKE ''%'+StringReplace(Filtro,'''','''''',[rfReplaceAll])+'%'') '
  else Filtro := '';
  Q := DM.AbrirQuery(
    'SELECT c.id, p.nombre||'' ''||COALESCE(p.apellido_paterno,''''), '+
    'COALESCE(p.ci,''''), COALESCE(c.licencia,''''), COALESCE(p.telefono,''''), c.estado '+
    'FROM choferes c INNER JOIN personas p ON p.id=c.persona_id '+
    'WHERE c.estado=''ACTIVO'''+Filtro+' ORDER BY p.nombre');
  Grid.RowCount := Q.RecordCount+1; Row:=1;
  while not Q.EOF do begin
    Grid.Cells[0,Row]:=Q.Fields[0].AsString; Grid.Cells[1,Row]:=Q.Fields[1].AsString;
    Grid.Cells[2,Row]:=Q.Fields[2].AsString; Grid.Cells[3,Row]:=Q.Fields[3].AsString;
    Grid.Cells[4,Row]:=Q.Fields[4].AsString; Grid.Cells[5,Row]:=Q.Fields[5].AsString;
    Q.Next; Inc(Row);
  end; Q.Close;
  btnEditar.Enabled:=False; btnEliminar.Enabled:=False;
end;

procedure TFrameChoferes.GridSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
begin
  btnEditar.Enabled:=(aRow>=1)and(Grid.Cells[0,aRow]<>'');
  btnEliminar.Enabled:=btnEditar.Enabled;
end;

function TFrameChoferes.GetSelectedID: Integer;
begin
  Result:=StrToIntDef(Grid.Cells[0,Grid.Row],0);
end;

procedure TFrameChoferes.btnNuevoClick(Sender: TObject);
var
  F: TForm; lbl: TLabel;
  eNom, ePat, eMat, eCI, eLic, eTel: TEdit;
  BtnOK, BtnCancel: TButton;
begin
  F := TForm.Create(nil);
  try
    F.Caption:='Nuevo Chofer'; F.Width:=460; F.Height:=380;
    F.Position:=poOwnerFormCenter; F.BorderStyle:=bsDialog;

    lbl:=TLabel.Create(F); lbl.Parent:=F; lbl.SetBounds(24,16,200,16);
    lbl.Caption:='Nombre *'; lbl.Font.Style:=[fsBold];
    eNom:=TEdit.Create(F); eNom.Parent:=F; eNom.SetBounds(24,36,190,32); eNom.Font.Size:=12;

    lbl:=TLabel.Create(F); lbl.Parent:=F; lbl.SetBounds(226,16,200,16);
    lbl.Caption:='Ap. Paterno'; lbl.Font.Style:=[fsBold];
    ePat:=TEdit.Create(F); ePat.Parent:=F; ePat.SetBounds(226,36,190,32); ePat.Font.Size:=12;

    lbl:=TLabel.Create(F); lbl.Parent:=F; lbl.SetBounds(24,76,200,16);
    lbl.Caption:='Ap. Materno'; lbl.Font.Style:=[fsBold];
    eMat:=TEdit.Create(F); eMat.Parent:=F; eMat.SetBounds(24,96,190,32); eMat.Font.Size:=12;

    lbl:=TLabel.Create(F); lbl.Parent:=F; lbl.SetBounds(226,76,200,16);
    lbl.Caption:='CI'; lbl.Font.Style:=[fsBold];
    eCI:=TEdit.Create(F); eCI.Parent:=F; eCI.SetBounds(226,96,190,32); eCI.Font.Size:=12;

    lbl:=TLabel.Create(F); lbl.Parent:=F; lbl.SetBounds(24,140,200,16);
    lbl.Caption:='Licencia'; lbl.Font.Style:=[fsBold];
    eLic:=TEdit.Create(F); eLic.Parent:=F; eLic.SetBounds(24,160,190,32); eLic.Font.Size:=12;

    lbl:=TLabel.Create(F); lbl.Parent:=F; lbl.SetBounds(226,140,200,16);
    lbl.Caption:='Teléfono'; lbl.Font.Style:=[fsBold];
    eTel:=TEdit.Create(F); eTel.Parent:=F; eTel.SetBounds(226,160,190,32); eTel.Font.Size:=12;

    BtnOK:=TButton.Create(F); BtnOK.Parent:=F;
    BtnOK.SetBounds(160,310,100,36); BtnOK.Caption:='Guardar';
    BtnOK.Font.Style:=[fsBold]; BtnOK.ModalResult:=mrOK;

    BtnCancel:=TButton.Create(F); BtnCancel.Parent:=F;
    BtnCancel.SetBounds(270,310,100,36); BtnCancel.Caption:='Cancelar';
    BtnCancel.ModalResult:=mrCancel;

    if F.ShowModal=mrOK then begin
      if Trim(eNom.Text)='' then begin ShowMessage('Nombre obligatorio'); Exit; end;
      DM.Transaccion.StartTransaction;
      try
        DM.EjecutarSQL('INSERT INTO personas (nombre, apellido_paterno, apellido_materno, ci, telefono, estado, fecha_creacion, fecha_modificacion) VALUES ('+
          QuotedStr(Trim(eNom.Text))+', '+QuotedStr(Trim(ePat.Text))+', '+QuotedStr(Trim(eMat.Text))+', '+
          QuotedStr(Trim(eCI.Text))+', '+QuotedStr(Trim(eTel.Text))+', ''ACTIVO'', '+
          ''''+FechaHoraActual+''', '''+FechaHoraActual+''')');
        DM.EjecutarSQL('INSERT INTO choferes (persona_id, licencia, telefono, estado, fecha_creacion, fecha_modificacion) VALUES ('+
          IntToStr(DM.ObtenerUltimoID)+', '+QuotedStr(Trim(eLic.Text))+', '+
          QuotedStr(Trim(eTel.Text))+', ''ACTIVO'', '''+FechaHoraActual+''', '''+FechaHoraActual+''')');
        DM.Transaccion.Commit; Refrescar(nil);
      except DM.Transaccion.Rollback; end;
    end;
  finally F.Free; end;
end;

procedure TFrameChoferes.btnEditarClick(Sender: TObject);
begin
  ShowMessage('Editar chofer - disponible en Fase 2.1');
end;

procedure TFrameChoferes.btnEliminarClick(Sender: TObject);
var ID: Integer;
begin
  ID:=GetSelectedID; if ID=0 then Exit;
  if MessageDlg('Confirmar','¿Desactivar chofer #'+IntToStr(ID)+'?',
    mtConfirmation,[mbYes,mbNo],0)<>mrYes then Exit;
  DM.EjecutarSQL('UPDATE choferes SET estado=''INACTIVO'', fecha_modificacion='''+
    FechaHoraActual+''' WHERE id='+IntToStr(ID));
  Refrescar(nil);
end;

end.
