unit Vector;

interface

uses
  Default,
  Math;

const M_PI = 3.14159265358979323846;

type
  TVec2F = record
    X, Y: Float;

    class function Create(AX, AY: Float): TVec2F; static;

    class operator Add(A, B: TVec2F): TVec2F;
    class operator Add(A: TVec2F; B: Float): TVec2F;

    class operator Subtract(A, B: TVec2F): TVec2F;
    class operator Subtract(A: TVec2F; B: Float): TVec2F;

    class operator Multiply(A, B: TVec2F): TVec2F;
    class operator Multiply(A: TVec2F; B: Float): TVec2F;

    class operator Divide(A, B: TVec2F): TVec2F;
    class operator Divide(A: TVec2F; B: Float): TVec2F;

    class operator Equal(A, B: TVec2F): Boolean;
    class operator NotEqual(A, B: TVec2F): Boolean;

    class operator Equal(A: TVec2F; B: Float): Boolean;
    class operator NotEqual(A: TVec2F; B: Float): Boolean;

    function Length: Float;
    function Distance(A: TVec2F): Float;
    function CrossProduct(A: TVec2F): Float;
    function DotProduct(A: TVec2F): Float;

    function ToString: LStr;
  end;

  PVec3F = ^TVec3F;
  TVec3F = record
    class function Create(AX, AY, AZ: Float): TVec3F; static;

    class operator Add(A, B: TVec3F): TVec3F;
    class operator Add(A: TVec3F; B: Float): TVec3F;

    class operator Subtract(A, B: TVec3F): TVec3F;
    class operator Subtract(A: TVec3F; B: Float): TVec3F;

    class operator Multiply(A, B: TVec3F): TVec3F;
    class operator Multiply(A: TVec3F; B: Float): TVec3F;

    class operator Divide(A, B: TVec3F): TVec3F;
    class operator Divide(A: TVec3F; B: Float): TVec3F;

    class operator Equal(A, B: TVec3F): Boolean;
    class operator NotEqual(A, B: TVec3F): Boolean;

    class operator Equal(A: TVec3F; B: Float): Boolean;
    class operator NotEqual(A: TVec3F; B: Float): Boolean;

    class operator Negative(A: TVec3F): TVec3F;
    class operator Positive(A: TVec3F): TVec3F;

    function Length: Float;
    function Distance(A: TVec3F): Float; overload;
    function Distance(A: TVec2F): Float; overload; // same as Distance2D
    function Distance2D(A: TVec3F): Float;
    function CrossProduct(A: TVec3F): TVec3F;
    function DotProduct(A: TVec3F): Float;

    function NormalizeAngles: TVec3F;
    function InterpolateAngles(A: TVec3F; AFraction: Float): TVec3F;
    function ViewTo(Origin: TVec3F): TVec3F;

    function ToString(AMode: Int32 = 0): LStr;
    function ToVec2F: TVec2F;

  case Int32 of
    1: (A: array [0..2] of Float);
    2: (X, Y, Z: Float);
  end;

  PVec3S = ^TVec3S;
  TVec3S = record
    function ToString: LStr;
    function ToVec3F: TVec3F;

  case Int32 of
    1: (A: array [0..2] of Int16);
    2: (X, Y, Z: Int16);
  end;

  TVec2FLine = record
    Hi, Lo: TVec2F;

    class function Create(AHiX, AHiY, ALoX, ALoY: Float): TVec2FLine; static;

    function Length: Float;
    function Center: TVec2F;
    function ToString: LStr;

    function IsIntersected(A: TVec2FLine): Boolean;
    function GetIntersectPoint(A: TVec2FLine): TVec2F;
  end;

  TVec3FLine = record
    Hi, Lo: TVec3F;

    class function Create(AHiX, AHiY, AHiZ, ALoX, ALoY, ALoZ: Float): TVec3FLine; overload; static;
    class function Create(A, B: TVec3F): TVec3FLine; overload; static;

    class operator Equal(A, B: TVec3FLine): Boolean;
    class operator NotEqual(A, B: TVec3FLine): Boolean;

    function Length: Float;
    function Center: TVec3F;
    function ToString: LStr;
  end;

  TExtent = record
    Hi, Lo: TVec3F;
    Heights: TVec2F;

    class function Create(LeftTop, RightTop, LeftDown, RightDown: TVec3F): TExtent; static;

    function Center: TVec3F;
    function Size: Float;
    function ToString: LStr;
  end;


