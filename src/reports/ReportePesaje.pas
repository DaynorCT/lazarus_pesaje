unit ReportePesaje;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, fppdf, fpttf, base64, fpimage, FPReadPNG, FPReadJPEG, DataModule;

function GenerarReportePDF(const FechaDesde, FechaHasta, Placa: string; out Stream: TMemoryStream): Boolean;

implementation

function WinCPToUTF8(const S: string): string;
begin
  Result := S;
end;

type
  TReporteRow = record
    Guia: string;
    FechaStr: string;
    HoraStr: string;
    ChoferNombre: string;
    ChoferCI: string;
    ChoferLicencia: string;
    VehiculoPlaca: string;
    VehiculoTipo: string;
    ProveedorNombre: string;
    ProductoNombre: string;
    OrigenNombre: string;
    DestinoNombre: string;
    PesoBruto, Tara, PesoNeto: Integer;
    CostoBs, FleteBs: Integer;
  end;

  TReporteRows = array of TReporteRow;

function CargarDatosReporte(const FechaDesde, FechaHasta, Placa: string;
  out Datos: TReporteRows; out NombreEmpresa, LogoBase64: string): Boolean;
var
  Q: TSQLQuery;
  SQL: string;
  Row: TReporteRow;
begin
  Result := False;
  SetLength(Datos, 0);
  NombreEmpresa := '';
  LogoBase64 := '';

  SQL :=
    'SELECT p.id, p.guia, p.fecha_creacion, ' +
    'COALESCE(pe.nombre,'''') as chofer_nombre, ' +
    'COALESCE(pe.apellido_paterno,'''') as chofer_ap, ' +
    'COALESCE(pe.apellido_materno,'''') as chofer_am, ' +
    'COALESCE(pe.ci,'''') as chofer_ci, ' +
    'COALESCE(ch.licencia,'''') as chofer_licencia, ' +
    'COALESCE(v.placa,'''') as vehiculo_placa, ' +
    'COALESCE(v.tipo_vehiculo,'''') as vehiculo_tipo, ' +
    'COALESCE(pr.nombre||'' ''||pr.apellido_paterno,'''') as proveedor_nombre, ' +
    'COALESCE(prod.nombre,'''') as producto_nombre, ' +
    'COALESCE(o.nombre,'''') as origen_nombre, ' +
    'COALESCE(d.nombre,'''') as destino_nombre, ' +
    'p.peso_bruto, p.tara, p.peso_neto, p.costo_bs, p.flete_bs_pendiente ' +
    'FROM pesajes p ' +
    'LEFT JOIN vehiculos v ON v.id=p.vehiculo_id ' +
    'LEFT JOIN choferes ch ON ch.id=p.chofer_id ' +
    'LEFT JOIN personas pe ON pe.id=ch.persona_id ' +
    'LEFT JOIN personas pr ON pr.id=(SELECT persona_id FROM proveedores WHERE id=p.proveedor_id) ' +
    'LEFT JOIN productos prod ON prod.id=p.producto_id ' +
    'LEFT JOIN origenes o ON o.id=p.id_origen ' +
    'LEFT JOIN destinos d ON d.id=p.id_destino ' +
    'WHERE p.estado=''ACTIVO''';

  if FechaDesde <> '' then
    SQL := SQL + ' AND p.fecha_creacion >= ''' + FechaDesde + ' 00:00:00''';
  if FechaHasta <> '' then
    SQL := SQL + ' AND p.fecha_creacion <= ''' + FechaHasta + ' 23:59:59''';
  if Placa <> '' then
    SQL := SQL + ' AND UPPER(v.placa) LIKE ''%' + UpperCase(Placa) + '%''';

  SQL := SQL + ' ORDER BY p.id DESC';

  Q := DM.AbrirQuery(SQL);
  try
    while not Q.EOF do
    begin
      Row := Default(TReporteRow);

      Row.Guia := UpperCase(Q.FieldByName('guia').AsString);
      if Length(Q.FieldByName('fecha_creacion').AsString) >= 16 then
      begin
        Row.FechaStr := Copy(Q.FieldByName('fecha_creacion').AsString, 9, 2) + '/' +
                        Copy(Q.FieldByName('fecha_creacion').AsString, 6, 2) + '/' +
                        Copy(Q.FieldByName('fecha_creacion').AsString, 1, 4);
        Row.HoraStr := Copy(Q.FieldByName('fecha_creacion').AsString, 12, 5);
      end;

      Row.ChoferNombre := UpperCase(Q.FieldByName('chofer_nombre').AsString + ' ' +
        Q.FieldByName('chofer_ap').AsString + ' ' + Q.FieldByName('chofer_am').AsString);
      Row.ChoferCI := UpperCase(Q.FieldByName('chofer_ci').AsString);
      Row.ChoferLicencia := UpperCase(Q.FieldByName('chofer_licencia').AsString);
      Row.VehiculoPlaca := UpperCase(Q.FieldByName('vehiculo_placa').AsString);
      Row.VehiculoTipo := UpperCase(Q.FieldByName('vehiculo_tipo').AsString);
      Row.ProveedorNombre := UpperCase(Q.FieldByName('proveedor_nombre').AsString);
      Row.ProductoNombre := UpperCase(Q.FieldByName('producto_nombre').AsString);
      Row.OrigenNombre := UpperCase(Q.FieldByName('origen_nombre').AsString);
      Row.DestinoNombre := UpperCase(Q.FieldByName('destino_nombre').AsString);
      Row.PesoBruto := Q.FieldByName('peso_bruto').AsInteger;
      Row.Tara := Q.FieldByName('tara').AsInteger;
      Row.PesoNeto := Q.FieldByName('peso_neto').AsInteger;
      Row.CostoBs := Q.FieldByName('costo_bs').AsInteger;
      Row.FleteBs := Q.FieldByName('flete_bs_pendiente').AsInteger;

      SetLength(Datos, Length(Datos) + 1);
      Datos[High(Datos)] := Row;

      Q.Next;
    end;
  finally
    Q.Close;
  end;

  if Length(Datos) = 0 then Exit;

  Q := DM.AbrirQuery('SELECT nombre_empresa, logo FROM empresas WHERE estado=''ACTIVO'' ORDER BY id DESC LIMIT 1');
  try
    if not Q.EOF then
    begin
      NombreEmpresa := UpperCase(Q.FieldByName('nombre_empresa').AsString);
      LogoBase64 := Q.FieldByName('logo').AsString;
    end;
  finally
    Q.Close;
  end;

  Result := True;
