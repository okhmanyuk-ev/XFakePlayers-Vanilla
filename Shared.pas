unit Shared;

{
-> maybe userinfo to UserInfo.pas ?
}

interface

uses
  Windows,
  SysUtils,
  Math,
  Default;

type
  TRGBA = record // to color pas
    R, G, B, A: UInt8;

    function ToString: LStr;
  end;

  TRGB = record
    R, G, B: UInt8;

    function ToString: LStr;
  end;

{$REGION 'Parse'}
function FirstWord(Data: LStr): LStr;
function SecondWord(Data: LStr): LStr;
function SecondWordEnd(Data:LStr):LStr;

function RemoveQuotes(Data: LStr): LStr;

function ParseAfter(Data, Separator: LStr; SaveOnFailure: Boolean = True): LStr;
function ParseBefore(Data, Separator: LStr; SaveOnFailure: Boolean = True): LStr;
function ParseBetween(Data, After, Before: LStr; SaveOnFailure: Boolean = True): LStr;

procedure DeleteBefore(var Data: LStr; Separator: LStr; SeparatorIncluded: Boolean = False);

function IsNumbers(Data: LStr): Boolean;
function Reverse(Data: LStr): LStr;
function RemoveTBytes(Data: LStr): LStr;
function ReadLine(Data: LStr): LStr;

function StrBComp(S1, S2: LStr): Boolean;

procedure WriteFile(FileName, Data: LStr); overload;
procedure WriteFile(FileName: LStr); overload;

function SecToTimeStr(Seconds: Int32): LStr; overload;
function SecToTimeStr(Seconds: Float): LStr; overload;

function Chance(APercent: UInt8): Boolean; inline;
{$ENDREGION}

{$REGION 'User Info'}
function Info_IsValid(Data: LStr): Boolean;
function Info_IsKeySet(Data, Key: LStr): Boolean;
function Info_IsKeyDataSet(Data, Key: LStr): Boolean;
function Info_Read(Data, Key: LStr; var Value: LStr): Boolean; overload;
function Info_Read(Data, Key: LStr): LStr; overload;
function Info_Remove(var Data: LStr; Key: LStr): Boolean;
function Info_Change(var Data: LStr; Key: LStr; NewStr: LStr): Boolean;
procedure Info_Add(var Data: LStr; Key, Value: LStr);
{$ENDREGION}

{$REGION 'Other'}
function ShowBytes(AData: LStr): LStr;
function ShowBytesEx(AData: LStr): LStr;
function ShowBytesEx2(AData: LStr): LStr;

function IsSafeFilePath(Data: LStr): Boolean;
function IsSafeFileToDownload(AName: LStr): Boolean;
function NormalizePath(Data: LStr): LStr;
function MD5_IsValid(Data: LStr): Boolean;
function FixSlashes(Data: LStr): LStr;
function FixSlashes2(Data: LStr): LStr;

function GetParam(AParam: LStr): LStr;
function HasParam(AParam: LStr): Boolean;
function GetParamValue(AParam: LStr): LStr;
function HasParamValue(AParam: LStr): Boolean;


function DeltaTicks(ASavedTickCount: UInt32): Int32; inline;
{$ENDREGION}


{$REGION '2010kohtep stuff'}
//function GetRandomHash: LStr;
function GetRandomString(Size: UInt32; IncludeNumbers: Boolean = False): LStr; //overload;
{$ENDREGION}

// color
procedure WriteRGB(var Data: LStr; Value: TRGB); overload; inline;
function WriteRGB(Value: TRGB): LStr; overload; inline;

procedure WriteRGBA(var Data: LStr; Value: TRGBA); overload; inline;
function WriteRGBA(Value: TRGBA): LStr; overload; inline;

procedure Clear(var Data: TRGB); overload; inline;
procedure Clear(var Data: TRGBA); overload; inline;


const
  SS = ' ';
  ValidFileExt: array[1..9] of PLChar = ('mdl', 'tga', 'wad', 'spr', 'bsp', 'wav', 'mp3', 'res', 'txt');

implementation

{$REGION 'Color'}
function TRGB.ToString: LStr;
begin
  Result := StringFromVarRec(['R: ', R, ', G: ', G, ', B: ', B]);
end;

function TRGBA.ToString: LStr;
begin
  Result := StringFromVarRec(['R: ', R, ', G: ', G, ', B: ', B, ', A: ', A]);
end;
{$ENDREGION}

