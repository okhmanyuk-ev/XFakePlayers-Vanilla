unit GameEvent;

interface

uses
  Default,
  Common,
  Generics.Defaults,
  Generics.Collections;

type
  PGameEvent = ^TGameEvent;
  TGameEvent = record
    Index: UInt8;
    Size: UInt8;
    Name: LStr;
    Callback: TProcedureObj;

    class function Create(AIndex, ASize: UInt8; AName: LStr; ACallback: TProcedureObj): TGameEvent; static;
  end;

  TGameEventComparer = class(TComparer<TGameEvent>)
    function Compare(const Left, Right: TGameEvent): Int32; override;
  end;

  TGameEventList = class(TList<TGameEvent>)
  public
    constructor Create;

    function Add(AIndex, ASize: UInt8; AName: LStr): Int32; overload;
    procedure AddCallback(AName: LStr; ACallback: TProcedureObj);

    function IndexOfIndex(const Value: UInt8): Int32;
    function IndexOf(const Value: LStr): Int32; overload;
  end;

implementation

{$REGION 'TGameEvent'}
class function TGameEvent.Create(AIndex, ASize: UInt8; AName: LStr; ACallback: TProcedureObj): TGameEvent;
begin
  Result.Index := AIndex;
  Result.Size := ASize;
  Result.Name := AName;
  Result.Callback := ACallback;
end;
{$ENDREGION}

{$REGION 'TGameEventComparer'}
function TGameEventComparer.Compare(const Left, Right: TGameEvent): Int32;
begin
  Result := Left.Index - Right.Index;
end;
{$ENDREGION}

{$REGION 'TGameEventList'}
constructor TGameEventList.Create;
begin
  inherited Create(TGameEventComparer.Create);
end;

function TGameEventList.Add(AIndex, ASize: UInt8; AName: LStr): Int32;
var
  I: Int32;
  G: TGameEvent;
begin
  I := IndexOf(AName);

  if I = -1 then
    I := Add(TGameEvent.Create(AIndex, ASize, AName, nil))
  else
  begin
    G := Items[I];
    G.Index := AIndex;
    G.Size := ASize;
    Items[I] := G;
  end;

  Result := I;
end;

procedure TGameEventList.AddCallback(AName: LStr; ACallback: TProcedureObj);
var
  I: Int32;
  G: TGameEvent;
begin
  I := IndexOf(AName);

  if I = -1 then
    Add(TGameEvent.Create(0, 0, AName, ACallback))
  else
  begin
    G := Items[I];
    G.Callback := ACallback;
    Items[I] := G;
  end;
end;

function TGameEventList.IndexOfIndex(const Value: UInt8): Int32;
var
  I: Int32;
begin
  for I := 0 to Count - 1 do
    if Items[I].Index = Value then
      Exit(I);

  Result := -1;
end;

function TGameEventList.IndexOf(const Value: LStr): Int32;
var
  I: Int32;
begin
  for I := 0 to Count - 1 do
    if Items[I].Name = Value then
      Exit(I);

  Result := -1;
end;
{$ENDREGION}

end.