unit ConsoleForX;

interface

uses
  SysUtils,
  Vcl.Graphics,

  XNativeEngine,
  Command,

  Console,
  Common,
  Network,
  Shared,
  Other,
  Protocol,
  Default;

type
  TConsoleForX = class(TConsole)
  strict protected
    Log: TLogSystem;

    procedure AddConsoleCommands(ANativeEngine: TXNativeEngine);
    procedure WriteHelloLogs(AUnitName, ABuildStr: LStr);

    function VclColToConCol(AVclCol: UInt32): UInt16;
    function GetEngineType: TEngineType; virtual; abstract;

    // general
    procedure OnLog(Sender: TObject; Data: LStr);

    // native engine
    procedure OnError(Sender: TObject; Title, Data: LStr);
    procedure OnHint(Sender: TObject; Title, Data: LStr);
    procedure OnPrint(Sender: TObject; Data: LStr);

    // native client
    procedure OnSimpleServerInfo(Sender: TObject; Address: TNETAdr; Info: TSimpleServerInfo; Latency: UInt16);
    procedure OnSimpleServerPlayers(Sender: TObject; Address: TNETAdr; Players: TArray<TSimplePlayer>; Latency: UInt16);
    procedure OnSimpleServerRules(Sender: TObject; Address: TNETAdr; Rules: TArray<TSimpleRule>; Latency: UInt16);

    // simple game client
    procedure OnEDeathMsg(Sender: TObject; Data: TDeathMsg);
    procedure OnESayText(Sender: TObject; Data: TSayText);
    procedure OnETextMsg(Sender: TObject; Data: TTextMsg);
  public
    constructor Create;
    destructor Destroy; override;
  end;


implementation

procedure TConsoleForX.AddConsoleCommands(ANativeEngine: TXNativeEngine);
begin
  with ANativeEngine.Commands do
  begin
    Add('clear', Self.Clear, 'Clear Console', CMD_PROTECTED);
    Add('quit', Self.Quit, 'Quit Program', CMD_PROTECTED);
  end;
end;

procedure TConsoleForX.WriteHelloLogs(AUnitName: AnsiString; ABuildStr: AnsiString);
begin
  Log.Add(AUnitName + ' build: ' + ABuildStr);
  Log.Add('Code by ZeaL');
  Log.Add;
  Log.Add('type "cmdlist" to see available commands');
end;

function TConsoleForX.VclColToConCol(AVclCol: UInt32): UInt16;
begin
  case AVclCol of
    clRed: Result := CON_COLOR_RED_EX;
    clYellow: Result := CON_COLOR_YELLOW_EX;
    clAqua: Result := CON_COLOR_AQUA;
    clSilver: Result := CON_COLOR_GRAY_EX;
    clGray: Result := CON_COLOR_GRAY;
    clLime: Result := CON_COLOR_GREEN_EX;
  else
    Result := CON_COLOR_STANDART;
  end;
end;

procedure TConsoleForX.OnLog(Sender: TObject; Data: LStr);
begin
  PrintLn(Data);
end;

procedure TConsoleForX.OnError(Sender: TObject; Title, Data: LStr);
begin
  Log.Add('[ERROR] ' + Title + ' : ' + Data, True, True, False);

  Print(GetTime + ' - [');
  Print('ERROR', CON_COLOR_RED_EX);
  Print('] ' + Title + ' : ' + Data);
  PrintLn;
end;

procedure TConsoleForX.OnHint(Sender: TObject; Title, Data: LStr);
begin
  Log.Add('[' + Title + '] ' + Data, True, True, False);

  Print(GetTime + ' - [');
  Print(Title, CON_COLOR_GREEN_EX);
  Print('] ' + Data);
  PrintLn;
end;

procedure TConsoleForX.OnPrint(Sender: TObject; Data: LStr);
begin
  Log.Add(Data);
end;

procedure TConsoleForX.OnSimpleServerInfo(Sender: TObject; Address: TNETAdr; Info: TSimpleServerInfo; Latency: UInt16);
begin
  with Log do
  begin
    Add;
    Add(['ServerInfo from: ', Address.ToString]);
    Add(['Address: ', Info.Address]);
    Add(['Name: ', Info.Name]);
    Add(['Map: ', Info.Map]);
    Add(['Folder: ', Info.Folder]);
    Add(['Game: ', Info.Game]);
    Add(['Players: ', Info.Players]);
    Add(['MaxPlayers: ', Info.MaxPlayers]);
    Add(['Protocol: ', Info.Protocol]);
    Add(['ServerType: ', Info.ServerType]);
    Add(['Environment: ', Info.Environment]);
    Add(['Visibility: ', Info.Visibility]);
    Add(['HMod: ', Info.HMod]);

    if Boolean(Info.HMod) then
    begin
      Add(['  HMod:']);
      Add(['  Link: ', Info.Link]);
      Add(['  DownloadLink: ', Info.DownloadLink]);
      Add(['  NByte: ', Info.NByte]);
      Add(['  Version: ', Info.Version]);
      Add(['  Size: ', Info.Size]);
      Add(['  HType: ', Info.HType]);
      Add(['  HDLL: ', Info.HDLL]);
    end;

    Add(['VAC: ', Info.VAC]);
    Add(['Bots: ', Info.Bots]);
    Add(['GameVersion: ', Info.GameVersion]);
    Add;
    Add(['Latency: ', Latency]);
  end;
