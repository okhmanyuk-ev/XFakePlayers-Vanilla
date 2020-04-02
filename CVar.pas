unit CVar;

interface

uses
  Default,
  SysUtils,
  Common,
  Buffer,

  Generics.Defaults,
  Generics.Collections;

const
  CVAR_HIDE = 1 shl 0; // hides from user
  CVAR_PROTECTED = 1 shl 1; // protected from svc_stufftext
  CVAR_PRIVATE = 1 shl 2; // protected from svc_sendcvarvalue, should use for all custom cvars in engine
  CVAR_USERINFO = 1 shl 3; // custom flag for all userinfos

const
  S_CVAR_UNKNOWN_CVAR = 'Unknown cvar "%s".';

type
  TCVarType = (V_BOOL, V_INT, V_FLOAT, V_STR);

  PCVar = ^TCVar;
  TCVar = record
    Name: LStr;
    VType: TCVarType;
    Ptr: Pointer;
    Data: LStr;
    Description: LStr;
    Flags: Int32;

    class function Create(AName: LStr; AType: TCVarType; APtr: Pointer; ADescription: LStr; AFlags: Int32 = 0): TCVar; static;

    function ToBoolean: Boolean;
    function ToInt: Int;
    function ToFloat: Float;
    function ToString: LStr;

    procedure Write(Value: Boolean); overload;
    procedure Write(Value: Int32); overload;
    procedure Write(Value: Float); overload;
    procedure Write(Value: LStr); overload;
  end;

  TCVarComparer = class(TComparer<TCVar>)
    function Compare(const Left, Right: TCVar): Int32; override;
  end;

  TCVarList = class(TList<TCVar>)
  public
    constructor Create;

    function Add(AName: LStr; APtr: Pointer; AValue: Boolean; ADescription: LStr; AFlags: Int32 = 0): Int32; overload;
    function Add(AName: LStr; APtr: Pointer; AValue: Int32; ADescription: LStr; AFlags: Int32 = 0): Int32; overload;
    function Add(AName: LStr; APtr: Pointer; AValue: Float; ADescription: LStr; AFlags: Int32 = 0): Int32; overload;
    function Add(AName: LStr; APtr: Pointer; AValue: LStr; ADescription: LStr; AFlags: Int32 = 0): Int32; overload;

    function Add(AName: LStr; APtr: Pointer; AValue: Boolean; AFlags: Int32 = 0): Int32; overload;
    function Add(AName: LStr; APtr: Pointer; AValue: Int32; AFlags: Int32 = 0): Int32; overload;
    function Add(AName: LStr; APtr: Pointer; AValue: Float; AFlags: Int32 = 0): Int32; overload;
    function Add(AName: LStr; APtr: Pointer; AValue: LStr; AFlags: Int32 = 0): Int32; overload;

    function IndexOf(const AName: LStr): Int32; overload;

    procedure SaveToFile(const AFileName: LStr);
    procedure LoadFromFile(const AFileName: LStr);
  end;

implementation

{$REGION 'TCVar'}
class function TCVar.Create(AName: LStr; AType: TCVarType; APtr: Pointer; ADescription: LStr; AFlags: Int32 = 0): TCVar;
begin
  Result.Name := AName;
  Result.VType := AType;
  Result.Ptr := APtr;
  Result.Description := ADescription;
  Result.Flags := AFlags;
end;

function TCVar.ToBoolean: Boolean;
begin
  case VType of
    V_BOOL: Result := PBoolean(Ptr)^;
    V_INT: Result := Boolean(PInt32(Ptr)^);
    V_FLOAT: Result := PFloat(Ptr)^ > 0;
    V_STR: Result := PLStr(Ptr)^ <> '';
  end;
end;

function TCVar.ToInt: Int;
begin
  case VType of
    V_INT: Result := PInt(Ptr)^;
  else
    Error(['TCVar.ToInt support only int values']);
  end;
end;

function TCVar.ToFloat: Float;
begin
  case VType of
    V_FLOAT: Result := PFloat(Ptr)^;
  else
    Error(['TCVar.ToFloat support only float values']);
  end;
end;

function TCVar.ToString: LStr;
begin
  case VType of
    V_BOOL: Result := IntToStr(Int32(PBoolean(Ptr)^));
    V_INT: Result := IntToStr(PInt32(Ptr)^);
    V_FLOAT: Result := FloatToStrDot(PFloat(Ptr)^);
    V_STR: Result := PLStr(Ptr)^;
  end;
end;

procedure TCVar.Write(Value: Boolean);
begin
  PBoolean(Ptr)^ := Value;
