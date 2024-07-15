unit uTools;

interface

function SecondesToHHMMSS(const DureeEnSecondes: double): string; overload;
function SecondesToHHMMSS(const DureeEnSecondes: int64): string; overload;

implementation

uses
  System.SysUtils;

function SecondesToHHMMSS(const DureeEnSecondes: int64): string;
  function ToString2(nb: int64): string;
  begin
    result := nb.ToString;
    while (result.length < 2) do
      result := '0' + result;
  end;

var
  heures, minutes, secondes: int64;
begin
  secondes := DureeEnSecondes mod 60;
  minutes := DureeEnSecondes div 60;
  heures := minutes div 60;
  minutes := minutes mod 60;
  result := ToString2(heures) + ':' + ToString2(minutes) + ':' +
    ToString2(secondes);
end;

function SecondesToHHMMSS(const DureeEnSecondes: double): string;
var
  DES: string;
begin
  DES := DureeEnSecondes.ToString;
  if (DES.IndexOfAny(['.', ',']) > 0) then
  begin
    result := SecondesToHHMMSS(trunc(DureeEnSecondes)) + ',' +
      DES.Substring(DES.IndexOfAny(['.', ',']) + 1, 3);
    while result.Substring(result.IndexOf(',') + 1).length < 3 do
      result := result + '0';
  end
  else
    result := SecondesToHHMMSS(trunc(DureeEnSecondes)) + ',000';
end;

end.
