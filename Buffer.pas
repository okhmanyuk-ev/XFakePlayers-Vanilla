unit Buffer;

interface

uses
  Classes,
  SysUtils,
  Default,
  Vector;

type
  TReadLStrMode = (
    rmNullTerminated,
    rmNullTerminatedOrLinebreak,
    rmEnd);

  TWriteLStrMode = (
    wmNullTerminated,
    wmLineBreak,
    wmLineBreakAndNullTerminated);

const
  BitTable: array[0..32] of UInt32 =
            (1 shl 0, 1 shl 1, 1 shl 2, 1 shl 3,
             1 shl 4, 1 shl 5, 1 shl 6, 1 shl 7,
             1 shl 8, 1 shl 9, 1 shl 10, 1 shl 11,
             1 shl 12, 1 shl 13, 1 shl 14, 1 shl 15,
             1 shl 16, 1 shl 17, 1 shl 18, 1 shl 19,
             1 shl 20, 1 shl 21, 1 shl 22, 1 shl 23,
             1 shl 24, 1 shl 25, 1 shl 26, 1 shl 27,
             1 shl 28, 1 shl 29, 1 shl 30, $80000000,
             $00000000);

  RowBitTable: array[0..32] of UInt32 =
               (1 shl 0 - 1, 1 shl 1 - 1, 1 shl 2 - 1, 1 shl 3 - 1,
                1 shl 4 - 1, 1 shl 5 - 1, 1 shl 6 - 1, 1 shl 7 - 1,
                1 shl 8 - 1, 1 shl 9 - 1, 1 shl 10 - 1, 1 shl 11 - 1,
                1 shl 12 - 1, 1 shl 13 - 1, 1 shl 14 - 1, 1 shl 15 - 1,
                1 shl 16 - 1, 1 shl 17 - 1, 1 shl 18 - 1, 1 shl 19 - 1,
                1 shl 20 - 1, 1 shl 21 - 1, 1 shl 22 - 1, 1 shl 23 - 1,
                1 shl 24 - 1, 1 shl 25 - 1, 1 shl 26 - 1, 1 shl 27 - 1,
                1 shl 28 - 1, 1 shl 29 - 1, 1 shl 30 - 1, $80000000 - 1,
                $FFFFFFFF);

  InvBitTable: array[0..32] of Int32 =
               (-(1 shl 0) - 1, -(1 shl 1) - 1, -(1 shl 2) - 1, -(1 shl 3) - 1,
                -(1 shl 4) - 1, -(1 shl 5) - 1, -(1 shl 6) - 1, -(1 shl 7) - 1,
                -(1 shl 8) - 1, -(1 shl 9) - 1, -(1 shl 10) - 1, -(1 shl 11) - 1,
                -(1 shl 12) - 1, -(1 shl 13) - 1, -(1 shl 14) - 1, -(1 shl 15) - 1,
                -(1 shl 16) - 1, -(1 shl 17) - 1, -(1 shl 18) - 1, -(1 shl 19) - 1,
                -(1 shl 20) - 1, -(1 shl 21) - 1, -(1 shl 22) - 1, -(1 shl 23) - 1,
                -(1 shl 24) - 1, -(1 shl 25) - 1, -(1 shl 26) - 1, -(1 shl 27) - 1,
                -(1 shl 28) - 1, -(1 shl 29) - 1, -(1 shl 30) - 1, $80000000 - 1,
                -1);

