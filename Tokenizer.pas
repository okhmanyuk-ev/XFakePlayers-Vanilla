unit Tokenizer;

interface

uses
  SysUtils,

  Shared,
  Common,
  Default;

type
  TTokenizer = class(TObject)
   strict private
    FToken: LStr;
    FTokens: TArray<LStr>;
    FIgnoreColons: Boolean;
    FUngetToken: Boolean;
    FUnTokenized: LStr;

    function GetCount: UInt;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Parse(var Data: Pointer);
    procedure ParseLine(var Data: Pointer);

    procedure Tokenize(const Data: LStr);
    function TokenizeEx(const Data: LStr): LStr;

    property Token: LStr read FToken;
    property Tokens: TArray<LStr> read FTokens;
    property UnTokenized: LStr read FUnTokenized;

    property IgnoreColons: Boolean read FIgnoreColons write FIgnoreColons;

    property Count: UInt read GetCount;
  end;

implementation

constructor TTokenizer.Create;
begin
  inherited;
  //
end;

destructor TTokenizer.Destroy;
begin
  //
  inherited;
end;

function TTokenizer.GetCount: UInt;
begin
  Result := Length(FTokens);
end;

procedure TTokenizer.Parse(var Data: Pointer);
var
  C: LChar;
begin
  if FUngetToken then
  begin
    FUngetToken := False;
    Exit;
  end;

  FToken := '';

  if Data = nil then
    Exit;

  C := #0;

  while True do
  begin
    C := PLChar(Data)^;

    while C <= ' ' do
    if C = #0 then
    begin
      Data := nil;
      Exit;
    end
    else
    begin
      Inc(UInt32(Data));
      C := PLChar(Data)^;
    end;

    if (C = '/') and (PLChar(UInt32(Data) + 1)^ = '/') then
      while C <> #0 do
        if C = #$A then
          Break
        else
        begin
          Inc(UInt32(Data));
          C := PLChar(Data)^;
        end
    else
      Break;
  end;

  if C = '"' then
  begin
    while True do
    begin
      Inc(UInt32(Data));

      if PLChar(Data)^ = '"' then
        Break
      else
        FToken := FToken + PLChar(Data)^;
    end;

    Data := Pointer(UInt32(Data) + 1);
  end
  else
    if (C in ['{', '}', ')', '(', '\', ',']) or (not FIgnoreColons and (C = ':')) then
    begin
      FToken := FToken + C;
      Data := Pointer(UInt32(Data) + 1);
    end
    else
      while not ((C in ['{', '}', ')', '(', '\', ',', #0..' ']) or (not FIgnoreColons and (C = ':'))) do
      begin
        FToken := FToken + C;
        Inc(UInt32(Data));
        C := PLChar(Data)^;
      end;
end;

procedure TTokenizer.ParseLine(var Data: Pointer);
var
  C: LChar;
begin
  if FUngetToken then
  begin
    FUngetToken := False;
    Exit;
  end;

  if Data = nil then
  begin
    FToken := '';
    Exit;
  end;

  C := PLChar(Data)^;

  while C >= ' ' do
  begin
    FToken := FToken + C;
    Inc(UInt32(Data));
    C := PLChar(Data)^;
  end;

  if C < ' ' then
    while C > #0 do
    begin
      Inc(UInt32(Data));
      C := PLChar(Data)^;

      if C >= ' ' then
        Break;
    end;
end;

procedure TTokenizer.Tokenize(const Data: LStr);
var
  P: Pointer;
  B: Boolean;
begin
  B := FIgnoreColons;
  FIgnoreColons := True;

  Finalize(FTokens);
  FUnTokenized := Data;

  P := @Data[Low(Data)];

  Parse(P);

  while P <> nil do
  begin
    SetLength(FTokens, Length(FTokens) + 1);
    FTokens[High(FTokens)] := FToken;
    Parse(P);
  end;

  FIgnoreColons := B;
end;

function TTokenizer.TokenizeEx(const Data: LStr): LStr;
var
  P: Pointer;
  I, J: Int32;
  B: Boolean;
begin
  B := FIgnoreColons;
  FIgnoreColons := True;

  Finalize(FTokens);

  P := @Data[Low(Data)];

  Parse(P);

  while P <> nil do
  begin
    I := Pos(';', FToken);

    if I = 1 then
      Break;

    SetLength(FTokens, Length(FTokens) + 1);
    FTokens[High(FTokens)] := FToken;

    if I > 1 then
    begin
      FTokens[High(FTokens)] := Copy(FTokens[High(FTokens)], Low(FTokens[High(FTokens)]), I - 1);
      Break;
    end;

    Parse(P);
  end;

  if I > 0 then
  begin
    J := Int32(P) - Int32(@Data[Low(Data)]) - Length(FToken) + I;
    Result := Trim(Copy(Data, J + 1, Length(Data) - J));
    FUnTokenized := Copy(Data, 1, J - 1);
  end
  else
  begin
    Result := '';
    FUnTokenized := Data;
  end;

  FIgnoreColons := B;
end;

end.
