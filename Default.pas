unit Default;

interface

uses SysUtils, SyncObjs; 
                         
type
  Int8 = System.Shortint;
  Int16 = System.Smallint;
  Int32 = System.Longint;
  Int64 = System.Int64;

  UInt8 = System.Byte;
  UInt16 = System.Word;
  UInt32 = System.LongWord;
  UInt64 = System.UInt64;

  PInt8 = ^Int8;
  PInt16 = ^Int16;
  PInt32 = ^Int32;
  PInt64 = ^Int64;

  PUInt8 = ^UInt8;
  PUInt16 = ^UInt16;
  PUInt32 = ^UInt32;
  PUInt64 = ^UInt64;

  LChar = System.AnsiChar;
  WChar = System.WideChar;

  PLChar = System.PAnsiChar;
  PWChar = System.PWideChar;

  PPLChar = ^PLChar;

  Float = Single;
  PFloat = ^Float;

  LStr = System.AnsiString;
  WStr = System.WideString;
  UStr = System.UnicodeString;

  PLStr = System.PAnsiString;
  PWStr = System.PWideString;
  PUStr = System.PUnicodeString;

  Bool8 = System.ByteBool;
  Bool16 = System.WordBool;
  Bool32 = System.LongBool;

  Pointer = System.Pointer;
  PPointer = ^Pointer;

  NativeInt = {$IFDEF CPU64}Int64{$ELSE}Int32{$ENDIF};
  NativeUInt = {$IFDEF CPU64}UInt64{$ELSE}UInt32{$ENDIF};

  Int = NativeInt;
  UInt = NativeUInt;
  PInt = ^Int;
  PUInt = ^UInt;

  TProcedure = procedure;

  PProcedureObj = ^TProcedureObj;
  TProcedureObj = procedure of object;
  TProcedurePtrObj = procedure(APtr: Pointer) of object;

  THandle = {$IFDEF MSWINDOWS}UInt{$ELSE}Pointer{$ENDIF};

const
  MinInt8 = Low(Int8);
  MaxInt8 = High(Int8);
  MinUInt8 = Low(UInt8);
  MaxUInt8 = High(UInt8);

  MinInt16 = Low(Int16);
  MaxInt16 = High(Int16);
  MinUInt16 = Low(UInt16);
  MaxUInt16 = High(UInt16);

  MinInt32 = Low(Int32);
  MaxInt32 = High(Int32);
  MinUInt32 = Low(UInt32);
  MaxUInt32 = High(UInt32);

  MinInt64 = Low(Int64);
  MaxInt64 = High(Int64);
  MinUInt64 = Low(UInt64);
  MaxUInt64 = High(UInt64);

  MinInt = MinInt32;
  MaxInt = MaxInt32;
  MinUInt = MinUInt32;
  MaxUInt = MaxUInt32;

  MinNativeInt = Low(NativeInt);
  MaxNativeInt = High(NativeInt);
  MinNativeUInt = Low(NativeUInt);
  MaxNativeUInt = High(NativeUInt);

  LineBreak = {$IFDEF MSWINDOWS}#$D#$A{$ELSE}#$A{$ENDIF};

  PathSeparator = {$IFDEF MSWINDOWS}'\'{$ELSE}'/'{$ENDIF};
  PathSeparator2 = {$IFDEF MSWINDOWS}'/'{$ELSE}'\'{$ENDIF};

  Slash = PathSeparator;
  Slash2 = PathSeparator2;

  DriveSeparator = ':' + PathSeparator;
  DriveSeparator2 = ':' + PathSeparator2;

function Swap16(Value: Int16): Int16;
function Swap32(Value: Int32): Int32;
function Swap64(Value: Int64): Int64;

function ArrayOfConstToArrayOfLStr(const A: array of const): TArray<LStr>;

procedure StringFromVarRec(const Data: array of const; var S: LStr); overload;
function StringFromVarRec(const Data: array of const): LStr; overload;

procedure Alert(const Data: array of const); overload;
procedure AThis;
procedure Error(const Data: array of const); overload;

function DotSettings: TFormatSettings;
function CommaSettings: TFormatSettings;

function FloatToStrDot(Value: Float): LStr;

