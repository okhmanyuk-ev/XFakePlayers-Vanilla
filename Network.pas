unit Network;

interface

uses
  Windows,
  WinSock,
  SysUtils,
  Shared,
  Default;

type
  TNETIP = record
    class operator Equal(A, B: TNETIP): Boolean;
    class operator NotEqual(A, B: TNETIP): Boolean;

  case Int32 of
    0: (AsBytes: array[0..3] of UInt8);
    1: (AsLong: UInt32);
  end;

  TNETAdr = record
    IP: TNETIP;
    Port: UInt16;

    class operator Equal(A, B: TNETAdr): Boolean;
    class operator NotEqual(A, B: TNETAdr): Boolean;

    class function Create(IP: LStr; Port: UInt16): TNETAdr; overload; static;
    class function Create(B1, B2, B3, B4: UInt8; Port: UInt16 = 0): TNETAdr; overload; static;
    class function Create(Address: LStr): TNETAdr; overload; static;
    class function Create(IP: UInt32; Port: UInt16 = 0): TNETAdr; overload; static;

    function ToString(IncludePort: Boolean = True): LStr;
    function ToSockAddr: TSockAddr;

    function ResolveIPAddress: LStr;
    function GetHostName: LStr;
  end;

  TOnEAdr = procedure(Sender: TObject; Address: TNETAdr) of object;

var
  WSA: TWSAData;

  NET_PORT: UInt16;

const
  NET_BUFFER_SIZE = 8192; // 65535 ?
  NET_LOCAL_ADDR: TNETAdr = (IP: (AsBytes: (127, 0, 0, 1)); Port: 0);
  NetAdrCleared: TNETAdr = (IP: (AsBytes: (0, 0, 0, 0)); Port: 0);

// shared
function SocketLastError: LStr;

function IPAddressToHostName(Address: LStr): LStr;
function HostNameToIPAddress(AHostName: LStr): LStr;

function ParseIP(Data: LStr): LStr;
function ParsePort(Data: LStr): Word;

function IsIPDigits(AIP: LStr): Boolean;

// clears
procedure Clear(var Data: TNETAdr); overload; inline;

implementation

{$REGION 'TNETIP'}
class operator TNETIP.Equal(A, B: TNETIP): Boolean;
begin
  Result := A.AsLong = B.AsLong;
end;

class operator TNETIP.NotEqual(A, B: TNETIP): Boolean;
begin
  Result := A.AsLong <> B.AsLong;
end;
{$ENDREGION}

{$REGION 'TNETAdr'}
class operator TNETAdr.Equal(A, B: TNETAdr): Boolean;
begin
  Result := (A.IP = B.IP) and (A.Port = B.Port);
end;

class operator TNETAdr.NotEqual(A, B: TNETAdr): Boolean;
begin
  Result := (A.IP <> B.IP) or (A.Port <> B.Port);
end;

class function TNETAdr.Create(IP: LStr; Port: UInt16): TNETAdr;
var
  I: Int32;
begin
  if not IsIPDigits(IP) then
    IP := HostNameToIPAddress(IP);

  if not IsIPDigits(IP) then
    Exit(TNETAdr.Create(0, Port));

  for I := 0 to 3 do
  begin
    Result.IP.AsBytes[I] := StrToIntDef(ParseBefore(IP, '.'), 0);
    DeleteBefore(IP, '.', True);
  end;

  Result.Port := Port;
end;

class function TNETAdr.Create(B1, B2, B3, B4: UInt8; Port: UInt16 = 0): TNETAdr;
begin
  Result.IP.AsBytes[0] := B1;
  Result.IP.AsBytes[1] := B2;
  Result.IP.AsBytes[2] := B3;
  Result.IP.AsBytes[3] := B4;
  Result.Port := Port;
end;

