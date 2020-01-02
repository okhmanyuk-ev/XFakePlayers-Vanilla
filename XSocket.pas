unit XSocket;

interface

uses
  Classes,
  WinSock,
  Windows,
  Buffer,
  Socks5,
  Network,
  Framer,
  Default;

const
  DEFAULT_SPEED_CHECK_PERIOD = 1000;

type
  {$REGION 'TXSocket'}
  TXSocket = class
  strict private
    FIsInitialized: Boolean;
    FPort: UInt16;

    FSocket: TSocket;
    FAddress: TSockAddr;

    FHasAssociatedProxy: Boolean;
    FAssociatedProxy: TNETAdr;

    FSendBuffer: TBufferEx2;

    FSpeedCheckPeriod,
    FLastSpeedCheckTime,

    FSpeedInInternal,
    FSpeedOutInternal,
    FSpeedIn,
    FSpeedOut,

    FPPSInInternal,
    FPPSOutInternal,
    FPPSIn,
    FPPSOut,

    FTrafficIn,
    FTrafficOut,

    FPacketsIn,
    FPacketsOut: UInt;

    procedure SetAssociatedProxy(AAddress: TNETAdr);

  public
    From: TNETAdr;

    constructor Create;
    destructor Destroy; override;

    procedure Initialize; overload;
    procedure Initialize(APort: UInt16); overload;

    property Port: UInt16 read FPort write FPort;

    property IsInitialized: Boolean read FIsInitialized;

    function ReadPacket(var AMSG: TBufferEx2): Boolean;

    procedure Send(ADestination: TNETAdr; const ABuffer; ASize: UInt); overload;
    procedure Send(ADestination: TNETAdr; const ABuffer: LStr); overload;
    procedure Send(ADestination: TNETAdr; const ABuffer: TBufferEx2); overload;

    procedure Send(const ABuffer; ASize: UInt); overload;
    procedure Send(const ABuffer: LStr); overload;
    procedure Send(const ABuffer: TBufferEx2); overload;

    property HasAssociatedProxy: Boolean read FHasAssociatedProxy;
    property AssociatedProxy: TNETAdr read FAssociatedProxy write SetAssociatedProxy;

    property SpeedCheckPeriod: UInt read FSpeedCheckPeriod write FSpeedCheckPeriod;

    property GetSpeedIn: UInt read FSpeedIn;
    property GetSpeedOut: UInt read FSpeedOut;
    function GetSpeed: UInt;

    property GetPPSIn: UInt read FPPSIn;
    property GetPPSOut: UInt read FPPSOut;
    function GetPPS: UInt;

    property GetTrafficIn: UInt read FTrafficIn;
    property GetTrafficOut: UInt read FTrafficOut;
    function GetTraffic: UInt;

    property GetPacketsIn: UInt read FPacketsIn;
    property GetPacketsOut: UInt read FPacketsOut;
    function GetPackets: UInt;

    procedure UpdateCounters;
  end;
  {$ENDREGION}

implementation

procedure TXSocket.Initialize;
const T = '[XSocket] ';
var
  I, L: Int;
begin
  if FIsInitialized then
    Exit;

  FIsInitialized := True;

  FSocket := socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);

  if FSocket = INVALID_SOCKET then
    Default.Error([T + 'Can''t allocate socket - ', SocketLastError, '.']);

  ZeroMemory(@FAddress.sin_zero, SizeOf(FAddress.sin_zero));

  FAddress.sin_family := AF_INET;
  FAddress.sin_addr.S_addr := INADDR_ANY;
  FAddress.sin_port := htons(FPort);

  if bind(FSocket, FAddress, SizeOf(FAddress)) = SOCKET_ERROR then
    if FPort = 0 then
      Default.Error([T + 'Can''t bind socket on random port - ', SocketLastError, '.'])
    else
      Default.Error([T + 'Can''t bind socket on port ', FPort, ' - ', SocketLastError, '.']);

  L := SizeOf(FAddress);

  if getsockname(FSocket, FAddress, L) = SOCKET_ERROR then
    Default.Error([T + 'Socket fault - ', SocketLastError, '.']);

  FPort := ntohs(FAddress.sin_port);

  I := 1;

  if ioctlsocket(FSocket, FIONBIO, I) = SOCKET_ERROR then
    Default.Error([T + 'Can''t set non-blocking I/O for socket - ', SocketLastError, '.']);
end;

procedure TXSocket.Initialize(APort: UInt16);
begin
  FPort := APort;
  Initialize;
end;

function TXSocket.ReadPacket(var AMSG: TBufferEx2): Boolean;
var
  Buffer: array[0..NET_BUFFER_SIZE - 1] of UInt8;
  RecvAddr: TSockAddr;
  RecvAddrLen,
  Size: Int;
label
  L1;
