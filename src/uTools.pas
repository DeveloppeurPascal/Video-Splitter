(* C2PP
  ***************************************************************************

  Video Splitter

  Copyright 2024-2025 Patrick PREMARTIN under AGPL 3.0 license.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
  DEALINGS IN THE SOFTWARE.

  ***************************************************************************

  Author(s) :
  Patrick PREMARTIN

  Site :
  https://videosplitter.olfsoftware.fr

  Project site :
  https://github.com/DeveloppeurPascal/Video-Splitter

  ***************************************************************************
  File last update : 2025-10-16T10:43:17.974+02:00
  Signature : d642546774c6107b6a72f57893d14d014c3f845b
  ***************************************************************************
*)

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
