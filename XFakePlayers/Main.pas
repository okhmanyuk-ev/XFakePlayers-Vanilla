unit Main;

interface

uses
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.Threading,
  System.SyncObjs,

  Winapi.Windows,
  Winapi.Messages,
  Winapi.WinSock,

  System.Generics.Collections,
  System.Generics.Defaults,

  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.Samples.Spin,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,
  Vcl.Menus,

  IdHTTP,
  IdSSLOpenSSL,

  Math,

  IdUDPServer,
  IdSocketHandle,
  IdBaseComponent,
  IdUDPBase,
  IdGlobal,

  About,
  RegExpr,
  XExtendedGameClient,
  Network,
  Socks5,
  Navigation,
  World,
  Common,
  Shared,
  Other,
  Default,
  Alias,
  Buffer,
  CVar,
  Protocol,
  BuildTime;

const WhiteListEnabled = True;

type
  TXFakePlayer = class(TXExtendedGameClient)
  strict private
    FLastLoopCmdTime,
    FLastRadioFloodTime: UInt32;
    FStatus: LStr;
  strict protected
    procedure SlowFrame; override; // radio flood
    procedure CL_Think; override; // voice flood
    procedure CL_Reconnect_F; override;
    procedure CL_VerifyResources; override;
    procedure CL_WriteCVarValue(Data: LStr); override;
    procedure CL_WriteCVarValue2(Index: Int32; CVar, Data: LStr); override;
    procedure CL_WriteCommand(Data: LStr); override;
  public
    function GetIdent: LStr;
    property LastLoopCmdTime: UInt32 read FLastLoopCmdTime write FLastLoopCmdTime;
    property Status: LStr read FStatus write FStatus;
  end;

  TEngine = class(TForm)
    ControlPanel: TPanel;
    Start: TButton;
    Stop: TButton;
    Label14: TLabel;
    PageControl1: TPageControl;
    Frame: TTimer;
    TabSheet2: TTabSheet;
    RichEdit1: TRichEdit;
    Edit2: TEdit;
    BAbout: TButton;
    TabSheet4: TTabSheet;
    EClients: TListView;
    TabSheet5: TTabSheet;
    PopupMenu1: TPopupMenu;
    disconnect1: TMenuItem;
    LabelTraffic: TLabel;
    ChartTrafficPanel: TPanel;
    ChartControlPanel: TPanel;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    RadioButton3: TRadioButton;
    ChartFramesPanel: TPanel;
    LabelFrames: TLabel;
    ChartEntitiesPanel: TPanel;
    LabelEntities: TLabel;
    ChartPacketsPanel: TPanel;
    LabelPackets: TLabel;
    TabSheet6: TTabSheet;
    TabSheet7: TTabSheet;
    PanelOptions: TPanel;
    Panel3: TPanel;
    MaxOnline: TSpinEdit;
    MaxOnlineEnabled: TCheckBox;
    DelayEnabled: TCheckBox;
    Delay: TSpinEdit;
    ListDelayEnabled: TCheckBox;
    ListDelay: TSpinEdit;
    Panel4: TPanel;
    Emulator: TComboBox;
    Label18: TLabel;
    NickName: TComboBox;
    Label19: TLabel;
    Team: TComboBox;
    Label20: TLabel;
    Panel5: TPanel;
    PanelServers: TPanel;
    Servers: TMemo;
    Panel8: TPanel;
    Panel9: TPanel;
    Panel2: TPanel;
    Proxies: TMemo;
    Panel7: TPanel;
    ProxiesEnabled: TCheckBox;
    Panel10: TPanel;
    Panel14: TPanel;
    Panel11: TPanel;
    TabSheet1: TTabSheet;
    Panel12: TPanel;
    Panel13: TPanel;
    Panel16: TPanel;
    LoopCommandsEnabled: TCheckBox;
    LoopCommands: TMemo;
    Panel15: TPanel;
    Panel17: TPanel;
    SignonCommandsEnabled: TCheckBox;
    SignonCommands: TMemo;
    Panel18: TPanel;
    Panel19: TPanel;
    Panel20: TPanel;
    Panel21: TPanel;
    Panel22: TPanel;
    Label2: TLabel;
    LoopDelay: TSpinEdit;
    VoiceFloodEnabled: TCheckBox;
    RadioFloodEnabled: TCheckBox;
    VoiceFloodDelay: TSpinEdit;
    VoiceFloodDelayEnabled: TCheckBox;
    RadioFloodDelayEnabled: TCheckBox;
    RadioFloodDelay: TSpinEdit;
    TabSheet3: TTabSheet;
    MoveSpeed: TTrackBar;
    Label12: TLabel;
    Label11: TLabel;
    Label1: TLabel;
    VoiceSize: TSpinEdit;
    VoiceCount: TSpinEdit;
    Label3: TLabel;
    Panel1: TPanel;
    Label4: TLabel;
    Panel6: TPanel;
    ProxyType: TRadioGroup;
    LogAI: TCheckBox;
    Label5: TLabel;
    CheckThreads: TSpinEdit;
    Label6: TLabel;
    CheckPeriod: TSpinEdit;
    ResolveIPAddressesForProxies: TButton;
    ResolveIPAddressesForServers: TButton;
    kill1: TMenuItem;
    LaunchAtStartup: TCheckBox;
    LogQCC: TCheckBox;
    LogStuffText: TCheckBox;
    LogDirector: TCheckBox;
    LogForwards: TCheckBox;
    LogSocks5: TCheckBox;
    RadioButton4: TRadioButton;
    AIEnabled: TCheckBox;
    DownloadWorld: TCheckBox;

    // native
    procedure OnLog(Sender: TObject; Data: LStr);
    procedure LimeLog(Data: LStr);
    procedure SilverLog(Data: LStr);
    procedure SilverLogEx(Ident, Title, Data: LStr);
    procedure OnError(Sender: TObject; Title, Data: LStr);
    procedure OnHint(Sender: TObject; Title, Data: LStr);
    procedure OnSocks5HandlerLog(Sender: TObject; S: LStr);

    // base game client
    procedure OnConnectionInitialized(Sender: TObject);
    procedure OnGameInitialized(Sender: TObject);
    procedure OnConnectionFinalized(Sender: TObject; Reason: LStr);
    procedure OnServerCommand(Sender: TObject; Data: LStr);
    procedure OnDirectorCommand(Sender: TObject; Data: LStr);

    procedure OnFileDownload(Sender: TObject; Filename: LStr);
    procedure OnStartDownloading(Sender: TObject; AFilesCount: Int);
    procedure OnDownloadProgress(Sender: TObject; AData: LStr);

    function RequestNavigation(Sender: TObject): PNavMesh;
    function RequestWorld(Sender: TObject): PWorld;

    // main engine
    procedure Edit2KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Edit2KeyPress(Sender: TObject; var Key: Char);
    procedure RadioButton10Click(Sender: TObject);
    procedure ServersChange(Sender: TObject);
    procedure ProxiesChange(Sender: TObject);
    procedure MoveSpeedChange(Sender: TObject);
    procedure BAboutClick(Sender: TObject);
    procedure BNameSelect(Sender: TObject);

    procedure LoadConfig;
    procedure SaveConfig;
    procedure LoadWhitelist;
    procedure CheckForUpdates;

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FinalizeAllClients;
    procedure FinalizeAllSocks5Handlers;
    procedure StartClick(Sender: TObject);
    procedure StopClick(Sender: TObject);
    procedure FormResize(Sender: TObject);

    procedure FrameTimer(Sender: TObject);
    procedure UpdateFormIndicators;
    procedure UpdateBottomLine;
    procedure CleanExternalObjects;
    procedure InitializeFakePlayer(var AClient: TXFakePlayer);
    procedure IncrementCurrentServer;
    procedure Socks5HandlerFrame;

    procedure FormShow(Sender: TObject);
    procedure ExecuteCommandForAll(Data: LStr);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure disconnect1Click(Sender: TObject);
    procedure kill1Click(Sender: TObject);
    procedure RadioButton1Click(Sender: TObject);
    procedure AI_EnabledClick(Sender: TObject);
    procedure DownloadWorldClick(Sender: TObject);
    procedure ProxyTypeClick(Sender: TObject);
    procedure ResolveIPAddressesForServersClick(Sender: TObject);
    procedure ResolveIPAddressesForProxiesClick(Sender: TObject);
  end;

