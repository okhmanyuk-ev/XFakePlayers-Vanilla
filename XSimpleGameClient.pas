unit XSimpleGameClient;

interface

uses
  Windows,
  SysUtils,
  Math,

  XBaseGameClient,
  Protocol,
  Weapon,

  Default,
  Shared,
  CVar,
  GameEvent,
  Command,
  Alias,
  Network,
  Vector,
  Common;

type
  TOnEDeathMsg = procedure(Sender: TObject; Data: TDeathMsg) of object;
  TOnETextMsg = procedure(Sender: TObject; Data: TTextMsg) of object;
  TOnESayText = procedure(Sender: TObject; Data: TSayText) of object;
  TOnEVGUIMenu = procedure(Sender: TObject; Data: TVGUIMenu) of object;

const
  GAME_EVENT_LOG_LEVEL = 2;

type
  TXSimpleGameClient = class(TXBaseGameClient)
  strict private
    // events
    FOnETextMsg: TOnETextMsg;
    FOnESayText: TOnESayText;
    FOnEVGUIMenu: TOnEVGUIMenu;
    FOnEDeathMsg: TOnEDeathMsg;

    // private vars
    FRoundStartTime: Int32;
    FRoundTime: Int16;

    FShowMenu: TSimpleMenu; // for multiparts
  strict protected
    MenuAnswers: TAliasList;

    HideWeapon: UInt8; // hideweapon
    Health: UInt8;  // health
    FlashBat: UInt8; // flashbat, battery of flashlight percentage
    IsFlashlightActive: Boolean; // flashlight
    Battery: Int16;  // battery
    Weapons: TWeapons;  // weaponlist
    Ammo: TArray<UInt8>;  // ammox
    StatusValue: TArray<Int16>;  // statusvalue
    ServerName: LStr; // servername
    IsTeamplay: Boolean; // gamemode
    Teams: TTeams; // teamnames, teamscores,  using from players
    StatusIcons: TStatusIcons; // status icon
    BombState: TBombState; // bomb state
    RoundTime: Int32; // round time
    Money: Int32; // money
    ScreenFade: TScreenFade;
    Hostages: TArray<TVec3F>;

    RandomPC: UInt8; // tfc
    BuildState: Int16; // tfc
    IsSettingDetpack: UInt8; // tfc
    IsFeigning: UInt8; // tfc

  strict protected

    procedure SlowFrame; override;

    procedure CL_ParseEVGUIMenu;
    procedure CL_ParseEStatusValue;
    procedure CL_ParseEStatusText;
    procedure CL_ParseETeamNames;
    procedure CL_ParseEAmmoX;
    procedure CL_ParseEScreenFade;
    procedure CL_ParseEScreenShake;
    procedure CL_ParseEShowMenu;
    procedure CL_ParseEHideWeapon;
    procedure CL_ParseEItemPickup;
    procedure CL_ParseEWeapPickup; virtual;
    procedure CL_ParseEAmmoPickup;
    procedure CL_ParseEServerName;
    procedure CL_ParseEMOTD;
    procedure CL_ParseEGameMode;
    procedure CL_ParseETeamScore;
    procedure CL_ParseETeamInfo; virtual;
    procedure CL_ParseEScoreInfo;
    procedure CL_ParseEDeathMsg;
    procedure CL_ParseEInitHUD;
    procedure CL_ParseEResetHUD;
    procedure CL_ParseEWeaponList;
    procedure CL_ParseETextMsg;
    procedure CL_ParseESayText; virtual;
    procedure CL_ParseEHudText;
    procedure CL_ParseEBattery;
    procedure CL_ParseEDamage;
    procedure CL_ParseEHealth;
    procedure CL_ParseEFlashBat;
    procedure CL_ParseEFlashlight;
    procedure CL_ParseEGeiger;
    procedure CL_ParseECurWeapon;
    procedure CL_ParseEReqState;
    procedure CL_ParseEVoiceMask;

    procedure CL_ParseEHudTextArgs_CStrike;
    procedure CL_ParseELocation_CStrike;
    procedure CL_ParseESpecHealth2_CStrike;
    procedure CL_ParseEHLTV_CStrike;
    procedure CL_ParseEHostageK_CStrike;
    procedure CL_ParseEHostagePos_CStrike;
    procedure CL_ParseEClCorpse_CStrike;
    procedure CL_ParseEBombPickup_CStrike; virtual;
    procedure CL_ParseEBombDrop_CStrike; virtual;
    procedure CL_ParseERadar_CStrike;
    procedure CL_ParseEStatusIcon_CStrike;
    procedure CL_ParseEBarTime_CStrike;
    procedure CL_ParseEBlinkAcct_CStrike;
    procedure CL_ParseEArmorType_CStrike;
    procedure CL_ParseEMoney_CStrike;
    procedure CL_ParseERoundTime_CStrike;
    procedure CL_ParseESendAudio_CStrike;
    procedure CL_ParseEScoreAttrib_CStrike;
    procedure CL_ParseEDeathMsg_CStrike;
    procedure CL_ParseEResetHUD_CStrike;

    procedure CL_ParseEScoreInfo_DMC;

    procedure CL_ParseERandomPC_TFC;
    procedure CL_ParseEBuildSt_TFC;
    procedure CL_ParseEDetpack_TFC;
    procedure CL_ParseEFeign_TFC;
    procedure CL_ParseETeamScore_TFC;

    procedure CL_ParseETeamScore_DOD;
    procedure CL_ParseEScoreInfo_DOD;
    procedure CL_ParseEDeathMsg_DOD;
    procedure CL_ParseEWeaponList_DOD;

    procedure CL_FinalizeConnection(Reason: LStr; IsReconnect: Boolean = False); override;

    procedure CL_InitializeGameEngine; override;
    procedure CL_RegisterGameEvents; virtual;

    procedure CL_ReadETextMsg(Data: TTextMsg); virtual;
    procedure CL_ReadEMenu(Data: TSimpleMenu); virtual;
    procedure CL_ReadEVGUIMenu(Data: TVGUIMenu); virtual;
    procedure CL_ReadERoundTime(ATime: Int16); virtual;

    function CL_GetWeapon(AIndex: UInt32): PWeapon; overload;
    function CL_GetWeapon: PWeapon; overload;

    function CL_GetAmmo(AAmmoID: UInt8): UInt8;

    function CL_HasHostages: Boolean;

    procedure CMD_RegisterCommands; override;
    procedure CMD_RegisterCVars; override;

    procedure CL_MenuAnswer_F;

    procedure CL_DebugWeaponList_F;

  public
    constructor Create;
    destructor Destroy; override;

    property GetHideWeapon: UInt8 read HideWeapon;
    property GetHealth: UInt8 read Health;
    property GetFlashBat: UInt8 read FlashBat;
    property GetIsFlashlightActive: Boolean read IsFlashlightActive;
    property GetBattery: Int16 read Battery;
    property GetWeapons: TWeapons read Weapons;
    property GetStatusValue: TArray<Int16> read StatusValue;
    property GetIsTeamplay: Boolean read IsTeamplay;
    property GetTeams: TTeams read Teams;
    property GetStatusIcons: TStatusIcons read StatusIcons;
    property GetBombState: TBombState read BombState;
    property GetRoundTime: Int32 read RoundTime;
    property GetMoney: Int32 read Money;
    property GetHostages: TArray<TVec3F> read Hostages;

    function GetWeapon(AIndex: UInt32): PWeapon; overload;
    function GetWeapon: PWeapon; overload;

    property OnETextMsg: TOnETextMsg read FOnETextMsg write FOnETextMsg;
    property OnESayText: TOnESayText read FOnESayText write FOnESayText;
    property OnEVGUIMenu: TOnEVGUIMenu read FOnEVGUIMenu write FOnEVGUIMenu;
    property OnEDeathMsg: TOnEDeathMsg read FOnEDeathMsg write FOnEDeathMsg;

    property GetAmmo[Index: UInt8]: UInt8 read CL_GetAmmo;
  end;