function StrToFloatDot(const Value: LStr): Float;
function StrToFloatDefDot(const Value: LStr; Default: Float): Float;
function TryStrToFloatDot(const Value: LStr; out FValue: Float): Boolean;

procedure FixEncoders(var AData: LStr);

function ReadUInt8(Data: LStr; Index: Int32 = 0): UInt8; inline;
function ReadChar(Data: LStr; Index: Int32 = 0): LChar; inline;
function ReadInt16(Data: LStr; Index: Int32 = 0): Int16; inline;
function ReadUInt16(Data: LStr; Index: Int32 = 0): UInt16; inline;
function ReadInt32(Data: LStr; Index: Int32 = 0): Int32; inline;
function ReadFloat(Data: LStr; Index: Int32 = 0): Float; inline;
function ReadUInt32(Data: LStr; Index: Int32 = 0): UInt32; inline;
function ReadInt64(Data: LStr; Index: Int32 = 0): Int64; inline;
function ReadUInt64(Data: LStr; Index: Int32 = 0): UInt64; inline;
function ReadString(Data: LStr; Index: Int32 = 0): LStr; inline;
function ReadStringLine(Data: LStr; Index: Int32 = 0): LStr; inline;
function ReadBuf(Data: LStr; Count: Int32; Index: Int32 = 1): LStr; inline;
function ReadEnd(Data: LStr; Index: Int32 = 1): LStr; inline;

procedure WriteUInt8(var Data: LStr; Value: UInt8); overload; inline;
function WriteUInt8(Value: UInt8): LStr; overload; inline;

procedure WriteChar(var Data: LStr; Value: LChar); overload; inline;
function WriteChar(Value: LChar): LStr; overload; inline;

procedure WriteInt16(var Data: LStr; Value: Int16); overload; inline;
function WriteInt16(Value: Int16): LStr; overload; inline;

procedure WriteUInt16(var Data: LStr; Value: UInt16); overload; inline;
function WriteUInt16(Value: UInt16): LStr; overload; inline;

procedure WriteInt32(var Data: LStr; Value: Int32); overload; inline;
function WriteInt32(Value: Int32): LStr; overload; inline;

procedure WriteUInt32(var Data: LStr; Value: UInt32); overload; inline;
function WriteUInt32(Value: UInt32): LStr; overload; inline;

procedure WriteFloat(var Data: LStr; Value: Float); overload; inline;
function WriteFloat(Value: Float): LStr; overload; inline;

procedure WriteString(var Data: LStr; Value: LStr); overload; inline;
procedure WriteString(var Data: LStr; Value: array of const); overload;
function WriteString(Value: LStr): LStr; overload; inline;
function WriteString(Value: array of const): LStr; overload;

procedure WriteLine(var Data: LStr; Value: LStr); overload; inline;
function WriteLine(Value: LStr): LStr; overload; inline;

procedure WriteStringLine(var Data: LStr; Value: LStr); overload; inline;
function WriteStringLine(Value: LStr): LStr; overload; inline;

procedure WriteBuf(var Data: LStr; Value: LStr); overload; inline;
function WriteBuf(Value: LStr): LStr; overload; inline;

procedure Clear(var Data: Boolean); overload; inline;
procedure Clear(var Data: PBoolean); overload; inline;

procedure Clear(var Data: Int8); overload; inline;
procedure Clear(var Data: Int16); overload; inline;
procedure Clear(var Data: Int32); overload; inline;
procedure Clear(var Data: Int64); overload; inline;

procedure Clear(var Data: UInt8); overload; inline;
procedure Clear(var Data: UInt16); overload; inline;
procedure Clear(var Data: UInt32); overload; inline;
procedure Clear(var Data: UInt64); overload; inline;

procedure Clear(var Data: Float); overload; inline;
procedure Clear(var Data: Double); overload; inline;

procedure Clear(var Data: LChar); overload; inline;
procedure Clear(var Data: WChar); overload; inline;

procedure Clear(var Data: LStr); overload; inline;
procedure Clear(var Data: PLStr); overload; inline;
procedure Clear(var Data: WStr); overload; inline;

procedure Clear(var Data: Pointer); overload; inline;

