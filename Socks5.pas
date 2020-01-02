unit Socks5;

interface

uses
  SysUtils,
  Windows,
  Classes,

  Default,
  Shared,
  Common,
  Network,
  WinSock,
  Buffer;

const
  SOCKS_VERSION = 5;

const
  SOCKS_AUTH_NOAUTH = 0;
  SOCKS_AUTH_GSSAPI = 1;
  SOCKS_AUTH_LOGINPASS = 2;

  SOCKS_AUTH_ERROR = $FF;

const
  SOCKS_CMD_TCP_CONNECTION = 1;
  SOCKS_CMD_TCP_BIND = 2;
  SOCKS_CMD_UDP_ASSOCIATION = 3;

const
  SOCKS_ADDR_IPV4 = 1;
  SOCKS_ADDR_DOMAIN = 3;
  SOCKS_ADDR_IPV6 = 4;

const
  SOCKS_ANSWER_OK = 0;
  SOCKS_ANSWER_ERROR = 1;
  SOCKS_ANSWER_FORBIDDEN_BY_RULES = 2;
  SOCKS_ANSWER_NETWORK_UNAVAILABLE = 3;
  SOCKS_ANSWER_HOST_UNAVAILABLE = 4;
  SOCKS_ANSWER_CONNECTION_REFUSED = 5;
  SOCKS_ANSWER_TTL_EXPIRATION = 6;
  SOCKS_ANSWER_UNKNOWN_COMMAND = 8; // or protocol error ?
  SOCKS_ANSWER_ADDR_ISNT_SUPPORTED = 9;

type
  TSocks5HandlerState = (S_NONE, S_DISCONNECTED, S_CONNECTING, S_WAITING_HELLO_RESPONSE, S_WAITING_ASSOCIATION_RESPONSE, S_ASSOCIATED);

  TSocks5Handler = class(TThread)
  strict private
    FPort: UInt16;
    FOnLog: TOnEString;

    FSocket: TSocket;
    FAddress: TSockAddr;

    FState: TSocks5HandlerState;

    MSG: TBufferEx2;
        
    Proxy: TNETAdr;
    Associated: TNETAdr;

    procedure Log(AData: LStr);
  protected
    procedure Send;
    function Read: Boolean;

    procedure Execute; override; final;
  public
    constructor Create(AAddress: TNETAdr);
    destructor Destroy; override;

    property GetState: TSocks5HandlerState read FState;
    property SetState: TSocks5HandlerState write FState;

    property GetAssociatedAddr: TNETAdr read Associated;
    property GetProxy: TNETAdr read Proxy;

    property OnLog: TOnEString read FOnLog write FOnLog;
  end;

implementation

procedure TSocks5Handler.Log(AData: LStr);
begin
  if Assigned(OnLog) then
    Synchronize(procedure begin OnLog(Self, AData) end);
end;

procedure TSocks5Handler.Send;
begin
  WinSock.send(FSocket, MSG.Memory^, MSG.Size, 0);
end;

function TSocks5Handler.Read: Boolean;
var
  Size: Int32;
  Buffer: array[0..NET_BUFFER_SIZE - 1] of UInt8;
begin
  Size := recv(FSocket, Buffer, SizeOf(Buffer), 0);

  Result := (Size <> SOCKET_ERROR) and (Size <> 0); // 0 - disconnected

  MSG.ResetPositionHistory;
  MSG.Clear;
  MSG.Write(Buffer, Size);
  MSG.Start;
end;

procedure TSocks5Handler.Execute;
var
  A: TSockAddr;
  P: UInt16;
  J: UInt8;
  S_ERROR: LStr;
label
  L1;