end;

procedure TConsoleForX.OnSimpleServerPlayers(Sender: TObject; Address: TNETAdr; Players: TArray<TSimplePlayer>; Latency: UInt16);
var
  I: Int32;
begin
  with Log do
  begin
    Add;

    Add(['PlayerInfo from: ', Address.ToString]);

    for I := Low(Players) to High(Players) do
      with Players[I] do
        Add([SS, I + 1, ') ', Name, '. Kills: ', Kills, ', Time: ', SecToTimeStr(Trunc(Time))]);

    Add;
    Add(['Latency: ', Latency]);
  end;
end;

procedure TConsoleForX.OnSimpleServerRules(Sender: TObject; Address: TNETAdr; Rules: TArray<TSimpleRule>; Latency: UInt16);
var
  I: Int32;
begin
  with Log do
  begin
    Add;

    Add(['RuleInfo from: ', Address.ToString]);

    for I := Low(Rules) to High(Rules) do
      with Rules[I] do
        Add([SS, I + 1, ') ', CVar, ' - ', Value]);

    Add;
    Add(['Latency: ', Latency]);
  end;
end;

procedure TConsoleForX.OnEDeathMsg(Sender: TObject; Data: TDeathMsg);
var
  S: LStr;
  C: Int32;
  K, V: LStr;
begin
  with Data do
  begin
    if Killer <> nil then
      K := Utf8ToAnsi(Killer.GetName)
    else
      K := 'worldspawn';

    if Victim <> nil then
      V := Utf8ToAnsi(Victim.GetName)
    else
      V := 'worldspawn';

    S := K + ' killed ' + V;

    if IsHeadshot then
      S := S + ' with a headshot from ' + Weapon
    else
      S := S + ' with ' + Weapon;

    if (Killer = Victim) and (Weapon = 'world') then
      S := Killer.GetName + ' suicided';

    Log.Add(S, True, True, False);

    // --------------------

    Print(GetTime + ' - ');

    if (Killer = Victim) and (Weapon = 'world') then
    begin
      Print(K, VclColToConCol(Killer.GetPlayerColor(GetEngineType)));
      Print(' suicided');
    end
    else
    begin
      if Killer <> nil then
        Print(K, VclColToConCol(Killer.GetPlayerColor(GetEngineType)))
      else
        Print(K);

      Print(' killed ');

      if Victim <> nil then
        Print(V, VclColToConCol(Victim.GetPlayerColor(GetEngineType)))
      else
        Print(V);

      if IsHeadshot then
        Print(' with a headshot from ' + Weapon)
      else
        Print(' with ' + Weapon);
    end;

    PrintLn;
  end;
end;

procedure TConsoleForX.OnESayText(Sender: TObject; Data: TSayText);
var
  S: LStr;
begin
  with Data do
  begin
    S1 := GameTitle(S1);
    S2 := GameTitle(S2);
    S3 := GameTitle(S3);
    S4 := GameTitle(S4);
                                   // player name instead of s2, it's ok.
    if Player <> nil then
      S := Format(S1, [Player.GetName, {S2,} S3, S4])
    else
      S := Format(S1, ['unknown', {S2,} S3, S4]);

    Log.Add(S);
  end;
end;

procedure TConsoleForX.OnETextMsg(Sender: TObject; Data: TTextMsg);
var
  C: Int32;
begin
  //1 - need decode
  //2 - simple decode (#Game_scoring)
  //3 - simple text or radio
  //4 - center text ? (#Spec_mode2, #CTs_Win, #Bomb_Defused)
  //5 - radio

  with Data do
  begin
    Data := GameTitle(Data);
    S1 := GameTitle(S1);
    S2 := GameTitle(S2);
    S3 := GameTitle(S3);
    S4 := GameTitle(S4);

    case DType of
      1..4: Log.Add(Format(Data, [S1, S2, S3, S4]));

      5: Log.Add(Format(S1, [S2, S3, S4]));
    end;
  end;
end;

constructor TConsoleForX.Create;
begin
  inherited;


  Log := TLogSystem.Create;
  Log.OnLog := OnLog;
end;

destructor TConsoleForX.Destroy;
begin
  Log.Free;

  inherited;
end;

end.