procedure Clear(var Data: TProcedureObj); overload; inline;

procedure Clear(var Data: TArray<Int8>); overload; inline;
procedure Clear(var Data: TArray<UInt8>); overload; inline;

procedure Clear(var Data: TArray<Int16>); overload; inline;
procedure Clear(var Data: TArray<UInt16>); overload; inline;

procedure Clear(var Data: TArray<Int32>); overload; inline;
procedure Clear(var Data: TArray<UInt32>); overload; inline;

procedure Clear(var Data: TArray<Int64>); overload; inline;
procedure Clear(var Data: TArray<UInt64>); overload; inline;

procedure Clear(var Data: TArray<Float>); overload; inline;

procedure Clear(var Data: TArray<LStr>); overload; inline;

type
  TOnTitleData = procedure(Sender: TObject; Title, Data: LStr) of object;

implementation

uses {$IFDEF MSWINDOWS} Windows{$ENDIF};

function Swap16(Value: Int16): Int16;
{$IFDEF ASM32} {$IFDEF FPC} assembler; {$ENDIF}
asm
  xchg al, ah
end;
{$ELSE}
begin
  Result := (Value shl 8) or (Value shr 8);
end;
{$ENDIF}

procedure _Swap32; {$IFDEF FPC} assembler; {$ENDIF}
asm
  mov ecx, eax

  shl ecx, 24

  mov edx, eax
  and edx, $FF00
  shl edx, 8

  or ecx, edx

  mov edx, eax
  and edx, $FF0000
  shr edx, 8

  shr eax, 24

  or eax, ecx
  or eax, edx
end;

function Swap32(Value: Int32): Int32;
{$IFDEF ASM32} {$IFDEF FPC} assembler; {$ENDIF}
asm
  {$IFNDEF I386COMPAT}
  bswap eax
  {$ELSE}
  call _Swap32
  {$ENDIF}
end;
{$ELSE}
begin
  Result := (Value shl 24) or (Value shr 24) or ((Value shl 8) and $FF0000) or
          ((Value shr 8) and $FF00);
end;
{$ENDIF}

function Swap64(Value: Int64): Int64;
type
 PInt64Rec = ^TInt64Rec;
 TInt64Rec = packed record
  case Boolean of
   False: (Lo, Hi: Int32);
   True: (Low, High: Int32);
 end;
begin
  Result := Swap32(TInt64Rec(Value).High) + (Int64(Swap32(TInt64Rec(Value).Low)) shl 32);
end;

function ArrayOfConstToArrayOfLStr(const A: array of const): TArray<LStr>;
  procedure Add(const S: LStr);
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := S;
  end;

const
  LookupTable: array[Boolean] of LStr = ('False', 'True');
var
  I: Int;
begin
  SetLength(Result, 0);

  for I := Low(A) to High(A) do
    with A[I] do
      case VType of
        vtInteger: Add(IntToStr(VInteger));
        vtBoolean: Add(LookupTable[VBoolean]);
        vtChar: Add(VChar);
        vtExtended: Add(FloatToStr(VExtended^));
        vtString: Add(VString^);
        vtPointer: Add(IntToStr(UInt32(VPointer)));
        vtPChar: Add(VPChar);
        vtObject: Add(VObject.ClassName);
        vtClass: Add(VClass.ClassName);
        vtWideChar: Add(LChar(VWideChar));
        vtPWideChar: Add(PLChar(VPWideChar));
        vtAnsiString: Add(LStr(VAnsiString));
        vtCurrency: Add(CurrToStr(VCurrency^));
        vtWideString: Add(LStr(WStr(VWideString)));
        vtInt64: Add(IntToStr(VInt64^));
        {$IFDEF UNICODE}vtUnicodeString: Add(LStr(UnicodeString(VUnicodeString)));{$ENDIF}
      else
        Add(' <unknown type> ');
      end;
end;

procedure StringFromVarRec(const Data: array of const; var S: LStr);
const
  LookupTable: array[Boolean] of LStr = ('False', 'True');
var
  I: NativeInt;
