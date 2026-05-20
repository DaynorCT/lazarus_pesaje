unit BoletaPesaje;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, fppdf, DataModule;

function GenerarBoletaPDF(PesajeID: Integer; out Stream: TMemoryStream): Boolean;

implementation

type
  TBoletaData = record
    Guia, Fecha, Hora: string;
    ChoferNombre, ChoferLicencia: string;
    VehiculoPlaca, VehiculoTipo: string;
    ProveedorNombre, ProductoNombre: string;
    OrigenNombre, DestinoNombre: string;
    PesoBruto, Tara, PesoNeto: Integer;
    CostoBs, FleteBs: Integer;
    Operador: string;
    Salida, Direccion, Celular1, Celular2, Ciudad: string;
    TituloSuperior, Marca, TituloDocumento, Acreditacion: string;
    LogoBase64: string;
  end;

function CargarDatosBoleta(PesajeID: Integer; out Datos: TBoletaData): Boolean;
var
  Q: TSQLQuery;
begin
  Result := False;
  FillChar(Datos, SizeOf(Datos), 0);

  Q := DM.AbrirQuery(
    'SELECT p.id, p.guia, p.fecha_creacion, ' +
    'COALESCE(pe.nombre,'''') as chofer_nombre, ' +
    'COALESCE(pe.apellido_paterno,'''') as chofer_ap, ' +
    'COALESCE(pe.apellido_materno,'''') as chofer_am, ' +
    'COALESCE(ch.licencia,'''') as chofer_licencia, ' +
    'COALESCE(v.placa,'''') as vehiculo_placa, ' +
    'COALESCE(v.tipo_vehiculo,'''') as vehiculo_tipo, ' +
    'COALESCE(pr.nombre||'' ''||pr.apellido_paterno,'''') as proveedor_nombre, ' +
    'COALESCE(prod.nombre,'''') as producto_nombre, ' +
    'COALESCE(o.nombre,'''') as origen_nombre, ' +
    'COALESCE(d.nombre,'''') as destino_nombre, ' +
    'p.peso_bruto, p.tara, p.peso_neto, p.costo_bs, p.flete_bs_pendiente, ' +
    'COALESCE(ps.nombre,'''') as operador ' +
    'FROM pesajes p ' +
    'LEFT JOIN vehiculos v ON v.id=p.vehiculo_id ' +
    'LEFT JOIN choferes ch ON ch.id=p.chofer_id ' +
    'LEFT JOIN personas pe ON pe.id=ch.persona_id ' +
    'LEFT JOIN personas pr ON pr.id=(SELECT persona_id FROM proveedores WHERE id=p.proveedor_id) ' +
    'LEFT JOIN productos prod ON prod.id=p.producto_id ' +
    'LEFT JOIN origenes o ON o.id=p.id_origen ' +
    'LEFT JOIN destinos d ON d.id=p.id_destino ' +
    'LEFT JOIN personas ps ON ps.id=p.pesador_id ' +
    'WHERE p.id=' + IntToStr(PesajeID));
  try
    if Q.EOF then Exit;

    Datos.Guia := UpperCase(Q.FieldByName('guia').AsString);
    if Length(Q.FieldByName('fecha_creacion').AsString) >= 16 then
    begin
      Datos.Fecha := Q.FieldByName('fecha_creacion').AsString;
      Datos.Hora := Copy(Datos.Fecha, 12, 5);
      Datos.Fecha := Copy(Q.FieldByName('fecha_creacion').AsString, 9, 2) + '/' +
                     Copy(Q.FieldByName('fecha_creacion').AsString, 6, 2) + '/' +
                     Copy(Q.FieldByName('fecha_creacion').AsString, 1, 4);
    end;
    Datos.ChoferNombre := UpperCase(Q.FieldByName('chofer_nombre').AsString + ' ' +
      Q.FieldByName('chofer_ap').AsString + ' ' + Q.FieldByName('chofer_am').AsString);
    Datos.ChoferLicencia := UpperCase(Q.FieldByName('chofer_licencia').AsString);
    Datos.VehiculoPlaca := UpperCase(Q.FieldByName('vehiculo_placa').AsString);
    Datos.VehiculoTipo := UpperCase(Q.FieldByName('vehiculo_tipo').AsString);
    Datos.ProveedorNombre := UpperCase(Q.FieldByName('proveedor_nombre').AsString);
    Datos.ProductoNombre := UpperCase(Q.FieldByName('producto_nombre').AsString);
    Datos.OrigenNombre := UpperCase(Q.FieldByName('origen_nombre').AsString);
    Datos.DestinoNombre := UpperCase(Q.FieldByName('destino_nombre').AsString);
    Datos.PesoBruto := Q.FieldByName('peso_bruto').AsInteger;
    Datos.Tara := Q.FieldByName('tara').AsInteger;
    Datos.PesoNeto := Q.FieldByName('peso_neto').AsInteger;
    Datos.CostoBs := Q.FieldByName('costo_bs').AsInteger;
    Datos.FleteBs := Q.FieldByName('flete_bs_pendiente').AsInteger;
    Datos.Operador := UpperCase(Q.FieldByName('operador').AsString);
  finally
    Q.Close;
  end;

  Q := DM.AbrirQuery('SELECT * FROM boleta_config LIMIT 1');
  try
    if not Q.EOF then
    begin
      Datos.Salida := UpperCase(Q.FieldByName('salida').AsString);
      Datos.Direccion := UpperCase(Q.FieldByName('direccion').AsString);
      Datos.Celular1 := UpperCase(Q.FieldByName('celular1').AsString);
      Datos.Celular2 := UpperCase(Q.FieldByName('celular2').AsString);
      Datos.Ciudad := UpperCase(Q.FieldByName('ciudad').AsString);
      Datos.TituloSuperior := UpperCase(Q.FieldByName('titulo_superior').AsString);
      Datos.Marca := UpperCase(Q.FieldByName('marca').AsString);
      Datos.TituloDocumento := UpperCase(Q.FieldByName('titulo_documento').AsString);
      Datos.Acreditacion := UpperCase(Q.FieldByName('acreditacion').AsString);
    end;
  finally
    Q.Close;
  end;

  Q := DM.AbrirQuery('SELECT logo FROM empresas WHERE estado=''ACTIVO'' LIMIT 1');
  try
    if not Q.EOF then
      Datos.LogoBase64 := Q.FieldByName('logo').AsString;
  finally
    Q.Close;
  end;

  Result := True;
end;

function GenerarBoletaPDF(PesajeID: Integer; out Stream: TMemoryStream): Boolean;
var
  Doc: TPDFDocument;
  Page: TPDFPage;
  Datos: TBoletaData;
  FontH, FontHBold, FontSmall: Integer;
  Y, XRight, PageW: Double;
begin
  Result := False;
  if not CargarDatosBoleta(PesajeID, Datos) then Exit;

  Doc := TPDFDocument.Create(nil);
  try
    Doc.DefaultOrientation := ppoPortrait;
    Doc.DefaultPaperType := ptLetter;
    Doc.Options := [poPageOriginAtTop];
    Doc.StartDocument;

    FontH := Doc.AddFont('Helvetica');
    FontHBold := Doc.AddFont('Helvetica-Bold');
    FontSmall := Doc.AddFont('Helvetica');

    Page := Doc.Pages.AddPage;
    Doc.Sections.AddSection.AddPage(Page);
    Page.UnitOfMeasure := uomMillimeters;
    Page.PaperType := ptLetter;
    Page.Orientation := ppoPortrait;

    PageW := 196;
    Y := 10;

    // ═══════════ HEADER 3 COLUMNAS ═══════════
    // Col Izquierda (25%)
    Page.SetFont(FontHBold, 9);
    Page.WriteText(10, Y, Datos.Salida);
    Y := Y + 5;
    Page.SetFont(FontH, 8);
    Page.WriteText(10, Y, Datos.Direccion);
    Y := Y + 4;
    Page.WriteText(10, Y, 'Cel: ' + Datos.Celular1);
    Y := Y + 4;
    Page.WriteText(10, Y, '     ' + Datos.Celular2);
    Y := Y + 4;
    Page.WriteText(10, Y, Datos.Ciudad);

    // Col Centro (50%)
    Y := 10;
    Page.SetFont(FontHBold, 11);
    Page.WriteText(45, Y, Datos.TituloSuperior);
    Y := Y + 7;
    Page.SetFont(FontHBold, 14);
    Page.WriteText(60, Y, Datos.Marca);
    Y := Y + 8;
    Page.SetFont(FontHBold, 11);
    Page.WriteText(50, Y, Datos.TituloDocumento);

    // Linea separadora
    Page.DrawLine(10, 32, PageW, 32, 0.3);
    Y := 36;

    // ═══════════ GUIA ═══════════
    Page.SetFont(FontH, 8);
    Page.WriteText(10, Y, 'GUIA:');
    Page.SetFont(FontHBold, 10);
    Page.WriteText(28, Y, Datos.Guia);
    Y := Y + 7;

    // ═══════════ DATOS 2 COLUMNAS ═══════════
    Y := Y + 1;
    // Col Izquierda
    Page.SetFont(FontH, 8);
    Page.WriteText(10, Y, 'PLACA:');
    Page.SetFont(FontHBold, 9); Page.WriteText(28, Y, Datos.VehiculoPlaca);
    Y := Y + 5;
    Page.SetFont(FontH, 8); Page.WriteText(10, Y, 'CHOFER:');
    Page.SetFont(FontHBold, 9); Page.WriteText(28, Y, Datos.ChoferNombre);
    Y := Y + 5;
    Page.SetFont(FontH, 8); Page.WriteText(10, Y, 'LICENCIA:');
    Page.SetFont(FontHBold, 9); Page.WriteText(28, Y, Datos.ChoferLicencia);
    Y := Y + 5;
    Page.SetFont(FontH, 8); Page.WriteText(10, Y, 'PROVEEDOR:');
    Page.SetFont(FontHBold, 9); Page.WriteText(28, Y, Datos.ProveedorNombre);
    Y := Y + 5;
    Page.SetFont(FontH, 8); Page.WriteText(10, Y, 'TIPO:');
    Page.SetFont(FontHBold, 9); Page.WriteText(28, Y, Datos.VehiculoTipo);

    // Col Derecha
    XRight := 110;
    Y := 44;
    Page.SetFont(FontH, 8); Page.WriteText(XRight, Y, 'PRODUCTO:');
    Page.SetFont(FontHBold, 9); Page.WriteText(XRight + 20, Y, Datos.ProductoNombre);
    Y := Y + 5;
    Page.SetFont(FontH, 8); Page.WriteText(XRight, Y, 'COSTO BS:');
    Page.SetFont(FontHBold, 9); Page.WriteText(XRight + 20, Y, 'Bs ' + FormatFloat('#,##0.00', Datos.CostoBs));
    Y := Y + 5;
    Page.SetFont(FontH, 8); Page.WriteText(XRight, Y, 'ORIGEN:');
    Page.SetFont(FontHBold, 9); Page.WriteText(XRight + 20, Y, Datos.OrigenNombre);
    Y := Y + 5;
    Page.SetFont(FontH, 8); Page.WriteText(XRight, Y, 'DESTINO:');
    Page.SetFont(FontHBold, 9); Page.WriteText(XRight + 20, Y, Datos.DestinoNombre);
    Y := Y + 5;
    Page.SetFont(FontH, 8); Page.WriteText(XRight, Y, 'FLETE BS:');
    Page.SetFont(FontHBold, 9); Page.WriteText(XRight + 20, Y, 'Bs ' + FormatFloat('#,##0.00', Datos.FleteBs));

    // ═══════════ FECHA ═══════════
    Y := 73;
    Page.SetFont(FontH, 8);
    Page.WriteText(10, Y, 'FECHA/HORA:');
    Page.SetFont(FontHBold, 9);
    Page.WriteText(34, Y, Datos.Fecha + ' ' + Datos.Hora);

    // ═══════════ PESOS 3 COLUMNAS ═══════════
    Y := Y + 7;
    Page.DrawLine(10, Y, PageW, Y, 0.3);
    Y := Y + 4;

    Page.SetFont(FontH, 7);
    Page.WriteText(10, Y, 'PESO BRUTO:');
    Page.SetFont(FontHBold, 10);
    Page.WriteText(28, Y, FormatFloat('#,##0.000', Datos.PesoBruto) + ' kg');

    Page.SetFont(FontH, 7);
    Page.WriteText(75, Y, 'PESO TARA:');
    Page.SetFont(FontHBold, 10);
    Page.WriteText(93, Y, FormatFloat('#,##0.000', Datos.Tara) + ' kg');

    Page.SetFont(FontH, 7);
    Page.WriteText(140, Y, 'PESO NETO:');
    Page.SetFont(FontHBold, 10);
    Page.WriteText(158, Y, FormatFloat('#,##0.000', Datos.PesoNeto) + ' kg');

    Y := Y + 7;
    Page.DrawLine(10, Y, PageW, Y, 0.3);

    // ═══════════ FIRMAS ═══════════
    Y := Y + 30;
    Page.DrawLine(10, Y, 80, Y, 0.3);
    Page.SetFont(FontH, 7);
    Page.WriteText(16, Y + 3, 'CHOFER O PRODUCTOR');

    Page.DrawLine(116, Y, 186, Y, 0.3);
    Page.WriteText(122, Y + 3, 'OPERADOR DE BALANZA');

    Stream := TMemoryStream.Create;
    Doc.SaveToStream(Stream);
    Stream.Position := 0;
    Result := True;
  finally
    Doc.Free;
  end;
end;

end.
