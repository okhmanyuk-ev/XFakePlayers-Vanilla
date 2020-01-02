unit Emulator;

// {$DEFINE NativeRandom}

interface

uses
  Windows,
  SysUtils,
  Buffer,
  Rijndael,
  SHA,
  Default;

const
  EMU_REVEMU2013 = 11;
  EMU_SC2009 = 21;

  EMU_REVEMU = 1;
  EMU_AVSMP = 2;
  EMU_STEAMEMU = 3;
  EMU_OLDREVEMU = 4;
  EMU_CUSTOM = 7;

function Emu_Generate(AEmulatorType: UInt8; SteamID: Int32 = 0; Prefix: Boolean = False): TArray<UInt8>;

implementation

function RandomInt32: Int32; register;
begin
 Result := Random(MaxInt32);
end;

function AllocZeroMem(Size: LongInt): Pointer;
begin
 Result := SysGetMem(Size);
 FillChar(Result^, Size, 0);
end;

function AllocPCharStr(Size: LongInt): PChar;
begin
 Result := AllocZeroMem(Size + 1);
 FillChar(Result^, Size, $CC);
end;

function RandomNumber(Max: Int32): LongInt;
begin
 Result := Random(Max);
end;

function GetRandomPChar(Size: UInt32; IncludeNumbers: Boolean = False): PLChar;
asm
 push ebx // IncludeNumbers
 push edi // AllocStr
 push esi // Size

 mov esi, eax
 xor ebx, ebx
 mov bl, dl

 inc eax
 call AllocPCharStr
 mov edi, eax

 add bl, 2
@Loop:
  mov eax, ebx
  call RandomNumber

  dec al
  js @Result0
  jz @Result1
   mov al, 10
   call RandomNumber
   add al, '0'
  jmp @Finish

@Result0:
  mov al, 26
  call RandomNumber
  add al, 'a'
  jmp @Finish

@Result1:
 mov al, 26
 call RandomNumber
 add al, 'A'

@Finish:
  mov byte ptr [edi], al

  inc edi
  cmp byte ptr [edi], 0
 jne @Loop

 xchg eax, edi
 sub eax, esi

 pop esi
 pop edi
 pop ebx
end;

function RevHash(const S: PLChar): LongInt; // so based
asm
  DD $BA08BE0F, $4E67C6A7, $1D74C985, $89574056, $05E6C1D6
  DD $CE01D789, $C108BE0F, $F70102EF, $8540FA31, $5FE875C9
  DW $895E
  DB $D0
end;

function Emu_Generate_AVSMP(SteamID: Int32 = 0; Prefix: Boolean = False): TArray<UInt8>;
asm
 push esi
 push edi
 push ebx

 push ecx

 mov esi, eax
 mov bl, dl

 mov eax, 36
 call AllocZeroMem
 mov edi, eax

 mov byte ptr [edi], 1
 mov byte ptr [edi+4], 28

 add edi, 8
 mov byte ptr [edi], 14h
 {$IFDEF NativeRandom}
  call RandomInt32
 {$ELSE}
  rdtsc
 {$ENDIF}
 mov dword ptr [edi+4], eax
 {$IFDEF NativeRandom}
  call RandomInt32
 {$ELSE}
  rdtsc
 {$ENDIF}
 mov dword ptr [edi+8], eax

 test esi, esi
 jnz @A1
 {$IFDEF NativeRandom}
  call RandomInt32
 {$ELSE}
  rdtsc
 {$ENDIF}
  jmp @A2
@A1:
  mov eax, esi
@A2:
 shl eax, 1
 or al, bl
 mov dword ptr [edi+12], eax

 mov dword ptr [edi+16], 01100001h
 {$IFDEF NativeRandom}
  call RandomInt32
 {$ELSE}
  rdtsc
 {$ENDIF}
 mov dword ptr [edi+20], eax
 xor eax, eax
 mov dword ptr [edi+24], eax

 xchg eax, edi

 pop ecx
 mov dword ptr [ecx], eax

 pop ebx
 pop edi
 pop esi
end;