implementation

procedure TXSimpleGameClient.SlowFrame;
begin
  inherited;

  if GetState >= CS_GAME then
    RoundTime := FRoundTime - (Round(Time) - FRoundStartTime);
end;

procedure TXSimpleGameClient.CL_ParseEVGUIMenu;
var
  Data: TVGUIMenu;
begin
  Clear(Data);

  with Data do
  begin
    Index := GMSG.ReadUInt8;
    {Keys := GMSG.ReadInt16;
    Time := GMSG.ReadUInt8;
    Name := GMSG.ReadString;}
  end;

  CL_ReadEVGUIMenu(Data);
end;

procedure TXSimpleGameClient.CL_ParseEStatusValue;
var
  Index: UInt8;
  Value: Int16;
begin
  {This message sends/updates the status values.
  For Flag, 1 is TeamRelation, 2 is PlayerID, and 3 is Health.
  For TeamRelation, 1 is Teammate player, 2 is Non-Teammate player, 3 is Hostage.
  If TeamRelation is Hostage, PlayerID will be 0 or will be not sent at all.
  Usually this is fired as a triple message, for example:

  [1,  2]  -  non-teammate player
  [2, 17]  -  player index is 17
  [3, 59]  -  player health is 59}

  Index := GMSG.ReadUInt8;
  Value := GMSG.ReadInt16;

  if Index > Length(StatusValue) then
    SetLength(StatusValue, Index);

  StatusValue[Index - 1] := Value;
end;

procedure TXSimpleGameClient.CL_ParseEStatusText;
var
  Flag: UInt8; // ?
  Data: LStr;
begin
  Flag := GMSG.ReadUInt8;
  Data := GMSG.ReadLStr;
end;

procedure TXSimpleGameClient.CL_ParseETeamNames;
var
  I: Int32;
begin
  SetLength(Teams, GMSG.ReadUInt8);

  for I := Low(Teams) to High(Teams) do
    with Teams[I] do
    begin
      Name := GameTitle(GMSG.ReadLStr);
    end;
end;

procedure TXSimpleGameClient.CL_ParseEAmmoX;
var
  AIndex: UInt8;
begin
  AIndex := GMSG.ReadUInt8;

  if AIndex > High(Ammo) then
    SetLength(Ammo, AIndex + 1);

  Ammo[AIndex] := GMSG.ReadUInt8;
end;

procedure TXSimpleGameClient.CL_ParseEScreenFade;
begin
  with ScreenFade do
  begin
    Duration := GMSG.ReadUInt16;
    StartTime := GetTickCount;
    HoldTime := GMSG.ReadUInt16;
    Flags := GMSG.ReadUInt16;
    GMSG.Read(Color, SizeOf(Color));
  end;
end;

procedure TXSimpleGameClient.CL_ParseEScreenShake;
var
  Amplitude, Duration, Frequency: Int16;
begin
  Amplitude := GMSG.ReadInt16;
  Duration := GMSG.ReadInt16;
  Frequency := GMSG.ReadInt16;
end;

procedure TXSimpleGameClient.CL_ParseEShowMenu;
var
  MultiPart: UInt8;
begin
  with FShowMenu do
  begin
    Keys := GMSG.ReadInt16;
    Time := GMSG.ReadUInt8;
    MultiPart := GMSG.ReadUInt8;
    Data :=  Data + Utf8ToAnsi(GMSG.ReadLStr);
  end;

  if MultiPart = 0 then
  begin
    CL_ReadEMenu(FShowMenu);
    Clear(FShowMenu);
  end;
end;

procedure TXSimpleGameClient.CL_ParseEHideWeapon;
begin
  HideWeapon := GMSG.ReadUInt8;
end;

procedure TXSimpleGameClient.CL_ParseEItemPickup;
var
  ItemName: LStr;
begin
  ItemName := GMSG.ReadLStr;
end;

procedure TXSimpleGameClient.CL_ParseEWeapPickup;
var
  AIndex: UInt8;
begin
  AIndex := GMSG.ReadUInt8;
end;

procedure TXSimpleGameClient.CL_ParseEAmmoPickup;
var
  AIndex, Amount: UInt8;
begin
  AIndex := GMSG.ReadUInt8;
  Amount := GMSG.ReadUInt8;
end;

procedure TXSimpleGameClient.CL_ParseEServerName;
begin
  ServerName := GMSG.ReadLStr;
end;

procedure TXSimpleGameClient.CL_ParseEMOTD;
var
  Flag: UInt8;
  Data: LStr;
begin
  Flag := GMSG.ReadUInt8;
  Data := GMSG.ReadLStr;
end;

procedure TXSimpleGameClient.CL_ParseEGameMode;
var
  B: UInt8;
begin
  B := GMSG.ReadUInt8;

  if B in [0..1] then
    IsTeamplay := B > 0
  else
    Error('CL_ParseEGameMode', ['Unknown GameMode: ', B]);
end;

procedure TXSimpleGameClient.CL_ParseETeamScore;
var
  TeamName: LStr;
  S: Int16;
  Team: PTeam;
begin
  TeamName := GameTitle(GMSG.ReadLStr);
  S := GMSG.ReadInt16;

  Team := FindTeamByName(@Teams, TeamName);

  if Team <> nil then
    Team.Score := S
  else
    Error('CL_ParseETeamScore', ['Unknown team name: "', TeamName, '"']);
end;

procedure TXSimpleGameClient.CL_ParseETeamInfo;
var
  Index: UInt8;
  Team: LStr;
begin
  Index := GMSG.ReadUInt8;
  Team := GameTitle(GMSG.ReadLStr);

  // 3rd party amx plugins can send incorrect index,
  // so we need to check it

  if CL_IsPlayerIndex(Index) then
  begin
    Players[Index - 1].Team := Team;

    // zombie plague can change teams during round,
    // we need to clear the radar

    Clear(Players[Index - 1].Radar);
  end;
end;

procedure TXSimpleGameClient.CL_ParseEScoreInfo;
var
  Index: UInt8;
  K, D, CID, TID: Int16;
begin
  Index := GMSG.ReadUInt8;
  K := GMSG.ReadInt16;
  D := GMSG.ReadInt16;
  CID := GMSG.ReadInt16;
  TID := GMSG.ReadInt16;

  if CL_IsPlayerIndex(Index) then
    with Players[Index - 1] do
    begin
      Kills := K;
      Deaths := D;
      ClassID := CID;
      TeamID := TID;
    end;
end;

procedure TXSimpleGameClient.CL_ParseEDeathMsg;
var
  Data: TDeathMsg;
  C: UInt8;
begin
  Clear(Data);

  with Data do
  begin
    Killer := nil;
    Victim := nil;

    C := GMSG.ReadUInt8;

    if C > 0 then
      Killer := @Players[C - 1];

    C := GMSG.ReadUInt8;

    if C > 0 then
      Victim := @Players[C - 1];

    Weapon := GMSG.ReadLStr;
  end;


  if Assigned(OnEDeathMsg) then
  begin
    Lock;
    OnEDeathMsg(Self, Data);
    UnLock;
  end;