var
  Engine: TEngine;
  Clients: TList<TXFakePlayer>;
  Whitelist: TList<TNETAdr>;
  Log: TLogSystem;
  Navigations: TList<TNavMesh>;
  Worlds: TList<TWorld>;

  Working, Paused: Boolean;

  Cmd_History_Id,
  LastClientInitTime,
  LastProxyAssociationInformTime,
  CurrentServer, CurrentProxy, Socks5ProxyIndex: Int32;

  Cmd_History: TStringList;

  LastSpeedCheckTime: UInt32;

  ListEndsTime,
  Socks5ListEndsTime: UInt32;

  NotAssociated,
  Associated: TList<TSocks5Handler>;

const
  Title = 'XFakePlayers';

  VERSION_MAJOR = 14;
  VERSION_MINOR = 0;
  IS_BETA = True;
  BETA_VERSION = 1;

  SCONFIG = 'xfakeplayers.sav';
var
  Header: LStr;

implementation

{$R *.dfm}

uses Proxy, Names;

function TXFakePlayer.GetIdent: LStr;
begin
  Result := Utf8ToAnsi(GetName) + ' (' + GetServer.ToString + ')';
end;

procedure TXFakePlayer.SlowFrame;
begin
  inherited;
end;

procedure TXFakePlayer.CL_Think;
const
  Radios: array [0..20] of LStr = ('coverme', 'takepoint', 'holdpos', 'regroup', 'followme', 'takingfire', 'go',
    'fallback', 'sticktog', 'getinpos', 'stormfront', 'report', 'roger', 'enemyspot', 'needbackup', 'sectorclear',
    'inposition', 'reportingin', 'getout', 'negative', 'enemydown');

  procedure SendRadio;
  begin
    CL_WriteCommand(Radios[Random(Length(Radios))]);
    FLastRadioFloodTime := GetTickCount;
  end;

  procedure SendVoice;
  var
    I, J: Int32;
  begin
    for I := 1 to Engine.VoiceCount.Value do
    begin
      BF.WriteUInt8(CLC_VOICEDATA);
      BF.WriteInt16(Engine.VoiceSize.Value);

      for J := 1 to Engine.VoiceSize.Value do
        BF.WriteUInt8(Random(MaxUInt8));
    end;
  end;
begin
  inherited;

  if GetState <> CS_GAME then
    Exit;

  if Engine.VoiceFloodEnabled.Checked then
    if Engine.VoiceFloodDelayEnabled.Checked then
      if GetTickCount - GameInitializingTime >= Engine.VoiceFloodDelay.Value then
        SendVoice
      else
    else
      SendVoice;

  if Engine.RadioFloodEnabled.Checked and (GetTickCount - FLastRadioFloodTime >= 1000) then
    if Engine.RadioFloodDelayEnabled.Checked then
      if GetTickCount - GameInitializingTime >= Engine.RadioFloodDelay.Value then
        SendRadio
      else
    else
      SendRadio;
end;

procedure TXFakePlayer.CL_Reconnect_F;
begin
  inherited;

  Synchronize(
  procedure
  begin
    Log.Add(GetIdent + ' reconnecting');
  end);
end;

procedure TXFakePlayer.CL_VerifyResources;
begin
  inherited;

  Status := 'verifying resources';
end;

procedure TXFakePlayer.CL_WriteCVarValue(Data: LStr);
begin
  inherited;

  Synchronize(
  procedure
  begin
    if Engine.LogQCC.Checked then
      Engine.SilverLogEx(GetIdent, 'QCC', Data);
  end);
end;

procedure TXFakePlayer.CL_WriteCVarValue2(Index: Int32; CVar, Data: LStr);
begin
  inherited;

  Synchronize(
  procedure
  begin
    if Engine.LogQCC.Checked then
      Engine.SilverLogEx(GetIdent, 'QCC2', CVar + ' "' + Data + '"');
  end);
end;

procedure TXFakePlayer.CL_WriteCommand(Data: LStr);
begin
  inherited;

  Synchronize(
  procedure
  begin
    if Engine.LogForwards.Checked then
      Engine.SilverLogEx(GetIdent, 'FORWARD', RemoveTBytes(Data));
  end);
end;

procedure TEngine.OnLog(Sender: TObject; Data: LStr);
var
  C: Int32;
begin
  if RichEdit1.Lines.Count >= 1000 then
    RichEdit1.Clear;

  with Richedit1 do
  begin
    C := GetTextLen{$IFDEF UNICODE} - Lines.Count {$ENDIF} + TIME_STR_LENGTH_EX;

    RichEdit1.Lines.Add(Data);

    SelStart := C;
    SelLength := Length(Data);
    SelAttributes.Color := clYellow;
  end;

  SendMessage(RichEdit1.Handle, EM_SCROLL, SB_LINEDOWN, 0);
  SendMessage(RichEdit1.Handle, EM_SCROLL, SB_LINEDOWN, 0);
