unit XNativeClient;

interface

uses
  Windows,
  SysUtils,
  BZip2,
  Classes,
  System.Generics.Collections,

  XNetworkedNativeEngine,
  Network,
  Protocol,
  Challenge,
  Shared,
  Common,
  Default,
  Fragment,
  Buffer,
  MasterServer;

type
  TOnSimpleServerInfo = procedure(Sender: TObject; AAddress: TNETAdr; Info: TSimpleServerInfo; Latency: UInt16) of object;
  TOnSimpleServerPlayers = procedure(Sender: TObject; AAddress: TNETAdr; Players: TArray<TSimplePlayer>; Latency: UInt16) of object;
  TOnSimpleServerRules = procedure(Sender: TObject; AAddress: TNETAdr; Rules: TArray<TSimpleRule>; Latency: UInt16) of object;
  TOnServerList = procedure(Sender: TObject; AAddress: TNETAdr; Servers: TArray<TNETAdr>; Latency: UInt16) of object;

  TNativeEngineType = (NE_GOLDSRC = 0, NE_SOURCE);

const
  SXC_FIRST_BUILD = '04.07.2014 00:00:00';

type
  TXNativeClient = class(TXNetworkedNativeEngine)
  strict private
    FOnSimpleServerInfo: TOnSimpleServerInfo;
    FOnSimpleServerPlayers: TOnSimpleServerPlayers;
    FOnSimpleServerRules: TOnSimpleServerRules;
    FOnServerList: TOnServerList;

    FNativeEngineType: TNativeEngineType;

    FLastMasterServerUsed,
    FLastAddressInServerList: TNETAdr;
    FLastFiltersUsed: LStr;

  type
    TLatencyItem = record
      Address: TNETAdr;
      Time: UInt32;
    end;

  var
    FLatencies: TList<TLatencyItem>;

  strict protected
    Rcon_Address: LStr;
    Rcon_Password: LStr;
    Rcon_LastCommand: LStr;

  strict protected
    procedure SlowFrame; override;
    procedure Frame; override;
    procedure CL_SendOutOfBandPacket(ADestination: TNETAdr); overload;
    procedure CL_SendOutOfBandPacket; overload;
    procedure CL_SendOutOfBandPacket(ADestination: TNETAdr; AData: LStr); overload;
    procedure CL_SendOutOfBandPacket(AData: LStr); overload;
  strict private
    procedure CL_InitializeLatency(AAddress: TNETAdr);
    function CL_FinalizeLatency(AAddress: TNETAdr): UInt16;
  strict protected
    Challenge: TChallengeSystem;
    SplitPacket: TFragmentReader;

    procedure ReadPacket; override;
    function CL_ReadPacket: Boolean; virtual;
    function CL_ConnectionLessPacket: Boolean; virtual;
    function CL_SplitPacket: Boolean; virtual;
    procedure CL_ParseChallenge; virtual;

    procedure CL_ParseServiceChallenge;
    procedure CL_ParsePrint;
    procedure CL_ParseSimpleServerInfo(OldStyle: Boolean);
    procedure CL_ParseSimpleServerPlayers;
    procedure CL_ParseSimpleServerRules;
    procedure CL_ParseServerList;

    procedure CL_SendRconCommand(Address: TNETAdr; Challenge, Password, Command: LStr);

    procedure CL_GetServiceChallenge(Address: TNETAdr; Data: LStr);
    procedure CL_GetSimpleServerInfo(Address: TNETAdr);
    procedure CL_GetSimplePlayerInfo(Address: TNETAdr);
    procedure CL_GetSimpleRuleInfo(Address: TNETAdr);
    procedure CL_GetServerList(AMasterServer, AServer: TNETAdr; AFilters: LStr = ''); overload;
    procedure CL_GetServerList(AMasterServer: TNETAdr; AFilters: LStr = ''); overload;

    procedure CMD_RegisterCommands; override;
    procedure CMD_RegisterCVars; override;

    procedure CL_Rcon_F; virtual;
    procedure CL_GetInfo_F;
    procedure CL_GetPlayers_F;
    procedure CL_GetRules_F;
    procedure CL_GetServerList_F;
    procedure CL_ResetServerListQuery_F;
    procedure CL_RepeatServerListQuery_F;

  public
    constructor Create;
    destructor Destroy; override;

    property NativeEngineType: TNativeEngineType read FNativeEngineType write FNativeEngineType;

    property OnSimpleServerInfo: TOnSimpleServerInfo read FOnSimpleServerInfo write FOnSimpleServerInfo;
    property OnSimpleServerPlayers: TOnSimpleServerPlayers read FOnSimpleServerPlayers write FOnSimpleServerPlayers;
    property OnSimpleServerRules: TOnSimpleServerRules read FOnSimpleServerRules write FOnSimpleServerRules;
    property OnServerList: TOnServerList read FOnServerList write FOnServerList;
  end;

