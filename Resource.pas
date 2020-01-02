unit Resource;

interface

uses Default, Shared, Common, Vector, Protocol, MD5;

const
  // type
  RT_SOUND = 0;
  RT_SKIN = 1;
  RT_MODEL = 2;
  RT_DECAL = 3;
  RT_GENERIC = 4;
  RT_EVENTSCRIPT = 5;
  RT_WORLD = 6;

  // flags
  RES_FATALIFMISSING = 1 shl 0;
  RES_WASMISSING = 1 shl 1;
  RES_CUSTOM = 1 shl 2;
  RES_REQUESTED = 1 shl 3;
  RES_PRECACHED = 1 shl 4;
  RES_ALWAYS = 1 shl 5;
  RES_PADDING = 1 shl 6;
  RES_CHECKFILE = 1 shl 7;

  // force type
  //TForceType = (ftExactFile = 0, ftModelSameBounds, ftModelSpecifyBounds, ftModelSpecifyBoundsIfAvail);
  FT_EXACT_FILE = 0;
  FT_MODEL_SAME_BOUNDS = 1;
  FT_MODEL_SPECIFY_BOUNDS = 2;
  FT_MODEL_SPECIFY_BOUNDS_IF_AVAIL = 3;
type

  PPackedConsistency = ^TPackedConsistency;
  TPackedConsistency = packed record
    ForceType: Byte;
    MinS, MaxS: TVec3F;
  end;

  PResource = ^TResource;
  TResource = record
    Name: LStr;
    RType: UInt8;
    Index: Int16;
    Size: Int32;
    Flags: UInt8;
    MD5: TMD5Digest;
    Reserved: LStr;

    class function Create(AName: LStr; AType: UInt8; AIndex: Int16; ASize: Int32; AFlags: UInt8; AMD5: TMD5Digest; AReserved: LStr = ''): TResource; overload; static;
    class function Create(AName: LStr; AType: UInt8; AIndex: Int16; ASize: Int32; AFlags: UInt8; AMD5: Int32 = 0; AReserved: LStr = ''): TResource; overload; static;

    class operator Equal(A, B: TResource): Boolean; overload;
    class operator NotEqual(A, B: TResource): Boolean; overload;

    // we can compare it by index
    class operator Equal(A: TResource; B: Int32): Boolean; overload;
    class operator NotEqual(A: TResource; B: Int32): Boolean; overload;

    // we can compare it by name
    class operator Equal(A: TResource; B: LStr): Boolean; overload;
    class operator NotEqual(A: TResource; B: LStr): Boolean; overload;

    function ToString: LStr;
  end;

  PResources = ^TResources;
  TResources = array of TResource;

  TDownloadingResource = record
    Downloaded: Boolean;
    Aborted: Boolean;
    //Time: UInt32;
    Name: LStr;
  end;

  TDownloadQueue = array of TDownloadingResource;

function GetResource(AResources: PResources; AName: LStr): PResource; overload;
function GetResource(AResources: PResources; AType: UInt8; AIndex: Int32): PResource; overload;

procedure Clear(var Data: TPackedConsistency); overload; inline;
procedure Clear(var Data: TDownloadingResource); overload; inline;
procedure Clear(var Data: TDownloadQueue); overload; inline;
procedure Clear(var Data: TResource); overload; inline;
procedure Clear(var Data: TResources); overload; inline;

function ResolvePWeaponNameFromWeaponModel(Resource: TResource): LStr;
function ResolveWWeaponNameFromWeaponModel(Resource: TResource): LStr;
function TruncateModelName(Resource: TResource): LStr;
function IsWeaponModel(Resource: TResource): Boolean;
function IsBombModel(Resource: TResource): Boolean;

implementation

{$REGION 'TResource'}
class function TResource.Create(AName: LStr; AType: UInt8; AIndex: Int16; ASize: Int32; AFlags: UInt8; AMD5: TMD5Digest; AReserved: LStr = ''): TResource;
begin
  Result.Name := AName;
  Result.RType := AType;
  Result.Index := AIndex;
  Result.Size := ASize;
  Result.Flags := AFlags;
  Result.MD5 := AMD5;
  Result.Reserved := AReserved;
end;

class function TResource.Create(AName: LStr; AType: UInt8; AIndex: Int16; ASize: Int32; AFlags: UInt8; AMD5: Int32 = 0; AReserved: LStr = ''): TResource;
begin
  Result.Name := AName;
  Result.RType := AType;
  Result.Index := AIndex;
  Result.Size := ASize;
  Result.Flags := AFlags;
  PUInt32(@Result.MD5)^ := AMD5;
  Result.Reserved := AReserved;
