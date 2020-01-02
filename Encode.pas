unit Encode;

interface

uses
  Default;

type
  TMungifyTable = array[0..15] of UInt8;

{type
  TMungifyTable = array[0..15] of UInt32;}

const
  MungifyTable1: TMungifyTable = ($7A, $64, $05, $F1, $1B, $9B, $A0, $B5, $CA, $ED, $61, $0D, $4A, $DF, $8E, $C7);
  MungifyTable2: TMungifyTable = ($05, $61, $7A, $ED, $1B, $CA, $0D, $9B, $4A, $F1, $64, $C7, $B5, $8E, $DF, $A0);
  MungifyTable3: TMungifyTable = ($20, $07, $13, $61, $03, $45, $17, $72, $0A, $2D, $48, $0C, $4A, $12, $A9, $B5);

{const
  MungifyTable1: TMungifyTable = ($FFAFE7FF, $BFFFA7E5, $BFBFF7A5, $BFBFBFF5,
                                  $BFAFBFBF, $FFBFA7BF, $FFEFB7A5, $FFEFEFB5,
                                  $BFEFEFEF, $FFAFE7ED, $FFEFAFE5, $BFFFEFAD,
                                  $FFAFFFEF, $FFEFAFFF, $FFFFE7AF, $BFEFFFE7);

  MungifyTable2: TMungifyTable = ($FFFFE7A5, $BFEFFFE5, $FFBFEFFF, $BFEFBFED,
                                  $BFAFEFBF, $FFBFAFEF, $FFEFBFAD, $FFFFEFBF,
                                  $FFEFF7EF, $BFEFE7F5, $BFBFE7E5, $FFAFB7E7,
                                  $BFFFAFB5, $BFAFFFAF, $FFAFA7FF, $FFEFA7A5);

  MungifyTable3: TMungifyTable = ($FFBFA7A5, $BFEFB7A7, $FFAFE7B7, $BFEFA7E5,
                                  $FFBFE7A7, $BFFFB7E5, $BFAFF7B7, $FFAFAFF7,
                                  $BFEFAFAF, $FFAFEFAD, $BFEFAFED, $BFBFEFAD,
                                  $BFAFB7EF, $BFBFAFB7, $BFAFB7AD, $BFAFA7B5);}


//procedure Munge(Buffer: Pointer; Length, Sequence: Int32; const MungifyTable: TMungifyTable); stdcall;
//procedure UnMunge(Buffer: Pointer; Length, Sequence: Int32; const MungifyTable: TMungifyTable); stdcall;

procedure Munge(Buffer: Pointer; Length: UInt; Sequence: Int32; const MungifyTable: TMungifyTable);
procedure UnMunge(Buffer: Pointer; Length: UInt; Sequence: Int32; const MungifyTable: TMungifyTable);

type
  TCRC = UInt32;