end;

procedure TEngine.LimeLog(Data: LStr);
var
  C: Int32;
begin
  with Engine.Richedit1 do
  begin
    C := GetTextLen{$IFDEF UNICODE} - Lines.Count {$ENDIF} + TIME_STR_LENGTH_EX;

    Log.Add(Data);

    SelStart := C;
    SelLength := Length(Data);
    SelAttributes.Color := clLime;
  end;
end;

procedure TEngine.SilverLog(Data: LStr);
var
  C: Int32;
begin
  with Engine.Richedit1 do
  begin
    C := GetTextLen{$IFDEF UNICODE} - Lines.Count {$ENDIF} + TIME_STR_LENGTH_EX;

    Log.Add(Data);

    SelStart := C;
    SelLength := Length(Data);
    SelAttributes.Color := clSilver;
  end;
end;

procedure TEngine.SilverLogEx(Ident, Title, Data: LStr);
var
  C: Int32;
begin
  with Engine.Richedit1 do
  begin
    C := GetTextLen{$IFDEF UNICODE} - Lines.Count {$ENDIF} + TIME_STR_LENGTH_EX;

    Log.Add(Ident + ' [' + Title + '] ' + Data);


    Inc(C, Length(Ident) + 2);

    SelStart := C;
    SelLength := Length(Title);
    SelAttributes.Color := clLime;

    SelStart := C + Length(Title) + 2;
    SelLength := Length(Data);
    SelAttributes.Color := clSilver;    // Data
  end;
end;

procedure TEngine.OnError(Sender: TObject; Title, Data: LStr);
var
  C: Int32;
begin
  with Engine.Richedit1 do
  begin
    C := GetTextLen{$IFDEF UNICODE} - Lines.Count {$ENDIF} + TIME_STR_LENGTH_EX;

    Log.Add(TXFakePlayer(Sender).GetIdent + ' ' + '[ERROR] ' + Title + ' : ' + Data);

    Inc(C, Length(TXFakePlayer(Sender).GetIdent) + 1);

    SelStart := C + 1;
    SelLength := 5;
    SelAttributes.Color := clRed;

    SelStart := C + 8;
    SelLength := Length(Title);
    SelAttributes.Color := clSilver;    // title

    SelStart := C + 8 + Length(Title) + 3;
    SelLength := Length(Data);
    SelAttributes.Color := clSilver;    // data
  end;

  if data = 'badread' then
    Log.Add([TXFakePlayer(Sender).GetMessagesHistory]);
end;

procedure TEngine.OnHint(Sender: TObject; Title, Data: LStr);
var
  C: Int32;
begin
  if Title = 'AI' then
  begin
    TXFakePlayer(Sender).Status := Data;

    if LogAI.Checked then
      SilverLogEx(TXFakePlayer(Sender).GetIdent, 'AI', Data);
  end;
end;

procedure TEngine.OnSocks5HandlerLog(Sender: TObject; S: LStr);
var
  C: Int32;
  A: LStr;
begin
  if not LogSocks5.Checked then
    Exit;

  with Engine.Richedit1 do
  begin
    C := GetTextLen{$IFDEF UNICODE} - Lines.Count {$ENDIF} + TIME_STR_LENGTH;

    A := TSocks5Handler(Sender).GetProxy.ToString;
    Log.Add('[' + A + '] ' + S);

    SelStart := C + 4;
    SelLength := Length(A);
    SelAttributes.Color := clSilver;

    SelStart := C + 4 + Length(A) + 2;
    SelLength := Length(S);
    SelAttributes.Color := clSilver;
  end;
end;

procedure TEngine.OnConnectionInitialized(Sender: TObject);
begin
  with TXFakePlayer(Sender), NET do
    if HasAssociatedProxy then
    begin
      Log.Add(GetIdent + ' initialized connection via ' + AssociatedProxy.ToString);
      Status := 'initialized connection to ' + GetServer.ToString + ' via ' + AssociatedProxy.ToString;
    end
    else
    begin
      Log.Add(GetIdent + ' initialized connection');
      Status := 'initialized connection to ' + GetServer.ToString;
    end;
end;

procedure TEngine.OnGameInitialized(Sender: TObject);
var
  I: Int32;
begin
  with TXFakePlayer(Sender) do
  begin
    Log.Add(GetIdent + ' connected');
    Status := 'connected';
  end;

  if SignonCommandsEnabled.Checked then
    for I := 0 to Engine.SignonCommands.Lines.Count - 1 do
      TXFakePlayer(Sender).ExecuteCommand(Engine.SignonCommands.Lines[I]);

  TXFakePlayer(Sender).LastLoopCmdTime := GetTickCount;
end;

procedure TEngine.OnConnectionFinalized(Sender: TObject; Reason: LStr);
begin
  with TXFakePlayer(Sender) do
    Log.Add(GetIdent + ' disconnected, reason: "' + Reason + '"');
end;

procedure TEngine.OnServerCommand(Sender: TObject; Data: LStr);
begin
  if LogStuffText.Checked then
    SilverLogEx(TXFakePlayer(Sender).GetIdent, 'STUFFTEXT', Data);
end;

procedure TEngine.OnDirectorCommand(Sender: TObject; Data: LStr);
begin
  if LogDirector.Checked then
    SilverLogEx(TXFakePlayer(Sender).GetIdent, 'DIRECTOR', Data);
end;

procedure TEngine.OnFileDownload(Sender: TObject; Filename: LStr);
begin
  SilverLogEx(TXFakePlayer(Sender).GetIdent, 'DOWNLOADED', FileName);
end;

procedure TEngine.OnStartDownloading(Sender: TObject; AFilesCount: Int);
begin
  with TXFakePlayer(Sender) do
    Log.Add(GetIdent + ' begin ' + IntToStr(AFilesCount) + ' files downloading');
end;

procedure TEngine.OnDownloadProgress(Sender: TObject; AData: LStr);
begin
  with TXFakePlayer(Sender) do
    Log.Add(GetIdent + ' ' + AData);
end;

function TEngine.RequestNavigation(Sender: TObject): PNavMesh;
var
  I: Int32;
label
  L1;
begin
  Result := nil;

  L1:
  for I := 0 to Navigations.Count - 1 do
    if Navigations[I].Name = TXFakePlayer(Sender).GetServerInfo.ResolveMapName then
      Exit(@Navigations.List[I]);

  if Navigations.List[Navigations.Add(TNavMesh.Create)].LoadFromFile(TXFakePlayer(Sender).GetServerInfo.ResolveMapName) = NAV_LOAD_OK then
    goto L1;