begin
  S := '';

  for I := Low(Data) to High(Data) do
    with Data[I] do
      case VType of
        vtInteger: S := S + IntToStr(VInteger);
        vtBoolean: S := S + LookupTable[VBoolean];
        vtChar: S := S + VChar;
        vtExtended: S := S + FloatToStr(VExtended^);
        vtString: S := S + VString^;
        vtPointer: S := S + IntToStr(UInt32(VPointer));
        vtPChar: S := S + VPChar;
        vtObject: S := S + VObject.ClassName;
        vtClass: S := S + VClass.ClassName;
        vtWideChar: S := S + LChar(VWideChar);
        vtPWideChar: S := S + PLChar(VPWideChar);
        vtAnsiString: S := S + LStr(VAnsiString);
        vtCurrency: S := S + CurrToStr(VCurrency^);
        vtWideString: S := S + LStr(WStr(VWideString));
        vtInt64: S := S + IntToStr(VInt64^);
        {$IFDEF UNICODE}vtUnicodeString: S := S + LStr(UnicodeString(VUnicodeString));{$ENDIF}
      else
        S := S + ' <unknown type> ';
      end;
end;

function StringFromVarRec(const Data: array of const): LStr;
begin
  StringFromVarRec(Data, Result);
end;

procedure Alert(const Data: array of const);
begin
  MessageBoxA(0, PLChar(StringFromVarRec(Data)), 'Alert', MB_OK or MB_ICONWARNING or MB_SYSTEMMODAL);
end;

procedure AThis;
begin
  Alert(['this']);
end;

procedure Error(const Data: array of const);
begin
  MessageBoxA(0, PLChar(StringFromVarRec(Data)), 'Error', MB_OK or MB_ICONERROR or MB_SYSTEMMODAL);
  ReportMemoryLeaksOnShutdown := False;
  Halt;
end;

function DotSettings: TFormatSettings;
begin
  GetLocaleFormatSettings(GetThreadLocale, Result);
  Result.DecimalSeparator := '.';
end;

function CommaSettings: TFormatSettings;
begin
  GetLocaleFormatSettings(GetThreadLocale, Result);
  Result.DecimalSeparator := ',';
end;

function FloatToStrDot(Value: Float): LStr;
begin
  Result := FloatToStr(Value, DotSettings);
end;

function StrToFloatDot(const Value: LStr): Float;
begin
  Result := StrToFloat(Value, DotSettings);
end;

function StrToFloatDefDot(const Value: LStr; Default: Float): Float;
begin
  Result := StrToFloatDef(Value, Default, DotSettings)
end;

function TryStrToFloatDot(const Value: LStr; out FValue: Float): Boolean;
begin
  Result := TryStrToFloat(Value, FValue, DotSettings);
end;

procedure FixEncoders(var AData: LStr);
begin
  AData := Utf8ToAnsi(AData);
end;

function ReadUInt8(Data: LStr; Index: Int32 = 0): UInt8;
begin
  Clear(Result);
  Result := PUInt8(UInt32(Data) + Index)^;
end;

function ReadChar(Data: LStr; Index: Int32 = 0): LChar;
begin
  Clear(Result);
  Result := PLChar(UInt32(Data) + Index)^;
end;

function ReadInt16(Data: LStr; Index: Int32 = 0): Int16;
begin
  Clear(Result);
  Result := PInt16(UInt32(Data) + Index)^;
end;

function ReadUInt16(Data: LStr; Index: Int32 = 0): UInt16;
begin
  Clear(Result);
  Result := PUInt16(UInt32(Data) + Index)^;
end;

function ReadInt32(Data: LStr; Index: Int32 = 0): Int32;
begin
  Clear(Result);
  Result := PInt32(UInt32(Data) + Index)^;
end;

function ReadFloat(Data: LStr; Index: Int32 = 0): Float;
begin
  Clear(Result);
  Result := PFloat(UInt32(Data) + Index)^;
end;

function ReadUInt32(Data: LStr; Index: Int32 = 0): UInt32;
begin
  Clear(Result);
  Result := PUInt32(UInt32(Data) + Index)^;
end;

function ReadInt64(Data: LStr; Index: Int32 = 0): Int64;
begin
  Clear(Result);
  Result := PInt64(UInt32(Data) + Index)^;
end;