const
  CRCTable: array[UInt8] of UInt32 =
           ($00000000, $77073096, $EE0E612C, $990951BA, $076DC419, $706AF48F, $E963A535, $9E6495A3,
            $0EDB8832, $79DCB8A4, $E0D5E91E, $97D2D988, $09B64C2B, $7EB17CBD, $E7B82D07, $90BF1D91,
            $1DB71064, $6AB020F2, $F3B97148, $84BE41DE, $1ADAD47D, $6DDDE4EB, $F4D4B551, $83D385C7,
            $136C9856, $646BA8C0, $FD62F97A, $8A65C9EC, $14015C4F, $63066CD9, $FA0F3D63, $8D080DF5,
            $3B6E20C8, $4C69105E, $D56041E4, $A2677172, $3C03E4D1, $4B04D447, $D20D85FD, $A50AB56B,
            $35B5A8FA, $42B2986C, $DBBBC9D6, $ACBCF940, $32D86CE3, $45DF5C75, $DCD60DCF, $ABD13D59,
            $26D930AC, $51DE003A, $C8D75180, $BFD06116, $21B4F4B5, $56B3C423, $CFBA9599, $B8BDA50F,
            $2802B89E, $5F058808, $C60CD9B2, $B10BE924, $2F6F7C87, $58684C11, $C1611DAB, $B6662D3D,
            $76DC4190, $01DB7106, $98D220BC, $EFD5102A, $71B18589, $06B6B51F, $9FBFE4A5, $E8B8D433,
            $7807C9A2, $0F00F934, $9609A88E, $E10E9818, $7F6A0DBB, $086D3D2D, $91646C97, $E6635C01,
            $6B6B51F4, $1C6C6162, $856530D8, $F262004E, $6C0695ED, $1B01A57B, $8208F4C1, $F50FC457,
            $65B0D9C6, $12B7E950, $8BBEB8EA, $FCB9887C, $62DD1DDF, $15DA2D49, $8CD37CF3, $FBD44C65,
            $4DB26158, $3AB551CE, $A3BC0074, $D4BB30E2, $4ADFA541, $3DD895D7, $A4D1C46D, $D3D6F4FB,
            $4369E96A, $346ED9FC, $AD678846, $DA60B8D0, $44042D73, $33031DE5, $AA0A4C5F, $DD0D7CC9,
            $5005713C, $270241AA, $BE0B1010, $C90C2086, $5768B525, $206F85B3, $B966D409, $CE61E49F,
            $5EDEF90E, $29D9C998, $B0D09822, $C7D7A8B4, $59B33D17, $2EB40D81, $B7BD5C3B, $C0BA6CAD,
            $EDB88320, $9ABFB3B6, $03B6E20C, $74B1D29A, $EAD54739, $9DD277AF, $04DB2615, $73DC1683,
            $E3630B12, $94643B84, $0D6D6A3E, $7A6A5AA8, $E40ECF0B, $9309FF9D, $0A00AE27, $7D079EB1,
            $F00F9344, $8708A3D2, $1E01F268, $6906C2FE, $F762575D, $806567CB, $196C3671, $6E6B06E7,
            $FED41B76, $89D32BE0, $10DA7A5A, $67DD4ACC, $F9B9DF6F, $8EBEEFF9, $17B7BE43, $60B08ED5,
            $D6D6A3E8, $A1D1937E, $38D8C2C4, $4FDFF252, $D1BB67F1, $A6BC5767, $3FB506DD, $48B2364B,
            $D80D2BDA, $AF0A1B4C, $36034AF6, $41047A60, $DF60EFC3, $A867DF55, $316E8EEF, $4669BE79,
            $CB61B38C, $BC66831A, $256FD2A0, $5268E236, $CC0C7795, $BB0B4703, $220216B9, $5505262F,
            $C5BA3BBE, $B2BD0B28, $2BB45A92, $5CB36A04, $C2D7FFA7, $B5D0CF31, $2CD99E8B, $5BDEAE1D,
            $9B64C2B0, $EC63F226, $756AA39C, $026D930A, $9C0906A9, $EB0E363F, $72076785, $05005713,
            $95BF4A82, $E2B87A14, $7BB12BAE, $0CB61B38, $92D28E9B, $E5D5BE0D, $7CDCEFB7, $0BDBDF21,
            $86D3D2D4, $F1D4E242, $68DDB3F8, $1FDA836E, $81BE16CD, $F6B9265B, $6FB077E1, $18B74777,
            $88085AE6, $FF0F6A70, $66063BCA, $11010B5C, $8F659EFF, $F862AE69, $616BFFD3, $166CCF45,
            $A00AE278, $D70DD2EE, $4E048354, $3903B3C2, $A7672661, $D06016F7, $4969474D, $3E6E77DB,
            $AED16A4A, $D9D65ADC, $40DF0B66, $37D83BF0, $A9BCAE53, $DEBB9EC5, $47B2CF7F, $30B5FFE9,
            $BDBDF21C, $CABAC28A, $53B39330, $24B4A3A6, $BAD03605, $CDD70693, $54DE5729, $23D967BF,
            $B3667A2E, $C4614AB8, $5D681B02, $2A6F2B94, $B40BBE37, $C30C8EA1, $5A05DF1B, $2D02EF8D);

procedure CRC32_Init(out CRC: TCRC);
function CRC32_Final(CRC: TCRC): TCRC;
procedure CRC32_ProcessBuffer(var CRC: TCRC; Buffer: Pointer; Size: UInt32);
function BlockSequenceCRCByte(Input: Pointer; Size: UInt32; Sequence: UInt32): TCRC;

implementation

procedure Munge(Buffer: Pointer; Length: UInt; Sequence: Int32; const MungifyTable: TMungifyTable);
type
  T = array[0..3] of Byte;
var
  I, K: UInt;
  P: PInt32;
  C: Int32;
begin
  Length := (Length and not 3) shr 2;

  if Length = 0 then
    Exit;

  for I := 0 to Length - 1 do
  begin
    P := Pointer(UInt(Buffer) + (I shl 2));
    C := Swap32(P^ xor not Sequence);

    for K := Low(T) to High(T) do
      T(C)[K] := T(C)[K] xor ($A5 or (K shl K) or K or MungifyTable[(I + K) and High(MungifyTable)]);

    C := C xor Sequence;
    P^ := C;
  end;
end;

procedure UnMunge(Buffer: Pointer; Length: UInt; Sequence: Int32; const MungifyTable: TMungifyTable);
type
  T = array[0..3] of Byte;
var
  I, K: UInt;
  P: PInt32;
  C: Int32;