end;

function TEngine.RequestWorld(Sender: TObject): PWorld;
var
  I: Int32;
label
  L1;
begin
  Result := nil;

  L1:
  for I := 0 to Worlds.Count - 1 do
    if Worlds[I].Name = TXFakePlayer(Sender).GetServerInfo.ResolveMapName then
      Exit(@Worlds.List[I]);

  if Worlds.List[Worlds.Add(TWorld.Create)].LoadFromFile(TXFakePlayer(Sender).GetServerInfo.ResolveMapName) = BSP_LOAD_OK then
    goto L1;
end;

procedure TEngine.Edit2KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = 38) and (Cmd_History.Count > 0) then
  begin
    Edit2.Text := Cmd_History[Cmd_History_Id - 1];
    Edit2.SelStart := Length(Edit2.Text);
    Dec(Cmd_History_Id);

    if Cmd_History_Id <= 0 then
      Cmd_History_Id := Cmd_History.Count;

    Clear(Key);
  end;
end;

procedure TEngine.Edit2KeyPress(Sender: TObject; var Key: Char);
var
  Data: LStr;
  I: Int32;
begin
  Data := AnsiToUtf8(Edit2.Text);

  if Key = #13 then
  begin
    if Trim(Data) = 'clear' then
      RichEdit1.Clear;

    Log.Add(']' + SS + Data);

    if Length(Trim(Data)) > 0 then
    begin
      Cmd_History.Add(Edit2.Text);
      Cmd_History_Id := Cmd_History.Count;
      ExecuteCommandForAll(Data);
    end;

    Edit2.Clear;
    Clear(Key);
    Exit;
  end;
end;

procedure TEngine.RadioButton10Click(Sender: TObject);
begin
  NamesForm.ShowModal;
end;

procedure TEngine.RadioButton1Click(Sender: TObject);
begin
  if RadioButton4.Checked then
  begin
    ChartTrafficPanel.Visible := False;
    ChartFramesPanel.Visible := True;
    ChartPacketsPanel.Visible := False;
    ChartEntitiesPanel.Visible := False;
  end
  else
    if RadioButton2.Checked then
    begin
      ChartTrafficPanel.Visible := True;
      ChartFramesPanel.Visible := False;
      ChartPacketsPanel.Visible := False;
      ChartEntitiesPanel.Visible := False;
    end
    else
      if RadioButton3.Checked then
      begin
        ChartTrafficPanel.Visible := False;
        ChartFramesPanel.Visible := False;
        ChartPacketsPanel.Visible := True;
        ChartEntitiesPanel.Visible := False;
      end
      else
        if RadioButton1.Checked then
        begin
          ChartTrafficPanel.Visible := False;
          ChartFramesPanel.Visible := False;
          ChartPacketsPanel.Visible := False;
          ChartEntitiesPanel.Visible := True;
        end;
end;

procedure TEngine.ServersChange(Sender: TObject);
begin
  if Servers.Lines.Count > 0 then
    Panel8.Caption := 'Servers (' + IntToStr(Servers.Lines.Count) + ')'
  else
    Panel8.Caption := 'Servers';
end;

procedure TEngine.ProxiesChange(Sender: TObject);
begin
  if Proxies.Lines.Count > 0 then
    ProxiesEnabled.Caption := 'Proxies: ' + IntToStr(Proxies.Lines.Count)
  else
    ProxiesEnabled.Caption := 'Proxies:';
end;

procedure TEngine.ProxyTypeClick(Sender: TObject);
begin
  case ProxyType.ItemIndex of
    0:
    begin
      CheckThreads.Enabled := True;
      CheckPeriod.Enabled := True;
      Label5.Enabled := True;
      Label6.Enabled := True;
    end;
    1:
    begin
      CheckThreads.Enabled := False;
      CheckPeriod.Enabled := False;
      Label5.Enabled := False;
      Label6.Enabled := False;
    end;
  end;
end;

procedure TEngine.MoveSpeedChange(Sender: TObject);
begin
  Label12.Caption := IntToStr(MoveSpeed.Position);

  ExecuteCommandForAll('cl_usercmd_count ' + IntToStr(MoveSpeed.Position));
end;

procedure TEngine.AI_EnabledClick(Sender: TObject);
begin
  ExecuteCommandForAll('cl_intellegence ' + IntToStr(UInt8(TCheckBox(Sender).Checked)));
end;

procedure TEngine.DownloadWorldClick(Sender: TObject);
begin
  ExecuteCommandForAll('cl_download_world ' + IntToStr(UInt8(TCheckBox(Sender).Checked)));
end;

procedure TEngine.BAboutClick(Sender: TObject);
var
  S: LStr;
begin
  case Random(3) of
    0: S := '.. dproto has been owned';
    1: S := '.. you can fuck dproto users with this software';
    2: S := '.. approved by gaben';
  end;

  AboutBox.Label1.Caption :=
    'Half-Life Extended Fake Players'  + sLineBreak +
    sLineBreak +
    'Author: ZeaL' + sLineBreak +
    '#icq: 646459042' + sLineBreak +
    sLineBreak +
    'based on XClient v1' + sLineBreak +
    'build: ' + BUILD_DATE + ' (' + XCLIENT_BUILD + ')' + sLineBreak +
    sLineBreak +
    'Thanks to: ratwayer, 2010kohtep, Mishel' + sLineBreak +
    sLineBreak + S;

  AboutBoxOfficialThreadURL := 'http://mmoru.com/board/showthread.php?t=578888';

  AboutBox.ShowModal;
end;

procedure TEngine.BNameSelect(Sender: TObject);
begin
  if NickName.ItemIndex = 1 then
    NamesForm.ShowModal;
end;

procedure TEngine.ResolveIPAddressesForProxiesClick(Sender: TObject);
var
  L: TStringList;
begin
  L := TStringList.Create;

  with TRegExpr.Create do
  begin
    L.AddStrings(Proxies.Lines);
    Proxies.Clear;
    Expression := '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{1,5}';

    if Exec(L.CommaText) then
      repeat
        Proxies.Lines.Add(Match[0])
      until (not ExecNext);

    Free;
  end;

  L.Free;
end;

procedure TEngine.ResolveIPAddressesForServersClick(Sender: TObject);
var
  L: TStringList;
