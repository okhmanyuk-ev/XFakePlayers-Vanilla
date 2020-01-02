unit Ways;

interface

uses
  Default,
  Vector;

type
  PWay = ^TWay;
  TWay = TArray<TVec3F>;
  PWays = ^TWays;
  TWays = TArray<TWay>;

implementation

end.