begin
  Length := (Length and not 3) shr 2;

  if Length = 0 then
    Exit;

  for I := 0 to Length - 1 do
  begin
    P := Pointer(UInt(Buffer) + (I shl 2));
    C := P^ xor Sequence;

    for K := Low(T) to High(T) do
      T(C)[K] := T(C)[K] xor ($A5 or (K shl K) or K or MungifyTable[(I + K) and High(MungifyTable)]);

    C := Swap32(C) xor not Sequence;
    P^ := C;
  end;
end;
                               // optimized by kohtep
{procedure Munge(Buffer: Pointer; Length, Sequence: Int32; const MungifyTable: TMungifyTable); stdcall;
asm
  push ebx
  push esi
  mov ebx, [Sequence]
  mov esi, [Buffer]
  mov edx, [MungifyTable]
  xor eax, eax
  not ebx
  shr [Length], 2
  jz @Exit

  @Encode:
  and al, $3F
  mov ecx, [esi]
  xor ecx, [Sequence]
  bswap ecx
  xor ecx, [edx + eax]
  xor ecx, ebx
  add al, 4
  mov [esi], ecx
  add esi, 4
  dec [Length]
  jnz @Encode

  @Exit:
  pop esi
  pop ebx
end;

procedure UnMunge(Buffer: Pointer; Length, Sequence: Int32; const MungifyTable: TMungifyTable); stdcall;
asm
  push ebx
  push esi

  mov ebx, [Sequence]
  mov esi, [Buffer]
  mov edx, [MungifyTable]
  xor eax, eax
  not ebx
  shr [Length], 2
  jz @Exit

  @Encode:
  and al, $3F
  mov ecx, [esi]
  xor ecx, [Sequence]
  xor ecx, [edx + eax]
  bswap ecx
  xor ecx, ebx
  add al, 4
  mov [esi], ecx
  add esi, 4
  dec [Length]
  jnz @Encode

  @Exit:
  pop esi
  pop ebx
end;
}
procedure CRC32_Init(out CRC: TCRC);
begin
  CRC := $FFFFFFFF;
end;

function CRC32_Final(CRC: TCRC): TCRC;
begin
  Result := not CRC;
end;

procedure CRC32_ProcessBuffer(var CRC: TCRC; Buffer: Pointer; Size: UInt32);
var
  I, FB: UInt32;
  C: TCRC;
begin
  C := CRC;

  while Size >= 8 do
  begin
    FB := UInt32(Buffer) and 3;
    Dec(Size, FB);
    for I := 1 to FB do
    begin
      C := CRCTable[Byte(PByte(Buffer)^ xor C)] xor (C shr 8);
      Inc(UInt32(Buffer));
    end;

    for I := 1 to Size shr 3 do
    begin
      C := C xor PUInt32(Buffer)^;
      C := CRCTable[Byte(C)] xor (C shr 8);
      C := CRCTable[Byte(C)] xor (C shr 8);
      C := CRCTable[Byte(C)] xor (C shr 8);
      C := CRCTable[Byte(C)] xor (C shr 8);

      C := C xor PUInt32(UInt32(Buffer) + SizeOf(UInt32))^;
      C := CRCTable[Byte(C)] xor (C shr 8);
      C := CRCTable[Byte(C)] xor (C shr 8);
      C := CRCTable[Byte(C)] xor (C shr 8);
      C := CRCTable[Byte(C)] xor (C shr 8);

      Inc(UInt32(Buffer), 8);
    end;
    Size := Size and 7;
  end;

  for I := 1 to Size do
  begin
    C := CRCTable[Byte(PByte(Buffer)^ xor C)] xor (C shr 8);
    Inc(UInt32(Buffer));
  end;

  CRC := C;
end;

function BlockSequenceCRCByte(Input: Pointer; Size: UInt32; Sequence: UInt32): TCRC;
type
  UInt8Array = packed array[0..0] of UInt8;
  PUInt8Array = ^UInt8Array;
var
  E: PUInt8Array;
  Buf: array[0..60 + 4 - 1] of Byte;
  K: array[0..3] of Byte;
  I: TCRC;
begin
  E := @PUInt8Array(@CRCTable)[Sequence mod 1020];

  if Size > 60 then
    Size := 60;

  Move(Input^, Buf, Size);
  PUInt32(@K)^ := PLongWord(E)^;
  Buf[Size + 0] := K[0];
  Buf[Size + 1] := K[1];
  Buf[Size + 2] := K[2];
  Buf[Size + 3] := K[3];
  Inc(Size, 4);

  I := Sequence;
  CRC32_Init(I);
  CRC32_ProcessBuffer(I, @Buf, Size);
  Result := CRC32_Final(I);
end;

end.