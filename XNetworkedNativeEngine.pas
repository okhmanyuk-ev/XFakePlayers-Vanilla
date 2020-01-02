unit XNetworkedNativeEngine;

interface

uses
  Default,
  XSocket,
  Buffer,
  XNativeEngine;

type
  TXNetworkedNativeEngine = class(TXNativeEngine)


  strict protected
    procedure Frame; override;
    procedure ReadPacket; virtual; abstract;

  strict protected
    MSG: TBufferEx2;

  public
    NET: TXSocket;

  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

procedure TXNetworkedNativeEngine.Frame;
begin
  if not NET.IsInitialized then
    NET.Initialize;

  inherited;

  while NET.ReadPacket(MSG) do
    ReadPacket;

  NET.UpdateCounters;
end;

constructor TXNetworkedNativeEngine.Create;
begin
  inherited;

  MSG := TBufferEx2.Create;
  NET := TXSocket.Create;
end;

destructor TXNetworkedNativeEngine.Destroy;
begin
  MSG.Free;
  NET.Free;

  inherited;
end;

end.