begin
  L := TStringList.Create;

  with TRegExpr.Create do
  begin
    L.AddStrings(Servers.Lines);
    Servers.Clear;
    Expression := '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{1,5}';

    if Exec(L.CommaText) then
      repeat
        Servers.Lines.Add(Match[0])
      until (not ExecNext);

    Free;
  end;

  L.Free;
end;

procedure TEngine.LoadConfig;
var
  I, J: Int32;
begin
  if not FileExists(SCONFIG) then
    Exit;

  with TBufferEx2.Create do
  begin
    LoadFromFile(SCONFIG);

    PageControl1.TabIndex := ReadInt32;

    // general
    MaxOnlineEnabled.Checked := ReadBool8;
    MaxOnline.Value := ReadInt32;

    DelayEnabled.Checked := ReadBool8;
    Delay.Value := ReadInt32;

    ListDelayEnabled.Checked := ReadBool8;
    ListDelay.Value := ReadInt32;

    Emulator.ItemIndex := ReadInt32;
    NickName.ItemIndex := ReadInt32;
    Team.ItemIndex := ReadInt32;

    LaunchAtStartup.Checked := ReadBool8;

    // security
    ProxiesEnabled.Checked := ReadBool8;

    ProxyType.ItemIndex := ReadInt32;
    CheckThreads.Value := ReadInt32;
    CheckPeriod.Value := ReadInt32;

    // advanved

    LogQCC.Checked := ReadBool8;
    LogStuffText.Checked := ReadBool8;
    LogDirector.Checked := ReadBool8;
    LogForwards.Checked := ReadBool8;
    LogAI.Checked := ReadBool8;
    LogSocks5.Checked := ReadBool8;

    AIEnabled.Checked := ReadBool8;
    DownloadWorld.Checked := ReadBool8;

    MoveSpeed.Position := ReadInt32;

    // flood
    LoopCommandsEnabled.Checked := ReadBool8;
    SignonCommandsEnabled.Checked := ReadBool8;

    LoopDelay.Value := ReadInt32;

    VoiceFloodEnabled.Checked := ReadBool8;
    VoiceFloodDelayEnabled.Checked := ReadBool8;
    VoiceFloodDelay.Value := ReadInt32;

    VoiceSize.Value := ReadInt32;
    VoiceCount.Value := ReadInt32;

    RadioFloodEnabled.Checked := ReadBool8;
    RadioFloodDelayEnabled.Checked := ReadBool8;
    RadioFloodDelay.Value := ReadInt32;
    //

    Free;
  end;
end;

procedure TEngine.SaveConfig;
var
  I, J: Int32;
begin
  with TBufferEx2.Create do
  begin
    WriteInt32(PageControl1.TabIndex);

    // general
    WriteBool8(MaxOnlineEnabled.Checked);
    WriteInt32(MaxOnline.Value);

    WriteBool8(DelayEnabled.Checked);
    WriteInt32(Delay.Value);

    WriteBool8(ListDelayEnabled.Checked);
    WriteInt32(ListDelay.Value);

    WriteInt32(Emulator.ItemIndex);
    WriteInt32(NickName.ItemIndex);
    WriteInt32(Team.ItemIndex);

    WriteBool8(LaunchAtStartup.Checked);

    // security
    WriteBool8(ProxiesEnabled.Checked);

    WriteInt32(ProxyType.ItemIndex);
    WriteInt32(CheckThreads.Value);
    WriteInt32(CheckPeriod.Value);

    WriteBool8(LogQCC.Checked);
    WriteBool8(LogStuffText.Checked);
    WriteBool8(LogDirector.Checked);
    WriteBool8(LogForwards.Checked);
    WriteBool8(LogAI.Checked);
    WriteBool8(LogSocks5.Checked);

    WriteBool8(AIEnabled.Checked);
    WriteBool8(DownloadWorld.Checked);

    // gameplay

    WriteInt32(MoveSpeed.Position);

    // flood
    WriteBool8(LoopCommandsEnabled.Checked);
    WriteBool8(SignonCommandsEnabled.Checked);

    WriteInt32(LoopDelay.Value);

    WriteBool8(VoiceFloodEnabled.Checked);
    WriteBool8(VoiceFloodDelayEnabled.Checked);
    WriteInt32(VoiceFloodDelay.Value);

    WriteInt32(VoiceSize.Value);
    WriteInt32(VoiceCount.Value);

    WriteBool8(RadioFloodEnabled.Checked);
    WriteBool8(RadioFloodDelayEnabled.Checked);
    WriteInt32(RadioFloodDelay.Value);

    //
    SaveToFile(SCONFIG);

    Free;
  end;
end;

procedure TEngine.LoadWhitelist;
begin
  with Whitelist do
  begin
    // mishel
    Add(TNETAdr.Create(134, 249, 185, 215, 27015));
    Add(TNETAdr.Create(83, 142, 106, 91, 27015));
    Add(TNETAdr.Create(83, 142, 106, 91, 27016));
    Add(TNETAdr.Create(83, 142, 106, 91, 27020));
    Add(TNETAdr.Create(83, 142, 106, 91, 27021));
    Add(TNETAdr.Create(83, 142, 106, 91, 27022));
    Add(TNETAdr.Create(83, 142, 106, 91, 27023));
    Add(TNETAdr.Create(83, 142, 106, 91, 27024));
    Add(TNETAdr.Create(83, 142, 106, 91, 27025));
    Add(TNETAdr.Create(83, 142, 106, 91, 27026));
    Add(TNETAdr.Create(83, 142, 106, 91, 1000));
    Add(TNETAdr.Create(83, 142, 106, 91, 27027));
    Add(TNETAdr.Create(83, 142, 106, 91, 27028));

  end;
end;

procedure TEngine.CheckForUpdates;
begin
  TThread.CreateAnonymousThread(
  procedure
  var
    HTTP: TIdHTTP;
    SSL: TIdSSLIOHandlerSocketOpenSSL;
    S: LStr;
  begin
    HTTP := TIdHTTP.Create;
    SSL := TIdSSLIOHandlerSocketOpenSSL.Create;
    HTTP.HandleRedirects := True;
    HTTP.IOHandler := SSL;

    S := HTTP.Get('https://raw.githubusercontent.com/zeal1209/XFakePlayers/master/README.md');
   // S := HTTP.Get('https://github.com/zeal1209/XFakePlayers');
    alert([S]);

    SSL.Free;
    HTTP.Free;
  end).Start;
end;

procedure TEngine.StartClick(Sender: TObject);
var
  T: LStr;
  I: Int32;
