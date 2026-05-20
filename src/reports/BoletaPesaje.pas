unit BoletaPesaje;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, fppdf, fpttf, DataModule;

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
  Datos := Default(TBoletaData);

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

  // Forzar valores idénticos a la imagen si la BD viene vacía (Opcional/Respaldo)
  Datos.TituloSuperior := 'BALANZA';
  Datos.Marca := 'PRIMAVERA';
  Datos.TituloDocumento := 'BOLETA DE PESAJE';

  Result := True;
end;

function MedirTexto(const Texto: string; const FontName: string; FontSize: Double): Double;
var
  fc: TFPFontCacheItem;
begin
  fc := gTTFontCache.Find(FontName);
  if Assigned(fc) then
    Result := fc.TextWidth(Texto, FontSize) * 25.4 / gTTFontCache.DPI
  else
    Result := Length(Texto) * FontSize * 0.35;
end;

function GenerarBoletaPDF(PesajeID: Integer; out Stream: TMemoryStream): Boolean;
var
  Doc: TPDFDocument;
  Page: TPDFPage;
  Datos: TBoletaData;
  FontH, FontHBold: Integer;
  Y, PageW, TicketW, XStart: Double;
  XCol1, XCol2: Double;
  LineaSeparadora: string;
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

    Page := Doc.Pages.AddPage;
    Doc.Sections.AddSection.AddPage(Page);

    Page.UnitOfMeasure := uomMillimeters;
    Page.PaperType := ptLetter;

    PageW := 215.9;
    TicketW := 100;
    XStart := (PageW - TicketW) / 2;

    XCol1 := XStart + 5;
    XCol2 := XStart + 40;
    LineaSeparadora := '----------------------------------------------------------------------------------';

    // ═══════════ ENCABEZADO CENTRADO ═══════════
    Y := 15;
    Page.SetFont(FontHBold, 20);
    Page.WriteText(XStart + (TicketW - MedirTexto(Datos.TituloSuperior, 'Helvetica-Bold', 20)) / 2, Y, Datos.TituloSuperior);

    Y := Y + 7;
    Page.WriteText(XStart + (TicketW - MedirTexto(Datos.Marca, 'Helvetica-Bold', 20)) / 2, Y, Datos.Marca);

    Y := Y + 8;
    Page.SetFont(FontHBold, 13);
    Page.WriteText(XStart + (TicketW - MedirTexto(Datos.TituloDocumento, 'Helvetica-Bold', 13)) / 2, Y, Datos.TituloDocumento);

    Y := Y + 5;
    Page.SetFont(FontH, 10);
    Page.WriteText(XStart + (TicketW - MedirTexto('BOLETA DE PESAJE DIGITAL', 'Helvetica', 10)) / 2, Y, 'BOLETA DE PESAJE DIGITAL');

    // ═══════════ INFORMACIÓN DE GUÍA, FECHA Y HORA ═══════════
    Y := Y + 7;
    Page.SetFont(FontH, 9);
    Page.WriteText(XCol1, Y, 'Guia: ' + Datos.Guia);
    Page.WriteText(XStart + 38, Y, 'Fecha: ' + Datos.Fecha);
    Page.WriteText(XStart + 72, Y, 'Hora: ' + Datos.Hora);

    Y := Y + 3;
    Page.WriteText(XCol1, Y, LineaSeparadora);

    // ═══════════ DATOS DEL VEHÍCULO ═══════════
    Y := Y + 5;
    Page.SetFont(FontHBold, 10);
    Page.WriteText(XStart + (TicketW - MedirTexto('DATOS DEL VEHÍCULO', 'Helvetica-Bold', 10)) / 2, Y, 'DATOS DEL VEHÍCULO');

    Y := Y + 5;
    Page.SetFont(FontH, 9.5);
    Page.WriteText(XCol1, Y, 'Placa:');
    Page.WriteText(XCol2, Y, Datos.VehiculoPlaca);

    Y := Y + 5;
    Page.WriteText(XCol1, Y, 'Chofer:');
    Page.WriteText(XCol2, Y, Datos.ChoferNombre);

    Y := Y + 5;
    Page.WriteText(XCol1, Y, 'Licencia:');
    Page.WriteText(XCol2, Y, Datos.ChoferLicencia);

    Y := Y + 5;
    Page.WriteText(XCol1, Y, 'Tipo Vehículo:');
    Page.WriteText(XCol2, Y, Datos.VehiculoTipo);

    Y := Y + 3;
    Page.WriteText(XCol1, Y, LineaSeparadora);

    // ═══════════ DATOS DE CARGA ═══════════
    Y := Y + 5;
    Page.SetFont(FontHBold, 10);
    Page.WriteText(XStart + (TicketW - MedirTexto('DATOS DE CARGA', 'Helvetica-Bold', 10)) / 2, Y, 'DATOS DE CARGA');

    Y := Y + 5;
    Page.SetFont(FontH, 9.5);
    Page.WriteText(XCol1, Y, 'Producto:');
    Page.WriteText(XCol2, Y, Datos.ProductoNombre);

    Y := Y + 5;
    Page.WriteText(XCol1, Y, 'Origen:');
    Page.WriteText(XCol2, Y, Datos.OrigenNombre);

    Y := Y + 5;
    Page.WriteText(XCol1, Y, 'Destino:');
    Page.WriteText(XCol2, Y, Datos.DestinoNombre);

    Y := Y + 5;
    Page.WriteText(XCol1, Y, 'Costo:');
    Page.WriteText(XCol2, Y, IntToStr(Datos.CostoBs) + ' Bs');

    Y := Y + 3;
    Page.WriteText(XCol1, Y, LineaSeparadora);

    // ═══════════ BLOQUE DE PESOS ═══════════
    Y := Y + 5;
    Page.SetFont(FontHBold, 9);
    Page.WriteText(XCol1, Y, '[PESO BRUTO:');
    Page.WriteText(XStart + 38, Y, '[PESO TARA:');
    Page.WriteText(XStart + 70, Y, '[PESO NETO:');

    Y := Y + 5.5;
    Page.SetFont(FontHBold, 12);
    Page.WriteText(XCol1, Y, FormatFloat('#,##0', Datos.PesoBruto) + ' kg');
    Page.WriteText(XStart + 38, Y, FormatFloat('#,##0', Datos.Tara) + ' kg');
    Page.WriteText(XStart + 70, Y, FormatFloat('#,##0', Datos.PesoNeto) + ' kg');

    Y := Y + 3;
    Page.SetFont(FontH, 9);
    Page.WriteText(XCol1, Y, LineaSeparadora);

    // ═══════════ PIE DE FECHA PESAJE ═══════════
    Y := Y + 5;
    Page.SetFont(FontH, 10);
    Page.WriteText(XStart + (TicketW - MedirTexto('Fecha Pesaje: ' + Datos.Fecha + ' ' + Datos.Hora, 'Helvetica', 10)) / 2, Y, 'Fecha Pesaje: ' + Datos.Fecha + ' ' + Datos.Hora);

    Y := Y + 5;
    Page.WriteText(XCol1, Y, LineaSeparadora);

    // ═══════════ ÁREA DE FIRMAS ═══════════
    Y := Y + 20;
    Page.SetFont(FontH, 9);
    Page.WriteText(XStart + 5, Y, '------------------------------');
    Page.WriteText(XStart + 55, Y, '------------------------------');

    Y := Y + 4;
    Page.WriteText(XStart + 12, Y, '(Operador)');
    Page.WriteText(XStart + 58, Y, '(Chofer/Productor)');

    Stream := TMemoryStream.Create;
    Doc.SaveToStream(Stream);
    Stream.Position := 0;
    Result := True;
  finally
    Doc.Free;
  end;
end;

end.