begin
  Result := True;

  RecvAddrLen := SizeOf(RecvAddr);
  Size := recvfrom(FSocket, Buffer, SizeOf(Buffer), 0, RecvAddr, RecvAddrLen);

  if Size = -1 then
    Exit(False);

  Inc(FSpeedInInternal, Size);
  Inc(FPPSInInternal);
  Inc(FTrafficIn, Size);
  Inc(FPacketsIn);

  AMSG.ResetPositionHistory;
  AMSG.Clear;
  AMSG.Write(Buffer, Size);
  AMSG.Start;

  From := TNETAdr.Create(RecvAddr.sin_addr.S_addr, ntohs(RecvAddr.sin_port));

  if HasAssociatedProxy and (From = AssociatedProxy) then
  begin
    AMSG.Skip(3);

    case AMSG.ReadUInt8 of
      SOCKS_ADDR_IPV4:
      begin
        From.IP.AsLong := AMSG.ReadUInt32;
        From.Port := Swap(AMSG.ReadUInt16);
      end;

      SOCKS_ADDR_DOMAIN:
      begin
        From := TNETAdr.Create(AMSG.ReadLStr(AMSG.ReadUInt8), 0);
        From.Port := Swap(AMSG.ReadUInt16);
      end;

      SOCKS_ADDR_IPV6: AMSG.Skip(16);
    end;

    AMSG.Delete(AMSG.Position, False);
  end;
end;

procedure TXSocket.Send(ADestination: TNETAdr; const ABuffer; ASize: UInt);
var
  A: TSockAddr;
begin
  if HasAssociatedProxy then
    A := AssociatedProxy.ToSockAddr
  else
    A := ADestination.ToSockAddr;

  with FSendBuffer do
  begin
    if HasAssociatedProxy then
    begin
      WriteUInt8(0);
      WriteUInt8(0);
      WriteUInt8(0);

      WriteUInt8(SOCKS_ADDR_IPV4);

      WriteUInt32(ADestination.IP.AsLong);
      WriteUInt16(Swap(ADestination.Port));
    end;

    Write(ABuffer, ASize);

    sendto(FSocket, Memory^, Size, 0, A, SizeOf(A));

    Clear;
  end;

  Inc(FSpeedOutInternal, ASize);
  Inc(FPPSOutInternal);

  Inc(FTrafficOut, ASize);
  Inc(FPacketsOut);
end;

procedure TXSocket.Send(const ABuffer; ASize: Cardinal);
begin
  Send(From, ABuffer, ASize);
end;

procedure TXSocket.Send(ADestination: TNETAdr; const ABuffer: LStr);
begin
  if Length(ABuffer) > 0 then
    Send(ADestination, ABuffer[1], Length(ABuffer));
end;

procedure TXSocket.Send(ADestination: TNETAdr; const ABuffer: TBufferEx2);
begin
  Send(ADestination, ABuffer.Memory^, ABuffer.Size);
end;

procedure TXSocket.Send(const ABuffer: LStr);
begin
  Send(From, ABuffer);
end;

procedure TXSocket.Send(const ABuffer: TBufferEx2);
begin
  Send(From, ABuffer);
end;

procedure TXSocket.SetAssociatedProxy(AAddress: TNETAdr);
begin
  if (AAddress = NET_LOCAL_ADDR) or (AAddress = NetAdrCleared) then
  begin
    FHasAssociatedProxy := False;
    Exit;
  end;

  FHasAssociatedProxy := True;
  FAssociatedProxy := AAddress;
end;

constructor TXSocket.Create;
begin
  inherited Create;

  FIsInitialized := False;
  FSendBuffer := TBufferEx2.Create;

  FSpeedCheckPeriod := DEFAULT_SPEED_CHECK_PERIOD;
end;

destructor TXSocket.Destroy;
begin
  if FIsInitialized then
    closesocket(FSocket);

  FSendBuffer.Free;

  inherited;
end;

function TXSocket.GetSpeed: UInt;
begin
  Result := GetSpeedIn + GetSpeedOut;
end;

function TXSocket.GetPPS: UInt;
begin
  Result := GetPPSIn + GetPPSOut;
end;

function TXSocket.GetTraffic: UInt;
begin
  Result := GetTrafficIn + GetTrafficOut;
end;

function TXSocket.GetPackets: UInt;
begin
  Result := GetPacketsIn + GetPacketsOut;
end;

procedure TXSocket.UpdateCounters;
begin
  if GetTickCount - FLastSpeedCheckTime >= FSpeedCheckPeriod then
  begin
    FSpeedIn := Round(FSpeedInInternal * (1000 / FSpeedCheckPeriod));
    FSpeedOut := Round(FSpeedOutInternal * (1000 / FSpeedCheckPeriod));

    Clear(FSpeedInInternal);
    Clear(FSpeedOutInternal);

    FPPSIn := Round(FPPSInInternal * (1000 / FSpeedCheckPeriod));
    FPPSOut := Round(FPPSOutInternal * (1000 / FSpeedCheckPeriod));

    Clear(FPPSInInternal);
    Clear(FPPSOutInternal);

    FLastSpeedCheckTime := GetTickCount;
  end;
end;

end.