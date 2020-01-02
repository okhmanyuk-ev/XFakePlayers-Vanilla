unit Alias;

interface

uses
  Default,  
  SysUtils,
  Shared,
  System.Generics.Defaults,
  Generics.Collections;

type
  PAlias = ^TAlias;
  TAlias = TPair<LStr, LStr>;

  TAliasComparer = class(TComparer<TAlias>)
    function Compare(const Left, Right: TAlias): Int32; override;
  end;

  TAliasList = class(TList<TAlias>)
  public
    constructor Create;
    
    function Add(AKey: LStr; AValue: LStr = ''; Overwrite: Boolean = True): Int32; overload;

    function IndexOf(const AKey: LStr; UseStrCmp: Boolean = False): Int32; overload;
  end;

implementation

{$REGION 'TAliasComparer'}
function TAliasComparer.Compare(const Left, Right: TAlias): Int32;
begin
  Result := CompareStr(Left.Key, Right.Key);
end;
{$ENDREGION}

{$REGION 'TAliasList'}
constructor TAliasList.Create;
begin
  inherited Create(TAliasComparer.Create);
end;

function TAliasList.Add(AKey: LStr; AValue: LStr = ''; Overwrite: Boolean = True): Int32;
var
  I: Int32;
  A: TAlias;
begin
  A.Key := AKey;
  A.Value := AValue;

  if Overwrite then
    I := IndexOf(AKey);

  if (I >= 0) and Overwrite then
    Items[I] := A
  else
    I := Add(A);

  Result := I;
end;

function TAliasList.IndexOf(const AKey: LStr; UseStrCmp: Boolean = False): Int32;
var
  I: Int32;
begin
  for I := 0 to Count - 1 do
    if UseStrCmp then
      if StrBComp(AKey, Items[I].Key) then
        Exit(I)
      else
    else
      if Items[I].Key = AKey then
        Exit(I);

  Result := -1;
end;
{$ENDREGION}

end.