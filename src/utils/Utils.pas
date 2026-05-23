unit Utils;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

function FormatearFechaHora(const Fecha: TDateTime): string;
function FechaHoraActual: string;
function FormatearPeso(const PesoKg: Integer): string;
function FormatearMoneda(const MontoBs: Integer): string;
function ConvertirFechaISO(const Input: string): string;
function RegistrarFAFuente: Boolean;

implementation

uses
  Theme
  {$IFDEF WINDOWS}, Windows{$ENDIF};

function FormatearFechaHora(const Fecha: TDateTime): string;
begin
  Result := FormatDateTime('dd/mm/yyyy hh:nn:ss', Fecha);
end;

function FechaHoraActual: string;
begin
  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
end;

function FormatearPeso(const PesoKg: Integer): string;
begin
  Result := FormatFloat('#,##0', PesoKg) + ' kg';
end;

function FormatearMoneda(const MontoBs: Integer): string;
begin
  Result := 'Bs ' + FormatFloat('#,##0', MontoBs);
end;

function ConvertirFechaISO(const Input: string): string;
begin
  Result := Input;
  if Length(Input) = 10 then
    if Input[3] in ['-', '/'] then
      Result := Copy(Input, 7, 4) + '-' + Copy(Input, 4, 2) + '-' + Copy(Input, 1, 2);
end;

function RegistrarFAFuente: Boolean;
var
  FontPath: string;
  {$IFDEF WINDOWS}
  NumFonts: Integer;
  FontPathW: UnicodeString;
  {$ENDIF}
begin
  FontPath := ExtractFilePath(ParamStr(0)) + 'fa-solid-900.ttf';

  if not FileExists(FontPath) then
  begin
    FA_FONT_LOADED := False;
    Exit(False);
  end;

  {$IFDEF WINDOWS}
  FontPathW := UnicodeString(FontPath);
  NumFonts := AddFontResourceW(PWideChar(FontPathW));
  Result := NumFonts > 0;
  {$ELSE}
  Result := True;
  {$ENDIF}

  FA_FONT_LOADED := Result;
end;

end.