type
  TBufferEx2 = class(TMemoryStream)
  private
    FOverwriting: Boolean;

    FOnError: TOnTitleData;
    FSavedBuffer: TMemoryStream;
    FSavedBufferPosition: Int64;
    FSavedPosition: array [UInt8] of Int64;
    FSavedPositionIndex: UInt8;

    FBitReading: record
      CurrentSize: UInt32;
      ReadCount: UInt32;
      ByteCount: UInt32;
      BitCount: UInt32;
      Data: Pointer;
      BadRead: Boolean;
    end;

    FBitData: LStr;
    FBitCount,            
    FBitOffset: UInt32;   

  protected
    function GetSpace(ASize: UInt32): Pointer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Start;

    procedure Save;
    procedure Restore;

    procedure SavePosition;
    procedure RestorePosition;
    procedure ResetPositionHistory;

    procedure Skip(ASize: Int32); 
    procedure Delete(ASize: UInt32; DeleteForward: Boolean = True);

    function Read(var ABuffer; ASize: Int32): Int32; override;

    function ReadBool8: Bool8;
    function ReadBool16: Bool16;
    function ReadBool32: Bool32;

    function ReadUInt8: UInt8;
    function ReadUInt16: UInt16;
    function ReadUInt32: UInt32;
    function ReadUInt64: UInt64;

    function ReadInt8: Int8;
    function ReadInt16: Int16;
    function ReadInt32: Int32;
    function ReadInt64: Int64;

    function ReadFloat: Float;

    function ReadLChar: LChar;
    function ReadLStr(AMode: TReadLStrMode = rmNullTerminated): LStr; overload;
    function ReadLStr(ASize: UInt32; CutStr: Boolean = False): LStr; overload;

    function ReadCoord: Float;
    function ReadCoord2: TVec2F;
    function ReadCoord3: TVec3F;

    function ReadVec2F: TVec2F;
    function ReadVec3F: TVec3F;

    function ReadVec3S: TVec3S;

    function ReadAngle: Float;
    function ReadHiResAngle: Float;

    procedure Peek(var ABuffer; ASize: UInt32);

    function PeekUInt8: UInt8;
    function PeekUInt16: UInt16;
    function PeekUInt32: UInt32;
    function PeekUInt64: UInt64;

    function PeekInt8: Int8;
    function PeekInt16: Int16;
    function PeekInt32: Int32;
    function PeekInt64: Int64;

    function PeekFloat: Float;

    function PeekLChar: LChar;
    function PeekLStr(AMode: TReadLStrMode = rmNullTerminated): LStr; overload;
    function PeekLStr(ASize: UInt32): LStr; overload;

    function PeekCoord: Float;
    function PeekCoord2: TVec2F;
    function PeekCoord3: TVec3F;

    function PeekVec2F: TVec2F;
    function PeekVec3F: TVec3F;

    function PeekVec3S: TVec3S;

    function PeekAngle: Float;
    function PeekHiResAngle: Float;

    function Write(const Buffer; Count: Longint): Longint; overload; override;
    procedure Write(AData: LStr); overload;

    procedure WriteBool8(AData: Bool8);
    procedure WriteBool16(AData: Bool16);
    procedure WriteBool32(AData: Bool32);

    procedure WriteUInt8(AData: UInt8);
    procedure WriteUInt16(AData: UInt16);
    procedure WriteUInt32(AData: UInt32);
    procedure WriteUInt64(AData: UInt64);

    procedure WriteInt8(AData: Int8);
    procedure WriteInt16(AData: Int16);
    procedure WriteInt32(AData: Int32);
    procedure WriteInt64(AData: Int64);

    procedure WriteFloat(AData: Float);

    procedure WriteLChar(AData: LChar);
    procedure WriteLStr(AData: LStr; AMode: TWriteLStrMode = wmNullTerminated);

    procedure WriteCoord(AData: Float);
    procedure WriteCoord2(AData: TVec2F);
    procedure WriteCoord3(AData: TVec3F);

    procedure WriteVec2F(AData: TVec2F);
    procedure WriteVec3F(AData: TVec3F);

    procedure WriteVec3S(AData: TVec3S);

    procedure WriteAngle(AData: Float);
    procedure WriteHiResAngle(AData: Float);

    procedure StartBitReading;

    procedure SkipBits(ASize: UInt32);

    function ReadBit: Boolean;
    function ReadUBits(ASize: UInt32): UInt32; overload;
    procedure ReadUBits(var ABuffer; ASize: UInt32); overload;
    function ReadSBits(ASize: UInt32): Int32;
    function ReadBitAngle(ASize: UInt32): Float;
    function ReadBitLStr: LStr; overload;
    function ReadBitLStr(ASize: UInt32): LStr; overload;
    function ReadBitCoord: Float;
    function ReadBitVec3F: TVec3F;

    function PeekUBits(ASize: UInt32): UInt32;

    procedure EndBitReading;

    procedure StartBitWriting;
    procedure WriteBit(AData: Boolean);
    procedure WriteUBits(AData, ASize: UInt32); overload;
    procedure WriteUBits(AData: LStr); overload;
    procedure WriteSBits(AData: Int32; ASize: UInt32);
    procedure WriteBitAngle(AData: Float; ASize: UInt32);
    procedure WriteBitLStr(AData: LStr; AMode: TWriteLStrMode = wmNullTerminated);
    procedure WriteBitCoord(AData: Float);
    procedure WriteBitVec3F(AData: TVec3F);
    procedure EndBitWriting;


    property Overwriting: Boolean read FOverwriting write FOverwriting;
    property OnError: TOnTitleData read FOnError write FOnError;
  end;