class function TNETAdr.Create(Address: LStr): TNETAdr;
begin
  if CompareStr(ParseBefore(Address, ':'), 'localhost') = 0 then
    Result := TNETAdr.Create(127, 0, 0, 1, ParsePort(Address))
  else
    Result := TNETAdr.Create(ParseIP(Address), ParsePort(Address));
end;

class function TNETAdr.Create(IP: UInt32; Port: UInt16 = 0): TNETAdr;
begin
  Result.IP.AsLong := IP;
  Result.Port := Port;
end;

function TNETAdr.ToString(IncludePort: Boolean = True): LStr;
begin
  Result :=
    IntToStr(IP.AsBytes[0]) + '.' +
    IntToStr(IP.AsBytes[1]) + '.' +
    IntToStr(IP.AsBytes[2]) + '.' +
    IntToStr(IP.AsBytes[3]);

  if IncludePort then
    Result := Result + ':' + IntToStr(Port);
end;

function TNETAdr.ToSockAddr: TSockAddr;
begin
  Result.sin_family := AF_INET;
  Result.sin_addr.S_addr := IP.AsLong;
  Result.sin_port := htons(Port);
  ZeroMemory(@Result.sin_zero, SizeOf(Result.sin_zero));
end;

function TNETAdr.ResolveIPAddress: LStr;
begin
  Result := ParseBefore(ToString, ':');
end;

function TNETAdr.GetHostName: LStr;
begin
  Result := IPAddressToHostName(ResolveIPAddress);
end;
{$ENDREGION}

{$REGION 'Shared'}
function SocketLastError: LStr;
begin
  case WSAGetLastError of
    WSAEINTR: Result := 'WSAEINTR';
    WSAEBADF: Result := 'WSAEBADF';
    WSAEACCES: Result := 'WSAEACCES';
    WSAEFAULT: Result := 'WSAEFAULT';
    WSAEINVAL: Result := 'WSAEINVAL';
    WSAEMFILE: Result := 'WSAEMFILE';
    WSAEWOULDBLOCK: Result := 'WSAEWOULDBLOCK';
    WSAEINPROGRESS: Result := 'WSAEINPROGRESS';
    WSAEALREADY: Result := 'WSAEALREADY';
    WSAENOTSOCK: Result := 'WSAENOTSOCK';
    WSAEDESTADDRREQ: Result := 'WSAEDESTADDRREQ';
    WSAEMSGSIZE: Result := 'WSAEMSGSIZE';
    WSAEPROTOTYPE: Result := 'WSAEPROTOTYPE';
    WSAENOPROTOOPT: Result := 'WSAENOPROTOOPT';
    WSAEPROTONOSUPPORT: Result := 'WSAEPROTONOSUPPORT';
    WSAESOCKTNOSUPPORT: Result := 'WSAESOCKTNOSUPPORT';
    WSAEOPNOTSUPP: Result := 'WSAEOPNOTSUPP';
    WSAEPFNOSUPPORT: Result := 'WSAEPFNOSUPPORT';
    WSAEAFNOSUPPORT: Result := 'WSAEAFNOSUPPORT';
    WSAEADDRINUSE: Result := 'WSAEADDRINUSE';
    WSAEADDRNOTAVAIL: Result := 'WSAEADDRNOTAVAIL';
    WSAENETDOWN: Result := 'WSAENETDOWN';
    WSAENETUNREACH: Result := 'WSAENETUNREACH';
    WSAENETRESET: Result := 'WSAENETRESET';
    WSAECONNABORTED: Result := 'WSAECONNABORTED';
    WSAECONNRESET: Result := 'WSAECONNRESET';
    WSAENOBUFS: Result := 'WSAENOBUFS';
    WSAEISCONN: Result := 'WSAEISCONN';
    WSAENOTCONN: Result := 'WSAENOTCONN';
    WSAESHUTDOWN: Result := 'WSAESHUTDOWN';
    WSAETOOMANYREFS: Result := 'WSAETOOMANYREFS';
    WSAETIMEDOUT: Result := 'WSAETIMEDOUT';
    WSAECONNREFUSED: Result := 'WSAECONNREFUSED';
    WSAELOOP: Result := 'WSAELOOP';
    WSAENAMETOOLONG: Result := 'WSAENAMETOOLONG';
    WSAEHOSTDOWN: Result := 'WSAEHOSTDOWN';
    WSAEHOSTUNREACH: Result := 'WSAEHOSTUNREACH';
    WSAENOTEMPTY: Result := 'WSAENOTEMPTY';
    WSAEPROCLIM: Result := 'WSAEPROCLIM';
    WSAEUSERS: Result := 'WSAEUSERS';
    WSAEDQUOT: Result := 'WSAEDQUOT';
    WSAESTALE: Result := 'WSAESTALE';
    WSAEREMOTE: Result := 'WSAEREMOTE';
    WSASYSNOTREADY: Result := 'WSASYSNOTREADY';
    WSAVERNOTSUPPORTED: Result := 'WSAVERNOTSUPPORTED';
    WSANOTINITIALISED: Result := 'WSANOTINITIALISED';
    WSAEDISCON: Result := 'WSAEDISCON';
    WSAHOST_NOT_FOUND: Result := 'WSAHOST_NOT_FOUND';
    WSATRY_AGAIN: Result := 'WSATRY_AGAIN';
    WSANO_RECOVERY: Result := 'WSANO_RECOVERY';
    WSANO_DATA: Result := 'WSANO_DATA';
  else
    Result := 'NO ERROR';
  end;