procedure AngleVectors(Angles: TVec3F; Fwd, Right, Up: PVec3F);
procedure AngleVectorsTranspose(Angles: TVec3F; Fwd, Right, Up: PVec3F);

//function AngleBetweenVectors(V1, V2: TVec3F): Float;


procedure NormalizeAngle(var AViewAngle: Float); inline;

// read & write
procedure WriteVec2F(var Data: LStr; Value: TVec2F); overload; inline;
function WriteVec2F(Value: TVec2F): LStr; overload; inline;

procedure WriteVec3F(var Data: LStr; Value: TVec3F); overload; inline;
function WriteVec3F(Value: TVec3F): LStr; overload; inline;

// clears
procedure Clear(var Data: TVec2F); overload; inline;
procedure Clear(var Data: TVec3F); overload; inline;
procedure Clear(var Data: TVec3S); overload; inline;
procedure Clear(var Data: TExtent); overload; inline;

procedure Clear(var Data: TArray<TVec2F>); overload; inline;
procedure Clear(var Data: TArray<TVec3F>); overload; inline;

implementation

{$REGION 'TVec2F'}
class function TVec2F.Create(AX, AY: Float): TVec2F;
begin
  Result.X := AX;
  Result.Y := AY;
end;

class operator TVec2F.Add(A, B: TVec2F): TVec2F;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
end;

class operator TVec2F.Add(A: TVec2F; B: Float): TVec2F;
begin
  Result.X := A.X + B;
  Result.Y := A.Y + B;
end;

class operator TVec2F.Subtract(A, B: TVec2F): TVec2F;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
end;

class operator TVec2F.Subtract(A: TVec2F; B: Float): TVec2F;
begin
  Result.X := A.X - B;
  Result.Y := A.Y - B;
end;

class operator TVec2F.Multiply(A, B: TVec2F): TVec2F;
begin
  Result.X := A.X * B.X;
  Result.Y := A.Y * B.Y;
end;

class operator TVec2F.Multiply(A: TVec2F; B: Float): TVec2F;
begin
  Result.X := A.X * B;
  Result.Y := A.Y * B;
end;

class operator TVec2F.Divide(A, B: TVec2F): TVec2F;
begin
  Result.X := A.X / B.X;
  Result.Y := A.Y / B.Y;
end;

class operator TVec2F.Divide(A: TVec2F; B: Float): TVec2F;
begin
  Result.X := A.X / B;
  Result.Y := A.Y / B;
end;

class operator TVec2F.Equal(A, B: TVec2F): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y);
end;

class operator TVec2F.NotEqual(A, B: TVec2F): Boolean;
begin
  Result := not (A = B);
end;

class operator TVec2F.Equal(A: TVec2F; B: Float): Boolean;
begin
  Result := (A.X = B) and (A.Y = B);
end;

class operator TVec2F.NotEqual(A: TVec2F; B: Float): Boolean;
begin
  Result := not (A = B);
end;

function TVec2F.Length: Float;
begin
  Result := Sqrt(Sqr(X) + Sqr(Y));
end;

function TVec2F.Distance(A: TVec2F): Float;
begin
  Result := Abs((A - Self).Length);
end;

function TVec2F.CrossProduct(A: TVec2F): Float;
begin
  Result := (Self.X * A.Y) - (Self.Y * A.X);
end;

function TVec2F.DotProduct(A: TVec2F): Float;
begin
  Result := (Self.X * A.X) + (Self.Y * A.Y);
end;

function TVec2F.ToString: LStr;
begin
  Result := StringFromVarRec(['X: ', Trunc(X), ', Y: ', Trunc(Y)]);
end;
{$ENDREGION}