implementation

  {$REGION 'General'}
constructor TBufferEx2.Create;
begin
  inherited;

  FSavedBuffer := TMemoryStream.Create;
  FOverwriting := False;
end;

destructor TBufferEx2.Destroy;
begin
  FSavedBuffer.Free;

  inherited;
end;

function TBufferEx2.GetSpace(ASize: UInt32): Pointer;
begin
  Result := Pointer(UInt32(Memory) + Size);
  SetSize(Size + ASize);
end;

procedure TBufferEx2.Start;
begin
  Position := 0;
end;

procedure TBufferEx2.Save;
begin
  FSavedBufferPosition := Position;
  FSavedBuffer.Clear;
  FSavedBuffer.LoadFromStream(Self);
end;

procedure TBufferEx2.Restore;
begin
  Clear;
  LoadFromStream(FSavedBuffer);
  Position := FSavedBufferPosition;
end;

procedure TBufferEx2.SavePosition;
begin
  Inc(FSavedPositionIndex);
  FSavedPosition[FSavedPositionIndex] := Position;
end;

procedure TBufferEx2.RestorePosition;
begin
  Position := FSavedPosition[FSavedPositionIndex];
  Dec(FSavedPositionIndex);
end;

procedure TBufferEx2.ResetPositionHistory;
begin
  FSavedPositionIndex := 0;
end;

procedure TBufferEx2.Skip(ASize: Int32);
begin
  Seek(ASize, soCurrent);
end;

procedure TBufferEx2.Delete(ASize: UInt32; DeleteForward: Boolean = True);
begin
  if DeleteForward then
  begin
    Move(Pointer(UInt32(Memory) + Position + ASize)^, Pointer(UInt32(Memory) + Position)^, Size - ASize);
    SetSize(Size - ASize);
  end
  else
  begin
    Move(Pointer(UInt32(Memory) + Position)^, Pointer(UInt32(Memory) + Position - ASize)^, Size - Position);
    SetSize(Size - ASize);
    Position := Position - ASize;
  end;
end;
  {$ENDREGION}

  {$REGION 'Read'}
function TBufferEx2.Read(var ABuffer; ASize: Int32): Int32;
begin
  Result := inherited;

  if (Result = 0) and Assigned(OnError) then
    OnError(Self, ClassName + '.Read', 'badread');
end;

function TBufferEx2.ReadBool8: Bool8;
begin
  Read(Result, SizeOf(Result));
end;

function TBufferEx2.ReadBool16: Bool16;
begin
  Read(Result, SizeOf(Result));
end;

function TBufferEx2.ReadBool32: Bool32;
begin
  Read(Result, SizeOf(Result));
end;

function TBufferEx2.ReadUInt8: UInt8;
begin
  Read(Result, SizeOf(Result));
end;

function TBufferEx2.ReadUInt16: UInt16;
begin
  Read(Result, SizeOf(Result));
end;

function TBufferEx2.ReadUInt32: UInt32;
begin
  Read(Result, SizeOf(Result));
end;

function TBufferEx2.ReadUInt64: UInt64;
begin
  Read(Result, SizeOf(Result));
end;

function TBufferEx2.ReadInt8: Int8;
begin
  Read(Result, SizeOf(Result));
end;

function TBufferEx2.ReadInt16: Int16;
begin
  Read(Result, SizeOf(Result));
end;

function TBufferEx2.ReadInt32: Int32;
begin
  Read(Result, SizeOf(Result));
end;

function TBufferEx2.ReadInt64: Int64;
begin
  Read(Result, SizeOf(Result));
end;

function TBufferEx2.ReadFloat: Float;
begin
  Read(Result, SizeOf(Result));
end;