end;

function IPAddressToHostName(Address: LStr): LStr;
var
  SockAddrIn: TSockAddrIn;
  HostEnt: PHostEnt;
begin
  SockAddrIn.sin_addr.s_addr := inet_addr(PLChar(Address));
  HostEnt := GetHostByAddr(@SockAddrIn.sin_addr.S_addr, 4, AF_INET);

  if HostEnt <> nil then
    Result := StrPas(Hostent^.h_name)
  else
    Result := Address;
end;

function HostNameToIPAddress(AHostName: LStr): LStr;
type
  TaPInAddr = array[0..10] of PInAddr;
  PaPInAddr = ^TaPInAddr;
var
  HostEnt: PHostEnt;
  APInAddr: PaPInAddr;
  I: Int32;
begin
  HostEnt := GetHostByName(PLChar(AHostName));

  if HostEnt = nil then
    Exit;

  APInAddr := PaPInAddr(HostEnt^.h_addr_list);

  I := 0;

  while APInAddr^[I] <> nil do      // there is may be > 1 hostnames at ip
  begin
    Result := inet_ntoa(APInAddr^[I]^);
    Inc(I);
  end;

  {if APInAddr^[0] <> nil then
    Result := inet_ntoa(APInAddr^[I]^);}
end;

function ParseIP(Data: LStr): LStr;
begin
  Result := ParseBefore(Data, ':');
end;

function ParsePort(Data: LStr): Word;
begin
  Result := StrToIntDef(ParseAfter(Data, ':', False), 0);
end;

function IsIPDigits(AIP: LStr): Boolean;
var
  I, J: Int32;
begin
  for I := 0 to 2 do
  begin
    J := StrToIntDef(ParseBefore(AIP, '.', False), -1);

    if (J < 0) or (J > 255) then
      Exit(False);

    DeleteBefore(AIP, '.', True);
  end;

  J := StrToIntDef(AIP, -1);

  if (J < 0) or (J > 255) then
    Exit(False);

  Result := True;
end;
{$ENDREGION}

{$REGION 'Clears'}
procedure Clear(var Data: TNETAdr);
begin
  with Data do
  begin
    Clear(IP.AsLong);
    Clear(Port);
  end;
end;
{$ENDREGION}

initialization
  WSAStartup($202, WSA);

finalization
  WSACleanup;

end.