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

implementation

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

end.