function TBufferEx2.ReadLChar;
begin
  Read(Result, SizeOf(Result));
end;

function TBufferEx2.ReadLStr(AMode: TReadLStrMode = rmNullTerminated): LStr;
var
  B: UInt8;
begin
  Default.Clear(Result);

  while Position < Size do
  begin
    B := ReadUInt8;

    case AMode of
      rmNullTerminated:
        if (B = 0) or (B = 255) then
          Break;

      rmNullTerminatedOrLinebreak:
        if (B = 0) or (B = 255) or (B = 10) then
          Break;

      rmEnd: {nothing};
    end;

    Result := Result + LChar(B); 
  end;
end;

function TBufferEx2.ReadLStr(ASize: UInt32; CutStr: Boolean = False): LStr;
var
  I: Int32;
begin
  Default.Clear(Result);

  for I := 0 to ASize - 1 do
    Result := Result + ReadLChar; 

  if CutStr then                  
    Result := ReadString(Result);
end;

function TBufferEx2.ReadCoord: Float;
begin
  Result := ReadInt16 / 8;
end;

function TBufferEx2.ReadCoord2: TVec2F;
begin
  Result.X := ReadCoord;
  Result.Y := ReadCoord;
end;

function TBufferEx2.ReadCoord3: TVec3F;
begin
  Result.X := ReadCoord;
  Result.Y := ReadCoord;
  Result.Z := ReadCoord;
end;

function TBufferEx2.ReadVec2F: TVec2F;
begin
  Read(Result, SizeOf(Result));
end;

function TBufferEx2.ReadVec3F: TVec3F;
begin
  Read(Result, SizeOf(Result));
end;

function TBufferEx2.ReadVec3S: TVec3S;
begin
  Read(Result, SizeOf(Result));
end;

function TBufferEx2.ReadAngle: Float;
begin
  Result := ReadUInt8 * (360 / 256);
end;

function TBufferEx2.ReadHiResAngle: Float;
begin
  Result := ReadInt16 * (360 / 65536);
end;
  {$ENDREGION}

  {$REGION 'Peek'}
procedure TBufferEx2.Peek(var ABuffer; ASize: UInt32);
begin
  SavePosition;
  Read(ABuffer, ASize);
  RestorePosition;
end;

function TBufferEx2.PeekUInt8: UInt8;
begin
  Peek(Result, SizeOf(Result));
end;

function TBufferEx2.PeekUInt16: UInt16;
begin
  Peek(Result, SizeOf(Result));
end;

function TBufferEx2.PeekUInt32: UInt32;
begin
  Peek(Result, SizeOf(Result));
end;

function TBufferEx2.PeekUInt64: UInt64;
begin
  Peek(Result, SizeOf(Result));
end;

function TBufferEx2.PeekInt8: Int8;
begin
  Peek(Result, SizeOf(Result));
end;

function TBufferEx2.PeekInt16: Int16;
begin
  Peek(Result, SizeOf(Result));
end;

function TBufferEx2.PeekInt32: Int32;
begin
  Peek(Result, SizeOf(Result));
end;

function TBufferEx2.PeekInt64: Int64;
begin
  Peek(Result, SizeOf(Result));
end;

function TBufferEx2.PeekFloat: Float;
begin
  Peek(Result, SizeOf(Result));
end;

function TBufferEx2.PeekLChar;
begin
  Peek(Result, SizeOf(Result));
end;

function TBufferEx2.PeekLStr(AMode: TReadLStrMode = rmNullTerminated): LStr;
begin
  SavePosition;
  Result := ReadLStr(AMode);
  RestorePosition;
end;

function TBufferEx2.PeekLStr(ASize: UInt32): LStr;
begin
  SavePosition;
  Result := ReadLStr(ASize);
  RestorePosition;
end;

function TBufferEx2.PeekCoord: Float;
begin
  SavePosition;
  Result := ReadCoord;
  RestorePosition;
end;

function TBufferEx2.PeekCoord2: TVec2F;
begin
  SavePosition;
  Result := ReadCoord2;
  RestorePosition;
end;

function TBufferEx2.PeekCoord3: TVec3F;
begin
  SavePosition;
  Result := ReadCoord3;
  RestorePosition;
end;