begin
  FState := S_CONNECTING;

  A := Proxy.ToSockAddr;

  Log('connecting');

  if connect(FSocket, A, SizeOf(A)) = SOCKET_ERROR then
  begin
    Log('cannot connect');
    goto L1;
  end;

  Log('connected, sending hello');

  MSG.Clear;
  MSG.WriteUInt8(SOCKS_VERSION);
  MSG.WriteUInt8(1); // count of auth types
  MSG.WriteUInt8(SOCKS_AUTH_NOAUTH); // out auth type
  Send;

  FState := S_WAITING_HELLO_RESPONSE;

  while Read do
  begin
    J := MSG.ReadUInt8;

    if J <> SOCKS_VERSION then
    begin
      Log('bas socks version (' + IntToStr(J) + ')');
      goto L1;
    end;

    case FState of
      S_WAITING_HELLO_RESPONSE:
      begin
        if MSG.ReadUInt8 <> SOCKS_AUTH_NOAUTH then
        begin
          Log('bad socks auth');
          goto L1;
        end;

        Log('hello received, sending association request');

        MSG.Clear;
        MSG.WriteUInt8(SOCKS_VERSION);
        MSG.WriteUInt8(SOCKS_CMD_UDP_ASSOCIATION);
        MSG.WriteUInt8(0);
        MSG.WriteUInt8(SOCKS_ADDR_IPV4);
        MSG.WriteInt32(0);
        MSG.WriteUInt16(0);
        Send;

        FState := S_WAITING_ASSOCIATION_RESPONSE;
      end;

      S_WAITING_ASSOCIATION_RESPONSE:
      begin
        J := MSG.ReadUInt8;

        if J <> SOCKS_ANSWER_OK then
        begin
          case J of
            SOCKS_ANSWER_ERROR: Log('SOCKS_ERROR');
            SOCKS_ANSWER_FORBIDDEN_BY_RULES: Log('SOCKS_FORBIDDEN_BY_RULES');
            SOCKS_ANSWER_NETWORK_UNAVAILABLE: Log('NETWORK_UNAVAILABLE');
            SOCKS_ANSWER_HOST_UNAVAILABLE: Log('HOST_UNAVAILABLE');
            SOCKS_ANSWER_CONNECTION_REFUSED: Log('CONNECTION_REFUSED');
            SOCKS_ANSWER_TTL_EXPIRATION: Log('TTL_EXPIRATION');
            SOCKS_ANSWER_UNKNOWN_COMMAND: Log('UNKNOWN_COMMAND');
            SOCKS_ANSWER_ADDR_ISNT_SUPPORTED: Log('ADDR ISN''T SUPPIRTED');
          end;

          goto L1;
        end;

        MSG.Skip(1);

        case MSG.ReadUInt8 of
          SOCKS_ADDR_IPV4:
          begin
            MSG.Skip(4);
            Associated.IP := Proxy.IP;
            Associated.Port := Swap(MSG.ReadUInt16);
          end;

          SOCKS_ADDR_DOMAIN:
          begin
            Associated := TNETAdr.Create(MSG.ReadLStr(MSG.ReadUInt8), 0);
            Associated.Port := Swap(MSG.ReadUInt16);
          end;

          SOCKS_ADDR_IPV6: // fuck this
          begin
            MSG.Skip(16);
            goto L1;
          end;
        end;

        Log('associated successfully: ' + Associated.ToString);

        FState := S_ASSOCIATED;
      end;

      S_ASSOCIATED:
      begin
       // Alert([ShowbytesEx(MSG.ReadLStr(rmEnd))]);
      end;
    end;
  end;

  L1:
  FState := S_DISCONNECTED;
end;

constructor TSocks5Handler.Create(AAddress: TNETAdr);
var
  L: Int32;
begin
  inherited Create(False);

  MSG := TBufferEx2.Create;
  Proxy := AAddress;
  FState := S_NONE;

  FSocket := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

  if FSocket = INVALID_SOCKET then
    Error(['Can''t allocate socket - ' + SocketLastError, '.']);

  ZeroMemory(@FAddress.sin_zero, SizeOf(FAddress.sin_zero));

  FAddress.sin_family := AF_INET;
  FAddress.sin_addr.S_addr := INADDR_ANY;
  FAddress.sin_port := htons(FPort);

  if bind(FSocket, FAddress, SizeOf(FAddress)) = SOCKET_ERROR then
    if FPort = 0 then
      Error(['Can''t bind socket on random port - ', SocketLastError, '.'])
    else
      Error(['Can''t bind socket on port ', FPort, ' - ', SocketLastError, '.']);

  L := SizeOf(FAddress);

  if getsockname(FSocket, FAddress, L) = SOCKET_ERROR then
    Error(['Socket fault - ', SocketLastError, '.']);

  FPort := ntohs(FAddress.sin_port);
end;

destructor TSocks5Handler.Destroy;
begin
  closesocket(FSocket);
  MSG.Free;

  inherited;
end;

end.