end;

procedure TCVar.Write(Value: Int32);
begin
  PInt32(Ptr)^ := Value;
end;

procedure TCVar.Write(Value: Float);
begin
  PFloat(Ptr)^ := Value;
end;

procedure TCVar.Write(Value: LStr);
begin
  PLStr(Ptr)^ := Value;
end;
{$ENDREGION}

{$REGION 'TCVarComparer'}
function TCVarComparer.Compare(const Left, Right: TCVar): Int32;
begin
  Result := CompareStr(Left.Name, Right.Name);
end;
{$ENDREGION}

{$REGION 'TCVarList'}
constructor TCVarList.Create;
begin
  inherited Create(TCVarComparer.Create);
end;

function TCVarList.Add(AName: LStr; APtr: Pointer; AValue: Boolean; ADescription: LStr; AFlags: Int32 = 0): Int32;
var
  I: Int32;
begin
  I := Add(TCVar.Create(AName, V_BOOL, APtr, ADescription, AFlags));
  List[I].Write(AValue);
  List[I].Data := List[I].ToString;
end;

function TCVarList.Add(AName: LStr; APtr: Pointer; AValue: Int32; ADescription: LStr; AFlags: Int32 = 0): Int32;
var
  I: Int32;
begin
  I := Add(TCVar.Create(AName, V_INT, APtr, ADescription, AFlags));
  List[I].Write(AValue);
  List[I].Data := List[I].ToString;
end;

function TCVarList.Add(AName: LStr; APtr: Pointer; AValue: Float; ADescription: LStr; AFlags: Int32 = 0): Int32;
var
  I: Int32;
begin
  I := Add(TCVar.Create(AName, V_FLOAT, APtr, ADescription, AFlags));
  List[I].Write(AValue);
  List[I].Data := List[I].ToString;
end;

function TCVarList.Add(AName: LStr; APtr: Pointer; AValue: LStr; ADescription: LStr; AFlags: Int32 = 0): Int32;
var
  I: Int32;
begin
  I := Add(TCVar.Create(AName, V_STR, APtr, ADescription, AFlags));
  List[I].Write(AValue);
  List[I].Data := List[I].ToString;
end;

function TCVarList.Add(AName: LStr; APtr: Pointer; AValue: Boolean; AFlags: Int32 = 0): Int32;
begin
  Add(AName, APtr, AValue, '', AFlags);
end;

function TCVarList.Add(AName: LStr; APtr: Pointer; AValue: Int32; AFlags: Int32 = 0): Int32;
begin
  Add(AName, APtr, AValue, '', AFlags);
end;

function TCVarList.Add(AName: LStr; APtr: Pointer; AValue: Float; AFlags: Int32 = 0): Int32;
begin
  Add(AName, APtr, AValue, '', AFlags);
end;

function TCVarList.Add(AName: LStr; APtr: Pointer; AValue: LStr; AFlags: Int32 = 0): Int32;
begin
  Add(AName, APtr, AValue, '', AFlags);
end;

function TCVarList.IndexOf(const AName: LStr): Int32;
var
  I: Int32;
begin
  for I := 0 to Count - 1 do
    if Items[I].Name = AName then
      Exit(I);

  Result := -1;
end;

procedure TCVarList.SaveToFile(const AFileName: LStr);
var
  I: Int;
  B: TBufferEx2;
begin
  B := TBufferEx2.Create;
  B.WriteInt32(Count);

  for I := 0 to Count - 1 do
    case Items[I].VType of
      V_BOOL: B.WriteBool8(Items[I].ToBoolean);
      V_INT: B.WriteInt32(Items[I].ToInt);
      V_FLOAT: B.WriteFloat(Items[I].ToFloat);
      V_STR: B.WriteLStr(Items[I].ToString);
    end;

  B.SaveToFile(AFileName);
  B.Free;
end;

procedure TCVarList.LoadFromFile(const AFileName: LStr);
var
  I, C: Int;
  B: TBufferEx2;
begin
  if not FileExists(AFileName) then
    Exit;

  B := TBufferEx2.Create;
  B.LoadFromFile(AFileName);

  C := B.ReadInt32;

  if C = Count then
    for I := 0 to Count - 1 do
      case Items[I].VType of
        V_BOOL: Items[I].Write(B.ReadBool8);
        V_INT: Items[I].Write(B.ReadInt32);
        V_FLOAT: Items[I].Write(B.ReadFloat);
        V_STR: Items[I].Write(B.ReadLStr);
      end;

  B.Free;
end;
{$ENDREGION}

end.