function TBufferEx2.PeekVec2F: TVec2F;
begin
  Peek(Result, SizeOf(Result));
end;

function TBufferEx2.PeekVec3F: TVec3F;
begin
  Peek(Result, SizeOf(Result));
end;

function TBufferEx2.PeekVec3S: TVec3S;
begin
  Peek(Result, SizeOf(Result));
end;

function TBufferEx2.PeekAngle: Float;
begin
  SavePosition;
  Result := ReadAngle;
  RestorePosition;
end;

function TBufferEx2.PeekHiResAngle: Float;
begin
  SavePosition;
  Result := ReadHiResAngle;
  RestorePosition;
end;
  {$ENDREGION}

  {$REGION 'Write'}
function TBufferEx2.Write(const Buffer; Count: Longint): Longint;
begin
  if not Overwriting and (Position < Size) then
  begin
    SetSize(Size + Count);
    Move(Pointer(UInt32(Memory) + Position)^, Pointer(UInt32(Memory) + Position + Count)^, Size - Count);
  end;

  inherited;
end;

procedure TBufferEx2.Write(AData: LStr);
var
  C: LChar;
begin
  for C in AData do
    WriteLChar(C);
end;

procedure TBufferEx2.WriteBool8(AData: Bool8);
begin
  Write(AData, SizeOf(AData));
end;

procedure TBufferEx2.WriteBool16(AData: Bool16);
begin
  Write(AData, SizeOf(AData));
end;

procedure TBufferEx2.WriteBool32(AData: Bool32);
begin
  Write(AData, SizeOf(AData));
end;

procedure TBufferEx2.WriteUInt8(AData: UInt8);
begin
  Write(AData, SizeOf(AData));
end;

procedure TBufferEx2.WriteUInt16(AData: UInt16);
begin
  Write(AData, SizeOf(AData));
end;

procedure TBufferEx2.WriteUInt32(AData: UInt32);
begin
  Write(AData, SizeOf(AData));
end;

procedure TBufferEx2.WriteUInt64(AData: UInt64);
begin
  Write(AData, SizeOf(AData));
end;

procedure TBufferEx2.WriteInt8(AData: Int8);
begin
  Write(AData, SizeOf(AData));
end;

procedure TBufferEx2.WriteInt16(AData: Int16);
begin
  Write(AData, SizeOf(AData));
end;

procedure TBufferEx2.WriteInt32(AData: Int32);
begin
  Write(AData, SizeOf(AData));
end;

procedure TBufferEx2.WriteInt64(AData: Int64);
begin
  Write(AData, SizeOf(AData));
end;

procedure TBufferEx2.WriteFloat(AData: Float);
begin
  Write(AData, SizeOf(AData));
end;

procedure TBufferEx2.WriteLChar(AData: LChar);
begin
  Write(AData, SizeOf(AData));
end;

procedure TBufferEx2.WriteLStr(AData: LStr; AMode: TWriteLStrMode = wmNullTerminated);
begin
  Write(AData);

  case AMode of
    wmNullTerminated: WriteUInt8(0);
    wmLineBreak: WriteUInt8(10);
    wmLineBreakAndNullTerminated:
    begin
      WriteUInt8(10);
      WriteUInt8(0);
    end;
  end;
end;

procedure TBufferEx2.WriteCoord(AData: Float);
begin
  WriteInt16(Trunc(AData * 8));
end;

procedure TBufferEx2.WriteCoord2(AData: TVec2F);
begin
  WriteCoord(AData.X);
  WriteCoord(AData.Y);
end;

procedure TBufferEx2.WriteCoord3(AData: TVec3F);
begin
  WriteCoord(AData.X);
  WriteCoord(AData.Y);
  WriteCoord(AData.Z);
end;

procedure TBufferEx2.WriteVec2F(AData: TVec2F);
begin
  Write(AData, SizeOf(AData));
end;

procedure TBufferEx2.WriteVec3F(AData: TVec3F);
begin
  Write(AData, SizeOf(AData));
end;

procedure TBufferEx2.WriteVec3S(AData: TVec3S);
begin
  Write(AData, SizeOf(AData));
end;

procedure TBufferEx2.WriteAngle(AData: Float);
begin
  WriteUInt8(Trunc(AData * 256 / 360));
end;