implementation

procedure TXNativeClient.SlowFrame;
var
  I: Int32;
begin
  inherited;

  SplitPacket.CheckTimeouts;

  for I := FLatencies.Count - 1 downto 0 do
    if GetTickCount - FLatencies[I].Time > MaxUInt16 then
      FLatencies.Delete(I);
end;

procedure TXNativeClient.Frame;
begin
  inherited;
end;

procedure TXNativeClient.CL_SendOutOfBandPacket(ADestination: TNETAdr);
const T = 'CL_SendOutOfBandPacket';
begin
  if MSG.Overwriting then
    Default.Error(['MSG.Overwriting must be false']);

  MSG.Start;
  MSG.WriteInt32(OUTOFBAND_PREFIX);
  Debug(T, [ShowBytesEx(MSG.ReadLStr(rmEnd))]);
  NET.Send(ADestination, MSG);
end;

procedure TXNativeClient.CL_SendOutOfBandPacket;
begin
  CL_SendOutOfBandPacket(NET.From);
end;

procedure TXNativeClient.CL_SendOutOfBandPacket(ADestination: TNETAdr; AData: LStr);
begin
  MSG.Clear;
  MSG.Write(AData);
  CL_SendOutOfBandPacket(ADestination);
end;

procedure TXNativeClient.CL_SendOutOfBandPacket(AData: LStr);
begin
  CL_SendOutOfBandPacket(NET.From, AData);
end;

procedure TXNativeClient.CL_InitializeLatency(AAddress: TNETAdr);
var
  L: TLatencyItem;
  I: Int32;
begin
  for I := FLatencies.Count - 1 downto 0 do
    if FLatencies[I].Address = AAddress then
      FLatencies.Delete(I);

  L.Address := AAddress;
  L.Time := GetTickCount;

  FLatencies.Add(L);
end;

function TXNativeClient.CL_FinalizeLatency(AAddress: TNETAdr): UInt16;
var
  I: Int32;
begin
  for I := 0 to FLatencies.Count - 1 do
    if FLatencies[I].Address = AAddress then
      Exit(GetTickCount - FLatencies[I].Time);

  Result := MaxUInt16;
end;

procedure TXNativeClient.ReadPacket;
begin
  CL_ReadPacket;
end;

function TXNativeClient.CL_ReadPacket: Boolean;
label
  L1;
begin
  Result := True;

  MSG.Start;

  if MSG.Size > 4 then
    case MSG.ReadInt32 of
      OUTOFBAND_PREFIX: if CL_ConnectionLessPacket then Exit;
      SPLIT_PREFIX: begin CL_SplitPacket; Exit end;
    end;

  Result := False;
end;

function TXNativeClient.CL_ConnectionLessPacket;
const T = 'CL_ConnectionLessPacket';
label
  L1;
begin
  Debug(T, [ShowBytesEx(MSG.PeekLStr(rmEnd))]);

  Result := False;

  MSG.SavePosition;

  case MSG.ReadLChar of
    'c': if StrBComp(MSG.ReadLStr, 'hallenge') then CL_ParseServiceChallenge else goto L1;
    'l': CL_ParsePrint;
    'm': CL_ParseSimpleServerInfo(True);
    'A': CL_ParseChallenge;
    'D': CL_ParseSimpleServerPlayers;
    'E': CL_ParseSimpleServerRules;
    'I': CL_ParseSimpleServerInfo(False);
    'f': CL_ParseServerList;
  else
    L1: MSG.RestorePosition;
    Exit;
  end;

  Result := True;
