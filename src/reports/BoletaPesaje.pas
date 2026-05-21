unit BoletaPesaje;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, fppdf, fpttf, base64, fpimage, FPReadPNG, FPReadJPEG, DataModule;

function GenerarBoletaPDF(PesajeID: Integer; out Stream: TMemoryStream): Boolean;

implementation

function WinCPToUTF8(const S: string): string;
begin
  Result := S;
end;

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

  Q := DM.AbrirQuery('SELECT * FROM boleta_config LIMIT 1');
  try
    if not Q.EOF then
    begin
      Datos.TituloSuperior := UpperCase(Q.FieldByName('titulo_superior').AsString);
      Datos.Marca := UpperCase(Q.FieldByName('marca').AsString);
      Datos.TituloDocumento := UpperCase(Q.FieldByName('titulo_documento').AsString);
      Datos.Salida := UpperCase(Q.FieldByName('salida').AsString);
      Datos.Direccion := UpperCase(Q.FieldByName('direccion').AsString);
      Datos.Celular1 := UpperCase(Q.FieldByName('celular1').AsString);
      Datos.Celular2 := UpperCase(Q.FieldByName('celular2').AsString);
      Datos.Ciudad := UpperCase(Q.FieldByName('ciudad').AsString);
    end;
  finally
    Q.Close;
  end;

  Q := DM.AbrirQuery('SELECT logo FROM empresas WHERE estado=''ACTIVO'' ORDER BY id DESC LIMIT 1');
  try
    if not Q.EOF then
      Datos.LogoBase64 := Q.FieldByName('logo').AsString;
  finally
    Q.Close;
  end;

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
    Result := Length(Texto) * FontSize * 0.32;
end;

function GenerarBoletaPDF(PesajeID: Integer; out Stream: TMemoryStream): Boolean;
var
  Doc: TPDFDocument;
  Page: TPDFPage;
  Datos: TBoletaData;
  FontH, FontHBold: Integer;
  Y: Double;
  EscalaY: Double;
  YCSup, YCMar, YCDoc: Double;
  XCol1, XCol2: Double;
  XIzq, XCentro, XDer: Double;
  XTit, XMar, XDoc: Double;
  LogoImgIdx: Integer;
  LogoB64Pos: Integer;
  LogoDecoded: string;
  LogoStream: TMemoryStream;
  dashEstilo: Integer;