end;

class operator TResource.Equal(A, B: TResource): Boolean;
begin
  Result := A.Index = B.Index;
end;

class operator TResource.NotEqual(A, B: TResource): Boolean;
begin
  Result := A.Index <> B.Index;
end;

class operator TResource.Equal(A: TResource; B: Int32): Boolean;
begin
  Result := A.Index = B;
end;

class operator TResource.NotEqual(A: TResource; B: Int32): Boolean;
begin
  Result := A.Index <> B;
end;

class operator TResource.Equal(A: TResource; B: LStr): Boolean;
begin
  Result := A.Name = B;
end;

class operator TResource.NotEqual(A: TResource; B: LStr): Boolean;
begin
  Result := A.Name <> B;
end;

function TResource.ToString: LStr;
begin
  Result := StringFromVarRec([
    'Name: "', Name, '", ',
    'Index: ', Index, ', ',
    'Type: ', RType, ', ',
    'Size: ', Size, ', ',
    'Flags: ', Flags, ', ',
    'MD5: ', MD5.AsLongs[0]]);
end;
{$ENDREGION}

{$REGION 'Shared'}
function GetResource(AResources: PResources; AName: LStr): PResource;
var
  I: Int32;
begin
  Result := nil;

  for I := Low(AResources^) to High(AResources^) do
    if AResources^[I] = AName then
      Exit(@AResources^[I]);
end;

function GetResource(AResources: PResources; AType: UInt8; AIndex: Int32): PResource;
var
  I: Int32;
begin
  Result := nil;

  for I := Low(AResources^) to High(AResources^) do
    with AResources^[I] do
    begin
      if RType <> AType then
        Continue;

      if Index <> AIndex then
        Continue;

      Exit(@AResources^[I]);
    end;
end;
{$ENDREGION}

{$REGION 'Clears'}
procedure Clear(var Data: TPackedConsistency);
begin
  with Data do
  begin
    Clear(ForceType);
    Clear(MinS);
    Clear(MaxS);
  end;
end;

procedure Clear(var Data: TDownloadingResource);
begin
  with Data do
  begin
    Clear(Downloaded);
    Clear(Aborted);
    Clear(Name);
   // Clear(Time);
  end;
end;

procedure Clear(var Data: TDownloadQueue);
var
  I: Int32;
begin
  for I := Low(Data) to High(Data) do
    Clear(Data[I]);

  SetLength(Data, 0);
end;

procedure Clear(var Data: TResource);
begin
  with Data do
  begin
    Clear(Name);
    Clear(RType);
    Clear(Index);
    Clear(Size);
    Clear(Flags);
 //   Clear(Hash);
    Clear(Reserved);
  //  Clear(MD5);
  end;
end;

procedure Clear(var Data: TResources);
var
  I: Int32;
begin
  for I := Low(Data) to High(Data) do
    Clear(Data[I]);

  SetLength(Data, 0);
end;
{$ENDREGION}

{$REGION 'Others'}
function ResolvePWeaponNameFromWeaponModel(Resource: TResource): LStr;
begin
  Clear(Result);

  if Resource.RType = RT_MODEL then
    Result := ParseAfter(ParseBefore(ParseAfter(Resource.Name, '/'), '.'), 'p_');
end;

function ResolveWWeaponNameFromWeaponModel(Resource: TResource): LStr;
begin
  Clear(Result);

  if Resource.RType = RT_MODEL then
    Result := ParseAfter(ParseBefore(ParseAfter(Resource.Name, '/'), '.'), 'w_');
end;

{function IsBombEntity(Resources: TResourceSystem; Entity: TEntity): Boolean;
begin
  Result := IsBombModel(Resources.GetModel(Entity.ModelIndex)^);
end;}

function TruncateModelName(Resource: TResource): LStr;
begin
  Clear(Result);

  if Resource.RType = RT_MODEL then
    Result := Reverse(ParseBefore(ParseBetween(Reverse(Resource.Name), '.', '/'), '_'));
end;

function IsWeaponModel(Resource: TResource): Boolean;
begin
  Result := (ResolveFileExtention(Resource.Name) = 'mdl')
        and (Copy(ResolveFileNameExtention(Resource.Name), 0, 2) = 'w_');
end;

function IsBombModel(Resource: TResource): Boolean;
begin
  Result :=
    (ResolveWWeaponNameFromWeaponModel(Resource) = 'backpack') or
    (ResolveWWeaponNameFromWeaponModel(Resource) = 'c4');
end;
{$ENDREGION}

end.