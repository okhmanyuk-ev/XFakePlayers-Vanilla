program XClient;

{$R *.res}

uses
  Windows,
  SysUtils,

  Default,
  Protocol,
  BuildTime,
  Resource,
  Weapon,
  Other,
  Shared,
  Command,
  CVar,
  Entity,

  ConsoleForX,

  XExtendedGameClient;

type
  TXClient = class(TXExtendedGameClient);

  TEngine = class(TConsoleForX)
  strict protected
    Client: TXClient;

    procedure Frame; override;

    procedure OnSlowFrame(Sender: TObject);

    function GetEngineType: TEngineType; override;
  public
    constructor Create;
    destructor Destroy; override;
  end;

procedure TEngine.OnSlowFrame(Sender: TObject);
var
  S: LStr;
  I: Int32;
begin
  if Client.NET.GetSpeed > 0  then
    S := 'Working... ' + BytesToTraffStr(Client.NET.GetSpeed) + '/s'
  else
    S := 'Idling... ';

  S := UnitName + ' v1 - ' + S;

  SetConsoleTitleA(PLChar(S));
end;

function TEngine.GetEngineType: TEngineType;
begin
  Result := Client.GetEngineType;
end;

constructor TEngine.Create;
begin
  inherited;

  // client >>>
  Client := TXClient.Create;

  // native engine
  Client.OnSlowFrame := OnSlowFrame;

  Client.OnError := OnError;
  Client.OnHint := OnHint;
  Client.OnPrint := OnPrint;

  // native client
  Client.OnSimpleServerInfo := OnSimpleServerInfo;
  Client.OnSimpleServerPlayers := OnSimpleServerPlayers;
  Client.OnSimpleServerRules := OnSimpleServerRules;

  // base game client

  // simple game client
  Client.OnETextMsg := OnETextMsg;
  Client.OnESayText := OnESayText;
  Client.OnEDeathMsg := OnEDeathMsg;

  AddConsoleCommands(Client);

  Client.NET.Port := StrToIntDef(GetParamValue('port'), 0);
  Client.Activate;

  Log.SetFileName(AnsiLowerCase(UnitName) + '_logs', FormatDateTime('dd.MM.yyyy', Now) + '_' + FormatDateTime('HH.mm.ss', Now) + '.txt');

  WriteHelloLogs(UnitName, BUILD_DATE + ' (' + XCLIENT_BUILD + ')');
end;

procedure TEngine.Frame;
var
  S: LStr;
begin
  Readln(S);
  Client.ExecuteCommand(S);
end;

destructor TEngine.Destroy;
begin
  Client.Free;

  inherited;
end;

begin
  TEngine.Create.Main;
end.