procedure TBufferEx2.WriteHiResAngle(AData: Float);
begin
  WriteInt16(Trunc(AData * 65536 / 360));
end;
  {$ENDREGION}

  {$REGION 'bit reading'}
procedure TBufferEx2.StartBitReading;
begin
  with FBitReading do
  begin
    CurrentSize := Position + 1;
    ReadCount := Position;
    ByteCount := 0;
    BitCount := 0;
    Data := Pointer(UInt32(Memory) + Position);
    BadRead := CurrentSize > Size;
  end;
end;

procedure TBufferEx2.SkipBits(ASize: UInt32);
begin
  ReadUBits(ASize); 
end;

function TBufferEx2.ReadBit: Boolean;
begin
  with FBitReading do
    if BadRead then
      Result := True
    else
    begin
      if BitCount > 7 then
      begin
        Inc(CurrentSize);
        Inc(ByteCount);
        Inc(UInt32(Data));
        BitCount := 0;
      end;

      if CurrentSize > Size then
      begin
        BadRead := True;
        Result := True;
      end
      else
      begin
        Result := BitTable[BitCount] and PUInt8(Data)^ <> 0;
        Inc(BitCount);
      end;
    end;
end;

function TBufferEx2.ReadUBits(ASize: UInt32): UInt32;
var
  CBit, CByte: UInt32;
  B: UInt32;
begin
  with FBitReading do
    if BadRead then
      Result := 1
    else
    begin
      if BitCount > 7 then
      begin
        Inc(CurrentSize);
        Inc(ByteCount);
        Inc(UInt32(Data));
        BitCount := 0;
      end;

      CBit := BitCount + ASize;

      if CBit <= 32 then
      begin
        Result := RowBitTable[ASize] and (PUInt32(Data)^ shr BitCount);

        if (CBit and 7) > 0 then
        begin
          BitCount := CBit and 7;
          CByte := CBit shr 3;
        end
        else
        begin
          BitCount := 8;
          CByte := (CBit shr 3) - 1;
        end;

        Inc(CurrentSize, CByte);
        Inc(ByteCount, CByte);
        Inc(UInt32(Data), CByte);
      end
      else
      begin
        B := PUInt32(Data)^ shr BitCount;
        Inc(UInt32(Data), 4);
        Result := ((RowBitTable[CBit and 7] and PUInt32(Data)^) shl (32 - BitCount)) or B;

        Inc(CurrentSize, 4);
        Inc(ByteCount, 4);
        BitCount := CBit and 7;
      end;

      if CurrentSize > Size then
      begin
        BadRead := True;
        Result := 1;
      end;
    end;
end;

procedure TBufferEx2.ReadUBits(var ABuffer; ASize: UInt32);
begin
  Move(ReadBitLStr(ASize)[1], ABuffer, ASize); 
end;

function TBufferEx2.ReadSBits(ASize: UInt32): Int32;
var
  B: Boolean;
begin
  if ASize = 0 then
    Error(['Invalid bit count.']);

  B := ReadBit;

  Result := ReadUBits(ASize - 1);

  if B then
    Result := -Result;
end;

function TBufferEx2.ReadBitAngle(ASize: UInt32): Float;
var
  X: UInt32;
begin
  X := 1 shl ASize;

  if X > 0 then
    Result := ReadUBits(ASize) * 360 / X
  else
  begin
    ReadUBits(ASize);
    Result := 0;
  end;
end;

function TBufferEx2.ReadBitLStr: LStr;
var
  I: Int32;
  B: UInt32;
begin
  Default.Clear(Result);

  for I := 1 to 8192 do
  begin
    B := ReadUBits(8);

    if B = 0 then
      Break;

    Result := Result + LChar(B);
  end;
end;

function TBufferEx2.ReadBitLStr(ASize: UInt32): LStr;
var
  I: Int32;
begin
  Default.Clear(Result);

  for I := 0 to ASize - 1 do
    Result := Result + LChar(ReadUBits(8));
end;

function TBufferEx2.ReadBitCoord: Float;
var
  IntData, FracData: Int32;
  SignBit: Boolean;