end;

function TXNativeClient.CL_SplitPacket: Boolean; // if packet completed then true else false
const T = 'CL_SplitPacket';
var
  I, Index, Count, Total: Int32;
  Size: Int16; // source
label
  L1;
begin
  Result := True;

  Index := MSG.ReadInt32;

  case NativeEngineType of
    NE_GOLDSRC:
    begin
      MSG.StartBitReading;

      Total := MSG.ReadUBits(4);
      Count := MSG.ReadUBits(4) + 1;

      MSG.EndBitReading;
    end;

    NE_SOURCE:
    begin
      Total := MSG.ReadUInt8;
      Count := MSG.ReadUInt8 + 1;
      Size := MSG.ReadInt16;
    end;
  end;

  Debug(T, ['Index: ', Index, ', (', Count, '/', Total, '), Size: ', Length(MSG.PeekLStr(rmEnd))]);

  SplitPacket.Add(Index, Count, Total, MSG.ReadLStr(rmEnd));

  Result := False;

  I := SplitPacket.GetCompleted;

  while I <> -1 do
  begin
    MSG.Clear;
    MSG.Write(SplitPacket[I].Defragmentate);

    Debug(T, ['Index: ', Index, ', Size: ', MSG.Size]);

    SplitPacket.Delete(I);

    CL_ReadPacket;

    Result := True;

    I := SplitPacket.GetCompleted;
  end;
end;

procedure TXNativeClient.CL_ParseChallenge;
begin
  if MSG.Size = 9 then // simple
    Challenge.Save(NET.From, MSG.ReadUInt32);
end;

procedure TXNativeClient.CL_ParseServiceChallenge;
begin
  CMD.Tokenize(MSG.ReadLStr(rmNullTerminatedOrLinebreak));

  if CMD.Count > 1 then
    if StrBComp(CMD.Tokens[1], 'rcon') then
      if CMD.Count > 2 then
        CL_SendRconCommand(NET.From, CMD.Tokens[2], Rcon_Password, Rcon_LastCommand);
end;

procedure TXNativeClient.CL_ParsePrint;
var
  Data: LStr;
begin
  Data := MSG.ReadLStr;

  Print([Data]);
end;

procedure TXNativeClient.CL_ParseSimpleServerInfo(OldStyle: Boolean);
var
  Data: TSimpleServerInfo;
  L: UInt16;
begin
  L := CL_FinalizeLatency(NET.From);

  with MSG, Data do
    if OldStyle then
    begin
      Address := ReadLStr;
      Name := ReadLStr;
      Map := ReadLStr;
      Folder := ReadLStr;
      Game := ReadLStr;
      Players := ReadUInt8;
      MaxPlayers := ReadUInt8;
      Protocol := ReadUInt8;  // bad for source engine
      ServerType := ReadUInt8;
      Environment := ReadUInt8;
      Visibility := ReadBool8;
      HMod := ReadUInt8;

      if HMod = 1 then
      begin
        Link := ReadLStr;
        DownloadLink := ReadLStr;
        NByte := ReadUInt8;
        Version := ReadInt32;
        Size := ReadInt32;
        HType := ReadUInt8;
        HDLL := ReadUInt8;
      end;

      VAC := ReadBool8;
      Bots := ReadUInt8;
    end
    else
    begin
      Protocol := ReadUInt8;
      Name := ReadLStr;
      Map := ReadLStr;
      Folder := ReadLStr;
      Game := ReadLStr;
      ReadLStr;
      Players := ReadUInt8;
      MaxPlayers := ReadUInt8;
      Bots := ReadUInt8;
      ServerType := ReadUInt8;
      Environment := ReadUInt8;
      Visibility := ReadBool8;
      VAC := ReadBool8;
      GameVersion := ReadLStr;
    end;

  if Assigned(OnSimpleServerInfo) then
  begin
    Lock;
    OnSimpleServerInfo(Self, NET.From, Data, L);
    UnLock;
  end;
end;

procedure TXNativeClient.CL_ParseSimpleServerPlayers;
var
  I: Int32;
  Data: TArray<TSimplePlayer>;
  L: UInt16;
