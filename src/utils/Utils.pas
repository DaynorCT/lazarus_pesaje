unit Utils;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

function FormatearFechaHora(const Fecha: TDateTime): string;
function FechaHoraActual: string;
function FormatearPeso(const PesoKg: Integer): string;
function FormatearMoneda(const MontoBs: Integer): string;

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

end.