{$REGION 'TVec3F'}
class function TVec3F.Create(AX, AY, AZ: Float): TVec3F;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Z := AZ;
end;

class operator TVec3F.Add(A, B: TVec3F): TVec3F;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
  Result.Z := A.Z + B.Z;
end;

class operator TVec3F.Add(A: TVec3F; B: Float): TVec3F;
begin
  Result.X := A.X + B;
  Result.Y := A.Y + B;
  Result.Z := A.Z + B;
end;

class operator TVec3F.Subtract(A, B: TVec3F): TVec3F;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
  Result.Z := A.Z - B.Z;
end;

class operator TVec3F.Subtract(A: TVec3F; B: Float): TVec3F;
begin
  Result.X := A.X - B;
  Result.Y := A.Y - B;
  Result.Z := A.Z - B;
end;

class operator TVec3F.Multiply(A, B: TVec3F): TVec3F;
begin
  Result.X := A.X * B.X;
  Result.Y := A.Y * B.Y;
  Result.Z := A.Z * B.Z;
end;

class operator TVec3F.Multiply(A: TVec3F; B: Float): TVec3F;
begin
  Result.X := A.X * B;
  Result.Y := A.Y * B;
  Result.Z := A.Z * B;
end;

class operator TVec3F.Divide(A, B: TVec3F): TVec3F;
begin
  Result.X := A.X / B.X;
  Result.Y := A.Y / B.Y;
  Result.Z := A.Z / B.Z;
end;

class operator TVec3F.Divide(A: TVec3F; B: Float): TVec3F;
begin
  Result.X := A.X / B;
  Result.Y := A.Y / B;
  Result.Z := A.Z / B;
end;

class operator TVec3F.Equal(A, B: TVec3F): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y) and (A.Z = B.Z);
end;

class operator TVec3F.NotEqual(A, B: TVec3F): Boolean;
begin
  Result := not (A = B);
end;

class operator TVec3F.Equal(A: TVec3F; B: Float): Boolean;
begin
  Result := (A.X = B) and (A.Y = B) and (A.Z = B);
end;

class operator TVec3F.NotEqual(A: TVec3F; B: Float): Boolean;
begin
  Result := not (A = B);
end;

class operator TVec3F.Negative(A: TVec3F): TVec3F;
begin
  Result.X := -A.X;
  Result.Y := -A.Y;
  Result.Z := -A.Z;
end;

class operator TVec3F.Positive(A: TVec3F): TVec3F;
begin
  Result.X := +A.X;
  Result.Y := +A.Y;
  Result.Z := +A.Z;
end;

function TVec3F.Length: Float;
begin
  Result := Sqrt(DotProduct(Self));
end;

function TVec3F.Distance(A: TVec3F): Float;
begin
  Result := Abs((A - Self).Length);
end;

function TVec3F.Distance(A: TVec2F): Float;
begin
  Result := Abs((A - TVec2F.Create(X, Y)).Length);
end;

function TVec3F.Distance2D(A: TVec3F): Float;
begin
  Result := Abs((TVec2F.Create(A.X, A.Y)  - TVec2F.Create(X, Y)).Length);
end;

function TVec3F.CrossProduct(A: TVec3F): TVec3F;
begin
  Result.X := (Self.Y * A.Z) - (Self.Z * A.Y);
  Result.Y := (Self.Z * A.X) - (Self.X * A.Z);
  Result.Z := (Self.X * A.Y) - (Self.Y * A.X);
end;

function TVec3F.DotProduct(A: TVec3F): Float;
begin
  Result := (Self.X * A.X) + (Self.Y * A.Y) + (Self.Z * A.Z);
end;

function TVec3F.NormalizeAngles: TVec3F;
begin
  Result := Self;

  with Result do
  begin
    NormalizeAngle(X);
    NormalizeAngle(Y);
    NormalizeAngle(Z);
  end;
end;

function TVec3F.InterpolateAngles(A: TVec3F; AFraction: Float): TVec3F;
var
  V, D: TVec3F;

var
  vec1, vec2, vecOut: TVec3F;
  Delta: Float;