begin
  L := CL_FinalizeLatency(NET.From);

  SetLength(Data, MSG.ReadUInt8);

  for I := Low(Data) to High(Data) do
    with Data[I] do
    begin
      Slot := MSG.ReadUInt8;
      Name := MSG.ReadLStr;
      Kills := MSG.ReadInt32;
      Time := MSG.ReadFloat;
    end;

  if Assigned(OnSimpleServerPlayers) then
  begin
    Lock;
    OnSimpleServerPlayers(Self, NET.From, Data, L);
    UnLock;
  end;
end;

procedure TXNativeClient.CL_ParseSimpleServerRules;
var
  Data: TArray<TSimpleRule>;
  I: UInt32;
  L: UInt16;
begin

  L := CL_FinalizeLatency(NET.From);

  SetLength(Data, MSG.ReadInt16);

  for I := Low(Data) to High(Data) do
    with Data[I] do
    begin
      CVar := MSG.ReadLStr;
      Value := MSG.ReadLStr;
    end;

  if Assigned(OnSimpleServerRules) then
  begin
    Lock;
    OnSimpleServerRules(Self, NET.From, Data, L);
    UnLock;
  end;
end;

procedure TXNativeClient.CL_ParseServerList;
var
  L: UInt16;
begin
  L := CL_FinalizeLatency(NET.From);

  MSG.ReadUInt8; // $10

  with TList<TNETAdr>.Create do
  begin
    while MSG.Position < MSG.Size do
    begin
      MSG.Read(FLastAddressInServerList, SizeOf(FLastAddressInServerList));
      FLastAddressInServerList.Port := Swap(FLastAddressInServerList.Port);

      Add(FLastAddressInServerList);
    end;

    if Assigned(OnServerList) then
    begin
      Lock;
      OnServerList(Self, NET.From, ToArray, L);
      UnLock;
    end;

    Free;
  end;
end;

procedure TXNativeClient.CL_SendRconCommand(Address: TNETAdr; Challenge, Password, Command: LStr);
begin
  MSG.Clear;
  MSG.WriteLStr('rcon ' + Challenge + ' "' + Password + '" ' + Command); // command already with quotes
  CL_SendOutOfBandPacket(Address);
end;

procedure TXNativeClient.CL_GetServiceChallenge(Address: TNETAdr; Data: LStr);
begin
  MSG.Clear;
  MSG.WriteLStr('challenge ' + Data);
  CL_SendOutOfBandPacket(Address);
end;

procedure TXNativeClient.CL_GetSimpleServerInfo(Address: TNETAdr);
begin
  MSG.Clear;
  MSG.WriteLChar('T');
  MSG.WriteLStr('Source Engine Query');
  CL_SendOutOfBandPacket(Address);
  CL_InitializeLatency(Address);
end;

procedure TXNativeClient.CL_GetSimplePlayerInfo(Address: TNETAdr);
begin
  MSG.Clear;
  MSG.WriteLChar('U');
  MSG.WriteUInt32(Challenge.Get(Address));
  CL_SendOutOfBandPacket(Address);
  CL_InitializeLatency(Address);
end;

procedure TXNativeClient.CL_GetSimpleRuleInfo(Address: TNETAdr);
begin
  MSG.Clear;
  MSG.WriteLChar('V');
  MSG.WriteUInt32(Challenge.Get(Address));
  CL_SendOutOfBandPacket(Address);
  CL_InitializeLatency(Address);
end;

procedure TXNativeClient.CL_GetServerList(AMasterServer, AServer: TNETAdr; AFilters: LStr = '');
begin
  MSG.Clear;
  MSG.WriteLChar(MS_SERVERLIST_HEADER);
  MSG.WriteUInt8(MS_REGION_REST_OF_WORLD);
  MSG.WriteLStr(AServer.ToString);
  MSG.WriteLStr(AFilters);
  NET.Send(AMasterServer, MSG);
  CL_InitializeLatency(AMasterServer);
end;

