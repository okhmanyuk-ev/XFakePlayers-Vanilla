unit Weapon;

interface

uses SysUtils, Default, Protocol, Shared;

const
  MAX_WEAPONS = 32;
  WEAPON_NOCLIP = -1; // ammo from ammox

type
  PWeapon = ^TWeapon;
  TWeapon = record
    Name: LStr;
    PrimaryAmmoID,
    PrimaryAmmoMaxAmount,
    SecondaryAmmoID,
    SecondaryAmmoMaxAmount,
    SlotID,
    NumberInSlot,
    Index,
    Flags: UInt8;

    class operator Equal(A, B: TWeapon): Boolean; overload;
    class operator Equal(A: TWeapon; B: UInt8): Boolean; overload;
    class operator Equal(A: TWeapon; B: LStr): Boolean; overload;

    class operator NotEqual(A, B: TWeapon): Boolean; overload;
    class operator NotEqual(A: TWeapon; B: UInt8): Boolean; overload;
    class operator NotEqual(A: TWeapon; B: LStr): Boolean; overload;

    function ResolveName(AUpperCase: Boolean = False): LStr;
  end;

  PWeapons = ^TWeapons;
  TWeapons = array of TWeapon;

const
  ITEM_FLAG_SELECTONEMPTY = 1 shl 0;
  ITEM_FLAG_NOAUTORELOAD = 1 shl 1;
  ITEM_FLAG_NOAUTOSWITCHEMPTY = 1 shl 2;
  ITEM_FLAG_LIMITINWORLD = 1 shl 3;
  ITEM_FLAG_EXHAUSTIBLE = 1 shl 4; // A player can totally exhaust their ammo supply and lose this weapon.

const
  WeaponCleared: TWeapon = ();

function FindWeapon(AWeapons: PWeapons; AName: LStr): PWeapon; overload;
function FindWeapon(AWeapons: PWeapons; AIndex: UInt8): PWeapon; overload;

procedure Clear(var Data: TWeapon); overload; inline;
procedure Clear(var Data: PWeapon); overload; inline;
procedure Clear(var Data: TWeapons); overload; inline;

implementation

{$REGION 'TWeapon'}
class operator TWeapon.Equal(A, B: TWeapon): Boolean;
begin
  Result := A.Index = B.Index;
end;

class operator TWeapon.Equal(A: TWeapon; B: UInt8): Boolean;
begin
  Result := A.Index = B;
end;

class operator TWeapon.Equal(A: TWeapon; B: LStr): Boolean;
begin
  Result := (A.Name = B) or (ParseAfter(A.Name, 'weapon_') = ParseAfter(B, 'weapon_'));
end;

class operator TWeapon.NotEqual(A, B: TWeapon): Boolean;
begin
  Result := A.Index <> B.Index;
end;

class operator TWeapon.NotEqual(A: TWeapon; B: UInt8): Boolean;
begin
  Result := A.Index <> B;
end;

class operator TWeapon.NotEqual(A: TWeapon; B: LStr): Boolean;
begin
  Result := (A.Name <> B) and (ParseAfter(A.Name, 'weapon_') <> ParseAfter(B, 'weapon_'));
end;

function TWeapon.ResolveName(AUpperCase: Boolean = False): LStr;
begin
  Result := ParseAfter(Name, 'weapon_');

  if AUpperCase then
    Result := AnsiUpperCase(Result);
end;
{$ENDREGION}

{$REGION 'Shared'}
function FindWeapon(AWeapons: PWeapons; AName: LStr): PWeapon;
var
  I: Int32;
begin
  Result := nil;

  for I := Low(AWeapons^) to High(AWeapons^) do
    if AWeapons^[I] = AName then
      Exit(@AWeapons^[I]);
end;

function FindWeapon(AWeapons: PWeapons; AIndex: UInt8): PWeapon;
var
  I: Int32;
begin
  Result := nil;

  for I := Low(AWeapons^) to High(AWeapons^) do
    if AWeapons^[I] = AIndex then
      Exit(@AWeapons^[I]);
end;
{$ENDREGION}

{$REGION 'Clears'}
procedure Clear(var Data: TWeapon);
begin
  with Data do
  begin
    Clear(Name);
    Clear(PrimaryAmmoID);
    Clear(PrimaryAmmoMaxAmount);
    Clear(SecondaryAmmoID);
    Clear(SecondaryAmmoMaxAmount);
    Clear(SlotID);
    Clear(NumberInSlot);
    Clear(Index);
    Clear(Flags);
  end;
end;

procedure Clear(var Data: PWeapon);
begin
  Data := nil;
end;

procedure Clear(var Data: TWeapons);
var
  I: Int32;
begin
  for I := Low(Data) to High(Data) do
    Clear(Data[I]);

  SetLength(Data, 0);
end;
{$ENDREGION}

end.