{$REGION 'Parse'}
function FirstWord(Data: LStr): LStr;
begin
  Result := ParseBefore(Data, SS);
end;

function SecondWord(Data: LStr): LStr;
begin
  Result := FirstWord(SecondWordEnd(Data));
end;

function SecondWordEnd(Data: LStr): LStr;
begin
  Result := TrimLeft(ParseAfter(Data, SS, False));
end;

function RemoveQuotes(Data: LStr): LStr;
begin
  Result := Data;

  while Pos('"', Result) <> 0 do
    Delete(Result, Pos('"', Result), 1);
end;

function ParseAfter(Data, Separator: LStr; SaveOnFailure: Boolean = True): LStr;
begin
  Clear(Result);

  if Pos(Separator, Data) <> 0 then
    Result := Copy(Data, Pos(Separator, Data) + Length(Separator), Length(Data) - Pos(Separator, Data))
  else
    if SaveOnFailure then
      Result := Data
end;

function ParseBefore(Data, Separator: LStr; SaveOnFailure: Boolean = True): LStr;
begin
  Clear(Result);

  if Pos(Separator, Data) <> 0 then
    Result := Copy(Data, 1, Pos(Separator, Data) - 1)
  else
    if SaveOnFailure then
      Result := Data
end;

function ParseBetween(Data, After, Before: LStr; SaveOnFailure: Boolean = True): LStr;
begin
  Clear(Result);

  Result := ParseBefore(ParseAfter(Data, After, SaveOnFailure), Before, SaveOnFailure);
end;

procedure DeleteBefore(var Data: LStr; Separator: LStr; SeparatorIncluded: Boolean = False);
begin
  if SeparatorIncluded then
    Delete(Data, 1, Pos(Separator, Data) - 1 + Length(Separator))
  else
    Delete(Data, 1, Pos(Separator, Data) - 1);
end;

function IsNumbers(Data: LStr): Boolean;
var
  C: LChar;
begin
  Result := True;

  if Length(Data) = 0 then
    Exit(False);

  for C in Data do
    if not (C in ['-', '0', '1'..'9']) then
      Exit(False);
end;

function Reverse(Data: LStr): LStr;
var
  C: LChar;
begin
  Clear(Result);

  for C in Data do
    Result := C + Result;
end;

function RemoveTBytes(Data: LStr): LStr;
var
  C: LChar;
begin
  Clear(Result);

  for C in Data do
    if UInt8(C) > 20 then
      Result := Result + C;
end;