function Emu_Generate_SteamEmu(SteamID: Int32 = 0): TArray<UInt8>;
asm
 push esi
 push edi

 push edx

 mov esi, eax

 xor eax, eax
 mov ax, 768
 call AllocZeroMem
 mov edi, eax

 mov byte ptr [edi], 1
 mov word ptr [edi+4], 768
 add edi, 8

 xor ecx, ecx
 mov cl, 20
@Loop1:
  {$IFDEF NativeRandom}
   call RandomInt32
  {$ELSE}
   rdtsc
  {$ENDIF}
  mov dword ptr [edi], eax
  add edi, type LongWord

  dec ecx
 jnz @Loop1

 mov dword ptr [edi], -1

 test esi, esi
 jnz @A1
 {$IFDEF NativeRandom}
  call RandomInt32
 {$ELSE}
  rdtsc
 {$ENDIF}
  jmp @A2
@A1:
  mov eax, esi
@A2:
 mov dword ptr [edi+4], eax

 add edi, 8

 xor ecx, ecx
 mov cl, 170

@Loop2:
  {$IFDEF NativeRandom}
   call RandomInt32
  {$ELSE}
   rdtsc
  {$ENDIF}
  mov dword ptr [edi], eax
  add edi, type LongWord

  dec ecx
 jnz @Loop2

 xchg eax, edi
 sub eax, 768

 pop edx
 mov dword ptr [edx], eax

 pop edi
 pop esi
end;

function Emu_Generate_OldRevEmu(SteamID: Int32 = 0): TArray<UInt8>;
asm
 push esi // SID
 push edi // EmuArray

 push edx

 mov esi, eax

 xor eax, eax
 mov al, 24
 call AllocZeroMem
 mov edi, eax

 mov byte ptr [edi], 1
 mov byte ptr [edi+4], 10
 add edi, 8

 mov word ptr [edi], -1
 {$IFDEF NativeRandom}
  call RandomInt32
 {$ELSE}
  rdtsc
 {$ENDIF}

 mov word ptr [edi+2], ax

 test esi, esi
 jnz @A1
 {$IFDEF NativeRandom}
  call RandomInt32
 {$ELSE}
  rdtsc
 {$ENDIF}
  jmp @A2
@A1:
  mov eax, esi
@A2:
 xor eax, 0C9710266h
 mov dword ptr [edi+4], eax

 {$IFDEF NativeRandom}
  call RandomInt32
 {$ELSE}
  rdtsc
 {$ENDIF}
 mov word ptr [edi+8], ax

 xchg edi, eax

 pop edx
 mov dword ptr [edx], eax

 pop edi
 pop esi
end;

function Emu_Generate_RevEmu: TArray<UInt8>;
const
  REVEMU_HDDSTR_MINLEN = 10;
  REVEMU_DEF_LEN = 148;
  REVEMU_MAGIC = $726576;
var
  HDDStrPtr: array of Char;
  HDDStrLen: LongWord;
  HDDStrHash: LongWord;

  C: Char;
  CertificateLen: LongInt;
  L: LongInt;
begin
  HDDStrLen := REVEMU_HDDSTR_MINLEN + RandomNumber(6);

  SetLength(HDDStrPtr, HDDStrLen + 1);

  for L := 0 to HDDStrLen - 1 do
  begin
    case Random(2) of
      0: C := Char(Ord('A') + Random(26));
      1: C := Char(Ord('0') + Random(10));
    end;

    HDDStrPtr[L] := C;
   end;

  HDDStrHash := RevHash(PLChar(HDDStrPtr));

  CertificateLen := REVEMU_DEF_LEN + HDDStrLen;
  SetLength(Result, CertificateLen);
  FillChar(Result[0], CertificateLen, 0);

  TArray<UInt8>(Result)[0] := $4A;
  TArray<UInt32>(Result)[1] := HDDStrHash;
  TArray<UInt32>(Result)[2] := REVEMU_MAGIC;
  TArray<UInt32>(Result)[4] := HDDStrHash shl 1;
  Move(HDDStrPtr[0], TArray<UInt32>(Result)[6], HDDStrLen);
  TArray<UInt8>(Result)[132 + HDDStrLen] := 20;
  TArray<UInt8>(Result)[136 + HDDStrLen] := 1;