begin
  // ver 1

  {Result := Self + (A - Self).NormalizeAngles * AFraction;}

  // ver 2

  {V := Self.NormalizeAngles;
  A := A.NormalizeAngles;
  D := (A - V).NormalizeAngles;
  Result := (V + D * AFraction).NormalizeAngles;}

  // ver 3

  vec1 := Self;
  vec2 := A;

  NormalizeAngle(vec1.X);
  NormalizeAngle(vec1.Y);

  NormalizeAngle(vec2.X);
  NormalizeAngle(vec2.Y);

  Delta := vec2.x - vec1.x;
  if Delta > 180 then
   Delta := Delta - 360
  else if Delta < -180 then
   Delta := Delta + 360;
  vecOut.x := vec1.x + Delta * AFraction;

  Delta := vec2.y - vec1.y;
  if Delta > 180 then
   Delta := Delta - 360
  else if Delta < -180 then
   Delta := Delta + 360;
  vecOut.y := vec1.y + Delta * AFraction;

{  Delta := vec2.z - vec1.z;
  if Delta > 180 then
   Delta := Delta - 360
  else if Delta < -180 then
   Delta := Delta + 360;
  vecOut.z := vec1.z + Delta * AFraction;}

  NormalizeAngle(vecout.X);
  NormalizeAngle(vecout.Y);

  Result := vecOut;
end;

function TVec3F.ViewTo(Origin: TVec3F): TVec3F;
var
  V: TVec3F;
begin
  V := Origin - Self;

  Result.Y := RadToDeg(ArcTan2(V.Y, V.X));
  Result.X := -RadToDeg(ArcTan2(V.Z, Sqrt(V.X * V.X + V.Y * V.Y)));
end;

function TVec3F.ToString(AMode: Int32 = 0): LStr;
begin
  case AMode of
    0: Result := StringFromVarRec(['X: ', Trunc(X), ', Y: ', Trunc(Y), ', Z: ', Trunc(Z)]);
    1: Result := StringFromVarRec([Trunc(X), ', ', Trunc(Y), ', ', Trunc(Z)]);
  end;
end;

function TVec3F.ToVec2F: TVec2F;
begin
  Result := TVec2F.Create(X, Y);
end;
{$ENDREGION}

{$REGION 'TVec3S'}
function TVec3S.ToString: LStr;
begin
  Result := StringFromVarRec(['X: ', X, ', Y: ', Y, ', Z: ', Z]);
end;

function TVec3S.ToVec3F: TVec3F;
begin
  Result := TVec3F.Create(X, Y, Z) ;
end;
{$ENDREGION}

{$REGION 'TVec2FLine'}
class function TVec2FLine.Create(AHiX, AHiY, ALoX, ALoY: Float): TVec2FLine;
begin
  Result.Hi.X := AHiX;
  Result.Hi.Y := AHiY;
  Result.Lo.X := ALoX;
  Result.Lo.Y := ALoY;
end;

function TVec2FLine.Length;
begin
  Result := (Hi - Lo).Length;
end;

function TVec2FLine.Center: TVec2F;
begin
  Result := (Lo + Hi) / 2
end;

function TVec2FLine.ToString: LStr;
begin
  Result := 'Hi: [' + Hi.ToString + '], Lo: [' + Lo.ToString + ']';
end;

function TVec2FLine.IsIntersected(A: TVec2FLine): Boolean;
var
  ADX, ADY,
  SDX, SDY: Float;

  V1, V2, V3, V4: Float;
begin
  ADX := A.Lo.X - A.Hi.X;
  ADY := A.Lo.Y - A.Hi.Y;
  SDX := Self.Lo.X - Self.Hi.X;
  SDY := Self.Lo.Y - Self.Hi.Y;

  V1 := ADX * (Self.Hi.Y - A.Hi.Y) - ADY * (Self.Hi.X - A.Hi.X);
  V2 := ADX * (Self.Lo.Y - A.Hi.Y) - ADY * (Self.Lo.X - A.Hi.X);
  V3 := SDX * (A.Hi.Y - Self.Hi.Y) - SDY * (A.Hi.X - Self.Hi.X);
  V4 := SDX * (A.Lo.Y - Self.Hi.Y) - SDY * (A.Lo.X - Self.Hi.X);

  Result := (V1 * V2 < 0) and (V3 * V4 < 0);
