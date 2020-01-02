unit Challenge;

interface

uses Default, Network;

type
  PChallenge = ^TChallenge;
  TChallenge = record
    Address: TNETAdr;
    Challenge: UInt32;
  end;

  TChallengeSystem = class(TObject)
  private
    FItems: TArray<TChallenge>; 

    function Find(AAddress: TNETAdr): PChallenge;
    function Add(AAddress: TNETAdr): PChallenge;
  public
    procedure Save(AAddress: TNETAdr; AChallenge: UInt32);
    function Get(AAddress: TNETAdr): UInt32;
  end;

implementation

function TChallengeSystem.Find(AAddress: TNETAdr): PChallenge;
var
  I: Int32;
begin
  Result := nil;

  for I := Low(FItems) to High(FItems) do
    if FItems[I].Address = AAddress then
      Exit(@FItems[I]);
end;

function TChallengeSystem.Add(AAddress: TNETAdr): PChallenge;
begin
  SetLength(FItems, Length(FItems) + 1);
  Result := @FItems[High(FItems)];
  Result.Address := AAddress;
end;

procedure TChallengeSystem.Save(AAddress: TNETAdr; AChallenge: UInt32);
var
  C: PChallenge;
begin
  C := Find(AAddress);

  if C = nil then
    C := Add(AAddress);

  C.Challenge := AChallenge;
end;

function TChallengeSystem.Get(AAddress: TNETAdr): UInt32;
var
  C: PChallenge;
begin
  C := Find(AAddress);

  if C = nil then
  begin
    C := Add(AAddress);
    C.Challenge := Random(MaxInt32); // or MaxUInt32 ?
  end;

  Result := C.Challenge;
end;

end.