procedure TXNativeClient.CL_GetServerList(AMasterServer: TNETAdr; AFilters: LStr = '');
begin
  if (FLastMasterServerUsed <> AMasterServer) // user changed the master, we should start
   or (FLastFiltersUsed <> AFilters) then
    Clear(FLastAddressInServerList);

  FLastMasterServerUsed := AMasterServer;
  FLastFiltersUsed := AFilters;

  CL_GetServerList(AMasterServer, FLastAddressInServerList, AFilters);
end;

procedure TXNativeClient.CMD_RegisterCommands;
begin
  inherited;

  with Commands do
  begin
    Add('rcon', CL_Rcon_F, 'remote server control');
    Add('getinfo', CL_GetInfo_F, 'get server info');
    Add('getplayers', CL_GetPlayers_F, 'get server players');
    Add('getrules', CL_GetRules_F, 'get server rules');
    Add('getserverlist', CL_GetServerList_F, 'get server list');
    Add('resetserverlistquery', CL_ResetServerListQuery_F, 'reset server list query');
    Add('repeatserverlist', CL_RepeatServerListQuery_F, 'repeat server list query')
  end;
end;

procedure TXNativeClient.CMD_RegisterCVars;
begin
  inherited;

  with CVars do
  begin
    Add('rcon_address', @Rcon_Address, '', 'RCON Address');
    Add('rcon_password', @Rcon_Password, '', 'RCON Password');
  end;
end;

procedure TXNativeClient.CL_Rcon_F;
var
  S: LStr;
  I: UInt32;
begin              //rcon_address 127.0.0.1:27015; rcon_password 123456; rcon hostname
  if Length(Rcon_Password) = 0 then
  begin
    Print('You must set ''rcon_password'' before issuing an rcon command.');
    Exit;
  end;

  if CMD.Count < 2 then
  begin
    Print('Empty rcon string');
    Exit;
  end;

  if Length(Rcon_Address) = 0 then
  begin
    Print('You must either set the ''rcon_address'' cvar to issue rcon commands');
    Exit;
  end;

  Clear(Rcon_LastCommand);

  for I := 1 to CMD.Count - 1 do
    Rcon_LastCommand := Rcon_LastCommand + ' "' + CMD.Tokens[I] + '"';

  CL_GetServiceChallenge(TNETAdr.Create(Rcon_Address), 'rcon');
end;

procedure TXNativeClient.CL_GetInfo_F;
begin
  if CMD.Count < 2 then
  begin
    PrintCMDUsage(['server']);
    Exit;
  end;

  CL_GetSimpleServerInfo(TNETAdr.Create(CMD.Tokens[1]));
end;

procedure TXNativeClient.CL_GetPlayers_F;
begin
  if CMD.Count < 2 then
  begin
    PrintCMDUsage(['server']);
    Exit;
  end;

  CL_GetSimplePlayerInfo(TNETAdr.Create(CMD.Tokens[1]));
end;

procedure TXNativeClient.CL_GetRules_F;
begin
  if CMD.Count < 2 then
  begin
    PrintCMDUsage(['server']);
    Exit;
  end;

  CL_GetSimpleRuleInfo(TNETAdr.Create(CMD.Tokens[1]));
end;

procedure TXNativeClient.CL_GetServerList_F; // hl1master.steampowered.com:27011
begin
  if CMD.Count < 2 then
  begin
    PrintCMDUsage(['masterserver', '(filters)']);
    Exit;
  end;

  if CMD.Count > 2 then
    CL_GetServerList(TNETAdr.Create(CMD.Tokens[1]), CMD.Tokens[2])
  else
    CL_GetServerList(TNETAdr.Create(CMD.Tokens[1]));
end;

procedure TXNativeClient.CL_ResetServerListQuery_F;
begin
  Clear(FLastAddressInServerList);
end;

procedure TXNativeClient.CL_RepeatServerListQuery_F;
begin
  CL_GetServerList(FLastMasterServerUsed, FLastFiltersUsed);
end;

constructor TXNativeClient.Create;
begin
  inherited;

  Challenge := TChallengeSystem.Create;
  SplitPacket := TFragmentReader.Create;
  FLatencies := TList<TLatencyItem>.Create;
end;

destructor TXNativeClient.Destroy;
begin
  Challenge.Free;
  SplitPacket.Free;
  FLatencies.Free;

  inherited;
end;

end.