begin
  Result := False;
  if not CargarDatosBoleta(PesajeID, Datos) then Exit;

  Doc := TPDFDocument.Create(nil);
  try
    Doc.DefaultOrientation := ppoPortrait;
    Doc.DefaultPaperType := ptLetter; 
    Doc.Options := [poPageOriginAtTop];
    Doc.StartDocument;

    dashEstilo := Doc.AddLineStyleDef(0.3, clBlack, ppsDash);

    FontH := Doc.AddFont('Helvetica');
    FontHBold := Doc.AddFont('Helvetica-Bold');

    Page := Doc.Pages.AddPage;
    Doc.Sections.AddSection.AddPage(Page);

    Page.UnitOfMeasure := uomMillimeters;
    Page.PaperType := ptLetter;

    // Las 3 coordenadas solicitadas para el encabezado
    XIzq := 20;
    XCentro := 80;
    XDer := 165;
    XTit := 77;
    XMar := 89;
    XDoc := 85;
    YCSup := 15;
    YCMar := 24;
    YCDoc := 35;

    EscalaY := (279 - 15 - 15) / 153;

    // Alineación para centrar el cuerpo de datos de forma equilibrada
    XCol1 := 30;
    XCol2 := 80;

    // Cargar logo de la empresa
    LogoImgIdx := -1;
    if Datos.LogoBase64 <> '' then
    begin
      LogoB64Pos := Pos(';base64,', Datos.LogoBase64);
      if LogoB64Pos > 0 then
      begin
        LogoDecoded := DecodeStringBase64(Copy(Datos.LogoBase64, LogoB64Pos + 8, MaxInt));
        if Length(LogoDecoded) > 0 then
        begin
          LogoStream := TMemoryStream.Create;
          try
            LogoStream.Write(LogoDecoded[1], Length(LogoDecoded));
            LogoStream.Position := 0;
            if Pos('image/png', Datos.LogoBase64) > 0 then
              LogoImgIdx := Doc.Images.AddFromStream(LogoStream, TFPReaderPNG)
            else if Pos('image/jpeg', Datos.LogoBase64) > 0 then
              LogoImgIdx := Doc.Images.AddFromStream(LogoStream, TFPReaderJPEG);
          finally
            LogoStream.Free;
          end;
        end;
      end;
    end;

    // ═══════════ ENCABEZADO 3 COLUMNAS ═══════════

    // --- FILA 1 ---
    Y := 15;
    Page.SetFont(FontHBold, 10);
    Page.WriteText(XIzq, Y, WinCPToUTF8(Datos.Salida));
    
    Page.SetFont(FontHBold, 11);
    Page.WriteText(XTit, YCSup, Datos.TituloSuperior);
    
    Page.SetFont(FontHBold, 9);
    Page.WriteText(XDer, Y, 'ACREDITADO POR:');
    if LogoImgIdx >= 0 then
    begin
      Page.DrawLine(XDer, Y + 4, XDer + 30, Y + 4, 0.2);
      Page.DrawLine(XDer, Y + 4, XDer, Y + 26, 0.2);
      Page.DrawLine(XDer + 30, Y + 4, XDer + 30, Y + 26, 0.2);
      Page.DrawLine(XDer, Y + 26, XDer + 30, Y + 26, 0.2);
      Page.DrawImage(XDer + 3, Y + 24, 24, 18, LogoImgIdx);
    end;

    // --- FILA 2 ---
    Y := Y + 5 * EscalaY;
    Page.SetFont(FontH, 9);
    Page.WriteText(XIzq, Y, WinCPToUTF8(Datos.Direccion));
    
    Page.SetFont(FontHBold, 18);
    Page.WriteText(XMar, YCMar, Datos.Marca);

    // --- FILA 3 ---
    Y := Y + 5 * EscalaY;
    Page.SetFont(FontH, 9);
    Page.WriteText(XIzq, Y, 'Cel: ' + Datos.Celular1);
    
    Page.SetFont(FontHBold, 13);
    Page.WriteText(XDoc, YCDoc, Datos.TituloDocumento);

    // --- FILA 4 ---
    Y := Y + 4.5 * EscalaY;
    Page.SetFont(FontH, 9);
    Page.WriteText(XIzq + 7, Y, Datos.Celular2);

    // --- FILA 5 ---
    Y := Y + 4.5 * EscalaY;
    Page.SetFont(FontH, 9);
    Page.WriteText(XIzq, Y, WinCPToUTF8(Datos.Ciudad));

    // --- FILA 6 ---
    Y := Y + 12 * EscalaY;
    Page.SetFont(FontH, 9);
    Page.WriteText(XIzq, Y, 'Guia: ' + Datos.Guia);

    Y := Y + 3 * EscalaY;
    Page.DrawLineStyle(XIzq, Y, XDer + 35, Y, dashEstilo);

    // ═══════════ DATOS DEL VEHÍCULO ═══════════
    Y := Y + 5 * EscalaY;
    Page.SetFont(FontHBold, 11);
    Page.WriteText(XCentro - 5, Y, 'DATOS DEL VEHICULO');

    Y := Y + 5 * EscalaY;
    Page.SetFont(FontH, 10);
    Page.WriteText(XCol1, Y, 'Placa:');
    Page.WriteText(XCol2, Y, Datos.VehiculoPlaca);

    Y := Y + 5 * EscalaY;
    Page.WriteText(XCol1, Y, 'Chofer:');
    Page.WriteText(XCol2, Y, WinCPToUTF8(Datos.ChoferNombre));

    Y := Y + 5 * EscalaY;
    Page.WriteText(XCol1, Y, 'Licencia:');
    Page.WriteText(XCol2, Y, Datos.ChoferLicencia);

    Y := Y + 5 * EscalaY;
    Page.WriteText(XCol1, Y, 'Proveedor:');
    Page.WriteText(XCol2, Y, Datos.ProveedorNombre);

    Y := Y + 5 * EscalaY;
    Page.WriteText(XCol1, Y, 'Tipo Vehiculo:');
    Page.WriteText(XCol2, Y, WinCPToUTF8(Datos.VehiculoTipo));

    Y := Y + 3 * EscalaY;
    Page.DrawLineStyle(XIzq, Y, XDer + 35, Y, dashEstilo);

    // ═══════════ DATOS DE CARGA ═══════════
    Y := Y + 5 * EscalaY;
    Page.SetFont(FontHBold, 11);
    Page.WriteText(XCentro - 3, Y, 'DATOS DE CARGA');

    Y := Y + 5 * EscalaY;
    Page.SetFont(FontH, 10);
    Page.WriteText(XCol1, Y, 'Producto:');
    Page.WriteText(XCol2, Y, WinCPToUTF8(Datos.ProductoNombre));

    Y := Y + 5 * EscalaY;
    Page.WriteText(XCol1, Y, 'Costo Bs.:');
    Page.WriteText(XCol2, Y, IntToStr(Datos.CostoBs) + ' Bs');

    Y := Y + 5 * EscalaY;
    Page.WriteText(XCol1, Y, 'Origen:');
    Page.WriteText(XCol2, Y, WinCPToUTF8(Datos.OrigenNombre));

    Y := Y + 5 * EscalaY;
    Page.WriteText(XCol1, Y, 'Destino:');
    Page.WriteText(XCol2, Y, WinCPToUTF8(Datos.DestinoNombre));

    Y := Y + 5 * EscalaY;
    Page.WriteText(XCol1, Y, 'Flete Bs.:');
    Page.WriteText(XCol2, Y, IntToStr(Datos.FleteBs) + ' Bs');


    Y := Y + 3 * EscalaY;
    Page.DrawLineStyle(XIzq, Y, XDer + 35, Y, dashEstilo);

    // ═══════════ BLOQUE DE PESOS EN 3 COLUMNAS COORDINADAS ═══════════
    Y := Y + 5 * EscalaY;
    Page.SetFont(FontHBold, 10);
    Page.WriteText(XCol1, Y, '[PESO BRUTO:');
    Page.WriteText(XCentro + 20, Y, '[PESO TARA:');
    Page.WriteText(XDer, Y, '[PESO NETO:');

    Y := Y + 6 * EscalaY;
    Page.SetFont(FontHBold, 16); // Pesos grandes y en negrita
    Page.WriteText(XCol1, Y, FormatFloat('#,##0', Datos.PesoBruto) + ' kg');
    Page.WriteText(XCentro + 20, Y, FormatFloat('#,##0', Datos.Tara) + ' kg');
    Page.WriteText(XDer, Y, FormatFloat('#,##0', Datos.PesoNeto) + ' kg');

    Y := Y + 4 * EscalaY;
    Page.SetFont(FontH, 9);
    Page.DrawLineStyle(XIzq, Y, XDer + 35, Y, dashEstilo);

    // ═══════════ PIE CON FECHA DE PESAJE ═══════════
    Y := Y + 5 * EscalaY;
    Page.SetFont(FontH, 11);
    Page.WriteText(XIzq, Y, 'Fecha/Hora (Pes): ' + Datos.Fecha + ' ' + Datos.Hora);
   
    Page.SetFont(FontH, 11);
    Page.WriteText(XCentro + 63, Y, 'Fecha/Hora (Imp): ' + Datos.Fecha + ' ' + Datos.Hora);

    Y := Y + 4 * EscalaY;
    Page.DrawLineStyle(XIzq, Y, XDer + 35, Y, dashEstilo);
    

    // ═══════════ SECCIÓN DE FIRMAS ═══════════
    Y := Y + 25 * EscalaY;
    Page.SetFont(FontH, 10);
    Page.WriteText(XIzq + 10, Y, '-----------------------------------------------');
    Page.WriteText(XCentro + 20, Y, '-----------------------------------------------');

    Y := Y + 4 * EscalaY;
    Page.WriteText(XIzq + 25, Y, '(Operador)');
    Page.WriteText(XCentro + 35, Y, '(Chofer/Productor)');

    Stream := TMemoryStream.Create;
    Doc.SaveToStream(Stream);
    Stream.Position := 0;
    Result := True;
  finally
    Doc.Free;
  end;
end;

end.