begin
  if Paused then
  begin
    Paused := False;

    LimeLog('Resumed');

    Stop.Caption := 'Pause';
    Start.Caption := 'Start';

    Start.Enabled := False;
    Exit;
  end;

  Start.Enabled := False;
  Stop.Enabled := True;

  CurrentServer := 0;
  CurrentProxy := 0;

  LimeLog('Start');

  Working := True;
  //TrafficSeriesIn.Clear;
  //TrafficSeriesOut.Clear;
  //PacketsSeriesIn.Clear;
  //PacketsSeriesOut.Clear;
  //FramesSeries.Clear;
  //EntitiesSeries.Clear;

  ListEndsTime := 0;
  Socks5ListEndsTime := 0;
end;

procedure TEngine.FrameTimer(Sender: TObject);
label
  L1;
var
  I, J: Int32;
  N: TNETAdr;

const
  SLOW_FRAME_PERIOD = 1000;

begin
  if GetTickCount - LastSpeedCheckTime >= SLOW_FRAME_PERIOD then
  begin
    LastSpeedCheckTime := GetTickCount;

    UpdateFormIndicators;
    CleanExternalObjects;
  end;

  if MaxOnlineEnabled.Checked then
    for I := MaxOnline.Value to Clients.Count - 1 do
      Clients[I].ExecuteCommand('disconnect');

  while EClients.Items.Count < Clients.Count do
    with EClients.Items.Add do
    begin
      SubItems.Add(SS);
      SubItems.Add(SS);

      //Engine.Width := Engine.Width + 1;
      //Engine.Width := Engine.Width - 1;
      EClients.Width := EClients.Width + 1;
      EClients.Width := EClients.Width - 1;
    end;

  while EClients.Items.Count > Clients.Count do
    EClients.Items[0].Delete;

  for I := Clients.Count - 1 downto 0 do
    with Clients[I] do
    begin
      EClients.Items[I].Caption := Utf8ToAnsi(GetName);
      EClients.Items[I].SubItems[0] := GetServer.ToString;
      EClients.Items[I].SubItems[1] := Status;

      case GetState of
        CS_DISCONNECTED:
        begin
          Terminate;
          WaitFor;
          Free;
          Clients.Delete(I);
        end;

        CS_GAME:
          if GetTickCount - LastLoopCmdTime >= LoopDelay.Value then
          begin
            if LoopCommandsEnabled.Checked then
              for J := 0 to LoopCommands.Lines.Count - 1 do
                Clients[I].ExecuteCommand(LoopCommands.Lines[J]);

            LastLoopCmdTime := GetTickCount;
          end;
      end;
    end;

  UpdateBottomLine;

  // threads ->

  if not Working then
    Exit;

  if Paused then
    Exit;

  if ProxiesEnabled.Checked and (ProxyType.ItemIndex = 0) then
  begin
    Socks5HandlerFrame;

    if Associated.Count = 0 then
    begin
      if GetTickCount - LastProxyAssociationInformTime > 2500 then
      begin
        LimeLog('waiting for socks5 proxy association');
        LastProxyAssociationInformTime := GetTickCount;
      end;

      Exit;
    end;
  end;

  if MaxOnlineEnabled.Checked then
    if Clients.Count >= MaxOnline.Value then
      Exit;

  if ListDelayEnabled.Checked then
    if GetTickCount - ListEndsTime < ListDelay.Value then
      Exit;

  if DelayEnabled.Checked then
    if GetTickCount - LastClientInitTime < Delay.Value then
      Exit;

  for I := 0 to Clients.Count - 1 do
    if Clients[I].GetState in [CS_NONE..CS_CONNECTING] then
      Exit;

  N := TNETAdr.Create(Servers.Lines[CurrentServer]);

  if N.Port = 0 then
    N.Port := 27015;

  for I := 0 to Clients.Count - 1 do
    if (Clients[I].GetServer = N) and (Clients[I].GetState <= CS_VERIFYING_RESOURCES) then
    begin
      IncrementCurrentServer;
      Exit;
    end;

  if WhiteListEnabled then
    for I := 0 to Whitelist.Count - 1 do
      if N = Whitelist[I] then
      begin
        IncrementCurrentServer;
        Exit;
      end;

  Clients.Add(TXFakePlayer.Create);

  InitializeFakePlayer(Clients.List[Clients.Count - 1]);

  IncrementCurrentServer;
end;

procedure TEngine.UpdateFormIndicators;
var
  I: Int;
  SpeedIn, SpeedOut,
  PPSIn, PPSOut,
  TrafficIn, TrafficOut,
  PacketsIn, PacketsOut,
  FPS, FramesCount, EntitiesCount: UInt;
begin
  Clear(SpeedIn);
  Clear(SpeedOut);
  Clear(PPSIn);
  Clear(PPSOut);
  Clear(TrafficIn);
  Clear(TrafficOut);
  Clear(PacketsIn);
  Clear(PacketsOut);
  Clear(FPS);

  for I := 0 to Clients.Count - 1 do
    with Clients[I] do
    begin
      Inc(SpeedIn, NET.GetSpeedIn);
      Inc(SpeedOut, NET.GetSpeedOut);
      Inc(PPSIn, NET.GetPPSIn);
      Inc(PPSOut, NET.GetPPSOut);
      Inc(TrafficIn, NET.GetTrafficIn);
      Inc(TrafficOut, NET.GetTrafficOut);
      Inc(PacketsIn, NET.GetPacketsIn);
      Inc(PacketsOut, NET.GetPacketsOut);
      Inc(FPS, GetFramesPerSecond);
      Inc(FramesCount, GetFramesCount);
      Inc(EntitiesCOunt, GetEntitiesCount);
    end;

  // caption
  if SpeedIn + SpeedOut > 0 then
    Caption := Header + ' - Working... ' + BytesToTraffStr(SpeedIn + SpeedOut) + '/s. '
  else
    Caption := Header + ' - Idling... ';

  // details
  if Working then
  begin
    //TrafficSeriesIn.Add(SpeedIn / 1000);
    //TrafficSeriesOut.Add(SpeedOut / 1000);

    LabelTraffic.Caption := 'Total In: ' + BytesToTraffStr(TrafficIn) + ', Total Out: ' + BytesToTraffStr(TrafficOut);

    //PacketsSeriesIn.Add(PPSIn);
    //PacketsSeriesOut.Add(PPSOut);

    LabelPackets.Caption := 'Total In: ' + IntToStr(PacketsIn) + ', Total Out: ' + IntToStr(PacketsOut);

    //FramesSeries.Add(FPS);

    LabelFrames.Caption := 'Total Frames: ' + IntToStr(FramesCount);

    //EntitiesSeries.Add(EntitiesCount);

    LabelEntities.Caption := 'Entities: ' + IntToStr(EntitiesCount);
  end;
