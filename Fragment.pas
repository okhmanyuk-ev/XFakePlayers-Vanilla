unit Fragment;

interface

uses
  Windows,
  Default,
  SysUtils,
  Math,
  System.Generics.Defaults,
  System.Generics.Collections;

type
  TFragment = record
    Index,
    LastUpdateTime: UInt32;
    Data: TArray<LStr>;

    function Defragmentate: LStr;
  end;

  TWritingFragment = record
    Data: LStr;
    Size,    
    Total,   
    Time: UInt32;
  end;

const
  ClearedFragment: TFragment = ();
  ClearedWritingFragment: TWritingFragment = ();

type
  TFragmentComparer = class(TComparer<TFragment>)
    function Compare(const Left, Right: TFragment): Int32; override;
  end;

  TWritingFragmentComparer = class(TComparer<TWritingFragment>)
    function Compare(const Left, Right: TWritingFragment): Int32; override;
  end;

  TFragmentReader = class(TList<TFragment>)
  public
    constructor Create;

    procedure Add(AIndex, ACount, ATotal: UInt32; AData: LStr); overload;
    function GetCompleted: Int32;
    procedure CheckTimeouts;

    function IndexOf(AIndex: UInt32): Int32; overload;
  end;

  TFragmentWriter = class(TList<TWritingFragment>)
  public
    constructor Create;

    procedure CreateNewBuffer(const AData: LStr; FragmentSize: UInt32);
    function GetFragment(Offset: UInt32): LStr;

    procedure CheckTimeouts;
  end;

implementation

{$REGION 'TFragment'}
function TFragment.Defragmentate: LStr;
var
  I: Int32;
begin
  Clear(Result);

  for I := Low(Data) to High(Data) do
    Result := Result + Data[I];
end;
{$ENDREGION}

{$REGION 'TFragmentComparer'}
function TFragmentComparer.Compare(const Left, Right: TFragment): Int32;
begin
  Result := Left.Index - Right.Index;
end;

function TWritingFragmentComparer.Compare(const Left, Right: TWritingFragment): Int32;
begin
  Result := CompareStr(Left.Data, Right.Data);
end;
{$ENDREGION}

{$REGION 'TFragmentReader'}
constructor TFragmentReader.Create;
begin
  inherited Create(TFragmentComparer.Create);
end;

procedure TFragmentReader.Add(AIndex, ACount, ATotal: UInt32; AData: LStr);
var
  I: Int32;
begin
  I := IndexOf(AIndex);

  if I = -1 then
  begin
    I := Add(ClearedFragment);
    SetLength(List[I].Data, ATotal);
    List[I].Index := AIndex;
  end;

  List[I].LastUpdateTime := GetTickCount;
  List[I].Data[ACount - 1] := AData;
end;

function TFragmentReader.GetCompleted: Int32;
var
  I, J: Int32;
label
  L1;
begin
  Result := -1;

  for I := 0 to Count - 1 do
  begin
    if Items[I].Index = 0 then
      Continue;

    for J := Low(Items[I].Data) to High(Items[I].Data) do
      if Length(Items[I].Data[J]) = 0 then
        goto L1;

    Exit(I);

    L1:
  end;
end;

function TFragmentReader.IndexOf(AIndex: UInt32): Int32;
var
  I: Int32;
begin
  for I := 0 to Count - 1 do
    if Items[I].Index = AIndex then
      Exit(I);

  Result := -1;
end;

procedure TFragmentReader.CheckTimeouts;
var
  I: Int32;
begin
  for I := Count - 1 downto 0 do
    if GetTickCount - Items[I].LastUpdateTime >= 5000 then
      Delete(I);
end;
{$ENDREGION}

{$REGION 'TFragmentWriter'}
constructor TFragmentWriter.Create;
begin
  inherited Create(TWritingFragmentComparer.Create);
end;

procedure TFragmentWriter.CreateNewBuffer(const AData: LStr; FragmentSize: UInt32);
begin
  Add(ClearedWritingFragment);

  with List[Count - 1] do
  begin
    Data := AData;
    Size := FragmentSize;
    Time := GetTickCount;
    Total := Ceil(Length(AData) / FragmentSize);
  end;
end;

procedure TFragmentWriter.CheckTimeouts;
var
  I: Int32;
begin
  for I := Count - 1 downto 0 do
    if GetTickCount - Items[I].Time >= 5000 then
      Delete(I);
end;

function TFragmentWriter.GetFragment(Offset: UInt32): LStr;
begin
  Default.Clear(Result);

  if Count = 0 then
    Default.Error(['GetFragment: no active fragments for writing']);

  with List[0] do
  begin
    Time := GetTickCount;
    Result := ReadBuf(Data, Size, Offset * Size - Size + 1);
  end;
end;
{$ENDREGION}
end.