begin
  IntData := ReadUBits(1);
  FracData := ReadUBits(1);

  if (IntData <> 0) or (FracData <> 0) then
  begin
    SignBit := ReadBit;

    if IntData <> 0 then
      IntData := ReadUBits(12);

    if FracData <> 0 then
      FracData := ReadUBits(3);

    Result := FracData * 0.125 + IntData;

    if SignBit then
      Result := -Result;
  end
  else
    Result := 0;
end;

function TBufferEx2.ReadBitVec3F: TVec3F;
var
  X, Y, Z: Boolean;
begin
  X := ReadBit;
  Y := ReadBit;
  Z := ReadBit;

  if X then
    Result.X := ReadBitCoord
  else
    Result.X := 0;

  if Y then
    Result.Y := ReadBitCoord
  else
    Result.Y := 0;

  if Z then
    Result.Z := ReadBitCoord
  else
    Result.Z := 0;
end;

function TBufferEx2.PeekUBits(ASize: UInt32): UInt32;
var
  Data: array[1..SizeOf(FBitReading)] of UInt8;
begin
  Move(FBitReading, Data, SizeOf(Data));
  Result := ReadUBits(ASize);
  Move(Data, FBitReading, SizeOf(Data));
end;

procedure TBufferEx2.EndBitReading;
begin
  Position := FBitReading.CurrentSize;
  FBitReading.ReadCount := 0;
  FBitReading.ByteCount := 0;
  FBitReading.BitCount := 0;
  FBitReading.Data := nil;
end;
  {$ENDREGION}

  {$REGION 'bit writing'}
{procedure TBufferEx2.StartBitWriting;
begin
  with FBitWriting do
  begin
    Count := 0;
    Data := Pointer(UInt32(Memory) + Size);
  end;
end;}

procedure TBufferEx2.StartBitWriting;
begin
  SetLength(FBitData, 4);
end;


{procedure TBufferEx2.WriteBit(AData: Boolean);
begin
  with FBitWriting do
  begin
    if Count >= 8 then
    begin
      GetSpace(1);
      Count := 0;
      Inc(UInt32(Data));
    end;

    if not AData then
      PUInt8(Data)^ := PUInt8(Data)^ and InvBitTable[Count]
    else
      PUInt8(Data)^ := PUInt8(Data)^ or BitTable[Count];

    Inc(Count);
  end;
end;}

procedure TBufferEx2.WriteBit(AData: Boolean);
begin
  WriteUBits(UInt32(AData), 1);
end;

{procedure TBufferEx2.WriteUBits(AData, ASize: UInt32);
var
  BitMask: UInt32;
  BitCount, ByteCount, BitsLeft: UInt32;
  NextRow: Boolean;
begin
  if (ASize <= 31) and (AData >= 1 shl ASize) then
    BitMask := RowBitTable[ASize]
  else
    BitMask := AData;

  with FBitWriting do
  begin
    if Count > 7 then
    begin
      NextRow := True;
      Count := 0;
      Inc(UInt32(Data));
    end
    else
      NextRow := False;

    BitCount := ASize + Count;

    if BitCount <= 32 then
    begin
      ByteCount := BitCount shr 3;
      BitCount := BitCount and 7;

      if BitCount = 0 then
        Dec(ByteCount);

      GetSpace(ByteCount + UInt32(NextRow));

      PUInt32(Data)^ := (PUInt32(Data)^ and RowBitTable[Count]) or (BitMask shl Count);

      if BitCount > 0 then
        Count := BitCount
      else
        Count := 8;

      Inc(UInt32(Data), ByteCount);
    end
    else
    begin
      GetSpace(UInt32(NextRow) + 4);
      PUInt32(Data)^ := (PUInt32(Data)^ and RowBitTable[Count]) or (BitMask shl Count);

      BitsLeft := 32 - Count;
      Count := BitCount and 7;
      Inc(UInt32(Data), 4);

      PUInt32(Data)^ := BitMask shr BitsLeft;
    end;
  end;
end;}

procedure TBufferEx2.WriteUBits(AData, ASize: UInt32);
var
  C,
  BitMask,
  BitsLeft,
  BitCount,
  ByteCount: UInt32;