end;

function TVec2FLine.GetIntersectPoint(A: TVec2FLine): TVec2F;
var
  LDetLineA, LDetLineB, LDetDivInv: Float;
  LDiffLA, LDiffLB : TVec2F;
begin
  LDetLineA := Self.Hi.X * Self.Lo.Y - Self.Hi.Y * Self.Lo.X;
  LDetLineB := A.Hi.X * A.Lo.Y - A.Hi.Y * A.Lo.X;

  LDiffLA := Self.Hi - Self.Lo;
  LDiffLB := A.Hi - A.Lo;

  LDetDivInv := 1 / ((LDiffLA.X * LDiffLB.Y) - (LDiffLA.Y * LDiffLB.X));

  Result.X := ((LDetLineA * LDiffLB.X) - (LDiffLA.X * LDetLineB)) * LDetDivInv;
  Result.Y := ((LDetLineA * LDiffLB.Y) - (LDiffLA.Y * LDetLineB)) * LDetDivInv;
end;

{$ENDREGION}

{$REGION 'TVec3FLine'}
class function TVec3FLine.Create(AHiX, AHiY, AHiZ, ALoX, ALoY, ALoZ: Float): TVec3FLine;
begin
  Result.Hi.X := AHiX;
  Result.Hi.Y := AHiY;
  Result.Hi.Z := AHiZ;
  Result.Lo.X := ALoX;
  Result.Lo.Y := ALoY;
  Result.Lo.Z := ALoZ;
end;

class function TVec3FLine.Create(A, B: TVec3F): TVec3FLine;
begin
  Result.Hi := A;
  Result.Lo := B;
end;

class operator TVec3FLine.Equal(A, B: TVec3FLine): Boolean;
begin
  Result := (A.Hi = B.Hi) and (A.Lo = B.Lo);
end;

class operator TVec3FLine.NotEqual(A, B: TVec3FLine): Boolean;
begin
  Result := not (A = B);
end;

function TVec3FLine.Length;
begin
  Result := (Hi - Lo).Length;
end;

function TVec3FLine.Center: TVec3F;
begin
  Result := (Lo + Hi) / 2
end;

function TVec3FLine.ToString: LStr;
begin
  Result := 'Hi: [' + Hi.ToString + '], Lo: [' + Lo.ToString + ']';
end;
{$ENDREGION}

{$REGION 'TExtent'}
class function TExtent.Create(LeftTop, RightTop, LeftDown, RightDown: TVec3F): TExtent;
begin
  Result.Lo := LeftTop;
  Result.Hi := RightDown;
  Result.Heights.X := RightTop.Z;
  Result.Heights.Y := LeftDown.Z;
end;

function TExtent.Center: TVec3F;
begin
  Result := (Hi + Lo) / 2;
  Result.Z := (Result.Z + (Heights.X + Heights.Y) / 2) / 2;
end;

function TExtent.Size: Float;
begin
  Result := Hi.Distance(Lo);
end;

function TExtent.ToString: LStr;
begin
  Result := 'Hi: [' + Hi.ToString + '], Lo: [' + Lo.ToString + '], Heights: [' + Heights.ToString + ']';
end;
{$ENDREGION}

{$REGION 'Shared'}
procedure AngleVectors(Angles: TVec3F; Fwd, Right, Up: PVec3F);
var
  Angle, SP, CP, SY, CY, SR, CR: Float;
begin
  Angle := Angles.X * (M_PI * 2 / 360);
  SP := Sin(Angle);
  CP := Cos(Angle);
  Angle := Angles.Y * (M_PI * 2 / 360);
  SY := Sin(Angle);
  CY := Cos(Angle);
  Angle := Angles.Z * (M_PI * 2 / 360);
  SR := Sin(Angle);
  CR := Cos(Angle);

  if Fwd <> nil then
  begin
    Fwd.X := CP * CY;
    Fwd.Y := CP * SY;
    Fwd.Z := -SP;
  end;

  if Right <> nil then
  begin
    Right.X := CR * SY - SR * SP * CY;
    Right.Y := -(CR * CY + SR * SP * SY);
    Right.Z := -(SR * CP);
  end;

  if Up <> nil then
  begin
    Up.X := CR * SP * CY + SR * SY;
    Up.Y := CR * SP * SY - SR * CY;
    Up.Z := CR * CP;
  end;