end;

procedure TXSimpleGameClient.CL_ParseEInitHUD;
begin
  //
end;

procedure TXSimpleGameClient.CL_ParseEResetHUD;
begin
  //
end;

procedure TXSimpleGameClient.CL_ParseEWeaponList;
var
  W: TWeapon;
begin
  Clear(W);

  with W do
  begin
    Name := GMSG.ReadLStr;
    PrimaryAmmoID := GMSG.ReadUInt8;
    PrimaryAmmoMaxAmount := GMSG.ReadUInt8;
    SecondaryAmmoID := GMSG.ReadUInt8;
    SecondaryAmmoMaxAmount := GMSG.ReadUInt8;
    SlotID := GMSG.ReadUInt8;
    NumberInSlot := GMSG.ReadUInt8;
    Index := GMSG.ReadUInt8;
    Flags := GMSG.ReadUInt8;

    if Commands.IndexOf(Name) = -1 then
      Commands.Add(Name, CL_WriteCommand, ParseAfter(Name, '_'), CMD_HIDE);
  end;

  if High(Weapons) < W.Index then
    SetLength(Weapons, W.Index + 1);

  Weapons[W.Index] := W;
end;

procedure TXSimpleGameClient.CL_ParseETextMsg;
var
  Data: TTextMsg;
begin
  //1 - need decode
  //2 - simple decode (#Game_scoring)
  //3 - simple text  #Game_attack_teammate?
  //5 - radio

  Clear(Data);

  with Data do
  begin
    DType := GMSG.ReadUInt8;
    Data := ReadLine(GMSG.ReadLStr);

    if GMSG.Position < GMSG.Size then
      S1 := ReadLine(GMSG.ReadLStr);

    if GMSG.Position < GMSG.Size then
      S2 := ReadLine(GMSG.ReadLStr);

    if GMSG.Position < GMSG.Size then
      S3 := ReadLine(GMSG.ReadLStr);

    if GMSG.Position < GMSG.Size then
      S4 := ReadLine(GMSG.ReadLStr);
  end;

  CL_ReadETextMsg(Data);
end;

procedure TXSimpleGameClient.CL_ParseESayText;
var
  Index: UInt8;
  SayText: TSayText;
begin
  Index := GMSG.ReadUInt8;

  with SayText do
  begin
    if CL_IsPlayerIndex(Index) then
      Player := @Players[Index - 1]
    else
      Player := nil;

    if GMSG.Position < GMSG.Size then
      S1 := ReadLine(GMSG.ReadLStr);

    if GMSG.Position < GMSG.Size then
      S2 := ReadLine(GMSG.ReadLStr);

    if GMSG.Position < GMSG.Size then
      S3 := ReadLine(GMSG.ReadLStr);

    if GMSG.Position < GMSG.Size then
      S4 := ReadLine(GMSG.ReadLStr);
  end;

  if Assigned(OnESayText) then
  begin
    Lock;
    OnESayText(Self, SayText);
    UnLock;
  end;
end;

procedure TXSimpleGameClient.CL_ParseEHudText;
var
  TextCode: LStr;
  InitHUDStyle: UInt8;
begin
  TextCode := GMSG.ReadLStr;
  InitHUDStyle := GMSG.ReadUInt8;
end;

procedure TXSimpleGameClient.CL_ParseEBattery;
begin
  Battery := GMSG.ReadInt16;
end;

procedure TXSimpleGameClient.CL_ParseEDamage;
var
  DmgSave, DmgTake: UInt8;
  DmgType: UInt32;
  Origin: TVec3F;
begin
  DmgSave := GMSG.ReadUInt8;
  DmgTake := GMSG.ReadUInt8;
  DmgType := GMSG.ReadUInt32;
  Origin := GMSG.ReadCoord3;
end;

procedure TXSimpleGameClient.CL_ParseEHealth;
begin
  Health := GMSG.ReadUInt8;
end;

procedure TXSimpleGameClient.CL_ParseEFlashBat;
begin
  FlashBat := GMSG.ReadUInt8;
end;

procedure TXSimpleGameClient.CL_ParseEFlashlight;
begin
  IsFlashlightActive := GMSG.ReadBool8;
  FlashBat := GMSG.ReadUInt8;
end;

procedure TXSimpleGameClient.CL_ParseEGeiger;
var
  Distance: UInt8;
begin
  Distance := GMSG.ReadUInt8;
end;

procedure TXSimpleGameClient.CL_ParseECurWeapon;
var
  IsActive, WeaponID, ClipAmmo: UInt8;
begin
  IsActive := GMSG.ReadUInt8;
  WeaponID := GMSG.ReadUInt8;
  ClipAmmo := GMSG.ReadUInt8;
end;

procedure TXSimpleGameClient.CL_ParseEReqState;
begin
  CL_WriteCommand('VModEnable 1');
end;

procedure TXSimpleGameClient.CL_ParseEVoiceMask;
var
  AudiblePlayersIndexBitSum, ServerBannedPlayersIndexBitSum: Int32;
begin
  AudiblePlayersIndexBitSum := GMSG.ReadInt32;
  ServerBannedPlayersIndexBitSum := GMSG.ReadInt32;
end;

procedure TXSimpleGameClient.CL_ParseEHudTextArgs_CStrike;
var
  TextCode, SubMsgs: LStr;
  InitHUDStyle, NumberOfSubMessages: UInt8;
  I: Int32;
begin
  {Note: An example of TextCode could be "#Hint_you_have_the_bomb".
  Note: Prints message with specified style in titles.txt with Big signs (CS Default)
  Note: If you have problems specifying the last two arguments, use 1 and 0 respectively.
  Name:	HudTextArgs

  Structure:
    string	TextCode
    byte	InitHUDstyle
    byte	NumberOfSubMessages
    string	SubMsg
    string	SubMsg
    string	...}

  TextCode := GMSG.ReadLStr;
  InitHUDStyle := GMSG.ReadUInt8;
  NumberOfSubMessages := GMSG.ReadUInt8;

  for I := 0 to NumberOfSubMessages - 1 do
    GMSG.ReadLStr; // submsg
end;

procedure TXSimpleGameClient.CL_ParseELocation_CStrike;
var
  Index: UInt8;
  L: LStr;
begin
  Index := GMSG.ReadUInt8;
  L := GMSG.ReadLStr;

  if CL_IsPlayerIndex(Index) then
    with Players[Index - 1] do
    begin
      Location := GMSG.ReadLStr;
    end;
end;

procedure TXSimpleGameClient.CL_ParseESpecHealth2_CStrike;
var
  PlayerID, FHealth: UInt8;
begin
  FHealth := GMSG.ReadUInt8;
  PlayerID := GMSG.ReadUInt8;
end;

procedure TXSimpleGameClient.CL_ParseEHLTV_CStrike;
var
  PlayerID, Flags: UInt8;
  I: Int32;
begin
  PlayerID := GMSG.ReadUInt8;
  Flags := GMSG.ReadUInt8;

  if PlayerID > 0 then
    if Flags and 128 > 0 then
      Players[PlayerID - 1].Health := Flags and not 128
    else
  else
    for I := Low(Players) to High(Players) do
      with Players[I] do
        if IsCSAlive and (GetCSPlayerTeam in [CS_TEAM_T..CS_TEAM_CT]) then
          if Flags and 128 > 0 then
            Players[I].Health := Flags and not 128;
end;

procedure TXSimpleGameClient.CL_ParseEHostageK_CStrike;
var
  Index: UInt8;