begin
  if (ASize <= 31) and (AData >= UInt32(1 shl ASize)) then
    BitMask := RowBitTable[ASize]
  else
    BitMask := AData;

  if FBitCount > 7 then
  begin
    SetLength(FBitData, Length(FBitData) + 1);
    FBitCount := 0;
    Inc(FBitOffset);
  end;

  C := ASize + FBitCount;

  ByteCount := C div 8;
  BitCount := C and 7; 

  if BitCount = 0 then
    Dec(ByteCount);

  if ByteCount > 0 then
    SetLength(FBitData, Length(FBitData) + ByteCount);

  PUInt32(UInt32(FBitData) + FBitOffset)^ := (PUInt32(UInt32(FBitData) + FBitOffset)^
    and RowBitTable[FBitCount]) or (BitMask shl FBitCount);

  Inc(FBitOffset, ByteCount);

  if C <= 32 then
    if BitCount > 0 then
      FBitCount := BitCount
    else
      FBitCount := 8
  else
  begin
    BitsLeft := 32 - FBitCount;
    FBitCount := BitCount;
    PUInt32(UInt32(FBitData) + FBitOffset)^ := BitMask shr BitsLeft;
  end;
end;

procedure TBufferEx2.WriteUBits(AData: LStr);
var
  C: LChar;
begin
  for C in AData do
    WriteUBits(UInt8(C), 8);
end;

procedure TBufferEx2.WriteSBits(AData: Int32; ASize: UInt32);
var
  I: Int32;
begin
  if ASize < 32 then
  begin
    I := (1 shl (ASize - 1)) - 1;

    if AData > I then
      AData := I
    else
      if AData < -I then
        AData := -I;
  end;

  WriteBit(AData < 0);
  WriteUBits(Abs(AData), ASize - 1);
end;

procedure TBufferEx2.WriteBitAngle(AData: Float; ASize: UInt32);
var
  B: UInt32;
begin
  if ASize >= 32 then
    Error(['Can''t write bit angle with 32 bits precision.']);

  B := 1 shl ASize;
  WriteUBits((B - 1) and (Trunc(B * AData) div 360), ASize);
end;

procedure TBufferEx2.WriteBitLStr(AData: LStr; AMode: TWriteLStrMode = wmNullTerminated);
begin
  WriteUBits(AData);

  case AMode of
    wmNullTerminated: WriteUBits(0, 8);
    wmLineBreak: WriteUBits(10, 8);
    wmLineBreakAndNullTerminated:
    begin
      WriteUBits(10, 8);
      WriteUBits(0, 8);
    end;
  end;
end;

procedure TBufferEx2.WriteBitCoord(AData: Float);
var
  I, IntData, FracData: Int32;
begin
  I := Trunc(AData);
  IntData := Abs(I);
  FracData := Abs(8 * I) and 7;

  WriteBit(IntData <> 0);
  WriteBit(FracData <> 0);

  if (IntData <> 0) or (FracData <> 0) then
  begin
    WriteBit(AData <= -0.125);

    if IntData <> 0 then
      WriteUBits(IntData, 12);

    if FracData <> 0 then
      WriteUBits(FracData, 3);
  end;
end;

procedure TBufferEx2.WriteBitVec3F(AData: TVec3F);
var
  X, Y, Z: Boolean;
begin
  X := (AData.X >= 0.125) or (AData.X <= -0.125);
  Y := (AData.Y >= 0.125) or (AData.Y <= -0.125);
  Z := (AData.Z >= 0.125) or (AData.Z <= -0.125);

  WriteBit(X);
  WriteBit(Y);
  WriteBit(Z);

  if X then
    WriteBitCoord(AData.X);

  if Y then
    WriteBitCoord(AData.Y);

  if Z then
    WriteBitCoord(AData.Z);
end;

{procedure TBufferEx2.EndBitWriting;
begin
  with FBitWriting do
  begin
    PUInt8(Data)^ := PByte(Data)^ and (255 shr (8 - Count));
    GetSpace(1);

    Count := 0;
    Data := nil;
  end;
end;}

procedure TBufferEx2.EndBitWriting;
begin
  PByte(UInt32(FBitData) + FBitOffset)^ := PByte(UInt32(FBitData) + FBitOffset)^
    and (255 shr (8 - FBitCount));

  Write(Copy(FBitData, 0, FBitOffset + 1));

  FBitData := '';
  FBitCount := 0;
  FBitOffset := 0;
end;
  {$ENDREGION}
end.