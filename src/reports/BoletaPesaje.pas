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
  XColIzq, XColIzqVal, XColDer, XColDerVal: Double;
  LogoImgIdx: Integer;
  LogoB64Pos: Integer;
  LogoDecoded: string;
   LogoStream: TMemoryStream;
   dashEstilo: Integer;
   ImgW, ImgH, ImgAspect, MaxW, MaxH, DrawW, DrawH, OffX, OffY: Double;
begin
  Result := False;
  if not CargarDatosBoleta(PesajeID, Datos) then Exit;

  Doc := TPDFDocument.Create(nil);
  try
    Doc.DefaultOrientation := ppoLandscape;
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
    Page.Orientation := ppoLandscape;

    // Posiciones horizontal (Landscape: 279mm)
    XIzq := 15;
    XDer := 220;
    XTit := 80;
    XMar := 100;
    XDoc := 95;
    YCSup := 12;
    YCMar := 22;
    YCDoc := 32;
    
    // Columnas de datos (2 columnas lado a lado)
    XColIzq := 15;
    XColIzqVal := 80;
    XColDer := 155;
    XColDerVal := 220;

    EscalaY := 1.0;

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
    Y := 12;
    Page.SetFont(FontHBold, 11);
    Page.WriteText(XIzq, Y, WinCPToUTF8(Datos.Salida));

    Page.SetFont(FontHBold, 13);
    Page.WriteText(XTit, YCSup, Datos.TituloSuperior);

    Page.SetFont(FontHBold, 9);
    Page.WriteText(XDer, Y, 'ACREDITADO POR:');
    if LogoImgIdx >= 0 then
    begin
      // Ajustar logo proporcionalmente sin deformar
      ImgW := Doc.Images[LogoImgIdx].Width;
      ImgH := Doc.Images[LogoImgIdx].Height;
      ImgAspect := ImgW / ImgH;
      MaxW := 34;
      MaxH := 27;

      if ImgW / MaxW > ImgH / MaxH then
      begin
        DrawW := MaxW;
        DrawH := MaxW / ImgAspect;
      end
      else
      begin
        DrawH := MaxH;
        DrawW := MaxH * ImgAspect;
      end;

      OffX := (MaxW - DrawW) / 2;
      OffY := (MaxH - DrawH) / 2;

      Page.DrawImage(XDer + 3 + OffX, Y + 33 - OffY, DrawW, DrawH, LogoImgIdx);
    end;

    // --- FILA 2 ---
    Y := Y + 5;
    Page.SetFont(FontH, 10);
    Page.WriteText(XIzq, Y, WinCPToUTF8(Datos.Direccion));

    Page.SetFont(FontHBold, 22);
    Page.WriteText(XMar, YCMar, Datos.Marca);

    // --- FILA 3 ---
    Y := Y + 5;
    Page.SetFont(FontH, 10);
    Page.WriteText(XIzq, Y, 'Cel: ' + Datos.Celular1);

    Page.SetFont(FontHBold, 15);
    Page.WriteText(XDoc, YCDoc, Datos.TituloDocumento);

    // --- FILA 4 ---
    Y := Y + 4;
    Page.SetFont(FontH, 10);
    Page.WriteText(XIzq + 7, Y, Datos.Celular2);

    // --- FILA 5 ---
    Y := Y + 4;
    Page.SetFont(FontH, 10);
    Page.WriteText(XIzq, Y, WinCPToUTF8(Datos.Ciudad));

    // --- FILA 6 ---
    Y := Y + 18;
    Page.SetFont(FontH, 10);
    Page.WriteText(XIzq, Y, 'Guia: ' + Datos.Guia);
 

    Y := Y + 3;
    Page.DrawLineStyle(XIzq, Y, XDer + 35, Y, dashEstilo);

    // ═══════════ 2 COLUMNAS: DATOS ═══════════
    Y := Y + 5;

    // Títulos de sección
    Page.SetFont(FontHBold, 13);
    Page.WriteText(XColIzq, Y, 'DATOS DEL VEHICULO:');
    Page.WriteText(XColDer, Y, 'DATOS DEL PESAJE:');

    // Row 1
    Y := Y + 7;
    Page.SetFont(FontH, 12);
    Page.WriteText(XColIzq, Y, 'Placa:');
    Page.WriteText(XColIzqVal, Y, Datos.VehiculoPlaca);
    Page.WriteText(XColDer, Y, 'Producto:');
    Page.WriteText(XColDerVal, Y, WinCPToUTF8(Datos.ProductoNombre));

    // Row 2
    Y := Y + 7;
    Page.WriteText(XColIzq, Y, 'Chofer:');
    Page.WriteText(XColIzqVal, Y, WinCPToUTF8(Datos.ChoferNombre));
    Page.WriteText(XColDer, Y, 'Costo Bs.:');
    Page.WriteText(XColDerVal, Y, IntToStr(Datos.CostoBs) + ' Bs');

    // Row 3
    Y := Y + 7;
    Page.WriteText(XColIzq, Y, 'Licencia:');
    Page.WriteText(XColIzqVal, Y, Datos.ChoferLicencia);
    Page.WriteText(XColDer, Y, 'Origen:');
    Page.WriteText(XColDerVal, Y, WinCPToUTF8(Datos.OrigenNombre));

    // Row 4
    Y := Y + 7;
    Page.WriteText(XColIzq, Y, 'Proveedor:');
    Page.WriteText(XColIzqVal, Y, Datos.ProveedorNombre);
    Page.WriteText(XColDer, Y, 'Destino:');
    Page.WriteText(XColDerVal, Y, WinCPToUTF8(Datos.DestinoNombre));

    // Row 5
    Y := Y + 7;
    Page.WriteText(XColIzq, Y, 'Tipo Vehiculo:');
    Page.WriteText(XColIzqVal, Y, WinCPToUTF8(Datos.VehiculoTipo));
    Page.WriteText(XColDer, Y, 'Flete Bs.:');
    Page.WriteText(XColDerVal, Y, IntToStr(Datos.FleteBs) + ' Bs');

    Y := Y + 3;
    Page.DrawLineStyle(XIzq, Y, XDer + 35, Y, dashEstilo);

    // ═══════════ BLOQUE DE PESOS ═══════════
    Y := Y + 5;
    Page.SetFont(FontHBold, 12);
    Page.WriteText(XColIzq, Y, 'PESO BRUTO:');
    Page.WriteText(XColDer - 10, Y, 'PESO TARA:');
    Page.WriteText(XDer - 10, Y, 'PESO NETO:');

    Y := Y + 6;
    Page.SetFont(FontHBold, 18);
    Page.WriteText(XColIzq, Y, FormatFloat('#,##0', Datos.PesoBruto) + ' kg');
    Page.WriteText(XColDer - 10, Y, FormatFloat('#,##0', Datos.Tara) + ' kg');
    Page.WriteText(XDer - 10, Y, FormatFloat('#,##0', Datos.PesoNeto) + ' kg');

    Y := Y + 4;
    Page.DrawLineStyle(XIzq, Y, XDer + 35, Y, dashEstilo);

    // ═══════════ FECHA/HORA ═══════════
    Y := Y + 5;
    Page.SetFont(FontH, 11);
    Page.WriteText(XIzq, Y, 'Fecha/Hora (Pes): ' + Datos.Fecha + ' ' + Datos.Hora);
    Page.WriteText(XColDer, Y, 'Fecha/Hora (Imp): ' + Datos.Fecha + ' ' + Datos.Hora);

    Y := Y + 4;
    Page.DrawLineStyle(XIzq, Y, XDer + 35, Y, dashEstilo);

    // ═══════════ FIRMAS ═══════════
    Y := Y + 12;
    Page.DrawLine(XIzq + 10, Y, XIzq + 110, Y, 0.3);
    Page.DrawLine(XColDer, Y, XDer + 35, Y, 0.3);

    Y := Y + 4;
    Page.SetFont(FontH, 10);
    Page.WriteText(XIzq + 35, Y, '(Operador)');
    Page.WriteText(XColDer + 25, Y, '(Chofer/Productor)');

    Stream := TMemoryStream.Create;
    Doc.SaveToStream(Stream);
    Stream.Position := 0;
    Result := True;
  finally
    Doc.Free;
  end;
end;

end.