begin
  Index := GMSG.ReadUInt8;

  if Index <= Length(Hostages) then
    Clear(Hostages[Index - 1]);
end;

procedure TXSimpleGameClient.CL_ParseEHostagePos_CStrike;
var
  Flag, Index: UInt8;
  Origin: TVec3F;
begin
  Flag := GMSG.ReadUInt8;
  Index := GMSG.ReadUInt8;
  Origin := GMSG.ReadCoord3;

  if Length(Hostages) < Index then
    SetLength(Hostages, Index);

  Hostages[Index - 1] := Origin;
end;

procedure TXSimpleGameClient.CL_ParseEClCorpse_CStrike;
var
  Model: LStr;
  Position, Angle: TVec3F;
  Delay: Int32;
  Sequence, ClassID, TeamID, PlayerID: UInt8;
begin
  Model := GMSG.ReadLStr;

  Position.X := GMSG.ReadInt32;
  Position.Y := GMSG.ReadInt32;
  Position.Z := GMSG.ReadInt32;

  Angle := GMSG.ReadCoord3;

  Delay := GMSG.ReadInt32;

  Sequence := GMSG.ReadUInt8;
//  ClassID := GMSG.ReadUInt8;
  TeamID := GMSG.ReadUInt8;
  PlayerID := GMSG.ReadUInt8;
end;

procedure TXSimpleGameClient.CL_ParseEBombPickup_CStrike;
begin
  BombState.Active := False;
end;

procedure TXSimpleGameClient.CL_ParseEBombDrop_CStrike;
begin
  BombState.Active := True;
  BombState.Position := GMSG.ReadCoord3;
  BombState.IsPlanted := GMSG.ReadBool8;
end;

procedure TXSimpleGameClient.CL_ParseERadar_CStrike;
var
  Index: UInt8;
  Position: TVec3F;
begin
  Index := GMSG.ReadUInt8;
  Position := GMSG.ReadCoord3;

  if CL_IsPlayerIndex(Index) then
    Players[Index - 1].Radar := Position;
end;

procedure TXSimpleGameClient.CL_ParseEStatusIcon_CStrike;
var
  Status: UInt8;
  Sprite: LStr;
  Color: TRGB;
  Icon: PStatusIcon;