function ReadUInt64(Data: LStr; Index: Int32 = 0): UInt64;
begin
  Clear(Result);
  Result := PUInt64(UInt32(Data) + Index)^;
end;

function ReadString(Data: LStr; Index: Int32 = 0): LStr;
var
  I: Int32;
  B: UInt8;
begin
  Clear(Result);

  for I := Index to Length(Data) do
  begin
    B := ReadUInt8(Data, I);

    if (B = 0) or (B = 255) then
      Break
    else
      Result := Result + LChar(B);
  end;
end;

function ReadStringLine(Data: LStr; Index: Int32 = 0): LStr;
var
  I: Int32;
  B: Byte;
  S: LStr;
begin
  Clear(Result);

  for I := Index to Length(Data) do
  begin
    B := ReadUInt8(Data, I);

    if (B = 0) or (B = 255) or (B = 10) then
      Break
    else
      Result := Result + LChar(B);
  end;
end;

function ReadBuf(Data: LStr; Count: Int32; Index: Int32 = 1): LStr;
var
  I: Int32;
begin
  Clear(Result);

  for I := Index - 1 to Count - 1 + Index - 1 do
    if I < Length(Data) then
      Result := Result + LChar(ReadUInt8(Data, I));
end;

function ReadEnd(Data: LStr; Index: Int32 = 1): LStr;
var
  I: Int32;
begin
  Clear(Result);

  for I := Index - 1 to Length(Data) - 1 + Index - 1 do Result := Result + LChar(ReadUInt8(Data, I));
end;

procedure WriteUInt8(var Data: LStr; Value: UInt8);
begin
  Data := Data + LChar(Value);
end;

function WriteUInt8(Value: UInt8): LStr;
begin
  Clear(Result);

  WriteUInt8(Result, Value);
end;

procedure WriteChar(var Data: LStr; Value: LChar);
begin
  Data := Data + Value;
end;

function WriteChar(Value: LChar): LStr;
begin
  Clear(Result);

  WriteChar(Result, Value);
end;

procedure WriteInt16(var Data: LStr; Value: Int16);
var
  S: LStr;
begin
  SetLength(S, SizeOf(Int16));
  MoveMemory(@S[1], @Value, Length(S));
  Data := Data + S;
end;

function WriteInt16(Value: Int16): LStr;
begin
  Clear(Result);

  WriteInt16(Result, Value);
end;

procedure WriteUInt16(var Data: LStr; Value: UInt16);
var
  S: LStr;
begin
  SetLength(S, SizeOf(UInt16));
  MoveMemory(@S[1], @Value, Length(S));
  Data := Data + S;
end;

function WriteUInt16(Value: UInt16): LStr;
begin
  Clear(Result);

  WriteUInt16(Result, Value);
end;

procedure WriteInt32(var Data: LStr; Value: Int32);
var
  S: LStr;
begin
  SetLength(S, SizeOf(Int32));
  MoveMemory(@S[1], @Value, Length(S));
  Data := Data + S;
end;

function WriteInt32(Value: Int32): LStr;
begin
  Clear(Result);

  WriteInt32(Result, Value);
end;

procedure WriteUInt32(var Data: LStr; Value: UInt32);
var
  S: LStr;
begin
  SetLength(S, SizeOf(UInt32));
  MoveMemory(@S[1], @Value, Length(S));
  Data := Data + S;
end;

function WriteUInt32(Value: UInt32): LStr;
begin
  Clear(Result);

  WriteUInt32(Result, Value);
end;

procedure WriteFloat(var Data: LStr; Value: Float);
var
  S: LStr;
begin
  SetLength(S, 4);
  MoveMemory(@S[1], @Value, 4);
  Data := Data + S;
end;

function WriteFloat(Value: Float): LStr;
begin
  Clear(Result);

  WriteFloat(Result, Value);
end;

procedure WriteString(var Data: LStr; Value: LStr);
begin
  WriteBuf(Data, Value);

  WriteUInt8(Data, 0);
end;

procedure WriteString(var Data: LStr; Value: array of const);
begin
  WriteString(Data, StringFromVarRec(Value));
end;

function WriteString(Value: LStr): LStr;
begin
  Clear(Result);

  WriteString(Result, Value);