end;

function JSHash(const Data: LStr; Size: UInt32; a3: Boolean): UInt32;
var
  Size2: Int64;
  I, J, v7: UInt32;
begin
  v7 := 1315423911;
  Size2 := Size;

  if a3 then
    for I := 0 to Size - 1 do
      if UInt8(Data[I + 1]) = 0 then
      begin
        Size2 := I;
        Break;
      end;

  for J := 0 to Size2 - 1 do
    v7 := 32 * v7 + (v7 shr 2) + UInt8(Data[J + 1]);

  Result := v7;
end;

function Emu_Generate_RevEmu2013: TArray<UInt8>;
const
  hwid = '                        ABCDEFGH';
  aes_key_rand = '0123456789ABCDEFGHIJKLMNOPQRSTUV';
  aes_key_rev = '_YOU_SERIOUSLY_NEED_TO_GET_LAID_';
var
  Ticket: array [0..2048 - 1] of LChar;
  hashed_hwid: UInt32;
  aes_hash_rand,
  aes_hash_rev,
  sha_hash: array [0..32 - 1] of LChar;
begin
  hashed_hwid := JSHash(hwid, 32, True);
  PUInt32(UInt32(Pointer(@Ticket[0])))^ := 83;
  PUInt32(UInt32(Pointer(@Ticket[0])) + 4)^ := hashed_hwid;
  PUInt32(UInt32(Pointer(@Ticket[0])) + 8)^ := 7497078;
  PUInt32(UInt32(Pointer(@Ticket[0])) + 16)^ := hashed_hwid * 2;
  PUInt32(UInt32(Pointer(@Ticket[0])) + 20)^ := 17825793;
  PUInt32(UInt32(Pointer(@Ticket[0])) + 24)^ := {Time(0) +} 90123;
  PUInt8(UInt32(Pointer(@Ticket[0])) + 27)^ := not (UInt8(Ticket[27]) + UInt8(Ticket[24]));
  PUInt32(UInt32(Pointer(@Ticket[0])) + 28)^ := {Time(}0{)};
  PUInt32(UInt32(Pointer(@Ticket[0])) + 32)^ := hashed_hwid * 2 shr 3;

  Rijndael.MakeKey(PLChar(aes_key_rand), PLChar(sm_chain0), 32, 32);
  Rijndael.EncryptBlock(hwid, aes_hash_rand);

  Move(aes_hash_rand[0], Ticket[40], 32);

  Rijndael.MakeKey(PLChar(aes_key_rev), PLChar(sm_chain0), 32, 32);
  Rijndael.EncryptBlock(aes_key_rand, aes_hash_rev);

  Move(aes_hash_rand[0], Ticket[72], 32);


{CSHA sha( CSHA::SHA256 );
sha.AddData( hwid, 32 );
sha.FinalDigest( sha_hash );

memcpy( ticket + 104, sha_hash, 32 );    }
  with TSHA1.Create do
  begin
    AddBytes(@hwid[1], 32);
    PByte(@sha_hash[0])^ := GetDigest^;
    Free;
  end;

  Move(sha_hash[0], Ticket[104], 32);

  SetLength(Result, 194);
  Move(Ticket[0], Result[0], 194);
{
msg.WriteShort( 194 ); // ticket len
msg.WriteBytes( ticket, 194 );}
end;

function Emu_Generate_SC2009: TArray<UInt8>;
{
char ticket[2048];

const char hwid[] = "                        ABCDEFGH";

uint32 hashed_hwid = JSHash( hwid, 32, true ); }

const
  hwid = '                        ABCDEFGH';
  aes_key_rand = '0123456789ABCDEFGHIJKLMNOPQRSTUV';
  aes_key_rev = '_YOU_SERIOUSLY_NEED_TO_GET_LAID_';
var
  Ticket: array [0..2048 - 1] of LChar;
  hashed_hwid: UInt32;

  aes_hash_rand,
  aes_hash_rev,
  sha_hash: array [0..32 - 1] of LChar;