function ReadLine(Data: LStr): LStr;
begin
  Result := ParseBefore(Data, #$0A);
end;

function StrBComp(S1, S2: LStr): Boolean;
begin
  Result := StrLComp(PLChar(S1), PLChar(S2), Length(S2)) = 0;
end;

procedure WriteFile(FileName, Data: LStr);
var
  F: TextFile;
begin
  FileName := FixSlashes(FileName);

  if ExtractFileDir(FileName) <> '' then
    if not DirectoryExists(ExtractFileDir(FileName)) then
      ForceDirectories(GetCurrentDir + '\' + ExtractFileDir(FileName));

  AssignFile(F, FileName);
  ReWrite(F);
  Write(F, Data);
  CloseFile(F);
end;

procedure WriteFile(FileName: LStr);
begin
  WriteFile(FileName, '');
end;

function SecToTimeStr(Seconds: Int32): LStr;
var
  H, M, S: LStr;
  ZH, ZM, ZS: Int32;
begin
  ZH := Seconds div 3600;
  ZM := Seconds div 60 - ZH * 60;
  ZS := Seconds - (ZH * 3600 + ZM * 60);

  H := IntToStr(ZH);
  M := IntToStr(ZM);
  S := IntToStr(ZS);

  if (ZH <= 9) and (ZH >= 0) then
    H := '0' + IntToStr(ZH);

  if (ZM <= 9) and (ZM >= 0) then
    M := '0' + IntToStr(ZM);

  if (ZS <= 9) and (ZS >= 0) then
    S := '0' + IntToStr(ZS);

   Result := H + ':' + M + ':' + S;

   {while Pos('-', Result) > 0 do
    Delete(Result, Pos('-', Result), 1);}
end;

function SecToTimeStr(Seconds: Float): LStr;
begin
  Result := SecToTimeStr(Int32(Trunc(Seconds)));
end;

function Chance(APercent: UInt8): Boolean;
begin
  Result := Random(100) < APercent;
end;
{$ENDREGION}

{$REGION 'UserInfo'}
function Info_IsValid(Data: LStr): Boolean;
begin
  Result := True; //fix it
end;

function Info_IsKeySet(Data, Key: LStr): Boolean;
begin
  Result := Pos('\' + Key + '\', AnsiLowerCase(Data)) <> 0;
end;

function Info_IsKeyDataSet(Data, Key: LStr): Boolean;
begin
  Result := Info_Read(Data, Key) <> '';
end;

function Info_Read(Data, Key: LStr; var Value: LStr): Boolean;
begin
  Result := True;

  if not Info_IsKeySet(Data, Key) then
  begin
    Result := False;
    Exit;
  end;

  Value := ParseBefore(ParseBefore(ParseAfter(Data, '\' + Key + '\'), '\'), '"');
end;

function Info_Read(Data, Key: LStr): LStr;
begin
  Clear(Result);
  Info_Read(Data, Key, Result);
end;

function Info_Remove(var Data: LStr; Key: LStr): Boolean;
begin
  Result := True;

  if not Info_IsKeySet(Data, Key) then
  begin
    Result := False;
    Exit;
  end;

  Delete(Data, Pos('\' + Key + '\', Data), Length('\' + Key + '\' + Info_Read(Data, Key)));
end;

function Info_Change(var Data: LStr; Key: LStr; NewStr: LStr): Boolean;
begin
  Result := True;

  if not Info_IsKeySet(Data, Key) then
  begin
    Result := False;
    Exit;
  end;

  Delete(Data, Pos('\' + Key + '\', Data) + Length('\' + Key + '\'), Length(Info_Read(Data, Key)));

  if ParseAfter(Data, '\' + Key + '\')[1] = '\' then
  begin
    Delete(Data, Pos('\' + Key + '\', Data) + Length('\' + Key + '\'), 1);
    Insert(NewStr + '\', Data, Pos('\' + Key + '\', Data) + Length('\' + Key + '\'));
  end
  else
    Insert(NewStr, Data, Pos('\' + Key + '\', Data) + Length('\' + Key + '\'));
end;

procedure Info_Add(var Data: LStr; Key, Value: LStr);
begin
  Data := Data + '\' + Key + '\' + Value;
end;
{$ENDREGION}

{$REGION 'Other'}
function ShowBytes(AData: LStr): LStr;
var
  C: LChar;
begin
  Clear(Result);

  for C in AData do
    Result := Result + '#' + IntToStr(UInt8(C));
end;

function ShowBytesEx(AData: LStr): LStr;
var
  C: LChar;
begin
  Clear(Result);

  for C in AData do
    if UInt8(C) > 30 then
      Result := Result + C
    else
      Result := Result + '#' + IntToStr(UInt8(C));
end;

function ShowBytesEx2(AData: LStr): LStr;
var
  C: LChar;
begin
  Clear(Result);

  for C in AData do
    if UInt8(C) > 30 then
      Result := Result + C;
end;

function IsSafeFilePath(Data: LStr): Boolean;
var
  I: UInt32;
  S2: PLChar;
begin
  if Data = '' then
    Result := False
  else
    if StrLComp(PLChar(Data), '!MD5', 4) = 0 then
      Result := MD5_IsValid(ReadEnd(Data, 5))
 else
  if (Data[1] in ['\', '/', '.']) or (StrScan(PLChar(Data), ':') <> nil) or (StrPos(PLChar(Data), '..') <> nil) or
     (StrPos(PLChar(Data), '//') <> nil) or (StrPos(PLChar(Data), '\\') <> nil) or (StrPos(PLChar(Data), '~/') <> nil) or
     (StrPos(PLChar(Data), '~\') <> nil) then
    Result := False
  else
  begin
    S2 := StrScan(PLChar(Data), '.');

    if (StrLen(PLChar(Data)) < 3) or (S2 = nil) or (StrRScan(PLChar(Data), '.') <> S2) or (StrLen(S2) <= 1) then
      Result := False
    else
    begin
      Inc(UInt32(S2));

      for I := Low(ValidFileExt) to High(ValidFileExt) do
        if StrIComp(S2, ValidFileExt[I]) = 0 then
        begin
          Result := True;
          Exit;
        end;

      Result := False;
    end;
  end;
end;

function IsSafeFileToDownload(AName: LStr): Boolean;
begin
  Result := (Pos('\\', AName) = 0)
    and (Pos(':', AName) = 0)
    and (Pos('..', AName) = 0)
    and (Pos('~', AName) = 0)
    and (Pos('.', AName) <> 0)
    and (Pos('.cfg', AName) = 0)
    and (Pos('.lst', AName) = 0)
    and (Pos('.exe', AName) = 0)
    and (Pos('.vbs', AName) = 0)
    and (Pos('.com', AName) = 0)
    and (Pos('.bat', AName) = 0)
    and (Pos('.dll', AName) = 0)
    and (Pos('.ini', AName) = 0)
    and (Pos('.log', AName) = 0);
 end;

function NormalizePath(Data: LStr): LStr;
var
  S: LStr;
begin
  Result := Reverse(Data);

  while Pos('..' + Slash2, Result) > 0 do
    Result := ParseBefore(Result, '..' + Slash2) + ParseAfter(ParseAfter(Result, '..' + Slash2), Slash2, False);

  Result := Reverse(Result);

  if Result[1] = Slash2 then
    Delete(Result, 1, 1);
end;

function MD5_IsValid(Data: LStr): Boolean;
var
  C: LChar;
begin
  Result := False;

  if Data <> '' then
    for C in Data do
      if not (C in ['0'..'9', 'a'..'f', 'A'..'F']) then
        Exit;


  Result := Length(Data) = 32;
end;

function FixSlashes(Data: LStr): LStr;
var
  I: Int32;
begin
  Result := Data;

  for I := 1 to Length(Result) do
    if Result[I] = Slash2 then
      Result[I] := Slash;
end;

function FixSlashes2(Data: LStr): LStr;
var
  I: Int32;
begin
  Result := Data;

  for I := 1 to Length(Result) do
    if Result[I] = Slash then
      Result[I] := Slash2;
end;

function GetParam(AParam: LStr): LStr;
var
  I: Int32;
  S, S2: LStr;
begin
  Result := '';

  for I := 1 to ParamCount do
    S := S + LStr(ParamStr(I)) + SS;

  while Pos('-', S) <> 0 do
  begin
    S2 := Trim(ParseBefore(ParseAfter(S, '-'), '-'));

    Delete(S, Pos('-', S), Length(S2) + 1);

    if StrBComp(S2, AParam) then
      Exit(S2);
  end;
end;

function HasParam(AParam: LStr): Boolean;
begin
  Result := GetParam(AParam) <> '';
end;

function GetParamValue(AParam: LStr): LStr;
begin
  Result := Trim(ParseAfter(GetParam(AParam), ' ', False));
end;

function HasParamValue(AParam: LStr): Boolean;
begin
  Result := GetParamValue(AParam) <> '';
end;

function DeltaTicks(ASavedTickCount: UInt32): Int32;
begin
  Result := GetTickCount - ASavedTickCount;
end;

function GetRandomString(Size: UInt32; IncludeNumbers: Boolean = False): LStr;
var
  I, J: Int32;
begin
  SetLength(Result, Size);

  for I := 0 to Size - 1 do
  begin
    if IncludeNumbers then
      J := Random(3)
    else
      J := Random(2);

    case J of
      0: PByte(Cardinal(Result) + I)^ := Ord('a') + Random(26);
      1: PByte(Cardinal(Result) + I)^ := Ord('A') + Random(26);
      2: PByte(Cardinal(Result) + I)^ := Ord('0') + Random(10);
    end;
  end;
end;
{$ENDREGION}

procedure WriteRGB(var Data: LStr; Value: TRGB);
begin
  WriteUInt8(Data, Value.R);
  WriteUInt8(Data, Value.G);
  WriteUInt8(Data, Value.B);
end;

function WriteRGB(Value: TRGB): LStr;
begin
  Clear(Result);

  WriteRGB(Result, Value);
end;

procedure WriteRGBA(var Data: LStr; Value: TRGBA);
begin
  WriteUInt8(Data, Value.R);
  WriteUInt8(Data, Value.G);
  WriteUInt8(Data, Value.B);
  WriteUInt8(Data, Value.A);
end;

function WriteRGBA(Value: TRGBA): LStr;
begin
  Clear(Result);

  WriteRGBA(Result, Value);
end;

procedure Clear(var Data: TRGB);
begin
  Data := System.Default(TRGB);
end;

procedure Clear(var Data: TRGBA);
begin
  Data := System.Default(TRGBA);
end;

end.