end;

procedure TEngine.UpdateBottomLine;
  function GetAliveCount: UInt32;
  var
    I: Int32;
  begin
    Result := 0;

    for I := 0 to Clients.Count - 1 do
      if Clients[I].IsAlive then
        Inc(Result);
  end;
var
  L: LStr;
begin
  if Working then
  begin
    if Servers.Lines.Count > 1 then
      L := '[' + IntToStr(Main.CurrentServer + 1) + '/' + IntToStr(Servers.Lines.Count) + '] ';

    if (ProxiesEnabled.Checked) and (ProxyType.ItemIndex = 0) then
      L := L + 'Tunnels: ' + IntToStr(Associated.Count) + '/' + IntToStr(NotAssociated.Count) + ', ';

    L := L + 'Online: ' + IntToStr(Clients.Count) + ', Alive: ' + IntToStr(GetAliveCount)
  end
  else
    L := SS;

  Label14.Caption := L;
end;

procedure TEngine.CleanExternalObjects;
var
  I, J: Int;
  B: Boolean;
begin
  // clean up navigations
  for I := Navigations.Count - 1 downto 0 do
  begin
    B := True;

    for J := 0 to Clients.Count - 1 do
      if Clients[J].GetNavigation = @Navigations.List[I] then
      begin
        B := False;
        Break;
      end;

    if B then
    begin
      Navigations[I].Free;
      Navigations.Delete(I);
    end;
  end;

  // clean up worlds
  for I := Worlds.Count - 1 downto 0 do
  begin
    B := True;

    for J := 0 to Clients.Count - 1 do
      if Clients[J].GetWorld = @Worlds.List[I] then
      begin
        B := False;
        Break;
      end;

    if B then
    begin
      Worlds[I].Free;
      Worlds.Delete(I);
    end;
  end;
end;

procedure TEngine.InitializeFakePlayer(var AClient: TXFakePlayer);
  procedure RecursiveNameSearch(var AClient: TXFakePlayer);
  var
    S: LStr;
  begin
    if NickName.ItemIndex = 1 then
      if NamesForm.Memo1.Lines.Count = 0 then
      begin
        LimeLog('No names found, using standart mode');
        NickName.ItemIndex := 0;
        RecursiveNameSearch(AClient);
      end
      else
        S := NamesForm.Memo1.Lines[Random(NamesForm.Memo1.Lines.Count)]
    else
      S := GetRandomString(Random(MAX_PLAYER_NAME - 1) + 1);

    AClient.ExecuteCommand('name "' + S + '"');
    TThread.NameThreadForDebugging(S, AClient.ThreadID);
  end;
begin
  LastClientInitTime := GetTickCount;

  AClient.OnError := OnError;
  AClient.OnHint := OnHint;

  AClient.OnConnectionInitialized := OnConnectionInitialized;
  AClient.OnGameInitialized := OnGameInitialized;
  AClient.OnConnectionFinalized := OnConnectionFinalized;
  AClient.OnServerCommand := OnServerCommand;
  AClient.OnDirectorCommand := OnDirectorCommand;

  AClient.OnFileDownload := OnFileDownload;
  AClient.OnStartDownloading := OnStartDownloading;
  AClient.OnDownloadProgress := OnDownloadProgress;

  AClient.RequestNavigation := RequestNavigation;
  AClient.RequestWorld := RequestWorld;

  with AClient do
  begin
    ExecuteCommand('cl_connection_attempts 0');
    ExecuteCommand(['cl_usercmd_count ', MoveSpeed.Position]);

    ExecuteCommand(['cl_intellegence ', Int32(AIEnabled.Checked)]);
    ExecuteCommand(['cl_download_world ', Int32(DownloadWorld.Checked)]);

    case Engine.Team.ItemIndex of
      0, 1, 2: ExecuteCommand(['cl_auto_jointeam_value ', Engine.Team.ItemIndex]);
      3: ExecuteCommand('cl_auto_jointeam_value 6');
    end;

    ExecuteCommand(['emulator ', Engine.Emulator.ItemIndex]);

    RecursiveNameSearch(AClient);

    if (Proxies.Lines.Count > 0) and ProxiesEnabled.Checked then
      case ProxyType.ItemIndex of
        0:
        begin
          if CurrentProxy > Associated.Count - 1 then
            CurrentProxy := 0;

          NET.AssociatedProxy := Associated[CurrentProxy].GetAssociatedAddr;
          ExecuteCommand('connect ' + Servers.Lines[CurrentServer]);

          Inc(CurrentProxy);
        end;
        1:
        begin
          if CurrentProxy > Proxies.Lines.Count - 1 then
            CurrentProxy := 0;

          ExecuteCommand('setinfo _ip "' + Servers.Lines[CurrentServer] + '"');
          ExecuteCommand('connect ' + Proxies.Lines[CurrentProxy]);

          Inc(CurrentProxy);
        end;
      end
    else
      ExecuteCommand('connect ' + Servers.Lines[CurrentServer]);

    Activate; // <- start framing here
  end;
end;

procedure TEngine.IncrementCurrentServer;
begin
  Inc(CurrentServer);

  if CurrentServer > Servers.Lines.Count - 1 then
  begin
    if (Servers.Lines.Count > 1) and ListDelayEnabled.Checked then
    begin
      ListEndsTime := GetTickCount;
      LimeLog('Restarting list with delay: ' + IntToStr(ListDelay.Value) + ' msec');
    end;

    CurrentServer := 0;
  end;
end;

procedure TEngine.Socks5HandlerFrame;
var
  I: Int;
  N: TNETAdr;
label
  L1;
begin
  for I := NotAssociated.Count - 1 downto 0 do
    with NotAssociated[I] do
      case GetState of
        S_DISCONNECTED:
        begin
          Free;
          NotAssociated.Delete(I);
        end;

        S_ASSOCIATED:
        begin
          Associated.Add(NotAssociated[I]);
          NotAssociated.Delete(I);
        end;
      end;

  for I := Associated.Count - 1 downto 0 do
    if Associated[I].GetState = S_DISCONNECTED then
      Associated.Delete(I);

  if GetTickCount - Socks5ListEndsTime < CheckPeriod.Value then
    Exit;

  if NotAssociated.Count >= CheckThreads.Value then
    Exit;

  if Socks5ProxyIndex > Proxies.Lines.Count - 1 then
    Exit;

  N := TNETAdr.Create(Proxies.Lines[Socks5ProxyIndex]);

  for I := 0 to Associated.Count - 1 do
    if Associated[I].GetAssociatedAddr.IP.AsLong = N.IP.AsLong then
    begin
      OnSocks5HandlerLog(Associated[I], 'already associated, skipping');
      goto L1;
    end;

  NotAssociated.Add(TSocks5Handler.Create(N));
  NotAssociated.Last.OnLog := OnSocks5HandlerLog;

  L1:
  Inc(Socks5ProxyIndex);

  if Socks5ProxyIndex > Proxies.Lines.Count - 1 then
  begin
    Socks5ProxyIndex := 0;
    Socks5ListEndsTime := GetTickCount;
  end;