end;

function GenerarReportePDF(const FechaDesde, FechaHasta, Placa: string; out Stream: TMemoryStream): Boolean;
var
  Doc: TPDFDocument;
  Page: TPDFPage;
  Datos: TReporteRows;
  NombreEmpresa, LogoBase64: string;
  FontH, FontHBold: Integer;
  Y: Double;
  XIzq, XDer: Double;
  XColIzq, XColIzqVal, XColDer, XColDerVal: Double;
  LogoImgIdx: Integer;
  LogoB64Pos: Integer;
  LogoDecoded: string;
  LogoStream: TMemoryStream;
  dashEstilo: Integer;
  ImgW, ImgH, ImgAspect, MaxW, MaxH, DrawW, DrawH: Double;
  i: Integer;
  FechaReporte: string;
  RowY: Double;
  NRowIdx: Integer;
  RowSpacing: Double;
begin
  Result := False;
  if not CargarDatosReporte(FechaDesde, FechaHasta, Placa, Datos, NombreEmpresa, LogoBase64) then Exit;

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

    XIzq := 15;
    XDer := 215;

    XColIzq := 15;
    XColIzqVal := 80;
    XColDer := 145;
    XColDerVal := 210;

    FechaReporte := 'Fecha: ' + FormatDateTime('dd/mm/yyyy hh:nn', Now);

    // Cargar logo
    LogoImgIdx := -1;
    if LogoBase64 <> '' then
    begin
      LogoB64Pos := Pos(';base64,', LogoBase64);
      if LogoB64Pos > 0 then
      begin
        LogoDecoded := DecodeStringBase64(Copy(LogoBase64, LogoB64Pos + 8, MaxInt));
        if Length(LogoDecoded) > 0 then
        begin
          LogoStream := TMemoryStream.Create;
          try
            LogoStream.Write(LogoDecoded[1], Length(LogoDecoded));
            LogoStream.Position := 0;
            if Pos('image/png', LogoBase64) > 0 then
              LogoImgIdx := Doc.Images.AddFromStream(LogoStream, TFPReaderPNG)
            else if Pos('image/jpeg', LogoBase64) > 0 then
              LogoImgIdx := Doc.Images.AddFromStream(LogoStream, TFPReaderJPEG);
          finally
            LogoStream.Free;
          end;
        end;
      end;
    end;

    // ═══════════ ENCABEZADO SIMPLE ═══════════
    Y := 20;

    // Centro: REPORTE DE PESAJE + Nombre Empresa
    Page.SetFont(FontHBold, 16);
    Page.WriteText(90, Y, 'REPORTE DE PESAJE');

    Y := Y + 8;
    if NombreEmpresa <> '' then
    begin
      Page.SetFont(FontHBold, 12);
      Page.WriteText(100, Y, WinCPToUTF8(NombreEmpresa));
      Y := Y + 6;
    end;

    Page.SetFont(FontH, 10);
    Page.WriteText(105, Y, FechaReporte);

    // Logo (derecha)
    Page.SetFont(FontHBold, 8);
    Page.WriteText(215, 20, 'ACREDITADO POR:');
    if LogoImgIdx >= 0 then
    begin
      ImgW := Doc.Images[LogoImgIdx].Width;
      ImgH := Doc.Images[LogoImgIdx].Height;
      ImgAspect := ImgW / ImgH;
      MaxW := 50;
      MaxH := 35;

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

      Page.DrawLine(XDer, 24, XDer + DrawW, 24, 0.2);
      Page.DrawLine(XDer, 24, XDer, 24 + DrawH, 0.2);
      Page.DrawLine(XDer + DrawW, 24, XDer + DrawW, 24 + DrawH, 0.2);
      Page.DrawLine(XDer, 24 + DrawH, XDer + DrawW, 24 + DrawH, 0.2);

      Page.DrawImage(XDer, 24 + DrawH, DrawW, DrawH, LogoImgIdx);
    end;

    Y := Y + 8;
    Page.DrawLineStyle(XIzq, Y, XDer + 51, Y, dashEstilo);
    Y := Y + 5;

    RowSpacing := 6;

    // ═══════════ BLOQUE POR CADA PESAJE ═══════════
    for i := 0 to High(Datos) do
    begin
      RowY := Y;

      NRowIdx := i + 1;
      Page.SetFont(FontHBold, 11);
      Page.WriteText(XColIzq, RowY, 'Nro. ' + IntToStr(NRowIdx));
      Page.WriteText(XColIzq + 30, RowY, 'GUIA: ' + Datos[i].Guia);

      RowY := RowY + RowSpacing;
      Page.DrawLineStyle(XIzq, RowY, XDer + 51, RowY, dashEstilo);
      RowY := RowY + 2;

      // Row 1: Chofer | Vehiculo
      Page.SetFont(FontH, 9);
      Page.WriteText(XColIzq, RowY, 'Chofer:');
      Page.SetFont(FontHBold, 9);
      Page.WriteText(XColIzqVal, RowY, WinCPToUTF8(Datos[i].ChoferNombre));
      Page.SetFont(FontH, 9);
      Page.WriteText(XColDer, RowY, 'Vehiculo:');
      Page.SetFont(FontHBold, 9);
      Page.WriteText(XColDerVal, RowY, Datos[i].VehiculoTipo + ' - ' + Datos[i].VehiculoPlaca);

      RowY := RowY + RowSpacing;

      // Row 2: N° Documento | Licencia
      Page.SetFont(FontH, 9);
      Page.WriteText(XColIzq, RowY, 'Nro. Documento:');
      Page.SetFont(FontHBold, 9);
      Page.WriteText(XColIzqVal, RowY, Datos[i].ChoferCI);
      Page.SetFont(FontH, 9);
      Page.WriteText(XColDer, RowY, 'Licencia:');
      Page.SetFont(FontHBold, 9);
      Page.WriteText(XColDerVal, RowY, Datos[i].ChoferLicencia);

      RowY := RowY + RowSpacing;

      // Row 3: Proveedor | Producto
      Page.SetFont(FontH, 9);
      Page.WriteText(XColIzq, RowY, 'Proveedor:');
      Page.SetFont(FontHBold, 9);
      Page.WriteText(XColIzqVal, RowY, Datos[i].ProveedorNombre);
      Page.SetFont(FontH, 9);
      Page.WriteText(XColDer, RowY, 'Producto:');
      Page.SetFont(FontHBold, 9);
      Page.WriteText(XColDerVal, RowY, WinCPToUTF8(Datos[i].ProductoNombre));

      RowY := RowY + RowSpacing;

      // Row 4: Origen | Destino
      Page.SetFont(FontH, 9);
      Page.WriteText(XColIzq, RowY, 'Origen:');
      Page.SetFont(FontHBold, 9);
      Page.WriteText(XColIzqVal, RowY, WinCPToUTF8(Datos[i].OrigenNombre));
      Page.SetFont(FontH, 9);
      Page.WriteText(XColDer, RowY, 'Destino:');
      Page.SetFont(FontHBold, 9);
      Page.WriteText(XColDerVal, RowY, WinCPToUTF8(Datos[i].DestinoNombre));

      RowY := RowY + RowSpacing;

      // Row 5: P. Bruto | Costo
      Page.SetFont(FontH, 9);
      Page.WriteText(XColIzq, RowY, 'P. Bruto:');
      Page.SetFont(FontHBold, 9);
      Page.WriteText(XColIzqVal, RowY, FormatFloat('#,##0', Datos[i].PesoBruto) + ' kg');
      Page.SetFont(FontH, 9);
      Page.WriteText(XColDer, RowY, 'Costo:');
      Page.SetFont(FontHBold, 9);
      Page.WriteText(XColDerVal, RowY, 'Bs ' + FormatFloat('#,##0', Datos[i].CostoBs));

      RowY := RowY + RowSpacing;

      // Row 6: Tara | Flete
      Page.SetFont(FontH, 9);
      Page.WriteText(XColIzq, RowY, 'Tara:');
      Page.SetFont(FontHBold, 9);
      Page.WriteText(XColIzqVal, RowY, FormatFloat('#,##0', Datos[i].Tara) + ' kg');
      Page.SetFont(FontH, 9);
      Page.WriteText(XColDer, RowY, 'Flete:');
      Page.SetFont(FontHBold, 9);
      Page.WriteText(XColDerVal, RowY, 'Bs ' + FormatFloat('#,##0', Datos[i].FleteBs));

      RowY := RowY + RowSpacing;

      // Row 7: P. Neto | Fecha/Hora
      Page.SetFont(FontH, 9);
      Page.WriteText(XColIzq, RowY, 'P. Neto:');
      Page.SetFont(FontHBold, 9);
      Page.WriteText(XColIzqVal, RowY, FormatFloat('#,##0', Datos[i].PesoNeto) + ' kg');
      Page.SetFont(FontH, 9);
      Page.WriteText(XColDer, RowY, 'Fecha/Hora:');
      Page.SetFont(FontHBold, 9);
      Page.WriteText(XColDerVal, RowY, Datos[i].FechaStr + ' ' + Datos[i].HoraStr);

      RowY := RowY + 2;
      Page.DrawLineStyle(XIzq, RowY, XDer + 51, RowY, dashEstilo);

      Y := RowY + 5;
    end;

    Stream := TMemoryStream.Create;
    Doc.SaveToStream(Stream);
    Stream.Position := 0;
    Result := True;
  finally
    Doc.Free;
  end;
end;

end.
