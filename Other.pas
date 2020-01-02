unit Other;

interface

uses
  Windows,
  SysUtils,
  Classes,

  Shared,
  Default;

function BytesToTraffStrGB(Data: UInt32; Delta: UInt32 = 1000): LStr;
function BytesToTraffStrMB(Data: UInt32; Delta: UInt32 = 1000): LStr;
function BytesToTraffStrKB(Data: UInt32; Delta: UInt32 = 1000): LStr;
function BytesToTraffStr(Data: UInt32; Delta: UInt32 = 1000): LStr;

function GetTime:LStr;
function DataProp(S: TDateTime): LStr;

function LinesCountInFile(FileName: LStr): Int32;


const
  TIME_STR_LENGTH = Length('00:00:00');
  TIME_STR_LENGTH_EX = Length('00:00:00 - ');

implementation

{$REGION 'Traffic'}
function BytesToTraffStrGB(Data: UInt32; Delta: UInt32 = 1000): LStr;
var
  S, S2 : LStr;
begin
  S := ParseBefore(FloatToStrDot(Data / 1024 / 1024 / 1024 * (1000 / Delta)), '.');

  if Pos('.', FloatToStrDot(Data / 1024 / 1024 / 1024 * (1000 / Delta))) <> 0 then
    S2 := Copy(ParseAfter(FloatToStrDot(Data / 1024 / 1024 / 1024 * (1000 / Delta)), '.'), 1, 1)
  else
    S2 := '0';

  Result := S + '.' + S2;
end;

function BytesToTraffStrMB(Data: UInt32; Delta: UInt32 = 1000): LStr;
var
  S, S2 : LStr;
begin
  S := ParseBefore(FloatToStrDot(Data / 1024 / 1024 * (1000 / Delta)), '.');

  if Pos('.', FloatToStrDot(Data / 1024 / 1024 * (1000 / Delta))) <> 0 then
    S2 := Copy(ParseAfter(FloatToStrDot(Data / 1024 / 1024 * (1000 / Delta)), '.'), 1, 1)
  else
    S2 := '0';

  Result := S + '.' + S2;
end;

function BytesToTraffStrKB(Data: UInt32; Delta: UInt32 = 1000): LStr;
var
  S, S2 : LStr;
begin
  S := ParseBefore(FloatToStrDot(Data /1024 * (1000 / Delta)), '.');

  if Pos('.', FloatToStrDot(Data / 1024 * (1000 / Delta))) <> 0 then
    S2 := Copy(ParseAfter(FloatToStrDot(Data / 1024 * (1000 / Delta)), '.'), 1, 1)
  else
    S2 := '0';

  Result := S + '.' + S2;
end;

function BytesToTraffStr(Data: UInt32; Delta: UInt32 = 1000): LStr;
begin
  if Data < 1024 * 1024 then
    Result := BytesToTraffStrKB(Data, Delta) + ' kb'
  else
    if Data < 1024 * 1024 * 1024 then
      Result := BytesToTraffStrMB(Data, Delta) + ' mb'
    else
      Result := BytesToTraffStrGB(Data, Delta) + ' gb';
end;
{$ENDREGION}

function GetTime: LStr;
var
  Time: TSystemTime;
  H, M, S: LStr;
begin
  GetLocalTime(Time);
  H := IntToStr(Time.wHour);
  M := IntToStr(Time.wMinute);
  S := IntToStr(Time.wSecond);
  if Length(H) < 2 then H := '0' + H;
  if Length(M) < 2 then M := '0' + M;
  if Length(S) < 2 then S := '0' + S;
  Result:= H + ':' + M + ':' + S;
end;

function DataProp(S: TDateTime): LStr;
const
   M: array[1..12] of LStr = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
var
   Year, Month, Day: Word;
begin
   DecodeDate(S, Year, Month, Day);
   Result := IntToStr(day) + SS + M[Month] + SS + IntToStr(Year);
end;

function LinesCountInFile(FileName: LStr): Int32;
var
  F: TextFile;
  Count: Int32;
begin
  AssignFile(F, FileName);
  Reset(F);
  Clear(Result);
  Clear(Count);

  while not Eof(F) do
  begin
    ReadLn(F);
    Inc(Count);
  end;

  CloseFile(F);

  Result := Count;
end;

end.