end;

function WriteString(Value: array of const): LStr;
begin
  Result := WriteString(StringFromVarRec(Value));
end;

procedure WriteLine(var Data: LStr; Value: LStr);
begin
  WriteBuf(Data, Value);

  WriteUInt8(Data, 10);
end;

function WriteLine(Value: LStr): LStr;
begin
  Clear(Result);

  WriteLine(Result, Value);
end;

procedure WriteStringLine(var Data: LStr; Value: LStr);
begin
  WriteString(Data, WriteLine(Value));
end;

function WriteStringLine(Value: LStr): LStr;
begin
  Clear(Result);

  WriteStringLine(Result, Value);
end;

procedure WriteBuf(var Data: LStr; Value: LStr);
begin
  Data := Data + Value;
end;

function WriteBuf(Value: LStr): LStr;
begin
  Clear(Result);

  WriteBuf(Result, Value);
end;

procedure Clear(var Data: Boolean);
begin
  Data := System.Default(Boolean);
end;

procedure Clear(var Data: PBoolean);
begin
  Data := System.Default(PBoolean);
end;

procedure Clear(var Data: Int8);
begin
  Data := System.Default(Int8);
end;

procedure Clear(var Data: Int16);
begin
  Data := System.Default(Int16);
end;

procedure Clear(var Data: Int32);
begin
  Data := System.Default(Int32);
end;

procedure Clear(var Data: Int64);
begin
  Data := System.Default(Int64);
end;

procedure Clear(var Data: UInt8);
begin
  Data := System.Default(UInt8);
end;

procedure Clear(var Data: UInt16);
begin
  Data := System.Default(UInt16);
end;

procedure Clear(var Data: UInt32);
begin
  Data := System.Default(UInt32);
end;

procedure Clear(var Data: UInt64);
begin
  Data := System.Default(UInt64);
end;

procedure Clear(var Data: Float);
begin
  Data := System.Default(Float);
end;

procedure Clear(var Data: Double);
begin
  Data := System.Default(Double);
end;

procedure Clear(var Data: LChar);
begin
  Data := System.Default(LChar);
end;

procedure Clear(var Data: WChar);
begin
  Data := System.Default(WChar);
end;

procedure Clear(var Data: LStr);
begin
  Data := System.Default(LStr);
end;

procedure Clear(var Data: PLStr);
begin
  Data := System.Default(PLStr);
end;

procedure Clear(var Data: WStr);
begin
  Data := System.Default(WStr);
end;

procedure Clear(var Data: Pointer);
begin
  Data := System.Default(Pointer);
end;

procedure Clear(var Data: TProcedureObj);
begin
  Data := System.Default(TProcedureObj);
end;

procedure Clear(var Data: TArray<Int8>);
begin
  Data := System.Default(TArray<Int8>);
end;

procedure Clear(var Data: TArray<UInt8>);
begin
  Data := System.Default(TArray<UInt8>);
end;

procedure Clear(var Data: TArray<Int16>);
begin
  Data := System.Default(TArray<Int16>);
end;

procedure Clear(var Data: TArray<UInt16>);
begin
  Data := System.Default(TArray<UInt16>);
end;

procedure Clear(var Data: TArray<Int32>);
begin
  Data := System.Default(TArray<Int32>);
end;

procedure Clear(var Data: TArray<UInt32>);
begin
  Data := System.Default(TArray<UInt32>);
end;

procedure Clear(var Data: TArray<Int64>);
begin
  Data := System.Default(TArray<Int64>);
end;

procedure Clear(var Data: TArray<UInt64>);
begin
  Data := System.Default(TArray<UInt64>);
end;

procedure Clear(var Data: TArray<Float>);
begin
  Data := System.Default(TArray<Float>);
end;

procedure Clear(var Data: TArray<LStr>);
begin
  Data := System.Default(TArray<LStr>);
end;

function Cleared(const Data: Boolean): Boolean;
begin
  Result := Data = False;
end;

initialization
  ReportMemoryLeaksOnShutdown := True;
  Randomize;
  SetCurrentDir(ExtractFilePath(ParamStr(0)));

finalization

end.