end;

procedure TEngine.StopClick(Sender: TObject);
var
  I: Int32;
begin
  if not Paused then
  begin
    Paused := True;

    LimeLog('Paused');

    Start.Enabled := True;
    Start.Caption := 'Resume';
    Stop.Caption := 'Stop';

    Exit;
  end;

  Working := False;
  Paused := False;

  LimeLog('Stopping..');

  Start.Caption := 'Start';
  Stop.Caption := 'Pause';
  Stop.Enabled := False;

  FinalizeAllClients;
  FinalizeAllSocks5Handlers;

  Start.Enabled := True;

  LimeLog('Stop');
end;

procedure TEngine.FormResize(Sender: TObject);
begin
//
end;

procedure TEngine.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FinalizeAllClients;
  Log.Free;
  Cmd_History.Free;
  Clients.Free;
  Whitelist.Free;
  Associated.Free;
  NotAssociated.Free;
  Navigations.Free;
  Worlds.Free;

  Servers.Lines.SaveToFile('servers.txt');
  Proxies.Lines.SaveToFile('proxies.txt');
  LoopCommands.Lines.SaveToFile('loop_commands.txt');
  SignonCommands.Lines.SaveToFile('signon_commands.txt');

  SaveConfig;
end;

procedure TEngine.FormCreate(Sender: TObject);
begin
  Randomize;
  ReportMemoryLeaksOnShutdown := False;

  Header := Title + SS + IntToStr(VERSION_MAJOR);

  if VERSION_MINOR > 0 then
    Header := Header + SS + 'R' + IntToStr(VERSION_MINOR);

  if IS_BETA then
    Header := Header + SS + 'beta';

  if BETA_VERSION > 0 then
    Header := Header + SS + IntToStr(BETA_VERSION);

  Log := TLogSystem.Create;
  Log.SetFileName('xfakeplayers_logs', FormatDateTime('dd.MM.yyyy', Now) + '_' + FormatDateTime('HH.mm.ss', Now) + '.txt');
  Log.OnLog := OnLog;

  Log.Add(Header);
  Log.Add('Coding: ZeaL');
  Log.Add;

  Cmd_History := TStringList.Create;

  Clients := TList<TXFakePlayer>.Create;
  Whitelist := TList<TNETAdr>.Create;
  NotAssociated := TList<TSocks5Handler>.Create;
  Associated := TList<TSocks5Handler>.Create;
  Navigations := TList<TNavMesh>.Create;
  Worlds := TList<TWorld>.Create;

  LoadWhitelist;
end;

procedure TEngine.FinalizeAllClients;
var
  I: Int32;
begin
  for I := Clients.Count - 1 downto 0 do
    with Clients[I] do
    begin
      Terminate;
      WaitFor;
      Free;
      Clients.Delete(I);
    end;
end;

procedure TEngine.FinalizeAllSocks5Handlers;
var
  I: Int;
begin
  for I := NotAssociated.Count - 1 downto 0 do
    with NotAssociated[I] do
    begin
      OnLog(NotAssociated[I], 'terminated');
      Free;
      NotAssociated.Delete(I);
    end;

  for I := Associated.Count - 1 downto 0 do
    with Associated[I] do
    begin
      OnLog(Associated[I], 'terminated');
      Free;
      Associated.Delete(I);
    end;
end;

procedure TEngine.FormShow(Sender: TObject);
begin
  if FileExists('names.txt') then
  begin
    NamesForm.Memo1.Lines.LoadFromFile('names.txt');

    if NamesForm.Memo1.Lines.Count > 0 then
    begin
      Log.Add('Loaded ' + IntToStr(NamesForm.Memo1.Lines.Count) + ' names.');
      NickName.ItemIndex := 1;
    end;
  end;

  if FileExists('servers.txt') then
  begin
    Servers.Lines.LoadFromFile('servers.txt');

    if Servers.Lines.Count > 0 then
      Log.Add('Loaded ' + IntToStr(Servers.Lines.Count) + ' servers.');
  end;

  if FileExists('proxies.txt') then
  begin
    Proxies.Lines.LoadFromFile('proxies.txt');

    if Proxies.Lines.Count > 0 then
      Log.Add('Loaded ' + IntToStr(Proxies.Lines.Count) + ' proxies.');
  end;

  if FileExists('loop_commands.txt') then
  begin
    LoopCommands.Lines.LoadFromFile('loop_commands.txt');

    if LoopCommands.Lines.Count > 0 then
      Log.Add('Loaded ' + IntToStr(LoopCommands.Lines.Count) + ' loop commands.');
  end;

  if FileExists('signon_commands.txt') then
  begin
    SignonCommands.Lines.LoadFromFile('signon_commands.txt');

    if SignonCommands.Lines.Count > 0 then
      Log.Add('Loaded ' + IntToStr(SignonCommands.Lines.Count) + ' signon commands.');
  end;

  LoadConfig;
//  CheckForUpdates;

  if LaunchAtStartup.Checked then
    Start.Click;

  ChartTrafficPanel.BringToFront;
end;

procedure TEngine.ExecuteCommandForAll(Data: AnsiString);
var
  I: Int32;
begin
  for I := 0 to Clients.Count - 1 do
    Clients[I].ExecuteCommand(Data);
end;

procedure TEngine.PopupMenu1Popup(Sender: TObject);
begin
  if EClients.ItemIndex = -1 then
  begin
    PopupMenu1.Items[0].Enabled := False;
    PopupMenu1.Items[1].Enabled := False;
  end
  else
  begin
    PopupMenu1.Items[0].Enabled := True;
    PopupMenu1.Items[1].Enabled := True;
  end;
end;

procedure TEngine.disconnect1Click(Sender: TObject);
begin
  Clients[EClients.ItemIndex].ExecuteCommand('disconnect');
end;

procedure TEngine.kill1Click(Sender: TObject);
begin
  Clients[EClients.ItemIndex].ExecuteCommand('kill');
end;

end.