end;

procedure AngleVectorsTranspose(Angles: TVec3F; Fwd, Right, Up: PVec3F);
var
  Angle, SP, CP, SY, CY, SR, CR: Single;
begin
  Angle := Angles.X * (M_PI * 2 / 360);
  SP := Sin(Angle);
  CP := Cos(Angle);
  Angle := Angles.Y * (M_PI * 2 / 360);
  SY := Sin(Angle);
  CY := Cos(Angle);
  Angle := Angles.Z * (M_PI * 2 / 360);
  SR := Sin(Angle);
  CR := Cos(Angle);

  if Fwd <> nil then
  begin
    Fwd.X := CP * CY;
    Fwd.Y := SR * SP * CY - CR * SY;
    Fwd.Z := CR * SP * CY + SR * SY;
  end;

  if Right <> nil then
  begin
    Right.X := CP * SY;
    Right.Y := SR * SP * SY + CR * CY;
    Right.Z := CR * SP * SY - SR * CY;
  end;

  if Up <> nil then
  begin
    Up.X := -SP;
    Up.Y := SR * CP;
    Up.Z := CR * CP;
  end;
end;

{function AngleBetweenVectors(V1, V2: TVec3F): Float;
var
  Angle, L1, L2: Float;                 
begin
  L1 := V1.Length;
  L2 := V2.Length;

  if (L1 = 0) or (L2 = 0) then
    Exit(0);

  Angle := (ArcCos(V1.DotProduct(V2)) / (L1 * L2)) * 180 / M_PI;
end;}

procedure NormalizeAngle(var AViewAngle: Float);
begin
  if AViewAngle > 180 then
    AViewAngle := AViewAngle - 360
  else
    if AViewAngle < -180 then
      AViewAngle := AViewAngle + 360;
end;
{$ENDREGION}

{$REGION 'Read & Write'}
procedure WriteVec2F(var Data: LStr; Value: TVec2F);
begin
  WriteFloat(Data, Value.X);
  WriteFloat(Data, Value.Y);
end;

function WriteVec2F(Value: TVec2F): LStr;
begin
  Clear(Result);

  WriteVec2F(Result, Value);
end;

procedure WriteVec3F(var Data: LStr; Value: TVec3F);
begin
  WriteFloat(Data, Value.X);
  WriteFloat(Data, Value.Y);
  WriteFloat(Data, Value.Z);
end;

function WriteVec3F(Value: TVec3F): LStr;
begin
  Clear(Result);

  WriteVec3F(Result, Value);
end;
{$ENDREGION}

{$REGION 'Clear'}
procedure Clear(var Data: TVec2F);
begin
  with Data do
  begin
    Clear(X);
    Clear(Y);
  end;
end;

procedure Clear(var Data: TVec3F);
begin
  with Data do
  begin
    Clear(X);
    Clear(Y);
    Clear(Z);
  end;
end;

procedure Clear(var Data: TVec3S);
begin
  with Data do
  begin
    Clear(X);
    Clear(Y);
    Clear(Z);
  end;
end;

procedure Clear(var Data: TExtent);
begin
  with Data do
  begin
    Clear(Hi);
    Clear(Lo);
    Clear(Heights);
  end;
end;

procedure Clear(var Data: TArray<TVec2F>);
var
  I: Int32;
begin
  for I := Low(Data) to High(Data) do
    Clear(Data[I]);

  SetLength(Data, 0);
end;

procedure Clear(var Data: TArray<TVec3F>);
var
  I: Int32;
begin
  for I := Low(Data) to High(Data) do
    Clear(Data[I]);

  SetLength(Data, 0);
end;
{$ENDREGION}

end.