begin
 {This message draws/removes the specified status HUD icon.
  For Status, 0 is Hide Icon, 1 is Show Icon, 2 is Flash Icon.
  Color arguments are optional and are required only if Status isn't equal to 0.}

  Status := GMSG.ReadUInt8;
  Sprite := GMSG.ReadLStr;

  if Status > 0 then
    GMSG.Read(Color, SizeOf(Color));

  Icon := FindStatusIconByName(@StatusIcons, Sprite);

  if Icon = nil then
    if Status > 0 then
      AddStatusIcon(StatusIcons, Status, Sprite, Color)
    else
      AddStatusIcon(StatusIcons, Status, Sprite)
  else
  begin
    Icon.Status := Status;

    if Status > 0 then
      Icon.Color := Color;
  end;
end;

procedure TXSimpleGameClient.CL_ParseEBarTime_CStrike;
var
  Duration: Int16;
begin
  Duration := GMSG.ReadInt16;
end;

procedure TXSimpleGameClient.CL_ParseEBlinkAcct_CStrike;
var
  BlinkAmt: UInt8;
begin
  BlinkAmt := GMSG.ReadUInt8;
end;

procedure TXSimpleGameClient.CL_ParseEArmorType_CStrike;
var
  Flag: UInt8;
begin
  Flag := GMSG.ReadUInt8;
end;

procedure TXSimpleGameClient.CL_ParseEMoney_CStrike;
var
  Flag: UInt8;
begin
  Money := GMSG.ReadInt32;
  Flag := GMSG.ReadUInt8;
end;

procedure TXSimpleGameClient.CL_ParseERoundTime_CStrike;
var
  Time: Int16;
begin
  Time := GMSG.ReadInt16;

  CL_ReadERoundTime(Time);
end;

procedure TXSimpleGameClient.CL_ParseESendAudio_CStrike;
var
  Sender: UInt8;
  AudioCode: LStr;
  Pitch: Int16;
begin
  Sender := GMSG.ReadUInt8;
  AudioCode := GMSG.ReadLStr;
  Pitch := GMSG.ReadInt16;
end;

procedure TXSimpleGameClient.CL_ParseEScoreAttrib_CStrike;
var
  Index,
  Attrib: UInt8;
begin
  Index := GMSG.ReadUInt8;
  Attrib := GMSG.ReadUInt8;

  if CL_IsPlayerIndex(Index) then
    with Players[Index - 1] do
    begin
      ScoreAttrib := Attrib;
    end;
end;

procedure TXSimpleGameClient.CL_ParseEDeathMsg_CStrike;
var
  Data: TDeathMsg;
  C: UInt8;
begin
  Clear(Data);

  with Data do
  begin
    Killer := nil;
    Victim := nil;

    C := GMSG.ReadUInt8;

    if C > 0 then
      Killer := @Players[C - 1];

    C := GMSG.ReadUInt8;

    if C > 0 then
      Victim := @Players[C - 1];

    IsHeadshot := GMSG.ReadBool8;

    Weapon := GMSG.ReadLStr;
  end;

  if Assigned(OnEDeathMsg) then
  begin
    Lock;
    OnEDeathMsg(Self, Data);
    UnLock;
  end;
end;

procedure TXSimpleGameClient.CL_ParseEResetHUD_CStrike;
var
  I: Int32;
begin
  // clear radar

  for I := Low(Players) to High(Players) do
    Clear(Players[I].Radar);
end;

procedure TXSimpleGameClient.CL_ParseEScoreInfo_DMC;
var
  Index: UInt8;
  K, D, ID: Int16;
begin
  Index := GMSG.ReadUInt8;
  K := GMSG.ReadInt16;
  D := GMSG.ReadInt16;
  ID := GMSG.ReadInt16;

  if CL_IsPlayerIndex(Index) then
    with Players[Index - 1] do
    begin
      Kills := K;
      Deaths := D;
      {ClassID :=ID};
    end;
end;

procedure TXSimpleGameClient.CL_ParseERandomPC_TFC;
begin
  RandomPC := GMSG.ReadUInt8;
end;

procedure TXSimpleGameClient.CL_ParseEBuildSt_TFC;
begin
  BuildState := GMSG.ReadInt16;
end;

procedure TXSimpleGameClient.CL_ParseEDetpack_TFC;
begin
  IsSettingDetpack := GMSG.ReadUInt8;
end;

procedure TXSimpleGameClient.CL_ParseEFeign_TFC;
begin
  IsFeigning := GMSG.ReadUInt8;
end;

procedure TXSimpleGameClient.CL_ParseETeamScore_TFC;
var
  TeamName: LStr;
  S, D: Int16;
  Team: PTeam;
begin
  TeamName := GameTitle(GMSG.ReadLStr);
  S := GMSG.ReadInt16;
  D := GMSG.ReadInt16;

  Team := FindTeamByName(@Teams, TeamName);

  if Team <> nil then
  begin
    Team.Score := S;
    Team.Deaths := D;
  end
  else
    Error('CL_ParseETeamScore_TFC', ['Unknown team name: "', TeamName, '"']);
end;

procedure TXSimpleGameClient.CL_ParseETeamScore_DOD;
var
  TeamID: UInt8;
  Score: Int16;
begin
  TeamID := GMSG.ReadUInt8;
  Score := GMSG.ReadInt16;
end;

procedure TXSimpleGameClient.CL_ParseEScoreInfo_DOD;
var
  Index: UInt8;
  K, D, ID: Int16;
begin
  Index := GMSG.ReadUInt8;
  K := GMSG.ReadInt16;
  D := GMSG.ReadInt16;
  ID := GMSG.ReadInt16;

  if CL_IsPlayerIndex(Index) then
    with Players[Index - 1] do
    begin
      Kills := K;
      Deaths := D;
      {ClassID :=ID};
    end;
end;

procedure TXSimpleGameClient.CL_ParseEDeathMsg_DOD;
var
  Data: TDeathMsg;
  C: UInt8;
begin
  Clear(Data);

  with Data do
  begin
    Killer := nil;
    Victim := nil;

    C := GMSG.ReadUInt8;

    if C > 0 then
      Killer := @Players[C - 1];

    C := GMSG.ReadUInt8;

    if C > 0 then
      Victim := @Players[C - 1];

    Weapon := {GMSG.ReadLStr}IntToStr(GMSG.ReadUInt8);
  end;

  if Assigned(OnEDeathMsg) then
  begin
    Lock;
    OnEDeathMsg(Self, Data);
    UnLock;
  end;
end;

procedure TXSimpleGameClient.CL_ParseEWeaponList_DOD;
var
  W: TWeapon;
begin
  {Clear(W);

  with W do
  begin
    Name := GMSG.ReadLStr;
    PrimaryAmmoID := GMSG.ReadUInt8;
    PrimaryAmmoMaxAmount := GMSG.ReadUInt8;
    SecondaryAmmoID := GMSG.ReadUInt8;
    SecondaryAmmoMaxAmount := GMSG.ReadUInt8;
    SlotID := GMSG.ReadUInt8;
    NumberInSlot := GMSG.ReadUInt8;
    Index := GMSG.ReadUInt8;
    Flags := GMSG.ReadUInt8;

    if Nulled(Commands.Find(Name)) then
      Commands.Add(Name, CL_WriteCommand, ParseAfter(Name, '_'), CMD_PROTECTED);

    Debug(T, [
      'Name: "', Name, '", ',
      'AID1: ', PrimaryAmmoID, ', ',
      'AMax1: ', PrimaryAmmoMaxAmount, ', ',
      'AID2: ', SecondaryAmmoID, ', ',
      'AMax2: ', SecondaryAmmoMaxAmount, ', ',
      'Slot: ', SlotID, ', ',
      'NumberInSlot: ', NumberInSlot, ', ',
      'Index: ', Index, ', ',
      'Flags: ', Flags], GAME_EVENT_LOG_LEVEL);
  end;

  if High(WeaponList) < W.Index then
    SetLength(WeaponList, W.Index + 1);

  WeaponList[W.Index] := W;}
end;

procedure TXSimpleGameClient.CL_FinalizeConnection(Reason: LStr; IsReconnect: Boolean = False);
var
  I: Int32;
begin
  // delete commands from weaponlist

  for I := Low(Weapons) to High(Weapons) do
    if Weapons[I].Index > 0 then // <-
      if Commands.IndexOf(Weapons[I].Name) <> -1 then
        Commands.Delete(Commands.IndexOf(Weapons[I].Name));

  Clear(HideWeapon);
  Clear(Health);
  Clear(FlashBat);
  Clear(IsFlashlightActive);
  Clear(Battery);
  Clear(Weapons);
  Clear(Ammo);
  Clear(StatusValue);
  Clear(IsTeamplay);

  if not IsReconnect then
    Clear(Teams);

  Clear(FRoundStartTime);
  Clear(FRoundTime);

  Clear(RoundTime);
  Clear(StatusIcons);
  Clear(BombState);
  Clear(Money);
  Clear(ScreenFade);

  inherited;
end;

procedure TXSimpleGameClient.CL_InitializeGameEngine;
begin
  inherited;

  case GetEngineType of
    E_CSTRIKE,
    E_CZERO:
    begin
      SetLength(Teams, 4);
      Teams[0].Name := 'UNASSIGNED';
      Teams[1].Name := 'TERRORIST';
      Teams[2].Name := 'CT';
      Teams[3].Name := 'SPECTATOR';
    end;
  end;

  CL_RegisterGameEvents;
end;

procedure TXSimpleGameClient.CL_RegisterGameEvents;
begin
  with GameEvents do
    case GetEngineType of
      E_VALVE:
      begin
        AddCallback('VGUIMenu', CL_ParseEVGUIMenu);  // need confirmation, if confirmed as is, then change vguimenu_dod to this.
        AddCallback('StatusValue', CL_ParseEStatusValue);
        AddCallback('StatusText', CL_ParseEStatusText);
        AddCallback('TeamNames', CL_ParseETeamNames);
        AddCallback('AmmoX', CL_ParseEAmmoX);
        AddCallback('ScreenFade', CL_ParseEScreenFade);
        AddCallback('ScreenShake', CL_ParseEScreenShake);
        AddCallback('ShowMenu', CL_ParseEShowMenu);
        AddCallback('SetFOV', nil);
        AddCallback('HideWeapon', CL_ParseEHideWeapon);
        AddCallback('ItemPickup', CL_ParseEItemPickup);
        AddCallback('WeapPickup', CL_ParseEWeapPickup);
        AddCallback('AmmoPickup', CL_ParseEAmmoPickup);
        AddCallback('ServerName', CL_ParseEServerName);
        AddCallback('MOTD', CL_ParseEMOTD);
        AddCallback('GameMode', CL_ParseEGameMode);
        AddCallback('TeamScore', CL_ParseETeamScore);
        AddCallback('TeamInfo', CL_ParseETeamInfo);
        AddCallback('ScoreInfo', CL_ParseEScoreInfo);
        AddCallback('DeathMsg', CL_ParseEDeathMsg);
        AddCallback('GameTitle', nil);
        AddCallback('InitHUD', CL_ParseEInitHUD);
        AddCallback('ResetHUD', CL_ParseEResetHUD);
        AddCallback('WeaponList', CL_ParseEWeaponList);
        AddCallback('TextMsg', CL_ParseETextMsg);
        AddCallback('SayText', CL_ParseESayText);
        AddCallback('HudText', CL_ParseEHudText);
        AddCallback('Train', nil);
        AddCallback('Battery', CL_ParseEBattery);
        AddCallback('Damage', CL_ParseEDamage);
        AddCallback('Health', CL_ParseEHealth);
        AddCallback('FlashBat', CL_ParseEFlashBat);
        AddCallback('Flashlight', CL_ParseEFlashlight);
        AddCallback('Geiger', CL_ParseEGeiger);
        AddCallback('CurWeapon', CL_ParseECurWeapon);
        AddCallback('SelAmmo', nil);
        AddCallback('ReqState', CL_ParseEReqState);
        AddCallback('VoiceMask', CL_ParseEVoiceMask);
      end;
      E_CSTRIKE,
      E_CZERO:
      begin
        AddCallback('HudTextArgs', CL_ParseEHudTextArgs_CStrike);
        AddCallback('ShowTimer', nil);
        AddCallback('Fog', nil);
        AddCallback('Brass', nil);
        AddCallback('BotProgress', nil);
        AddCallback('Location', CL_ParseELocation_CStrike);
        AddCallback('ItemStatus', nil);
        AddCallback('BarTime2', nil);
        AddCallback('SpecHealth2', CL_ParseESpecHealth2_CStrike);
        AddCallback('BuyClose', nil);
        AddCallback('BotVoice', nil);
        AddCallback('Scenario', nil);
        AddCallback('TaskTime', nil);
        AddCallback('ShadowIdx', nil);
        AddCallback('CZCareerHUD', nil);
        AddCallback('CZCareer', nil);
        AddCallback('ReceiveW', nil);
        AddCallback('ADStop', nil);
        AddCallback('ForceCam', nil);
        AddCallback('SpecHealth', nil);
        AddCallback('HLTV', CL_ParseEHLTV_CStrike);
        AddCallback('HostageK', CL_ParseEHostageK_CStrike);
        AddCallback('HostagePos', CL_ParseEHostagePos_CStrike);
        AddCallback('ClCorpse', CL_ParseEClCorpse_CStrike);
        AddCallback('BombPickup', CL_ParseEBombPickup_CStrike);
        AddCallback('BombDrop', CL_ParseEBombDrop_CStrike);
        AddCallback('AllowSpec', nil);
        AddCallback('TutorClose', nil);
        AddCallback('TutorState', nil);
        AddCallback('TutorLine', nil);
        AddCallback('TutorText', nil);
        AddCallback('VGUIMenu', CL_ParseEVGUIMenu);
        AddCallback('Spectator', nil);
        AddCallback('Radar', CL_ParseERadar_CStrike);
        AddCallback('NVGToggle', nil);
        AddCallback('Crosshair', nil);
        AddCallback('ReloadSound', nil);
        AddCallback('BarTime', CL_ParseEBarTime_CStrike);
        AddCallback('StatusIcon', CL_ParseEStatusIcon_CStrike);
        AddCallback('StatusText', CL_ParseEStatusText);
        AddCallback('StatusValue', CL_ParseEStatusValue);
        AddCallback('BlinkAcct', CL_ParseEBlinkAcct_CStrike);
        AddCallback('ArmorType', CL_ParseEArmorType_CStrike);
        AddCallback('Money', CL_ParseEMoney_CStrike);
        AddCallback('RoundTime', CL_ParseERoundTime_CStrike);
        AddCallback('SendAudio', CL_ParseESendAudio_CStrike);
        AddCallback('AmmoX', CL_ParseEAmmoX);
        AddCallback('ScreenFade', CL_ParseEScreenFade);
        AddCallback('ScreenShake', CL_ParseEScreenShake);
        AddCallback('ShowMenu', CL_ParseEShowMenu);
        AddCallback('SetFOV', nil);
        AddCallback('HideWeapon', CL_ParseEHideWeapon);
        AddCallback('ItemPickup', CL_ParseEItemPickup);
        AddCallback('WeapPickup', CL_ParseEWeapPickup);
        AddCallback('AmmoPickup', CL_ParseEAmmoPickup);
        AddCallback('ServerName', CL_ParseEServerName);
        AddCallback('MOTD', CL_ParseEMOTD);
        AddCallback('GameMode', CL_ParseEGameMode);
        AddCallback('TeamScore', CL_ParseETeamScore);
        AddCallback('TeamInfo', CL_ParseETeamInfo);
        AddCallback('ScoreInfo', CL_ParseEScoreInfo);
        AddCallback('ScoreAttrib', CL_ParseEScoreAttrib_CStrike);
        AddCallback('DeathMsg', CL_ParseEDeathMsg_CStrike);
        AddCallback('GameTitle', nil);
        AddCallback('ViewMode', nil);
        AddCallback('InitHUD', CL_ParseEInitHUD);
        AddCallback('ResetHUD', CL_ParseEResetHUD_CStrike);
        AddCallback('WeaponList', CL_ParseEWeaponList);
        AddCallback('TextMsg', CL_ParseETextMsg);
        AddCallback('SayText', CL_ParseESayText);
        AddCallback('HudText', CL_ParseEHudText);
        AddCallback('HudTextPro', nil);
        AddCallback('Train', nil);
        AddCallback('Battery', CL_ParseEBattery);
        AddCallback('Damage', CL_ParseEDamage);
        AddCallback('Health', CL_ParseEHealth);
        AddCallback('FlashBat', CL_ParseEFlashBat);
        AddCallback('Flashlight', CL_ParseEFlashlight);
        AddCallback('Geiger', CL_ParseEGeiger);
        AddCallback('CurWeapon', CL_ParseECurWeapon);
        AddCallback('ReqState', CL_ParseEReqState);
        AddCallback('VoiceMask', CL_ParseEVoiceMask);
      end;
      E_DMC:
      begin
        AddCallback('StatusValue', CL_ParseEStatusValue);
        AddCallback('StatusText', CL_ParseEStatusText);
        AddCallback('QItems', nil);
        AddCallback('AmmoX', CL_ParseEAmmoX);
        AddCallback('ScreenFade', CL_ParseEScreenFade);
        AddCallback('ScreenShake', CL_ParseEScreenShake);
        AddCallback('ShowMenu', CL_ParseEShowMenu);
        AddCallback('SetFOV', nil);
        AddCallback('HideWeapon', CL_ParseEHideWeapon);
        AddCallback('ItemPickup', CL_ParseEItemPickup);
        AddCallback('WeapPickup', CL_ParseEWeapPickup);
        AddCallback('AmmoPickup', CL_ParseEAmmoPickup);
        AddCallback('ServerName', CL_ParseEServerName);
        AddCallback('MOTD', CL_ParseEMOTD);
        AddCallback('GameMode', CL_ParseEGameMode);
        AddCallback('TeamScore', CL_ParseETeamScore);
        AddCallback('TeamInfo', CL_ParseETeamInfo);
        AddCallback('ScoreInfo', CL_ParseEScoreInfo_DMC); // dmc
        AddCallback('DeathMsg', CL_ParseEDeathMsg);
        AddCallback('GameTitle', nil);
        AddCallback('InitHUD', CL_ParseEInitHUD);
        AddCallback('ResetHUD', CL_ParseEResetHUD);
        AddCallback('WeaponList', CL_ParseEWeaponList);
        AddCallback('TextMsg', CL_ParseETextMsg);
        AddCallback('SayText', CL_ParseESayText);
        AddCallback('HudText', CL_ParseEHudText);
        AddCallback('Train', nil);
        AddCallback('Battery', CL_ParseEBattery);
        AddCallback('Damage', CL_ParseEDamage);
        AddCallback('Health', CL_ParseEHealth);
        AddCallback('FlashBat', CL_ParseEFlashBat);
        AddCallback('Flashlight', CL_ParseEFlashlight);
        AddCallback('Geiger', CL_ParseEGeiger);
        AddCallback('CurWeapon', CL_ParseECurWeapon);
        AddCallback('SelAmmo', nil);
        AddCallback('ReqState', CL_ParseEReqState);
        AddCallback('VoiceMask', CL_ParseEVoiceMask);
      end;
      E_TFC:
      begin
        AddCallback('RandomPC', CL_ParseERandomPC_TFC);
        AddCallback('BuildSt', CL_ParseEBuildSt_TFC);
        AddCallback('VGUIMenu', CL_ParseEVGUIMenu);
        AddCallback('Detpack', CL_ParseEDetpack_TFC);
        AddCallback('Feign', CL_ParseEFeign_TFC);
        AddCallback('TeamNames', CL_ParseETeamNames);
        AddCallback('ValClass', nil);
        AddCallback('ResetFade', nil); // set screenfade to zero ?
        AddCallback('SpecFade', nil);
        AddCallback('AllowSpec', nil);
        AddCallback('Spectator', nil);
        AddCallback('Bench', nil);
        AddCallback('AmmoX', CL_ParseEAmmoX);
        AddCallback('ScreenFade', CL_ParseEScreenFade);
        AddCallback('ScreenShake', CL_ParseEScreenShake);
        AddCallback('ShowMenu', CL_ParseEShowMenu);
        AddCallback('SetFOV', nil);
        AddCallback('HideWeapon', CL_ParseEHideWeapon);
        AddCallback('ItemPickup', CL_ParseEItemPickup);
        AddCallback('WeapPickup', CL_ParseEWeapPickup);
        AddCallback('AmmoPickup', CL_ParseEAmmoPickup);
        AddCallback('ServerName', CL_ParseEServerName);
        AddCallback('MOTD', CL_ParseEMOTD);
        AddCallback('GameMode', CL_ParseEGameMode);
        AddCallback('TeamScore', CL_ParseETeamScore);
        AddCallback('TeamInfo', CL_ParseETeamInfo);
        AddCallback('ScoreInfo', CL_ParseEScoreInfo);
        AddCallback('DeathMsg', CL_ParseEDeathMsg);
        AddCallback('GameTitle', nil);
        AddCallback('ViewMode', nil);
        AddCallback('InitHUD', CL_ParseEInitHUD);
        AddCallback('ResetHUD', CL_ParseEResetHUD);
        AddCallback('WeaponList', CL_ParseEWeaponList);
        AddCallback('StatusValue', CL_ParseEStatusValue);
        AddCallback('StatusText', CL_ParseEStatusText);
        AddCallback('SpecHealth', nil);
        AddCallback('TextMsg', CL_ParseETextMsg);
        AddCallback('StatusIcon', nil);
        AddCallback('SayText', CL_ParseESayText);
        AddCallback('HudText', {CL_ParseEHudText}nil); // tfc
        AddCallback('Concuss', nil);
        AddCallback('Items', nil);
        AddCallback('Train', nil);
        AddCallback('SecAmmoIcon', nil);
        AddCallback('SecAmmoVal', nil);
        AddCallback('Battery', CL_ParseEBattery);
        AddCallback('Damage', CL_ParseEDamage);
        AddCallback('Health', CL_ParseEHealth);
        AddCallback('FlashBat', CL_ParseEFlashBat);
        AddCallback('Flashlight', CL_ParseEFlashlight);
        AddCallback('Geiger', CL_ParseEGeiger);
        AddCallback('CurWeapon', CL_ParseECurWeapon);
        AddCallback('SelAmmo', nil);
        AddCallback('ReqState', CL_ParseEReqState);
        AddCallback('VoiceMask', CL_ParseEVoiceMask);
      end;
      E_DOD:
      begin
        AddCallback('TimeLeft', nil);
        AddCallback('ClCorpse', nil); // dod
        AddCallback('CurMarker', nil);
        AddCallback('HandSignal', nil);
        AddCallback('CapMsg', nil);
        AddCallback('UseSound', nil);
        AddCallback('RoundState', nil);
        AddCallback('ReloadDone', nil);
        AddCallback('ObjScore', nil);
        AddCallback('Weather', nil);
        AddCallback('PShoot', nil);
        AddCallback('YouDied', nil);
        AddCallback('PTeam', nil);
        AddCallback('PClass', nil);
        AddCallback('ScoreShort', nil);
        AddCallback('PStatus', nil);
        AddCallback('Frags', nil);
        AddCallback('ShowMenu', CL_ParseEShowMenu);
        AddCallback('MapMarker', nil);
        AddCallback('ClanTimer', nil);
        AddCallback('StatusValue', nil); // dod
        AddCallback('PlayersIn', nil);
        AddCallback('ClientAreas', nil);
        AddCallback('HLTV', CL_ParseEHLTV_CStrike); // need confirmation
        AddCallback('TimerStatus', nil);
        AddCallback('CancelProg', nil);
        AddCallback('ProgUpdate', nil);
        AddCallback('StartProgF', nil);
        AddCallback('StartProg', nil);
        AddCallback('SetObj', nil);
        AddCallback('InitObj', nil);
        AddCallback('CameraView', nil);
        AddCallback('Object', nil);
        AddCallback('Scope', nil);
        AddCallback('WaveStatus', nil);
        AddCallback('WaveTime', nil);
        AddCallback('Spectator', nil);
        AddCallback('VGUIMenu', CL_ParseEVGUIMenu); // dod
        AddCallback('BloodPuff', nil);
        AddCallback('AmmoShort', nil);
        AddCallback('AmmoX', CL_ParseEAmmoX);
        AddCallback('ScreenFade', CL_ParseEScreenFade);
        AddCallback('ScreenShake', CL_ParseEScreenShake);
        AddCallback('SetFOV', nil);
        AddCallback('HideWeapon', CL_ParseEHideWeapon);
        AddCallback('WeapPickup', CL_ParseEWeapPickup);
        AddCallback('AmmoPickup', CL_ParseEAmmoPickup);
        AddCallback('ServerName', CL_ParseEServerName);
        AddCallback('MOTD', CL_ParseEMOTD);
        AddCallback('TeamScore', CL_ParseETeamScore_DOD); // dod
        AddCallback('ResetSens', nil);
        AddCallback('GameRules', nil);
        AddCallback('ScoreInfo', CL_ParseEScoreInfo_DOD); // dod
        AddCallback('DeathMsg', CL_ParseEDeathMsg_DOD); // dod
        AddCallback('InitHUD', CL_ParseEInitHUD);
        AddCallback('ResetHUD', CL_ParseEResetHUD);
        AddCallback('WeaponList', CL_ParseEWeaponList_DOD); // dod
        AddCallback('TextMsg', CL_ParseETextMsg);
        AddCallback('SayText', CL_ParseESayText);
        AddCallback('HudText', CL_ParseEHudText);
        AddCallback('Health', CL_ParseEHealth);
        AddCallback('CurWeapon', CL_ParseECurWeapon);
        AddCallback('ReqState', CL_ParseEReqState);
        AddCallback('VoiceMask', CL_ParseEVoiceMask);
      end;
      E_GEARBOX: {nothing now};
      E_RICOCHET:
      begin

{13:17:59 - CL_ParseNewUserMsg : Index: 102, Size: 1, Name: "Frozen"
13:17:59 - CL_ParseNewUserMsg : Index: 101, Size: 2, Name: "Reward"
13:17:59 - CL_ParseNewUserMsg : Index: 100, Size: 1, Name: "Powerup"
13:17:59 - CL_ParseNewUserMsg : Index: 99, Size: 255, Name: "EndRnd"
13:17:59 - CL_ParseNewUserMsg : Index: 98, Size: 255, Name: "StartRnd"
13:17:59 - CL_ParseNewUserMsg : Index: 97, Size: 2, Name: "Spectator"}
        AddCallback('AmmoX', CL_ParseEAmmoX);
        AddCallback('ScreenFade', CL_ParseEScreenFade);
        AddCallback('ScreenShake', CL_ParseEScreenShake);
        AddCallback('ShowMenu', CL_ParseEShowMenu);
{13:17:59 - CL_ParseNewUserMsg : Index: 92, Size: 1, Name: "SetFOV"}
        AddCallback('HideWeapon', CL_ParseEHideWeapon);
        AddCallback('ItemPickup', CL_ParseEItemPickup);
        AddCallback('WeapPickup', CL_ParseEWeapPickup);
        AddCallback('AmmoPickup', CL_ParseEAmmoPickup);
        AddCallback('MOTD', CL_ParseEMOTD);
        AddCallback('GameMode', CL_ParseEGameMode);
        AddCallback('TeamScore', CL_ParseETeamScore);
        AddCallback('TeamInfo', CL_ParseETeamInfo);
        AddCallback('ScoreInfo', CL_ParseEScoreInfo);
        AddCallback('DeathMsg', CL_ParseEDeathMsg);
{13:17:59 - CL_ParseNewUserMsg : Index: 81, Size: 1, Name: "GameTitle"}
        AddCallback('InitHUD', CL_ParseEInitHUD);
        AddCallback('ResetHUD', CL_ParseEResetHUD);
        AddCallback('WeaponList', CL_ParseEWeaponList);
        AddCallback('TextMsg', CL_ParseETextMsg);
        AddCallback('SayText', CL_ParseESayText);
        AddCallback('HudText', CL_ParseEHudText);
{13:17:59 - CL_ParseNewUserMsg : Index: 74, Size: 1, Name: "Train"}
        AddCallback('Battery', CL_ParseEBattery);
        AddCallback('Damage', CL_ParseEDamage);
        AddCallback('Health', CL_ParseEHealth);
        AddCallback('FlashBat', CL_ParseEFlashBat);
        AddCallback('Flashlight', CL_ParseEFlashlight);
        AddCallback('Geiger', CL_ParseEGeiger);
        AddCallback('CurWeapon', CL_ParseECurWeapon);
{13:17:59 - CL_ParseNewUserMsg : Index: 66, Size: 4, Name: "SelAmmo"     }
        AddCallback('ReqState', CL_ParseEReqState);
        AddCallback('VoiceMask', CL_ParseEVoiceMask);
      end;
    end;
end;

procedure TXSimpleGameClient.CL_ReadETextMsg(Data: TTextMsg);
begin
  if Assigned(OnETextMsg) then
  begin
    Lock;
    OnETextMsg(Self, Data);
    UnLock;
  end;
end;

procedure TXSimpleGameClient.CL_ReadEMenu(Data: TSimpleMenu);
const
  BadChars: array [0..3] of LStr = ('\w', '\y', '\r', '\d');
var
  I: Int32;
  S: LStr;
  L: TArray<LStr>;
begin
  S := Data.Data;

  for I := Low(BadChars) to High(BadChars) do // remove bad chars
    while Pos(BadChars[I], S) > 0 do
      Delete(S, Pos(BadChars[I], S), Length(BadChars[I]));

  for I := 0 to MenuAnswers.Count - 1 do
    with MenuAnswers, MenuAnswers[I] do
      if StrBComp(S, Key) then
      begin
        S := Value;

        if Pos(',', S) > 0 then
        begin
          Default.Clear(L);

          while Pos(',', S) > 0 do
          begin
            SetLength(L, Length(L) + 1);
            L[High(L)] := ParseBefore(S, ',', True);

            S := ParseAfter(S, ',', True);
          end;

          S := L[Random(Length(L))];
        end;

        if IsNumbers(S) then
          ExecuteCommand('later ' + FloatToStrDot(RandomRange(0, 10) / 10) + ' "menuselect ' + S + '"')
        else
          ExecuteCommand(S);

        Hint(H_ENGINE, ['answer for menu "', Key, '" with "', S, '"']);

        Break;
      end;
end;

procedure TXSimpleGameClient.CL_ReadEVGUIMenu(Data: TVGUIMenu);
begin
  if Assigned(OnEVGUIMenu) then
  begin
    Lock;
    OnEVGUIMenu(Self, Data);
    UnLock;
  end;
end;

procedure TXSimpleGameClient.CL_ReadERoundTime(ATime: Int16);
begin
  FRoundStartTime := Round(Time);
  FRoundTime := ATime;
end;

function TXSimpleGameClient.CL_GetWeapon(AIndex: UInt32): PWeapon;
begin
  Result := nil;

  if Length(Weapons) = 0 then
    Exit;

  if AIndex = 0 then
    Exit;

  if not (AIndex in [Low(Weapons)..High(Weapons)]) then
    Exit;

  Result := @Weapons[AIndex];
end;

function TXSimpleGameClient.CL_GetWeapon: PWeapon;
begin
  Result := CL_GetWeapon(CL_GetWeaponIndex); // move it to XEGC ?
end;

function TXSimpleGameClient.CL_GetAmmo(AAmmoID: UInt8): UInt8;
begin
  Result := 0;

  if Length(Ammo) = 0 then
    Exit;

  if not (AAmmoID in [Low(Ammo)..High(Ammo)]) then
    Exit;

  Result := Ammo[AAmmoID];
end;

function TXSimpleGameClient.CL_HasHostages: Boolean;
var
  I: Int32;
begin
  Result := False;

  for I := Low(Hostages) to High(Hostages) do
    if Hostages[I] <> 0 then
      Exit(True);
end;

procedure TXSimpleGameClient.CMD_RegisterCommands;
begin
  inherited;

  with Commands do
  begin
    Add('menu_answer', CL_MenuAnswer_F, 'add menu answer', CMD_PROTECTED);

    Add('debug_weaponlist', CL_DebugWeaponList_F, CMD_PROTECTED);
  end;
end;

procedure TXSimpleGameClient.CMD_RegisterCVars;
begin
  inherited;

  with CVars do
  begin
    //
  end;
end;

procedure TXSimpleGameClient.CL_MenuAnswer_F;
var
  S: LStr;
  I: Int32;
begin
  with MenuAnswers do
    if CMD.Count > 1 then
      if CMD.Count > 2 then
        Add(CMD.Tokens[1], CMD.Tokens[2])
      else
        Add(CMD.Tokens[1])
    else
      if Count > 0 then
      begin
        WriteLine(S, 'Menu Answers: ');

        for I := 0 to Count - 1 do
          with MenuAnswers[I] do
            WriteLine(S, '  ' + IntToStr(I + 1) + ') ' + Key + ': "' + Value + '"');

        Print([S]);
      end
      else
      begin
        Print(['No menu answers registered.']);
        PrintCMDUsage(['menu_name', 'key']);
      end;
end;

procedure TXSimpleGameClient.CL_DebugWeaponList_F;
var
  I: Int32;
begin
  for I := 0 to Length(Weapons) - 1 do
    with Weapons[I] do

      Print(['Index: ', Index, ', ',
             'Name: "', Name, '", ',
             'Slot: ', SlotID, ', ',
             'NumInSlot: ', NumberInSlot, ', ',
             'PrimaryAmmoID: ', PrimaryAmmoID, ', ',
             'PrimaryAmmoMaxAmmount: ', PrimaryAmmoMaxAmount, ', ',
             'SecondaryAmmoID: ', SecondaryAmmoID, ', ',
             'SecondaryAmmoMaxAmount: ', SecondaryAmmoMaxAmount, ', ',
             'Flags: ', Flags]);
end;

constructor TXSimpleGameClient.Create;
begin
  inherited;

  MenuAnswers := TAliasList.Create;
end;

destructor TXSimpleGameClient.Destroy;
begin
  if GetState > CS_DISCONNECTED then
    CL_FinalizeConnection;

  MenuAnswers.Free;

  inherited;
end;

function TXSimpleGameClient.GetWeapon(AIndex: UInt32): PWeapon;
begin
  Result := CL_GetWeapon(AIndex);
end;

function TXSimpleGameClient.GetWeapon: PWeapon;
begin
  Result := CL_GetWeapon;
end;

end.