begin
  hashed_hwid := JSHash(hwid, 32, True);
{
*( uint32* )ticket = 83;
*( uint32* )( ticket + 4 ) = hashed_hwid;
*( uint32* )( ticket + 8 ) = 7497078;
*( uint32* )( ticket + 16 ) = hashed_hwid * 2;
*( uint32* )( ticket + 20 ) = 17825793;  }

  TArray<UInt32>(@Ticket[0])[0] := 83;
  TArray<UInt32>(@Ticket[0])[1] := hashed_hwid;
  TArray<UInt32>(@Ticket[0])[2] := 7497078;
  TArray<UInt32>(@Ticket[0])[4] := hashed_hwid * 2;
  TArray<UInt32>(@Ticket[0])[5] := 17825793;

{const char aes_key_rand[] = "0123456789ABCDEFGHIJKLMNOPQRSTUV";
char aes_hash_rand[32];                 }

{CRijndael rijndael_rand;
rijndael_rand.MakeKey( aes_key_rand, CRijndael::sm_chain0, 32, 32 );
rijndael_rand.EncryptBlock( hwid, aes_hash_rand );

memcpy( ticket + 24, aes_hash_rand, 32 );}

  Rijndael.MakeKey(PLChar(aes_key_rand), PLChar(sm_chain0), 32, 32);
  Rijndael.EncryptBlock(hwid, aes_hash_rand);

  Move(aes_hash_rand[0], Ticket[24], 32);

{const char aes_key_rev[] = "_YOU_SERIOUSLY_NEED_TO_GET_LAID_";
char aes_hash_rev[32];}

{CRijndael rijndael_rev;
rijndael_rev.MakeKey( aes_key_rev, CRijndael::sm_chain0, 32, 32 );
rijndael_rev.EncryptBlock( aes_key_rand, aes_hash_rev );

memcpy( ticket + 56, aes_hash_rev, 32 ); }

  Rijndael.MakeKey(PLChar(aes_key_rev), PLChar(sm_chain0), 32, 32);
  Rijndael.EncryptBlock(aes_key_rand, aes_hash_rev);

  Move(aes_hash_rev[0], Ticket[56], 32);

{char sha_hash[32];

CSHA sha( CSHA::SHA256 );
sha.AddData( hwid, 32 );
sha.FinalDigest( sha_hash );

memcpy( ticket + 88, sha_hash, 32 );   }

{  with TSHA1.Create do
  begin
    AddBytes(PByte(hwid[1]), 32);
    PByte(sha_hash[0])^ := GetDigest^;
    Free;
  end;

  Move(sha_hash[0], Ticket[88], 32);}

{msg.WriteShort( 178 ); // ticket len
msg.WriteBytes( ticket, 178 );
}

  SetLength(Result, 178);
  Move(Ticket[0], Result[0], 178);
end;

function Emu_Generate_Custom: TArray<UInt8>;
const EMU_FILENAME = 'certificate.dat';
begin
  if FileExists(EMU_FILENAME) then
    with TBufferEx2.Create do
    begin
      LoadFromFile(EMU_FILENAME);
      Start;
      SetLength(Result, Size);
      Read(Result, Size);
      Free;
    end;
end;

function Emu_Generate(AEmulatorType: UInt8; SteamID: Int32 = 0; Prefix: Boolean = False): TArray<UInt8>;
begin
  case AEmulatorType of
    EMU_REVEMU2013: Result := Emu_Generate_RevEmu2013;
    EMU_SC2009: Result := Emu_Generate_SC2009;
    EMU_REVEMU: Result := Emu_Generate_RevEmu;
    EMU_AVSMP: Result := Emu_Generate_AVSMP(SteamID, Prefix);
    EMU_STEAMEMU: Result := Emu_Generate_SteamEmu(SteamID);
    EMU_OLDREVEMU: Result := Emu_Generate_OldRevEmu(SteamID);
    EMU_CUSTOM: Result := Emu_Generate_Custom;
  else
    Error(['unknown emulator: ', AEmulatorType]);
  end;
end;

end.