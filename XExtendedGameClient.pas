unit XExtendedGameClient;

interface

uses
  Classes,
  SysUtils,
  IOUtils,

  XSimpleGameClient,
  Navigation,
  World,
  Ways,
  Command,
  CVar,
  Alias,
  Lua,
  Lua.Lib,
  Vector,
  Sound,
  Protocol,
  Resource,
  Buffer,
  Emulator,
  Shared,
  Default;

const
  FIRST_BUILD = '04.07.2014 00:00:00';
  H_ENGINE = 'Engine';

type
  TRequestNavigation = function(Sender: TObject): PNavMesh of object;
  TRequestWorld = function(Sender: TObject): PWorld of object;

type
  TXExtendedGameClient = class(TXSimpleGameClient)
  strict private
    FRequestNavigation: TRequestNavigation;
    FOnNavigationInitialized: TNotifyEvent;
    FIsNavigationInitialized: Boolean;
    FNavigationBase: TNavMesh;

    FRequestWorld: TRequestWorld;
    FOnWorldInitialized: TNotifyEvent;
    FIsWorldInitialized: Boolean;
    FWorldBase: TWorld;

    FWaysInitialized: Boolean;

    FIsLuaInitialized: Boolean;

    FEndOfRound: Boolean;
    FIsBombDropped: Boolean;

    FAutobuySet: Boolean;

    FTryedJoinTeam: Boolean;

  strict protected
    TriggerTypes: TCommandList;
    Triggers: TAliasList;

    Navigation: PNavMesh;
    World: PWorld;
    Ways: TWays;

    Lua: TLua;

      {$REGION 'CVars'}
    CL_AutowepSwitch: LStr;

    Emulator,
    SteamID: UInt32;

    CL_AutoJoinTeam: Boolean;
    CL_AutoJoinTeam_Value: UInt32; // 0 - random, 1 - t, 2 - ct

    CL_AutoJoinClass: Boolean;
    CL_AutoJoinClass_Value: UInt32;

    CL_CS_Autobuy_Data: LStr;

    CL_DownloadWorld,
    CL_Intellegence: Boolean;
      {$ENDREGION}

        {$REGION 'GameEvents'}
    procedure CL_ParseETeamInfo; override;
    procedure CL_ParseEWeapPickup; override;
    procedure CL_ParseEBombPickup_CStrike; override;
    procedure CL_ParseEBombDrop_CStrike; override;
        {$ENDREGION}

    procedure CL_FinalizeConnection(Reason: LStr; IsReconnect: Boolean = False); override;
    procedure CL_WriteConnectPacket; override;
    procedure CL_InitializeGame; override;
    procedure CL_InitializeWorld;
    procedure CL_InitializeNavigation;
    procedure CL_InitializeWays;
    procedure CL_InitializeLua;

    procedure CL_Think; override;

    procedure CL_PlaySound(ASound: TSound); override;
    
    procedure NavLock;
    procedure NavUnLock;

    procedure WorldLock;
    procedure WorldUnLock;

    function CL_IsVisible(AStart, AFinish: TVec3F; Ignore: array of Int32): Boolean; overload;
    function CL_IsVisible(AStart, AFinish: TVec3F): Boolean; overload;
    function CL_IsVisible(AFinish: TVec3F): Boolean; overload;

    function CL_GetGroundedOriginEx: TVec3F;

    function CL_NeedToDownloadResource(AResource: TResource; CustomName: LStr = ''): Boolean; override;

    procedure CL_ReadERoundTime(Time: Int16); override;
    procedure CL_ReadETextMsg(Data: TTextMsg); override;
    procedure CL_ReadEVGUIMenu(Data: TVGUIMenu); override;
    procedure CL_ParseTETextMessage; override;

    procedure CL_ExecuteTrigger(ATrigger: LStr);
    procedure CL_ExecuteTriggerByText(AText: LStr);

    procedure CL_RoundEnd_T;
    procedure CL_RoundStart_T;
    procedure CL_BombDropped_T;
    procedure CL_BombPickedUp_T;

    procedure CMD_RegisterCommands; override;
    procedure CMD_RegisterCVars; override;

    procedure CL_JoinTeam_F;
    procedure CL_JoinClass_F;

    procedure CL_Autobuy_F;

    procedure CL_NavigationInfo_F;
    procedure CL_NavigationTest_F;

    procedure CL_Trigger_F;

    procedure CMD_Version; override;

  public
    constructor Create;
    destructor Destroy; override;

    property RequestNavigation: TRequestNavigation read FRequestNavigation write FRequestNavigation;
    property OnNavigationInitialized: TNotifyEvent read FOnNavigationInitialized write FOnNavigationInitialized;
    property HasNavigation: Boolean read FIsNavigationInitialized;
    property GetNavigation: PNavMesh read Navigation;

    property RequestWorld: TRequestWorld read FRequestWorld write FRequestWorld;
    property OnWorldInitialized: TNotifyEvent read FOnWorldInitialized write FOnWorldInitialized;
    property HasWorld: Boolean read FIsWorldInitialized;
    property GetWorld: PWorld read World;

    property HasWays: Boolean read FWaysInitialized;
    property HasLua: Boolean read FIsLuaInitialized;

    procedure LuaPrint(A: LStr);
  published
    // XNativeEngine

    function Lua_ExecuteCommand(L: TLuaHandle): Int32;

    // XBaseGameClient

    function Lua_GetServer(L: TLuaHandle): Int32;
    function Lua_GetTime(L: TLuaHandle): Int32;

    function Lua_GetClientOrigin(L: TLuaHandle): Int32;
    function Lua_GetClientVelocity(L: TLuaHandle): Int32;
    function Lua_GetClientViewModel(L: TLuaHandle): Int32;
    function Lua_GetClientPunchAngle(L: TLuaHandle): Int32;
    function Lua_GetClientFlags(L: TLuaHandle): Int32;
    function Lua_GetClientWaterLevel(L: TLuaHandle): Int32;
    function Lua_GetClientWaterType(L: TLuaHandle): Int32;
    function Lua_GetClientViewOffset(L: TLuaHandle): Int32;
    function Lua_GetClientHealth(L: TLuaHandle): Int32;
    function Lua_GetClientInDuck(L: TLuaHandle): Int32;
    function Lua_GetClientWeapons(L: TLuaHandle): Int32;
    function Lua_GetClientTimeStepSound(L: TLuaHandle): Int32;
    function Lua_GetClientDuckTime(L: TLuaHandle): Int32;
    function Lua_GetClientSwimTime(L: TLuaHandle): Int32;
    function Lua_GetClientWaterJumpTime(L: TLuaHandle): Int32;
    function Lua_GetClientMaxSpeed(L: TLuaHandle): Int32;
    function Lua_GetClientFOV(L: TLuaHandle): Int32;
    function Lua_GetClientWeaponAnim(L: TLuaHandle): Int32;
    function Lua_GetClientID(L: TLuaHandle): Int32;
    function Lua_GetClientAmmoShells(L: TLuaHandle): Int32;
    function Lua_GetClientAmmoNails(L: TLuaHandle): Int32;
    function Lua_GetClientAmmoCells(L: TLuaHandle): Int32;
    function Lua_GetClientAmmoRockets(L: TLuaHandle): Int32;
    function Lua_GetClientNextAttack(L: TLuaHandle): Int32;
    function Lua_GetClientTFState(L: TLuaHandle): Int32;
    function Lua_GetClientPushMSec(L: TLuaHandle): Int32;
    function Lua_GetClientDeadFlag(L: TLuaHandle): Int32;
    function Lua_GetClientPhysInfo(L: TLuaHandle): Int32;
    function Lua_GetClientIUser1(L: TLuaHandle): Int32;
    function Lua_GetClientIUser2(L: TLuaHandle): Int32;
    function Lua_GetClientIUser3(L: TLuaHandle): Int32;
    function Lua_GetClientIUser4(L: TLuaHandle): Int32;
    function Lua_GetClientFUser1(L: TLuaHandle): Int32;
    function Lua_GetClientFUser2(L: TLuaHandle): Int32;
    function Lua_GetClientFUser3(L: TLuaHandle): Int32;
    function Lua_GetClientFUser4(L: TLuaHandle): Int32;
    function Lua_GetClientVUser1(L: TLuaHandle): Int32;
    function Lua_GetClientVUser2(L: TLuaHandle): Int32;
    function Lua_GetClientVUser3(L: TLuaHandle): Int32;
    function Lua_GetClientVUser4(L: TLuaHandle): Int32;

    function Lua_GetProtocol(L: TLuaHandle): Int32;
    function Lua_GetMaxPlayers(L: TLuaHandle): Int32;
    function Lua_GetClientIndex(L: TLuaHandle): Int32;
    function Lua_GetGameDir(L: TLuaHandle): Int32;
    function Lua_GetMap(L: TLuaHandle): Int32;
    function Lua_GetMapEx(L: TLuaHandle): Int32;

    function Lua_GetLightStylesCount(L: TLuaHandle): Int32;
    function Lua_GetLightStyle(L: TLuaHandle): Int32;

    function Lua_GetResourcesCount(L: TLuaHandle): Int32;

    function Lua_GetResourceName(L: TLuaHandle): Int32;
    function Lua_GetResourceType(L: TLuaHandle): Int32;
    function Lua_GetResourceIndex(L: TLuaHandle): Int32;
    function Lua_GetResourceSize(L: TLuaHandle): Int32;
    function Lua_GetResourceFlags(L: TLuaHandle): Int32;

    function Lua_GetIntermission(L: TLuaHandle): Int32;
    function Lua_IsPaused(L: TLuaHandle): Int32;

    function Lua_GetPlayersCount(L: TLuaHandle): Int32;

    function Lua_GetPlayerUserInfo(L: TLuaHandle): Int32;
    function Lua_GetPlayerKills(L: TLuaHandle): Int32;
    function Lua_GetPlayerDeaths(L: TLuaHandle): Int32;
    function Lua_GetPlayerPing(L: TLuaHandle): Int32;
    function Lua_GetPlayerLoss(L: TLuaHandle): Int32;
    function Lua_GetPlayerTeam(L: TLuaHandle): Int32;
    function Lua_GetPlayerClassID(L: TLuaHandle): Int32;
    function Lua_GetPlayerTeamID(L: TLuaHandle): Int32;
    function Lua_GetPlayerHealth(L: TLuaHandle): Int32;
    function Lua_GetPlayerScoreAttrib(L: TLuaHandle): Int32;
    function Lua_GetPlayerLocation(L: TLuaHandle): Int32;
    function Lua_GetPlayerRadar(L: TLuaHandle): Int32;
    function Lua_GetPlayerOrigin(L: TLuaHandle): Int32;
    function Lua_GetPlayerName(L: TLuaHandle): Int32;
    function Lua_IsPlayerAlive(L: TLuaHandle): Int32;
    function Lua_IsPlayerBomber(L: TLuaHandle): Int32;
    function Lua_IsPlayerVIP(L: TLuaHandle): Int32;

    function Lua_GetEntitiesCount(L: TLuaHandle): Int32;

    function Lua_GetEntityType(L: TLuaHandle): Int32;
    function Lua_GetEntityNumber(L: TLuaHandle): Int32;
    function Lua_GetEntityMsgTime(L: TLuaHandle): Int32;
    function Lua_GetEntityMessageNum(L: TLuaHandle): Int32;
    function Lua_GetEntityOrigin(L: TLuaHandle): Int32;
    function Lua_GetEntityAngles(L: TLuaHandle): Int32;
    function Lua_GetEntityModelIndex(L: TLuaHandle): Int32;
    function Lua_GetEntitySequence(L: TLuaHandle): Int32;
    function Lua_GetEntityFrame(L: TLuaHandle): Int32;
    function Lua_GetEntityColorMap(L: TLuaHandle): Int32;
    function Lua_GetEntitySkin(L: TLuaHandle): Int32;
    function Lua_GetEntitySolid(L: TLuaHandle): Int32;
    function Lua_GetEntityEffects(L: TLuaHandle): Int32;
    function Lua_GetEntityScale(L: TLuaHandle): Int32;
    function Lua_GetEntityEFlags(L: TLuaHandle): Int32;
    function Lua_GetEntityRenderMode(L: TLuaHandle): Int32;
    function Lua_GetEntityRenderAmt(L: TLuaHandle): Int32;
    //function Lua_GetEntityRenderColor(L: TLuaHandle): Int32;
    function Lua_GetEntityRenderFX(L: TLuaHandle): Int32;
    function Lua_GetEntityMoveType(L: TLuaHandle): Int32;
    function Lua_GetEntityAnimTime(L: TLuaHandle): Int32;
    function Lua_GetEntityFrameRate(L: TLuaHandle): Int32;
    function Lua_GetEntityBody(L: TLuaHandle): Int32;
    //function Lua_GetEntityController(L: TLuaHandle): Int32;
    //function Lua_GetEntityBlending(L: TLuaHandle): Int32;
    function Lua_GetEntityVelocity(L: TLuaHandle): Int32;
    function Lua_GetEntityMinS(L: TLuaHandle): Int32;
    function Lua_GetEntityMaxS(L: TLuaHandle): Int32;
    function Lua_GetEntityAimEnt(L: TLuaHandle): Int32;
    function Lua_GetEntityOwner(L: TLuaHandle): Int32;
    function Lua_GetEntityFriction(L: TLuaHandle): Int32;
    function Lua_GetEntityGravity(L: TLuaHandle): Int32;
    function Lua_GetEntityTeam(L: TLuaHandle): Int32;
    function Lua_GetEntityPlayerClass(L: TLuaHandle): Int32;
    function Lua_GetEntityHealth(L: TLuaHandle): Int32;
    function Lua_GetEntitySpectator(L: TLuaHandle): Int32;
    function Lua_GetEntityWeaponModel(L: TLuaHandle): Int32;
    function Lua_GetEntityGaitSequence(L: TLuaHandle): Int32;
    function Lua_GetEntityBaseVelocity(L: TLuaHandle): Int32;
    function Lua_GetEntityUseHull(L: TLuaHandle): Int32;
    function Lua_GetEntityOldButtons(L: TLuaHandle): Int32;
    function Lua_GetEntityOnGround(L: TLuaHandle): Int32;
    function Lua_GetEntityStepLeft(L: TLuaHandle): Int32;
    function Lua_GetEntityFallVelocity(L: TLuaHandle): Int32;
    function Lua_GetEntityFOV(L: TLuaHandle): Int32;
    function Lua_GetEntityWeaponAnim(L: TLuaHandle): Int32;
    function Lua_GetEntityStartPos(L: TLuaHandle): Int32;
    function Lua_GetEntityEndPos(L: TLuaHandle): Int32;
    function Lua_GetEntityImpactTime(L: TLuaHandle): Int32;
    function Lua_GetEntityStartTime(L: TLuaHandle): Int32;
    function Lua_GetEntityIUser1(L: TLuaHandle): Int32;
    function Lua_GetEntityIUser2(L: TLuaHandle): Int32;
    function Lua_GetEntityIUser3(L: TLuaHandle): Int32;
    function Lua_GetEntityIUser4(L: TLuaHandle): Int32;
    function Lua_GetEntityFUser1(L: TLuaHandle): Int32;
    function Lua_GetEntityFUser2(L: TLuaHandle): Int32;
    function Lua_GetEntityFUser3(L: TLuaHandle): Int32;
    function Lua_GetEntityFUser4(L: TLuaHandle): Int32;
    function Lua_GetEntityVUser1(L: TLuaHandle): Int32;
    function Lua_GetEntityVUser2(L: TLuaHandle): Int32;
    function Lua_GetEntityVUser3(L: TLuaHandle): Int32;
    function Lua_GetEntityVUser4(L: TLuaHandle): Int32;
    function Lua_IsEntityActive(L: TLuaHandle): Int32;

    function Lua_IsPlayerIndex(L: TLuaHandle): Int32;

    function Lua_MoveTo(L: TLuaHandle): Int32;
    function Lua_MoveOut(L: TLuaHandle): Int32;

    function Lua_LookAt(L: TLuaHandle): Int32;
    function Lua_LookAtEx(L: TLuaHandle): Int32;

    function Lua_GetViewAngles(L: TLuaHandle): Int32;
    function Lua_SetViewAngles(L: TLuaHandle): Int32;

    function Lua_PressButton(L: TLuaHandle): Int32;
    function Lua_UnPressButton(L: TLuaHandle): Int32;
    function Lua_IsButtonPressed(L: TLuaHandle): Int32;

    function Lua_GetOrigin(L: TLuaHandle): Int32;
    function Lua_GetVelocity(L: TLuaHandle): Int32;
    function Lua_GetPunchAngle(L: TLuaHandle): Int32;
    function Lua_GetWeaponAbsoluteIndex(L: TLuaHandle): Int32;
    function Lua_GetFieldOfView(L: TLuaHandle): Int32;

    function Lua_GetDistance(L: TLuaHandle): Int32;
    function Lua_GetDistance2D(L: TLuaHandle): Int32;

    function Lua_IsWeaponExists(L: TLuaHandle): Int32;

    function Lua_IsCrouching(L: TLuaHandle): Int32;
    function Lua_IsOnGround(L: TLuaHandle): Int32;
    function Lua_IsSpectator(L: TLuaHandle): Int32;

    function Lua_HasWeaponData(L: TLuaHandle): Int32;
    function Lua_GetWeaponDataField(L: TLuaHandle): Int32;

    function Lua_IsReloading(L: TLuaHandle): Int32;
    function Lua_GetMaxSpeed(L: TLuaHandle): Int32;

    function Lua_CanAttack(L: TLuaHandle): Int32;

    function Lua_InFieldOfView(L: TLuaHandle): Int32;

    function Lua_IsAlive(L: TLuaHandle): Int32;

    function Lua_UseEnvironment(L: TLuaHandle): Int32;

    function Lua_PrimaryAttack(L: TLuaHandle): Int32;
    function Lua_SecondaryAttack(L: TLuaHandle): Int32;
    function Lua_FastPrimaryAttack(L: TLuaHandle): Int32;
    function Lua_FastSecondaryAttack(L: TLuaHandle): Int32;

    function Lua_Jump(L: TLuaHandle): Int32;
    function Lua_Duck(L: TLuaHandle): Int32;
    function Lua_DuckJump(L: TLuaHandle): Int32;

    function Lua_GetGroundedOrigin(L: TLuaHandle): Int32;
    function Lua_GetGroundedDistance(L: TLuaHandle): Int32;

    // XSimpleGameClient

    function Lua_GetHideWeapon(L: TLuaHandle): Int32;
    function Lua_GetHealth(L: TLuaHandle): Int32;
    function Lua_GetFlashBat(L: TLuaHandle): Int32;
    function Lua_IsFlashlightActive(L: TLuaHandle): Int32;
    function Lua_GetBattery(L: TLuaHandle): Int32;

    function Lua_GetWeaponsCount(L: TLuaHandle): Int32;

    function Lua_GetWeaponName(L: TLuaHandle): Int32;
    function Lua_GetWeaponPrimaryAmmoID(L: TLuaHandle): Int32;
    function Lua_GetWeaponPrimaryAmmoMaxAmount(L: TLuaHandle): Int32;
    function Lua_GetWeaponSecondaryAmmoID(L: TLuaHandle): Int32;
    function Lua_GetWeaponSecondaryAmmoMaxAmount(L: TLuaHandle): Int32;
    function Lua_GetWeaponSlotID(L: TLuaHandle): Int32;
    function Lua_GetWeaponNumberInSlot(L: TLuaHandle): Int32;
    function Lua_GetWeaponIndex(L: TLuaHandle): Int32;
    function Lua_GetWeaponFlags(L: TLuaHandle): Int32;
    function Lua_GetWeaponNameEx(L: TLuaHandle): Int32;
    function Lua_GetWeaponByAbsoluteIndex(L: TLuaHandle): Int32;

    function Lua_GetStatusValuesCount(L: TLuaHandle): Int32;
    function Lua_GetStatusValue(L: TLuaHandle): Int32;

    function Lua_GetStatusIconsCount(L: TLuaHandle): Int32;

    function Lua_GetStatusIconName(L: TLuaHandle): Int32;
    function Lua_GetStatusIconStatus(L: TLuaHandle): Int32;

    function Lua_GetBombStateActive(L: TLuaHandle): Int32;
    function Lua_GetBombStatePosition(L: TLuaHandle): Int32;
    function Lua_GetBombStatePlanted(L: TLuaHandle): Int32;

    function Lua_GetRoundTime(L: TLuaHandle): Int32;
    function Lua_GetMoney(L: TLuaHandle): Int32;

    function Lua_IsTeamPlay(L: TLuaHandle): Int32;

    function Lua_GetAmmo(L: TLuaHandle): Int32;

    // XExtendedGameClient

    // engine
    function Lua_HasNavigation(L: TLuaHandle): Int32;
    function Lua_HasWorld(L: TLuaHandle): Int32;
    function Lua_HasWays(L: TLuaHandle): Int32;

    function Lua_IsVisible(L: TLuaHandle): Int32;

    function Lua_GetGroundedOriginEx(L: TLuaHandle): Int32;

    // navigation

    function Lua_GetNavArea(L: TLuaHandle): Int32;
    function Lua_GetRandomNavArea(L: TLuaHandle): Int32;

    function Lua_GetNavAreaIndex(L: TLuaHandle): Int32;
    function Lua_GetNavAreaFlags(L: TLuaHandle): Int32;
    function Lua_GetNavAreaName(L: TLuaHandle): Int32;
    function Lua_GetNavAreaCenter(L: TLuaHandle): Int32;

    function Lua_GetNavAreaConnectionsCount(L: TLuaHandle): Int32;
    function Lua_GetNavAreaHidingSpotsCount(L: TLuaHandle): Int32;

    function Lua_GetNavAreaApproachesCount(L: TLuaHandle): Int32;

    function Lua_GetNavAreaApproachHere(L: TLuaHandle): Int32;
    function Lua_GetNavAreaApproachPrev(L: TLuaHandle): Int32;
    function Lua_GetNavAreaApproachNext(L: TLuaHandle): Int32;

    function Lua_GetNavAreaEncountersCount(L: TLuaHandle): Int32;
    function Lua_GetNavAreaLaddersCount(L: TLuaHandle): Int32;

    function Lua_GetNavAreaRandomConnection(L: TLuaHandle): Int32;

    function Lua_IsNavAreaConnected(L: TLuaHandle): Int32;
    function Lua_IsNavAreaBiLinked(L: TLuaHandle): Int32;

    function Lua_GetNavAreaPortal(L: TLuaHandle): Int32;
    function Lua_GetNavAreaWindow(L: TLuaHandle): Int32;
    function Lua_GetNavAreaWindowEx(L: TLuaHandle): Int32;

    function Lua_GetNavHidingSpot(L: TLuaHandle): Int32;
    function Lua_GetRandomNavHidingSpot(L: TLuaHandle): Int32;

    function Lua_GetNavHidingSpotIndex(L: TLuaHandle): Int32;
    function Lua_GetNavHidingSpotPosition(L: TLuaHandle): Int32;
    function Lua_GetNavHidingSpotFlags(L: TLuaHandle): Int32;
    function Lua_GetNavHidingSpotParent(L: TLuaHandle): Int32;

    function Lua_GetNavChain(L: TLuaHandle): Int32;

    // world

    function Lua_GetWorldEntitiesCount(L: TLuaHandle): Int32;
    function Lua_GetWorldVertexesCount(L: TLuaHandle): Int32;
    function Lua_GetWorldEdgesCount(L: TLuaHandle): Int32;
    function Lua_GetWorldSurfEdgesCount(L: TLuaHandle): Int32;
    function Lua_GetWorldTexturesCount(L: TLuaHandle): Int32;
    function Lua_GetWorldPlanesCount(L: TLuaHandle): Int32;
    function Lua_GetWorldFacesCount(L: TLuaHandle): Int32;
    function Lua_GetWorldLeafsCount(L: TLuaHandle): Int32;
    function Lua_GetWorldNodesCount(L: TLuaHandle): Int32;
    function Lua_GetWorldClipNodesCount(L: TLuaHandle): Int32;
    function Lua_GetWorldModelsCount(L: TLuaHandle): Int32;

    function Lua_GetWorldEntity(L: TLuaHandle): Int32;
    function Lua_GetWorldEntities(L: TLuaHandle): Int32;
    function Lua_GetWorldRandomEntity(L: TLuaHandle): Int32;

    function Lua_GetWorldEntityByClassName(L: TLuaHandle): Int32;
    function Lua_GetWorldEntitiesByClassName(L: TLuaHandle): Int32;
    function Lua_GetWorldRandomEntityByClassName(L: TLuaHandle): Int32;

    function Lua_GetWorldEntityField(L: TLuaHandle): Int32;

    function Lua_GetModelForEntity(L: TLuaHandle): Int32;

    function Lua_GetWorldModelMinS(L: TLuaHandle): Int32;
    function Lua_GetWorldModelMaxS(L: TLuaHandle): Int32;
    function Lua_GetWorldModelOrigin(L: TLuaHandle): Int32;
    //HeadNode: array[0..MAX_MAP_HULLS - 1] of Int32;
    function Lua_GetWorldModelVisLeafs(L: TLuaHandle): Int32;
    function Lua_GetWorldModelFirstFace(L: TLuaHandle): Int32;
    function Lua_GetWorldModelNumFaces(L: TLuaHandle): Int32;
  end;

implementation

procedure TXExtendedGameClient.CL_ParseETeamInfo;
var
  S: LStr;
begin
  S := CL_GetPlayer.Team;

  inherited;

 // if S <> CL_GetPlayer.Team then            FIX
 //   CL_ExecuteTrigger('TeamChanged');
end;

procedure TXExtendedGameClient.CL_ParseEWeapPickup;
var
  Index: UInt8;
begin
  GMSG.SavePosition;

  Index := GMSG.ReadUInt8;

  GMSG.RestorePosition;

  inherited;

  Hint(H_ENGINE, ['picked up: ', GetWeapons[Index].ResolveName]);
end;

procedure TXExtendedGameClient.CL_ParseEBombPickup_CStrike;
begin
  inherited;

  if FIsBombDropped then
    CL_ExecuteTrigger('BombPickedUp');
end;

procedure TXExtendedGameClient.CL_ParseEBombDrop_CStrike;
begin
  inherited;

  if not GetBombState.IsPlanted and not FIsBombDropped then
    CL_ExecuteTrigger('BombDropped');
end;

procedure TXExtendedGameClient.CL_FinalizeConnection(Reason: LStr; IsReconnect: Boolean = False);
begin
  // navs
  Clear(FIsNavigationInitialized);
  Finalize(FNavigationBase);
  Navigation := nil;

  Clear(FIsWorldInitialized);
  Finalize(FWorldBase);
  World := nil;

  Finalize(Ways);
  Clear(FWaysInitialized);

  if (State >= CS_GAME) and HasLua then
    Lua.Call('Finalization');

  Clear(FIsLuaInitialized);

  Clear(FAutobuySet);

  Clear(FTryedJoinTeam);

  inherited;
end;

procedure TXExtendedGameClient.CL_WriteConnectPacket;
var
  E: Int32;
  A: TArray<UInt8>;
begin
  MSG.WriteLStr('connect ' + IntToStr(PROTOCOL_VERSION) + ' ' + IntToStr(Challenge.Get(NET.From)) + ' ' +
    '"\prot\3\unique\-1\raw\steam\cdkey\' + GetCDKey + '" ' +
    '"' + CL_GetUserInfoString + '"', wmLineBreak);

  if not (Emulator in [1..5]) then
    E := Random(4) + 1
  else
    E := Emulator;

  A := Emu_Generate(E, SteamID);

  MSG.Write(A, Length(A));

  {MSG.WriteLStr('connect 46 ' + IntToStr(Challenge.Get(From)) + ' ' +
    '"\prot\2\unique\-1\raw\' + GetCDKey + '" ' +
    '"' + CL_GetUserInfoString + '"', wmLineBreak);}
end;

procedure TXExtendedGameClient.CL_InitializeGame;
begin
  inherited;

  CL_InitializeWorld;
  CL_InitializeNavigation;
  CL_InitializeWays;
  CL_InitializeLua;
end;

procedure TXExtendedGameClient.CL_InitializeWorld;
label
  L1;
begin
  if Assigned(RequestWorld) then
  begin
    Lock;
    World := RequestWorld(Self);
    UnLock;
  end;

  if World = nil then
    World := @FWorldBase
  else
    goto L1;

  case World.LoadFromFile(GetServerInfo.ResolveMapName, GetServerInfo.GameDir) of
    BSP_LOAD_OK: L1:
    begin
      Print([World.EntitiesCount + World.VertexesCount + World.EdgesCount + World.SurfEdgesCount +
             World.TexturesCount + World.PlanesCount + World.FacesCount + World.LeafsCount +
             World.NodesCount + World.ClipNodesCount + World.ModelsCount, ' world objects initialized']);

      FIsWorldInitialized := True;

      ReleaseEvent(OnWorldInitialized);
    end;

    BSP_LOAD_FILE_NOT_FOUND: Print(['World not found']);
    BSP_LOAD_CORRUPT_DATA: Print(['Bad world data']);
  end;
end;

procedure TXExtendedGameClient.CL_InitializeNavigation;
label
  L1;
begin
  if Assigned(RequestNavigation) then
  begin
    Lock;
    Navigation := RequestNavigation(Self);
    UnLock;
  end;

  if Navigation = nil then
    Navigation := @FNavigationBase
  else
    goto L1;

  case Navigation.LoadFromFile(GetServerInfo.ResolveMapName, GetServerInfo.GameDir) of
    NAV_LOAD_OK: L1:
    begin
      if Navigation.WorldSize <> GetResource(@GetResources, GetServerInfo.Map).Size then
        Print(['The AI navigation data is from a different version of this map']);

      if Navigation.HasLocations then
        Print([Navigation.AreasCount, ' navigation areas, with ', Navigation.LocationsCount, ' locations initialized'])
      else
        Print([Navigation.AreasCount, ' navigation areas initialized']);

      FIsNavigationInitialized := True;

      {if HasWorld and not Navigation.HasLadders then
        Navigation.LoadLaddersFromWorld(World);}

      ReleaseEvent(OnNavigationInitialized);
    end;

    NAV_LOAD_FILE_NOT_FOUND: Print(['Navigation not found']);
    NAV_LOAD_BAD_MAGIC,
    NAV_LOAD_BAD_VERSION: Print(['Bad navigation version (', Navigation.Version, ')']);
    NAV_LOAD_BAD_DATA: Print(['Bad navigation data']);
  end;

//  if not HasNavigation and HasWorld then
//    TThread.CreateAnonymousThread(
//    procedure
//    begin
//      Navigation.Generate(World^);
//      Navigation.SaveToFile(GetServerInfo.GameDir + Slash2 + 'maps' + Slash2 + GetServerInfo.ResolveMapName + '.nav');
//
//      if Navigation.HasLocations then
//        Print([Navigation.AreasCount, ' navigation areas, with ', Navigation.LocationsCount, ' locations generated'])
//      else
//        Print([Navigation.AreasCount, ' navigation areas generated']);
//
//      FIsNavigationInitialized := True;
//
//      if HasWorld and not Navigation.HasLadders then
//        Navigation.LoadLaddersFromWorld(World);
//
//      ReleaseEvent(OnNavigationInitialized);
//
//    end).Start;
end;

procedure TXExtendedGameClient.CL_InitializeWays;
var
  S: LStr;
  I, W, P: Int32;
begin
  S := 'waypoints\' + TPath.GetFileNameWithoutExtension(ExtractFileName(GetServerInfo.ResolveMapName)) + '.way';

  if not FileExists(S) then
    Exit;

  with TStringList.Create do
  begin
    LoadFromFile(S);

    for I := 0 to Count - 1 do
    begin
      S := Trim(Strings[I]);

      if Length(S) = 0 then
        Continue;

      if S[1] <> 'P' then
        Continue;

      W := StrToIntDef(ParseBetween(S, '(', ')', False), -1);
      S := ParseAfter(S, ')', False);
      P := StrToIntDef(ParseBetween(S, '(', ')', False), -1);

      if (W = -1) or (P = -1) then
      begin
        Print(['Failed to load ways']);
        Exit;
      end;

      S := ParseAfter(S, ':', False);

      if Length(Ways) < W then
        SetLength(Ways, W);

      W := W - 1;

      if Length(Ways[W]) < P + 1 then
        SetLength(Ways[W], P + 1);

      Ways[W][P].X := StrToFloatDefDot(ParseBefore(S, ' ', False), 0);
      S := ParseAfter(S, ' ', False);
      Ways[W][P].Y := StrToFloatDefDot(ParseBefore(S, ' ', False), 0);
      Ways[W][P].Z := StrToFloatDefDot(ParseAfter(S, ' ', False), 0);

      with Ways[W][P] do
        if (X = 0) or (Y = 0) or (Z = 0) then
        begin
          Print(['Failed to load ways']);
          Exit;
        end;
    end;

    Free;
  end;

  FWaysInitialized := True;

  Print([Length(Ways), ' ways initialized']);
end;

procedure TXExtendedGameClient.CL_InitializeLua;
begin
  if not FileExists('ai\core.lua') then
    Exit;

  Lua.DoFile('ai\core.lua');
  Print([LUA_RELEASE, ' initialized']);
  Lua.Call('Initialization');
  FIsLuaInitialized := True;
end;

procedure TXExtendedGameClient.CL_Think;
begin
  inherited;

  if (GetState >= CS_GAME) and IsNewThinking and HasLua and CL_Intellegence then
    Lua.Call('Frame');
end;

procedure TXExtendedGameClient.CL_PlaySound(ASound: TSound);
begin
  inherited;

  if HasLua then
    with ASound do
      Lua.Call('OnSound', [Index, Entity, Channel, Volume, Pitch, Attenuation, Flags, Origin.X, Origin.Y, Origin.Z]);
end;

procedure TXExtendedGameClient.NavLock;
begin
  if Assigned(RequestNavigation) then
    Lock;
end;

procedure TXExtendedGameClient.NavUnLock;
begin
  if Assigned(RequestNavigation) then
    UnLock;
end;

procedure TXExtendedGameClient.WorldLock;
begin
  if Assigned(RequestWorld) then
    Lock;
end;

procedure TXExtendedGameClient.WorldUnLock;
begin
  if Assigned(RequestWorld) then
    UnLock;
end;

function TXExtendedGameClient.CL_IsVisible(AStart, AFinish: TVec3F; Ignore: array of Int): Boolean;
begin
  if not HasWorld then
    Default.Error(['CL_IsVisible: world isn''t initialized.' + sLineBreak + 'You must check world (func. HasWorld) before calling this function']);

//  WorldLock;
  Result := World.IsVisible(AStart, AFinish, Entities, Ignore);
//  WorldUnLock;
end;

function TXExtendedGameClient.CL_IsVisible(AStart, AFinish: TVec3F): Boolean;
begin
  Result := CL_IsVisible(AStart, AFinish, []);
end;

function TXExtendedGameClient.CL_IsVisible(AFinish: TVec3F): Boolean;
begin
  Result := CL_IsVisible(GetOrigin, AFinish);
end;
{
  if not APlayer.Entity.IsActive then
    Exit(CL_IsVisible(APlayer.GetOrigin));


  // A player interpretation
  //
  // LT - left top
  // H - head
  // RT - right top
  // LH - left hand
  // O - origin
  // RH - right hand
  // LB - left bottom
  // F - foot
  // RB - right bottom
  //
  // LT -- H -- RT
  //  |    |    |
  //  |    |    |
  // LH -- O -- RH
  //  |    |    |
  //  |    |    |
  // LB -- F -- RB
  //

  Result := CL_IsVisible(APlayer.GetOrigin)
        // or CL_IsVisible(APlayer.GetLeftTop)
        //// or CL_IsVisible(APlayer.GetHeadOrigin)
        // or CL_IsVisible(APlayer.GetRightTop)
        // or CL_IsVisible(APlayer.GetLeftHand)
        // or CL_IsVisible(APlayer.GetRightHand)
        // or CL_IsVisible(APlayer.GetLeftBottom)
        //// or CL_IsVisible(APlayer.GetFootOrigin)
        // or CL_IsVisible(APlayer.GetRightBottom)
}
    {$ENDREGION}

    {$REGION 'CL_GetGroundedOriginEx'}
function TXExtendedGameClient.CL_GetGroundedOriginEx;
begin
  Result := World.TraceLine(CL_GetOrigin, CL_GetOrigin - TVec3F.Create(0, 0, MAX_UNITS)).EndPos;
end;
    {$ENDREGION}

  {$REGION 'Resources'}
    {$REGION 'CL_NeedToDownloadResource'}
function TXExtendedGameClient.CL_NeedToDownloadResource(AResource: TResource; CustomName: LStr = ''): Boolean;

  function IsWorldExist: Boolean;
  var
    S: LStr;
  begin
    S := TPath.GetFileNameWithoutExtension(ExtractFileName(GetServerInfo.Map)) + '.bsp';

    if FileExists(S) then
      Result := True
    else
      if FileExists('worlds\' + S) then
        Result := True
      else
        if FileExists('maps\' + S) then
          Result := True
        else
          if FileExists(GetServerInfo.GameDir + '\worlds\' + S) then
            Result := True
          else
            if FileExists(GetServerInfo.GameDir + '\maps\' + S) then
              Result := True
            else
              Result := False;
  end;

var
  S: LStr;
begin
  if CustomName <> '' then
    S := CustomName
  else
    S := AResource.Name;

  if inherited then
    Exit(True);

  if CL_DownloadWorld and (S = GetServerInfo.Map) and not IsWorldExist then
    Exit(True);

  Result := False;
end;

procedure TXExtendedGameClient.CL_ReadERoundTime(Time: Int16);
begin
  inherited;

  if FEndOfRound then
    CL_ExecuteTrigger('RoundStart');
end;

procedure TXExtendedGameClient.CL_ReadETextMsg(Data: TTextMsg);
begin
  inherited;

  CL_ExecuteTriggerByText(Data.Data);
end;

procedure TXExtendedGameClient.CL_ReadEVGUIMenu(Data: TVGUIMenu);
begin
  case Data.Index of
    VGUI_CHOOSE_TEAM:
      if CL_AutoJoinTeam and not FTryedJoinTeam then // no relchan overflowed
      begin
        case CL_AutoJoinTeam_Value of
          0:
          begin
            ExecuteCommand('later 0.5 "jointeam 5"');
            Hint(H_ENGINE, ['joining to random team']);
          end;
          1:
          begin
            ExecuteCommand('later 0.5 "jointeam 1"');
            Hint(H_ENGINE, ['joining to first team']);
          end;
          2:
          begin
            ExecuteCommand('later 0.5 "jointeam 2"');
            Hint(H_ENGINE, ['joining to secons team']);
          end;
        else
          Error('CL_ReadEVGUIMenu', ['unkown autojointeam value: ', CL_AutoJoinTeam_Value, ', value must be in 0..2, 0 is random']);
        end;

        FTryedJoinTeam := True;

        Exit;
      end;

    VGUI_CHOOSE_CLASS_TFC:
      if CL_AutoJoinClass then
      begin
        case CL_AutoJoinClass_Value of
          0: ; // write every class here
        end;

        ExecuteCommand('randompc'); // <- delete it after
      end;

    VGUI_CHOOSE_CLASS_ALLIES,
    VGUI_CHOOSE_CLASS_BRITISH,
    VGUI_CHOOSE_CLASS_AXIS:
      if CL_AutoJoinClass then
      begin
        case CL_AutoJoinClass_Value of
          0: ; // write every class here
        end;

        ExecuteCommand('cls_random');
      end;

    VGUI_CHOOSE_MODEL_T,
    VGUI_CHOOSE_MODEL_CT:
      if CL_AutoJoinClass then
      begin
        case CL_AutoJoinClass_Value of
          0:
            begin
              ExecuteCommand('joinclass 6');
              Hint(H_ENGINE, ['joining to random class']);
            end;
          else
            if CL_AutoJoinClass_Value in [1..5] then
            begin
              ExecuteCommand(['joinclass ', CL_AutoJoinClass_Value]);
              Hint(H_ENGINE, ['joining to class, ', CL_AutoJoinClass_Value]);
            end
            else
              Error('CL_ReadEVGUIMenu', ['unkown autojoinclass value: ', CL_AutoJoinClass_Value, ', value must be in 0..5, 0 is random']);
          end;

        Exit;
      end;
  end;

  inherited;
end;

procedure TXExtendedGameClient.CL_ParseTETextMessage;
var
  Effect: UInt8;
begin
  MSG.SavePosition;
  inherited;
  MSG.RestorePosition;

  MSG.Skip(5);

  Effect := MSG.ReadUInt8;

  MSG.Skip(14);

  if Effect = 2 then
    MSG.Skip(2);

  CL_ExecuteTriggerByText(MSG.ReadLStr);
end;

procedure TXExtendedGameClient.CL_ExecuteTrigger(ATrigger: LStr);
var
  I: Int32;
begin
  I := TriggerTypes.IndexOf(ATrigger);

  if I = -1 then
  begin
    Error('CL_ExecuteTrigger', ['unkown trigger "', ATrigger, '"']);
    Exit;
  end;

  Hint(H_ENGINE, ['triggered: "', ATrigger, '"']);

  if Assigned(TriggerTypes.Items[I].Callback) then
    TriggerTypes.Items[I].Callback;

  Lua.Call('OnTrigger', [ATrigger])
end;

procedure TXExtendedGameClient.CL_ExecuteTriggerByText(AText: LStr);
var
  I: Int32;
begin
  for I := 0 to Triggers.Count - 1 do
    if StrBComp(AText, Triggers[I].Value) then
    begin
      CL_ExecuteTrigger(Triggers[I].Key);
      Exit;
    end;
end;

procedure TXExtendedGameClient.CL_RoundEnd_T;
begin
  FEndOfRound := True;
end;

procedure TXExtendedGameClient.CL_RoundStart_T;
begin
  FEndOfRound := False;
end;

procedure TXExtendedGameClient.CL_BombDropped_T;
begin
  FIsBombDropped := True;
end;

procedure TXExtendedGameClient.CL_BombPickedUp_T;
begin
  FIsBombDropped := False;
end;

procedure TXExtendedGameClient.CMD_RegisterCommands;
begin
  inherited;

  with Commands do
  begin
    Add('_firstspawn', CL_WriteCommand, 'first spawn (dmc)', CMD_HIDE or CMD_ONLY_IN_GAME); // dmc

    // cs, cz, tfc, dod
    Add('jointeam', CL_JoinTeam_F, 'join team (1\2\5)', CMD_HIDE or CMD_ONLY_IN_GAME); // cs, cz

    // cs
    Add('joinclass', CL_JoinClass_F, 'join class (1\2\3\4\6)', CMD_HIDE or CMD_ONLY_IN_GAME); // cs, cz
    Add('chooseteam', CL_WriteCommand, 'choose team (cs, cz)', CMD_HIDE or CMD_ONLY_IN_GAME);

    // tfc, dod. вызывают vgui меню.
    Add('changeteam', CL_WriteCommand, 'change team (tfc)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('changeclass', CL_WriteCommand, 'change class (tfc)', CMD_HIDE or CMD_ONLY_IN_GAME);

    // tfc classes                     fix this descriptions
    Add('civilian', CL_WriteCommand, 'Civilian (tfc)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('scout', CL_WriteCommand, 'Scout (tfc)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('sniper', CL_WriteCommand, 'Sniper (tfc)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('soldier', CL_WriteCommand, 'Soldier (tfc)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('demoman', CL_WriteCommand, 'Demoman (tfc)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('medic', CL_WriteCommand, 'Medic (tfc)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('hwguy', CL_WriteCommand, 'Heavy (tfc)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('pyro', CL_WriteCommand, 'Pyro (tfc)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('spy', CL_WriteCommand, 'Spy (tfc)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('engineer', CL_WriteCommand, 'Engineer (tfc)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('randompc', CL_WriteCommand, 'Random (tfc)', CMD_HIDE or CMD_ONLY_IN_GAME);

    // dod classes
    Add('cls_garand', CL_WriteCommand, 'Rifleman (M1 Garand) (dod)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('cls_carbine', CL_WriteCommand, 'Staff Sergeant (M1 Carbine) (dod)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('cls_tommy', CL_WriteCommand, 'Master Sergeant (Thompson) (dod)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('cls_grease', CL_WriteCommand, 'Sergeant (Greasegun) (dod)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('cls_spring', CL_WriteCommand, 'Sniper (Springfield) (dod)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('cls_bar', CL_WriteCommand, 'Support Infantry (BAR) (dod)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('cls_30cal', CL_WriteCommand, 'Mashine Gunner (.30 Cal) (dod)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('cls_bazooka', CL_WriteCommand, 'Bazooka (Bazooka) (dod)', CMD_HIDE or CMD_ONLY_IN_GAME);

    Add('cls_k98', CL_WriteCommand, 'Grenadier (K98) (dod)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('cls_k43', CL_WriteCommand, 'Stosstruppe (K43) (dod)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('cls_mp40', CL_WriteCommand, 'Unteroffizier (MP40) (dod)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('cls_mp44', CL_WriteCommand, 'Sturmtruppe (STG44) (dod)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('cls_k98s', CL_WriteCommand, 'Scharfschutze (K98 Sniper) (dod)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('cls_mg34', CL_WriteCommand, 'MG34-Schutze (MG34) (dod)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('cls_mg42', CL_WriteCommand, 'MG42-Schutze (MG42) (dod)', CMD_HIDE or CMD_ONLY_IN_GAME);
    Add('cls_pschreck', CL_WriteCommand, 'Panzerjager (Panzerchreck) (dod)', CMD_HIDE or CMD_ONLY_IN_GAME);

    Add('cls_random', CL_WriteCommand, 'Random Class (dod)', CMD_HIDE or CMD_ONLY_IN_GAME);

    //
    Add('autobuy', CL_Autobuy_F, 'autobuy', CMD_ONLY_IN_GAME);

    // experimental
    Add('nav_info', CL_NavigationInfo_F, 'show navigation file info', CMD_PROTECTED);
    Add('nav_test', CL_NavigationTest_F, 'test navigation file', CMD_PROTECTED);
//    Add('wad_info', CL_TextureInfo_F, 'Show texture file info');

    //
    Add('trigger', CL_Trigger_F, 'add trigger', CMD_PROTECTED);

    //Add('test', CL_Test_F, 'test');

    Add('reload_ai', CL_InitializeLua, 'reload ai script', CMD_PROTECTED or CMD_ONLY_IN_GAME);
  end;
end;

procedure TXExtendedGameClient.CMD_RegisterCVars;
begin
  inherited;

  with CVars do
  begin
    // userinfo
    Add('_cl_autowepswitch', @CL_AutowepSwitch, '0', 'Auto Weapon Switch', CVAR_USERINFO);

    Add('emulator', @Emulator, 0, 'Emulator', CVAR_PRIVATE);
    Add('steamid', @SteamID, 0, 'SteamID', CVAR_PRIVATE);

    Add('cl_auto_jointeam', @CL_AutoJoinTeam, True, 'Auto Join Team', CVAR_PRIVATE); // dmc and cs
    Add('cl_auto_jointeam_value', @CL_AutoJoinTeam_Value, 0, 'A. Join Team Value (0/1/2)', CVAR_PRIVATE);

    Add('cl_auto_joinclass', @CL_AutoJoinClass, True, 'Auto Join Class', CVAR_PRIVATE);
    Add('cl_auto_joinclass_value', @CL_AutoJoinClass_Value, 0, 'A. Join Class Value (0/1/2/3/4/5)', CVAR_PRIVATE);

    Add('cl_autobuy_data', @CL_CS_AutoBuy_Data, 'm4a1 ak47 famas galil p90 mp5 primammo secammo defuser vesthelm vest hegren sgren flash flash deagle', 'Autobuy Data', CVAR_PRIVATE);

    Add('cl_download_world', @CL_DownloadWorld, True, 'Download world if not found', CVAR_PRIVATE);
    Add('cl_intellegence', @CL_Intellegence, True, 'Use lua framework', CVAR_PRIVATE);
  end;
end;

procedure TXExtendedGameClient.CL_JoinTeam_F;
begin
  if CMD.Count = 1 then
  begin
    PrintCMDUsage(['team id']);
    Exit;
  end;

  if not IsNumbers(CMD.Tokens[1]) then
  begin
    Print([Format(S_CMD_MUST_BE_INTEGER, [CMD.Tokens[1]])]);
    Exit;
  end;

  CL_WriteCommand;
end;

procedure TXExtendedGameClient.CL_JoinClass_F;
begin
  if CMD.Count = 1 then
  begin
    PrintCMDUsage(['class id']);
    Exit;
  end;

  if not IsNumbers(CMD.Tokens[1]) then
  begin
    Print([Format(S_CMD_MUST_BE_INTEGER, [CMD.Tokens[1]])]);
    Exit;
  end;

  CL_WriteCommand;
end;

procedure TXExtendedGameClient.CL_Autobuy_F;
begin
  if not FAutobuySet then
  begin
    CL_WriteCommand(['cl_setautobuy "', CL_CS_Autobuy_Data, '"']);
    FAutobuySet := True;
  end
  else
    CL_WriteCommand('cl_autobuy');
end;

procedure TXExtendedGameClient.CL_NavigationInfo_F;
var
  SR: TSearchRec;

  procedure PrintInfo(ANavigation: TNavMesh);
  var
    I: Int32;
  begin
    with ANavigation do
    begin
      Print([Name + ' navigation:']);
      Print(['Version: ', Version]);
      Print(['SubVersion: ', SubVersion]);
      Print(['WorldSize: ', WorldSize]);
      Print(['Areas: ', AreasCount]);
      Print(['Ladders: ', LaddersCount]);
      Print(['Hiding Spots: ', HidingSpotsCount]);
      Print(['Approaches: ', ApproachesCount]);
      Print(['Encounters: ', EncountersCount]);
      Print(['Locations: ']);

      if HasLocations then
        for I := Low(Locations) to High(Locations) do
          Print([' - ' + Locations[I]])
      else
        Print([' - no locations for this navigation found']);
    end;
  end;

  procedure Work(AFile: LStr);
  var
    N: TNavMesh;
  begin
    N := TNavMesh.Create;

    case N.LoadFromFile(AFile) of
      NAV_LOAD_OK: PrintInfo(N);
      NAV_LOAD_FILE_NOT_FOUND: Print(['Navigation not found']);
      NAV_LOAD_BAD_MAGIC: Print(['Bad navigation file']);
      NAV_LOAD_BAD_VERSION: Print(['Bad navigation version (', N.Version, '.', N.SubVersion, ')']);
      NAV_LOAD_BAD_DATA: Print(['Bad navigation']);
    end;

    N.Free;
  end;
begin
  if CMD.Count = 1 then
  begin
    if HasNavigation then
      PrintInfo(Navigation^)
    else
      Print([Format(S_CMD_USAGE, [CMD.Tokens[0], 'map'])]);

    Exit;
  end;

  if CMD.Tokens[1] = 'all' then
    if FindFirst('navigations\' + '*.nav', faAnyFile, SR) = 0 then
    begin
      repeat
        if (SR.Attr <> faDirectory) then
          Work(SR.Name)
      until FindNext(SR) <> 0;

      FindClose(SR);
    end
    else
      if FindFirst('maps\' + '*.nav', faAnyFile, SR) = 0 then
      begin
        repeat
          if (SR.Attr <> faDirectory) then
            Work(SR.Name)
        until FindNext(SR) <> 0;

        FindClose(SR);
      end
      else
        if FindFirst('*.nav', faAnyFile, SR) = 0 then
        begin
          repeat
            if (SR.Attr <> faDirectory) then
              Work(SR.Name)
          until FindNext(SR) <> 0;

          FindClose(SR);
        end
        else
  else
    Work(CMD.Tokens[1]);
end;

procedure TXExtendedGameClient.CL_NavigationTest_F;
var
  SR: TSearchRec;

  procedure Work(AFile: LStr);
  var
    I: Int32;
    S: LStr;
    N: TNavMesh;
  begin
    N := TNavMesh.Create;

    case N.LoadFromFile(S) of
      NAV_LOAD_OK: Hint(N.Name, ['Successful']);
      NAV_LOAD_FILE_NOT_FOUND: Error(N.Name, ['File not found']);
      NAV_LOAD_BAD_VERSION: Error(N.Name, ['Bad navigation version (', N.Version, '.', N.SubVersion, ')']);
      NAV_LOAD_BAD_MAGIC: Error(N.Name, ['Bad navigation file']);
      NAV_LOAD_BAD_DATA: Error(N.Name, ['Bad navigation']);
    end;

    N.Free;
  end;
begin
  if CMD.Count = 1 then
  begin
    Print([Format(S_CMD_USAGE, [CMD.Tokens[0], 'map'])]);
    Exit;
  end;

  if CMD.Tokens[1] = 'all' then
    if FindFirst('navigations\' + '*.nav', faAnyFile, SR) = 0 then
    begin
      repeat
        if (SR.Attr <> faDirectory) then
          Work(SR.Name)
      until FindNext(SR) <> 0;

      FindClose(SR);
    end
    else
      if FindFirst('maps\' + '*.nav', faAnyFile, SR) = 0 then
      begin
        repeat
          if (SR.Attr <> faDirectory) then
            Work(SR.Name)
        until FindNext(SR) <> 0;

        FindClose(SR);
      end
      else
        if FindFirst('*.nav', faAnyFile, SR) = 0 then
        begin
          repeat
            if (SR.Attr <> faDirectory) then
              Work(SR.Name)
          until FindNext(SR) <> 0;

          FindClose(SR);
        end
        else
  else
    Work(CMD.Tokens[1]);
end;

procedure TXExtendedGameClient.CL_Trigger_F;
var
  I: Int32;
  S: LStr;
begin
  with Triggers do
    if CMD.Count > 2 then
      if TriggerTypes.IndexOf(CMD.Tokens[1]) <> -1 then
        Add(CMD.Tokens[1], CMD.Tokens[2], False)
      else
        Print(['unknown trigger: "', CMD.Tokens[1], '"'])
    else
      if Count > 0 then
      begin
        WriteLine(S, 'Triggers: ');

        for I := 0 to Count - 1 do
          with Triggers[I] do
            WriteLine(S, '  ' + IntToStr(I + 1) + ') ' + Key + ': "' + Value + '"');

        Print([S]);
      end
      else
      begin
        Print(['No triggers registered.']);
        PrintCMDUsage(['type', 'how']);
      end;
end;

procedure TXExtendedGameClient.CMD_Version;
begin
  inherited;

  //Print(['AI Version: ', AI_VERSION]);
end;

constructor TXExtendedGameClient.Create;
begin
  inherited;

  Lua := TLua.Create;
  Lua.OnPrint := LuaPrint;
  Lua.RegisterFunctions(Self);

  FNavigationBase := TNavMesh.Create;
  FWorldBase := TWorld.Create;

  Triggers := TAliasList.Create;
  TriggerTypes := TCommandList.Create;

  with TriggerTypes do
  begin
    Add('RoundEnd', CL_RoundEnd_T);
    Add('RoundStart', CL_RoundStart_T);
    Add('BombPlanted');
    Add('BombDropped', CL_BombDropped_T);
    Add('BombPickedUp', CL_BombPickedUp_T);
   // Add('TeamChanged', AI_ResetScenario);   FIX
  end;
end;

destructor TXExtendedGameClient.Destroy;
begin
  if GetState > CS_DISCONNECTED then
    CL_FinalizeConnection;

  Lua.Free;

  FNavigationBase.Free;
  FWorldBase.Free;

  TriggerTypes.Free;
  Triggers.Free;

  inherited;
end;

function TXExtendedGameClient.Lua_ExecuteCommand(L: TLuaHandle): Int32;
begin
  ExecuteCommand(lua_tostring(L, 1));
  Result := 0;
end;

function TXExtendedGameClient.Lua_GetServer(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetServer.ToString]);
end;

function TXExtendedGameClient.Lua_GetTime(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetTime])
end;

function TXExtendedGameClient.Lua_GetClientOrigin(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.Origin.X, GetClientData.Origin.Y, GetClientData.Origin.Z]);
end;

function TXExtendedGameClient.Lua_GetClientVelocity(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.Velocity.X, GetClientData.Velocity.Y, GetClientData.Velocity.Z]);
end;

function TXExtendedGameClient.Lua_GetClientViewModel(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.ViewModel]);
end;

function TXExtendedGameClient.Lua_GetClientPunchAngle(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.PunchAngle.X, GetClientData.PunchAngle.Y, GetClientData.PunchAngle.Z]);
end;

function TXExtendedGameClient.Lua_GetClientFlags(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.Flags]);
end;

function TXExtendedGameClient.Lua_GetClientWaterLevel(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.WaterLevel]);
end;

function TXExtendedGameClient.Lua_GetClientWaterType(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.WaterType]);
end;

function TXExtendedGameClient.Lua_GetClientViewOffset(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.ViewOffset.X, GetClientData.ViewOffset.Y, GetClientData.ViewOffset.Z]);
end;

function TXExtendedGameClient.Lua_GetClientHealth(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.Health]);
end;

function TXExtendedGameClient.Lua_GetClientInDuck(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.InDuck]);
end;

function TXExtendedGameClient.Lua_GetClientWeapons(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.Weapons]);
end;

function TXExtendedGameClient.Lua_GetClientTimeStepSound(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.TimeStepSound]);
end;

function TXExtendedGameClient.Lua_GetClientDuckTime(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.DuckTime]);
end;

function TXExtendedGameClient.Lua_GetClientSwimTime(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.SwimTime]);
end;

function TXExtendedGameClient.Lua_GetClientWaterJumpTime(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.WaterJumpTime]);
end;

function TXExtendedGameClient.Lua_GetClientMaxSpeed(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.MaxSpeed]);
end;

function TXExtendedGameClient.Lua_GetClientFOV(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.FOV]);
end;

function TXExtendedGameClient.Lua_GetClientWeaponAnim(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.WeaponAnim]);
end;

function TXExtendedGameClient.Lua_GetClientID(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.ID]);
end;

function TXExtendedGameClient.Lua_GetClientAmmoShells(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.AmmoShells]);
end;

function TXExtendedGameClient.Lua_GetClientAmmoNails(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.AmmoNails]);
end;

function TXExtendedGameClient.Lua_GetClientAmmoCells(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.AmmoCells]);
end;

function TXExtendedGameClient.Lua_GetClientAmmoRockets(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.AmmoRockets]);
end;

function TXExtendedGameClient.Lua_GetClientNextAttack(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.NextAttack]);
end;

function TXExtendedGameClient.Lua_GetClientTFState(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.TFState]);
end;

function TXExtendedGameClient.Lua_GetClientPushMSec(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.PushMSec]);
end;

function TXExtendedGameClient.Lua_GetClientDeadFlag(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.DeadFlag]);
end;

function TXExtendedGameClient.Lua_GetClientPhysInfo(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.PhysInfo]);
end;

function TXExtendedGameClient.Lua_GetClientIUser1(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.IUser1]);
end;

function TXExtendedGameClient.Lua_GetClientIUser2(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.IUser2]);
end;

function TXExtendedGameClient.Lua_GetClientIUser3(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.IUser3]);
end;

function TXExtendedGameClient.Lua_GetClientIUser4(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.IUser4]);
end;

function TXExtendedGameClient.Lua_GetClientFUser1(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.FUser1]);
end;

function TXExtendedGameClient.Lua_GetClientFUser2(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.FUser2]);
end;

function TXExtendedGameClient.Lua_GetClientFUser3(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.FUser3]);
end;

function TXExtendedGameClient.Lua_GetClientFUser4(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.FUser4]);
end;

function TXExtendedGameClient.Lua_GetClientVUser1(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.VUser1.X, GetClientData.VUser1.Y, GetClientData.VUser1.Z]);
end;

function TXExtendedGameClient.Lua_GetClientVUser2(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.VUser2.X, GetClientData.VUser2.Y, GetClientData.VUser2.Z]);
end;

function TXExtendedGameClient.Lua_GetClientVUser3(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.VUser3.X, GetClientData.VUser3.Y, GetClientData.VUser3.Z]);
end;

function TXExtendedGameClient.Lua_GetClientVUser4(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetClientData.VUser4.X, GetClientData.VUser4.Y, GetClientData.VUser4.Z]);
end;

function TXExtendedGameClient.Lua_GetProtocol(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetServerInfo.Protocol])
end;

function TXExtendedGameClient.Lua_GetMaxPlayers(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetServerInfo.MaxPlayers])
end;

function TXExtendedGameClient.Lua_GetClientIndex(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetServerInfo.Index])
end;

function TXExtendedGameClient.Lua_GetGameDir(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetServerInfo.GameDir])
end;

function TXExtendedGameClient.Lua_GetMap(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetServerInfo.Map])
end;

function TXExtendedGameClient.Lua_GetMapEx(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetServerInfo.ResolveMapName])
end;

function TXExtendedGameClient.Lua_GetLightStylesCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [Length(GetLightStyles)])
end;

function TXExtendedGameClient.Lua_GetLightStyle(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetLightStyles[lua_tointeger(L, 1)]]);
end;

function TXExtendedGameClient.Lua_GetResourcesCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [Length(GetResources)]);
end;

function TXExtendedGameClient.Lua_GetResourceName(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetResources[lua_tointeger(L, 1)].Name]);
end;

function TXExtendedGameClient.Lua_GetResourceType(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetResources[lua_tointeger(L, 1)].RType]);
end;

function TXExtendedGameClient.Lua_GetResourceIndex(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetResources[lua_tointeger(L, 1)].Index]);
end;

function TXExtendedGameClient.Lua_GetResourceSize(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetResources[lua_tointeger(L, 1)].Size]);
end;

function TXExtendedGameClient.Lua_GetResourceFlags(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetResources[lua_tointeger(L, 1)].Flags]);
end;

function TXExtendedGameClient.Lua_GetIntermission(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetIntermission])
end;

function TXExtendedGameClient.Lua_IsPaused(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [IsPaused])
end;

function TXExtendedGameClient.Lua_GetPlayersCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [Length(Players)])
end;

function TXExtendedGameClient.Lua_GetPlayerUserInfo(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetPlayers[lua_tointeger(L, 1)].UserInfo]);
end;

function TXExtendedGameClient.Lua_GetPlayerKills(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetPlayers[lua_tointeger(L, 1)].Kills]);
end;

function TXExtendedGameClient.Lua_GetPlayerDeaths(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetPlayers[lua_tointeger(L, 1)].Deaths]);
end;

function TXExtendedGameClient.Lua_GetPlayerPing(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetPlayers[lua_tointeger(L, 1)].Ping]);
end;

function TXExtendedGameClient.Lua_GetPlayerLoss(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetPlayers[lua_tointeger(L, 1)].Loss]);
end;

function TXExtendedGameClient.Lua_GetPlayerTeam(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetPlayers[lua_tointeger(L, 1)].Team]);
end;

function TXExtendedGameClient.Lua_GetPlayerClassID(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetPlayers[lua_tointeger(L, 1)].ClassID]);
end;

function TXExtendedGameClient.Lua_GetPlayerTeamID(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetPlayers[lua_tointeger(L, 1)].TeamID]);
end;

function TXExtendedGameClient.Lua_GetPlayerHealth(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetPlayers[lua_tointeger(L, 1)].Health]);
end;

function TXExtendedGameClient.Lua_GetPlayerScoreAttrib(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetPlayers[lua_tointeger(L, 1)].ScoreAttrib]);
end;

function TXExtendedGameClient.Lua_GetPlayerLocation(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetPlayers[lua_tointeger(L, 1)].Location]);
end;

function TXExtendedGameClient.Lua_GetPlayerRadar(L: TLuaHandle): Int32;
begin
  with GetPlayers[lua_tointeger(L, 1)] do
    Result := TLua.Return(L, [Radar.X, Radar.Y, Radar.Z]);
end;

function TXExtendedGameClient.Lua_GetPlayerOrigin(L: TLuaHandle): Int32;
begin
  with GetPlayers[lua_tointeger(L, 1)] do
    Result := TLua.Return(L, [GetOrigin.X, GetOrigin.Y, GetOrigin.Z]);
end;

function TXExtendedGameClient.Lua_GetPlayerName(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetPlayers[lua_tointeger(L, 1)].GetName]);
end;

function TXExtendedGameClient.Lua_IsPlayerAlive(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetPlayers[lua_tointeger(L, 1)].IsCSAlive]);
end;

function TXExtendedGameClient.Lua_IsPlayerBomber(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetPlayers[lua_tointeger(L, 1)].IsCSBomber]);
end;

function TXExtendedGameClient.Lua_IsPlayerVIP(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetPlayers[lua_tointeger(L, 1)].IsCSVIP]);
end;

function TXExtendedGameClient.Lua_GetEntitiesCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [Length(GetEntities)])
end;

function TXExtendedGameClient.Lua_GetEntityType(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].EntityType]);
end;

function TXExtendedGameClient.Lua_GetEntityNumber(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].Number]);
end;

function TXExtendedGameClient.Lua_GetEntityMsgTime(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].MsgTime]);
end;

function TXExtendedGameClient.Lua_GetEntityMessageNum(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].MessageNum]);
end;

function TXExtendedGameClient.Lua_GetEntityOrigin(L: TLuaHandle): Int32;
begin
  with GetEntities[lua_tointeger(L, 1)] do
    Result := TLua.Return(L, [Origin.X, Origin.Y, Origin.Z]);
end;

function TXExtendedGameClient.Lua_GetEntityAngles(L: TLuaHandle): Int32;
begin
  with GetEntities[lua_tointeger(L, 1)] do
    Result := TLua.Return(L, [Angles.X, Angles.Y, Angles.Z]);
end;

function TXExtendedGameClient.Lua_GetEntityModelIndex(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].ModelIndex]);
end;

function TXExtendedGameClient.Lua_GetEntitySequence(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].Sequence]);
end;

function TXExtendedGameClient.Lua_GetEntityFrame(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].Frame]);
end;

function TXExtendedGameClient.Lua_GetEntityColorMap(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].ColorMap]);
end;

function TXExtendedGameClient.Lua_GetEntitySkin(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].Skin]);
end;

function TXExtendedGameClient.Lua_GetEntitySolid(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].Solid]);
end;

function TXExtendedGameClient.Lua_GetEntityEffects(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].Effects]);
end;

function TXExtendedGameClient.Lua_GetEntityScale(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].Scale]);
end;

function TXExtendedGameClient.Lua_GetEntityEFlags(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].EFlags]);
end;

function TXExtendedGameClient.Lua_GetEntityRenderMode(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].RenderMode]);
end;

function TXExtendedGameClient.Lua_GetEntityRenderAmt(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].RenderAmt]);
end;

function TXExtendedGameClient.Lua_GetEntityRenderFX(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].RenderFX]);
end;

function TXExtendedGameClient.Lua_GetEntityMoveType(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].MoveType]);
end;

function TXExtendedGameClient.Lua_GetEntityAnimTime(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].AnimTime]);
end;

function TXExtendedGameClient.Lua_GetEntityFrameRate(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].FrameRate]);
end;

function TXExtendedGameClient.Lua_GetEntityBody(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].Body]);
end;

function TXExtendedGameClient.Lua_GetEntityVelocity(L: TLuaHandle): Int32;
begin
  with GetEntities[lua_tointeger(L, 1)] do
    Result := TLua.Return(L, [Velocity.X, Velocity.Y, Velocity.Z]);
end;

function TXExtendedGameClient.Lua_GetEntityMinS(L: TLuaHandle): Int32;
begin
  with GetEntities[lua_tointeger(L, 1)] do
    Result := TLua.Return(L, [MinS.X, MinS.Y, MinS.Z]);
end;

function TXExtendedGameClient.Lua_GetEntityMaxS(L: TLuaHandle): Int32;
begin
  with GetEntities[lua_tointeger(L, 1)] do
    Result := TLua.Return(L, [MaxS.X, MaxS.Y, MaxS.Z]);
end;

function TXExtendedGameClient.Lua_GetEntityAimEnt(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].AimEnt]);
end;

function TXExtendedGameClient.Lua_GetEntityOwner(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].Owner]);
end;

function TXExtendedGameClient.Lua_GetEntityFriction(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].Friction]);
end;

function TXExtendedGameClient.Lua_GetEntityGravity(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].Gravity]);
end;

function TXExtendedGameClient.Lua_GetEntityTeam(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].Team]);
end;

function TXExtendedGameClient.Lua_GetEntityPlayerClass(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].PlayerClass]);
end;

function TXExtendedGameClient.Lua_GetEntityHealth(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].Health]);
end;

function TXExtendedGameClient.Lua_GetEntitySpectator(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].Spectator]);
end;

function TXExtendedGameClient.Lua_GetEntityWeaponModel(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].WeaponModel]);
end;

function TXExtendedGameClient.Lua_GetEntityGaitSequence(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].GaitSequence]);
end;

function TXExtendedGameClient.Lua_GetEntityBaseVelocity(L: TLuaHandle): Int32;
begin
  with GetEntities[lua_tointeger(L, 1)] do
    Result := TLua.Return(L, [BaseVelocity.X, BaseVelocity.Y, BaseVelocity.Z]);
end;

function TXExtendedGameClient.Lua_GetEntityUseHull(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].UseHull]);
end;

function TXExtendedGameClient.Lua_GetEntityOldButtons(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].OldButtons]);
end;

function TXExtendedGameClient.Lua_GetEntityOnGround(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].OnGround]);
end;

function TXExtendedGameClient.Lua_GetEntityStepLeft(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].StepLeft]);
end;

function TXExtendedGameClient.Lua_GetEntityFallVelocity(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].FallVelocity]);
end;

function TXExtendedGameClient.Lua_GetEntityFOV(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].Fov]);
end;

function TXExtendedGameClient.Lua_GetEntityWeaponAnim(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].WeaponAnim]);
end;

function TXExtendedGameClient.Lua_GetEntityStartPos(L: TLuaHandle): Int32;
begin
  with GetEntities[lua_tointeger(L, 1)] do
    Result := TLua.Return(L, [StartPos.X, StartPos.Y, StartPos.Z]);
end;

function TXExtendedGameClient.Lua_GetEntityEndPos(L: TLuaHandle): Int32;
begin
  with GetEntities[lua_tointeger(L, 1)] do
    Result := TLua.Return(L, [EndPos.X, EndPos.Y, EndPos.Z]);
end;

function TXExtendedGameClient.Lua_GetEntityImpactTime(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].ImpactTime]);
end;

function TXExtendedGameClient.Lua_GetEntityStartTime(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].StartTime]);
end;

function TXExtendedGameClient.Lua_GetEntityIUser1(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].IUser1]);
end;

function TXExtendedGameClient.Lua_GetEntityIUser2(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].IUser2]);
end;

function TXExtendedGameClient.Lua_GetEntityIUser3(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].IUser3]);
end;

function TXExtendedGameClient.Lua_GetEntityIUser4(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].IUser4]);
end;

function TXExtendedGameClient.Lua_GetEntityFUser1(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].FUser1]);
end;

function TXExtendedGameClient.Lua_GetEntityFUser2(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].FUser2]);
end;

function TXExtendedGameClient.Lua_GetEntityFUser3(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].FUser3]);
end;

function TXExtendedGameClient.Lua_GetEntityFUser4(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].FUser4]);
end;

function TXExtendedGameClient.Lua_GetEntityVUser1(L: TLuaHandle): Int32;
begin
  with GetEntities[lua_tointeger(L, 1)] do
    Result := TLua.Return(L, [VUser1.X, VUser1.Y, VUser1.Z]);
end;

function TXExtendedGameClient.Lua_GetEntityVUser2(L: TLuaHandle): Int32;
begin
  with GetEntities[lua_tointeger(L, 1)] do
    Result := TLua.Return(L, [VUser2.X, VUser2.Y, VUser2.Z]);
end;

function TXExtendedGameClient.Lua_GetEntityVUser3(L: TLuaHandle): Int32;
begin
  with GetEntities[lua_tointeger(L, 1)] do
    Result := TLua.Return(L, [VUser3.X, VUser3.Y, VUser3.Z]);
end;

function TXExtendedGameClient.Lua_GetEntityVUser4(L: TLuaHandle): Int32;
begin
  with GetEntities[lua_tointeger(L, 1)] do
    Result := TLua.Return(L, [VUser4.X, VUser4.Y, VUser4.Z]);
end;

function TXExtendedGameClient.Lua_IsEntityActive(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetEntities[lua_tointeger(L, 1)].IsActive])
end;

function TXExtendedGameClient.Lua_IsPlayerIndex(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [IsPlayerIndex[lua_tointeger(L, 1)]]);
end;

function TXExtendedGameClient.Lua_MoveTo(L: TLuaHandle): Int32;
begin
  case lua_gettop(L) of
    1:
      if IsPlayerIndex[lua_tointeger(L, 1)] then
        MoveTo(GetPlayers[lua_tointeger(L, 1) - 1])
      else
        MoveTo(GetEntities[lua_tointeger(L, 1)]);

    2:
      if IsPlayerIndex[lua_tointeger(L, 1)] then
        MoveTo(GetPlayers[lua_tointeger(L, 1) - 1], lua_tonumber(L, 2))
      else
        MoveTo(GetEntities[lua_tointeger(L, 1)], lua_tonumber(L, 2));

    3: MoveTo(TVec3F.Create(lua_tonumber(L, 1), lua_tonumber(L, 2), lua_tonumber(L, 3)));
    4: MoveTo(TVec3F.Create(lua_tonumber(L, 1), lua_tonumber(L, 2), lua_tonumber(L, 3)), lua_tonumber(L, 4));
  end;

  Result := 0;
end;

function TXExtendedGameClient.Lua_MoveOut(L: TLuaHandle): Int32;
begin
  case lua_gettop(L) of
    1:
      if IsPlayerIndex[lua_tointeger(L, 1)] then
        MoveOut(GetPlayers[lua_tointeger(L, 1) - 1])
      else
        MoveOut(GetEntities[lua_tointeger(L, 1)]);

    2:
      if IsPlayerIndex[lua_tointeger(L, 1)] then
        MoveOut(GetPlayers[lua_tointeger(L, 1) - 1], lua_tonumber(L, 2))
      else
        MoveOut(GetEntities[lua_tointeger(L, 1)], lua_tonumber(L, 2));

    3: MoveOut(TVec3F.Create(lua_tonumber(L, 1), lua_tonumber(L, 2), lua_tonumber(L, 3)));
    4: MoveOut(TVec3F.Create(lua_tonumber(L, 1), lua_tonumber(L, 2), lua_tonumber(L, 3)), lua_tonumber(L, 4));
  end;

  Result := 0;
end;

function TXExtendedGameClient.Lua_LookAt(L: TLuaHandle): Int32;
begin
  if lua_gettop(L) = 3 then
    LookAt(TVec3F.Create(lua_tonumber(L, 1), lua_tonumber(L, 2), lua_tonumber(L, 3)))
  else
    if IsPlayerIndex[lua_tointeger(L, 1)] then
      LookAt(GetPlayers[lua_tointeger(L, 1) - 1])
    else
      LookAt(GetEntities[lua_tointeger(L, 1)]);

  Result := 0;
end;

function TXExtendedGameClient.Lua_LookAtEx(L: TLuaHandle): Int32;
begin
  if lua_gettop(L) = 3 then
    LookAtEx(TVec3F.Create(lua_tonumber(L, 1), lua_tonumber(L, 2), lua_tonumber(L, 3)))
  else
    if IsPlayerIndex[lua_tointeger(L, 1)] then
      LookAtEx(GetPlayers[lua_tointeger(L, 1) - 1])
    else
      LookAtEx(GetEntities[lua_tointeger(L, 1)]);

  Result := 0;
end;

function TXExtendedGameClient.Lua_GetViewAngles(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetViewAngles.X, GetViewAngles.Y, GetViewAngles.Z]);
end;

function TXExtendedGameClient.Lua_SetViewAngles(L: TLuaHandle): Int32;
begin
  SetViewAngles := TVec3F.Create(lua_tonumber(L, 1), lua_tonumber(L, 2), lua_tonumber(L, 3));
  Result := 0;
end;

function TXExtendedGameClient.Lua_PressButton(L: TLuaHandle): Int32;
begin
  PressButton(lua_tointeger(L, 1));
  Result := 0;
end;

function TXExtendedGameClient.Lua_UnPressButton(L: TLuaHandle): Int32;
begin
  UnPressButton(lua_tointeger(L, 1));
  Result := 0;
end;

function TXExtendedGameClient.Lua_IsButtonPressed(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [IsButtonPressed[lua_tointeger(L, 1)]]);
end;

function TXExtendedGameClient.Lua_GetOrigin(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetOrigin.X, GetOrigin.Y, GetOrigin.Z]);
end;

function TXExtendedGameClient.Lua_GetVelocity(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetVelocity.X, GetVelocity.Y, GetVelocity.Z]);
end;

function TXExtendedGameClient.Lua_GetPunchAngle(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetPunchAngle.X, GetPunchAngle.Y, GetPunchAngle.Z]);
end;

function TXExtendedGameClient.Lua_GetWeaponAbsoluteIndex(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWeaponIndex])
end;

function TXExtendedGameClient.Lua_GetFieldOfView(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetFieldOfView])
end;

function TXExtendedGameClient.Lua_GetDistance(L: TLuaHandle): Int32;
begin
  if lua_gettop(L) = 3 then
    Result := TLua.Return(L, [GetDistance(TVec3F.Create(lua_tonumber(L, 1), lua_tonumber(L, 2), lua_tonumber(L, 3)))])
  else
    if IsPlayerIndex[lua_tointeger(L, 1)] then
      Result := TLua.Return(L, [GetDistance(GetPlayers[lua_tointeger(L, 1) - 1])])
    else
      Result := TLua.Return(L, [GetDistance(GetEntities[lua_tointeger(L, 1)])]);
end;

function TXExtendedGameClient.Lua_GetDistance2D(L: TLuaHandle): Int32;
begin
  if lua_gettop(L) = 3 then
    Result := TLua.Return(L, [GetDistance2D(TVec3F.Create(lua_tonumber(L, 1), lua_tonumber(L, 2), lua_tonumber(L, 3)))])
  else
    if IsPlayerIndex[lua_tointeger(L, 1)] then
      Result := TLua.Return(L, [GetDistance2D(GetPlayers[lua_tointeger(L, 1) - 1])])
    else
      Result := TLua.Return(L, [GetDistance2D(GetEntities[lua_tointeger(L, 1)])]);
end;

function TXExtendedGameClient.Lua_IsWeaponExists(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [IsWeaponExists(lua_tointeger(L, 1))])
end;

function TXExtendedGameClient.Lua_IsCrouching(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [IsCrouching]);
end;

function TXExtendedGameClient.Lua_IsOnGround(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [IsOnGround]);
end;

function TXExtendedGameClient.Lua_IsSpectator(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [IsSpectator]);
end;

function TXExtendedGameClient.Lua_HasWeaponData(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWeaponData(lua_tointeger(L, 1)) <> nil])
end;

function TXExtendedGameClient.Lua_GetWeaponDataField(L: TLuaHandle): Int32;
const
  AID = 1;
  AClip = 2;
  ANextPrimaryAttack = 3;
  ANextSecondaryAttack = 4;
  ATimeWeaponIdle = 5;
  AInReload = 6;
  AInSpecialReload = 7;
  ANextReload = 8;
  APumpTime = 9;
  AReloadTime = 10;
  AAimedDamage = 11;
  ANextAimBonus = 12;
  AInZoom = 13;
  AWeaponState = 14;
  AIUser1 = 15;
  AIUser2 = 16;
  AIUser3 = 17;
  AIUser4 = 18;
  AFUser1 = 19;
  AFUser2 = 20;
  AFUser3 = 21;
  AFUser4 = 22;
begin
  with GetWeaponData(lua_tointeger(L, 1))^ do
    case lua_tointeger(L, 2) of
      AID: Result := TLua.Return(L, [ID]);
      AClip: Result := TLua.Return(L, [Clip]);
      ANextPrimaryAttack: Result := TLua.Return(L, [NextPrimaryAttack]);
      ANextSecondaryAttack: Result := TLua.Return(L, [NextSecondaryAttack]);
      ATimeWeaponIdle: Result := TLua.Return(L, [TimeWeaponIdle]);
      AInReload: Result := TLua.Return(L, [InReload]);
      AInSpecialReload: Result := TLua.Return(L, [InSpecialReload]);
      ANextReload: Result := TLua.Return(L, [NextReload]);
      APumpTime: Result := TLua.Return(L, [PumpTime]);
      AReloadTime: Result := TLua.Return(L, [ReloadTime]);
      AAimedDamage: Result := TLua.Return(L, [AimedDamage]);
      ANextAimBonus: Result := TLua.Return(L, [NextAimBonus]);
      AInZoom: Result := TLua.Return(L, [InZoom]);
      AWeaponState: Result := TLua.Return(L, [WeaponState]);
      AIUser1: Result := TLua.Return(L, [IUser1]);
      AIUser2: Result := TLua.Return(L, [IUser2]);
      AIUser3: Result := TLua.Return(L, [IUser3]);
      AIUser4: Result := TLua.Return(L, [IUser4]);
      AFUser1: Result := TLua.Return(L, [FUser1]);
      AFUser2: Result := TLua.Return(L, [FUser2]);
      AFUser3: Result := TLua.Return(L, [FUser3]);
      AFUser4: Result := TLua.Return(L, [FUser4]);
    end;
end;

function TXExtendedGameClient.Lua_IsReloading(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [IsReloading]);
end;

function TXExtendedGameClient.Lua_GetMaxSpeed(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetMaxSpeed])
end;

function TXExtendedGameClient.Lua_CanAttack(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [CanAttack])
end;

function TXExtendedGameClient.Lua_InFieldOfView(L: TLuaHandle): Int32;
begin
  if lua_gettop(L) = 3 then
    Result := TLua.Return(L, [InFieldOfView(TVec3F.Create(lua_tonumber(L, 1), lua_tonumber(L, 2), lua_tonumber(L, 3)))])
  else
    if IsPlayerIndex[lua_tointeger(L, 1)] then
      Result := TLua.Return(L, [InFieldOfView(GetPlayers[lua_tointeger(L, 1) - 1])])
    else
      Result := TLua.Return(L, [InFieldOfView(GetEntities[lua_tointeger(L, 1)])]);
end;

function TXExtendedGameClient.Lua_IsAlive(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [IsAlive]);
end;

function TXExtendedGameClient.Lua_UseEnvironment(L: TLuaHandle): Int32;
begin
  UseEnvironment;
  Result := 0;
end;

function TXExtendedGameClient.Lua_PrimaryAttack(L: TLuaHandle): Int32;
begin
  PrimaryAttack;
  Result := 0;
end;

function TXExtendedGameClient.Lua_SecondaryAttack(L: TLuaHandle): Int32;
begin
  SecondaryAttack;
  Result := 0;
end;

function TXExtendedGameClient.Lua_FastPrimaryAttack(L: TLuaHandle): Int32;
begin
  FastPrimaryAttack;
  Result := 0;
end;

function TXExtendedGameClient.Lua_FastSecondaryAttack(L: TLuaHandle): Int32;
begin
  FastSecondaryAttack;
  Result := 0;
end;

function TXExtendedGameClient.Lua_Jump(L: TLuaHandle): Int32;
begin
  Jump;
  Result := 0;
end;

function TXExtendedGameClient.Lua_Duck(L: TLuaHandle): Int32;
begin
  Duck;
  Result := 0;
end;

function TXExtendedGameClient.Lua_DuckJump(L: TLuaHandle): Int32;
begin
  DuckJump;
  Result := 0;
end;

function TXExtendedGameClient.Lua_GetGroundedOrigin(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetGroundedOrigin.X, GetGroundedOrigin.Y, GetGroundedOrigin.Z]);
end;

function TXExtendedGameClient.Lua_GetGroundedDistance(L: TLuaHandle): Int32;
begin
  if lua_gettop(L) = 3 then
    Result := TLua.Return(L, [GetGroundedDistance(TVec3F.Create(lua_tonumber(L, 1), lua_tonumber(L, 2), lua_tonumber(L, 3)))])
  else
    if IsPlayerIndex[lua_tointeger(L, 1)] then
      Result := TLua.Return(L, [GetGroundedDistance(GetPlayers[lua_tointeger(L, 1) - 1])])
    else
      Result := TLua.Return(L, [GetGroundedDistance(GetEntities[lua_tointeger(L, 1)])]);
end;

function TXExtendedGameClient.Lua_GetHideWeapon(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetHideWeapon]);
end;

function TXExtendedGameClient.Lua_GetHealth(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetHealth])
end;

function TXExtendedGameClient.Lua_GetFlashBat(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetFlashBat]);
end;

function TXExtendedGameClient.Lua_IsFlashlightActive(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetIsFlashlightActive]);
end;

function TXExtendedGameClient.Lua_GetBattery(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetBattery]);
end;

function TXExtendedGameClient.Lua_GetWeaponsCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [Length(GetWeapons)])
end;

function TXExtendedGameClient.Lua_GetWeaponName(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWeapons[lua_tointeger(L, 1)].Name])
end;

function TXExtendedGameClient.Lua_GetWeaponPrimaryAmmoID(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWeapons[lua_tointeger(L, 1)].PrimaryAmmoID])
end;

function TXExtendedGameClient.Lua_GetWeaponPrimaryAmmoMaxAmount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWeapons[lua_tointeger(L, 1)].PrimaryAmmoMaxAmount])
end;

function TXExtendedGameClient.Lua_GetWeaponSecondaryAmmoID(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWeapons[lua_tointeger(L, 1)].SecondaryAmmoID])
end;

function TXExtendedGameClient.Lua_GetWeaponSecondaryAmmoMaxAmount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWeapons[lua_tointeger(L, 1)].SecondaryAmmoMaxAmount])
end;

function TXExtendedGameClient.Lua_GetWeaponSlotID(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWeapons[lua_tointeger(L, 1)].SlotID])
end;

function TXExtendedGameClient.Lua_GetWeaponNumberInSlot(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWeapons[lua_tointeger(L, 1)].NumberInSlot])
end;

function TXExtendedGameClient.Lua_GetWeaponIndex(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWeapons[lua_tointeger(L, 1)].Index])
end;

function TXExtendedGameClient.Lua_GetWeaponFlags(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWeapons[lua_tointeger(L, 1)].Flags])
end;

function TXExtendedGameClient.Lua_GetWeaponNameEx(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWeapons[lua_tointeger(L, 1)].ResolveName])
end;

function TXExtendedGameClient.Lua_GetWeaponByAbsoluteIndex(L: TLuaHandle): Int32;
var
  I, J: Int;
begin
  J := lua_tointeger(L, 1);

  for I := Low(GetWeapons) to High(GetWeapons) do
    if GetWeapons[I].Index = J then
      Exit(TLua.Return(L, [I]));

  Result := TLua.Return(L, [nil]);
end;

function TXExtendedGameClient.Lua_GetStatusValuesCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [Length(GetStatusValue)]);
end;

function TXExtendedGameClient.Lua_GetStatusValue(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetStatusValue[lua_tointeger(L, 1)]]);
end;

function TXExtendedGameClient.Lua_GetStatusIconsCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [Length(GetStatusIcons)])
end;

function TXExtendedGameClient.Lua_GetStatusIconName(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetStatusIcons[lua_tointeger(L, 1)].Name]);
end;

function TXExtendedGameClient.Lua_GetStatusIconStatus(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetStatusIcons[lua_tointeger(L, 1)].Status])
end;

function TXExtendedGameClient.Lua_GetBombStateActive(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetBombState.Active]);
end;

function TXExtendedGameClient.Lua_GetBombStatePosition(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetBombState.Position.X, GetBombState.Position.Y, GetBombState.Position.Z]);
end;

function TXExtendedGameClient.Lua_GetBombStatePlanted(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetBombState.IsPlanted]);
end;

function TXExtendedGameClient.Lua_GetRoundTime(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetRoundTime]);
end;

function TXExtendedGameClient.Lua_GetMoney(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetMoney]);
end;

function TXExtendedGameClient.Lua_IsTeamPlay(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetIsTeamPlay]);
end;

function TXExtendedGameClient.Lua_GetAmmo(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetAmmo[lua_tointeger(L, 1)]])
end;

procedure TXExtendedGameClient.LuaPrint(A: LStr);
begin
  Hint('AI', [A]);
end;

function TXExtendedGameClient.Lua_HasNavigation(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [HasNavigation]);
end;

function TXExtendedGameClient.Lua_HasWorld(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [HasWorld]);
end;

function TXExtendedGameClient.Lua_HasWays(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [HasWays]);
end;

function TXExtendedGameClient.Lua_IsVisible(L: TLuaHandle): Int32;
begin
  if lua_gettop(L) = 3 then
    Result := TLua.Return(L, [CL_IsVisible(TVec3F.Create(lua_tonumber(L, 1), lua_tonumber(L, 2), lua_tonumber(L, 3)))])
  else
    if IsPlayerIndex[lua_tointeger(L, 1)] then
      Result := TLua.Return(L, [CL_IsVisible(GetOrigin, GetPlayers[lua_tointeger(L, 1) - 1].GetOrigin, [lua_tointeger(L, 1)])])
    else
      Result := TLua.Return(L, [CL_IsVisible(GetOrigin, GetEntities[lua_tointeger(L, 1)].Origin, [lua_tointeger(L, 1)])])
end;

function TXExtendedGameClient.Lua_GetGroundedOriginEx(L: TLuaHandle): Int32;
var
  V: TVec3F;
begin
  V := CL_GetGroundedOriginEx;

  Result := TLua.Return(L, [V.X, V.Y, V.Z]);
end;

function TXExtendedGameClient.Lua_GetNavArea(L: TLuaHandle): Int32;
var
  A: PNavArea;
  I: Int32;
begin
  case lua_gettop(L) of
    0: A := GetNavigation.GetArea(GetGroundedOrigin);
    1: A := GetNavigation.GetArea(lua_tointeger(L, 1));
    3: A := GetNavigation.GetArea(TVec3F.Create(lua_tonumber(L, 1), lua_tonumber(L, 2), lua_tonumber(L, 3)));
  end;

  I := GetNavigation.GetAbsoluteIndex(A);

  if I = -1 then
    Result := TLua.Return(L, [nil])
  else
    Result := TLua.Return(L, [I]);
end;

function TXExtendedGameClient.Lua_GetRandomNavArea(L: TLuaHandle): Int32;
var
  I: Int32;
begin
  I := GetNavigation.GetAbsoluteIndex(GetNavigation.GetRandomArea);

  if I = -1 then
    Result := TLua.Return(L, [nil])
  else
    Result := TLua.Return(L, [I]);
end;

function TXExtendedGameClient.Lua_GetNavAreaIndex(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetNavigation.Areas[lua_tointeger(L, 1)].Index]);
end;

function TXExtendedGameClient.Lua_GetNavAreaFlags(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetNavigation.Areas[lua_tointeger(L, 1)].Flags]);
end;

function TXExtendedGameClient.Lua_GetNavAreaName(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetNavigation.Areas[lua_tointeger(L, 1)].ToString]);
end;

function TXExtendedGameClient.Lua_GetNavAreaCenter(L: TLuaHandle): Int32;
begin
  with GetNavigation.Areas[lua_tointeger(L, 1)] do
    Result := TLua.Return(L, [GetCenter.X, GetCenter.Y, GetCenter.Z]);
end;

function TXExtendedGameClient.Lua_GetNavAreaConnectionsCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetNavigation.Areas[lua_tointeger(L, 1)].ConnectionsCount]);
end;

function TXExtendedGameClient.Lua_GetNavAreaHidingSpotsCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetNavigation.Areas[lua_tointeger(L, 1)].HidingSpotsCount]);
end;

function TXExtendedGameClient.Lua_GetNavAreaApproachesCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetNavigation.Areas[lua_tointeger(L, 1)].ApproachesCount]);
end;

function TXExtendedGameClient.Lua_GetNavAreaApproachHere(L: TLuaHandle): Int32;
var
  I: Int32;
begin
  I := GetNavigation.GetAbsoluteIndex(GetNavigation.Areas[lua_tointeger(L, 1)].Approaches[lua_tointeger(L, 2)].Here);

  if I = -1 then
    Result := TLua.Return(L, [nil])
  else
    Result := TLua.Return(L, [I]);
end;

function TXExtendedGameClient.Lua_GetNavAreaApproachPrev(L: TLuaHandle): Int32;
var
  I: Int32;
begin
  I := GetNavigation.GetAbsoluteIndex(GetNavigation.Areas[lua_tointeger(L, 1)].Approaches[lua_tointeger(L, 2)].Prev);

  if I = -1 then
    Result := TLua.Return(L, [nil])
  else
    Result := TLua.Return(L, [I]);
end;

function TXExtendedGameClient.Lua_GetNavAreaApproachNext(L: TLuaHandle): Int32;
var
  I: Int32;
begin
  I := GetNavigation.GetAbsoluteIndex(GetNavigation.Areas[lua_tointeger(L, 1)].Approaches[lua_tointeger(L, 2)].Next);

  if I = -1 then
    Result := TLua.Return(L, [nil])
  else
    Result := TLua.Return(L, [I]);
end;

function TXExtendedGameClient.Lua_GetNavAreaEncountersCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetNavigation.Areas[lua_tointeger(L, 1)].EncountersCount]);
end;

function TXExtendedGameClient.Lua_GetNavAreaLaddersCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetNavigation.Areas[lua_tointeger(L, 1)].LaddersCount]);
end;

function TXExtendedGameClient.Lua_GetNavAreaRandomConnection(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [Navigation.GetAbsoluteIndex(GetNavigation.Areas[lua_tointeger(L, 1)].GetRandomConnection)]);
end;

function TXExtendedGameClient.Lua_IsNavAreaConnected(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetNavigation.Areas[lua_tointeger(L, 1)].IsConnected(GetNavigation.Areas[lua_tointeger(L, 2)])]);
end;

function TXExtendedGameClient.Lua_IsNavAreaBiLinked(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetNavigation.Areas[lua_tointeger(L, 1)].IsBiLinked(GetNavigation.Areas[lua_tointeger(L, 2)])]);
end;

function TXExtendedGameClient.Lua_GetNavAreaPortal(L: TLuaHandle): Int32;
var
  A1, A2: TNavArea;
  A, B, V: TVec3F;
begin
  A1 := GetNavigation.Areas[lua_tointeger(L, 1)];
  A2 := GetNavigation.Areas[lua_tointeger(L, 2)];

  if lua_gettop(L) = 8 then
  begin
    A := TVec3F.Create(lua_tonumber(L, 3), lua_tonumber(L, 4), lua_tonumber(L, 5));
    B := TVec3F.Create(lua_tonumber(L, 6), lua_tonumber(L, 7), lua_tonumber(L, 8));

    V := A1.GetPortal(A2, A, B).Hi;
  end
  else
    V := A1.GetPortal(A2).Hi;

  Result := TLua.Return(L, [V.X, V.Y, V.Z]);
end;

function TXExtendedGameClient.Lua_GetNavAreaWindow(L: TLuaHandle): Int32;
var
  W: TVec3FLine;
begin
  W := GetNavigation.Areas[lua_tointeger(L, 1)].GetWindow(GetNavigation.Areas[lua_tointeger(L, 2)]);
  Result := TLua.Return(L, [W.Hi.X, W.Hi.Y, W.Hi.Z, W.Lo.X, W.Lo.Y, W.Lo.Z]);
end;

function TXExtendedGameClient.Lua_GetNavAreaWindowEx(L: TLuaHandle): Int32;
var
  W: TVec3FLine;
begin
  W := GetNavigation.Areas[lua_tointeger(L, 1)].GetWindowEx(GetNavigation.Areas[lua_tointeger(L, 2)]);
  Result := TLua.Return(L, [W.Hi.X, W.Hi.Y, W.Hi.Z, W.Lo.X, W.Lo.Y, W.Lo.Z]);
end;

function TXExtendedGameClient.Lua_GetNavHidingSpot(L: TLuaHandle): Int32;
var
  H: PNavHidingSpot;
  I: Int32;
begin
  case lua_gettop(L) of
    0: H := GetNavigation.GetHidingSpot(GetGroundedOrigin);
    1: H := GetNavigation.GetHidingSpot(lua_tointeger(L, 1));
    3: H := GetNavigation.GetHidingSpot(TVec3F.Create(lua_tonumber(L, 1), lua_tonumber(L, 2), lua_tonumber(L, 3)));
  end;

  I := GetNavigation.GetAbsoluteIndex(H);

  if I = -1 then
    Result := TLua.Return(L, [nil])
  else
    Result := TLua.Return(L, [I]);
end;

function TXExtendedGameClient.Lua_GetRandomNavHidingSpot(L: TLuaHandle): Int32;
var
  H: PNavHidingSpot;
  I: Int32;
begin
  case lua_gettop(L) of
    0: H := GetNavigation.GetRandomHidingSpot;
    4: H := GetNavigation.GetRandomHidingSpot(TVec3F.Create(lua_tonumber(L, 1), lua_tonumber(L, 2), lua_tonumber(L, 3)), lua_tonumber(L, 4));
  end;

  I := GetNavigation.GetAbsoluteIndex(H);

  if I = -1 then
    Result := TLua.Return(L, [nil])
  else
    Result := TLua.Return(L, [I]);
end;

function TXExtendedGameClient.Lua_GetNavHidingSpotIndex(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetNavigation.HidingSpots[lua_tointeger(L, 1)].Index]);
end;

function TXExtendedGameClient.Lua_GetNavHidingSpotPosition(L: TLuaHandle): Int32;
begin
  with GetNavigation.HidingSpots[lua_tointeger(L, 1)] do
    Result := TLua.Return(L, [Position.X, Position.Y, Position.Z]);
end;

function TXExtendedGameClient.Lua_GetNavHidingSpotFlags(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetNavigation.HidingSpots[lua_tointeger(L, 1)].Flags]);
end;

function TXExtendedGameClient.Lua_GetNavHidingSpotParent(L: TLuaHandle): Int32;
var
  I: Int32;
begin
  I := GetNavigation.GetAbsoluteIndex(GetNavigation.HidingSpots[lua_tointeger(L, 1)].Parent);

  if I = -1 then
    Result := TLua.Return(L, [nil])
  else
    Result := TLua.Return(L, [I]);
end;

function TXExtendedGameClient.Lua_GetNavChain(L: TLuaHandle): Int32;
  function CostMultiplier(A: TNavArea): Float;
  begin
    Result := 1;

    if A.Flags and NAV_AREA_JUMP > 0 then
      Result := Result + 3;

    if A.Flags and NAV_AREA_CROUCH > 0 then
      Result := Result + 20;
  end;
var
  Chain: TNavChain;
  I: Int;
  A1, A2: PNavArea;
begin
  A1 := @GetNavigation.Areas[lua_tointeger(L, 1)];
  A2 := @GetNavigation.Areas[lua_tointeger(L, 2)];

//  NavLock;
  Chain := GetNavigation.GetChain(A1, A2, @CostMultiplier);
//  NavUnLock;

  if lua_checkstack(L, Length(Chain)) <> 0 then
    for I := Low(Chain) to High(Chain) do
      lua_pushinteger(L, GetNavigation.GetAbsoluteIndex(Chain[I]))
  else
    SetLength(Chain, 0);

  Result := Length(Chain);
end;

function TXExtendedGameClient.Lua_GetWorldEntitiesCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWorld.EntitiesCount]);
end;

function TXExtendedGameClient.Lua_GetWorldVertexesCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWorld.VertexesCount]);
end;

function TXExtendedGameClient.Lua_GetWorldEdgesCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWorld.EdgesCount]);
end;

function TXExtendedGameClient.Lua_GetWorldSurfEdgesCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWorld.SurfEdgesCount]);
end;

function TXExtendedGameClient.Lua_GetWorldTexturesCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWorld.TexturesCount]);
end;

function TXExtendedGameClient.Lua_GetWorldPlanesCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWorld.PlanesCount]);
end;

function TXExtendedGameClient.Lua_GetWorldFacesCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWorld.FacesCount]);
end;

function TXExtendedGameClient.Lua_GetWorldLeafsCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWorld.LeafsCount]);
end;

function TXExtendedGameClient.Lua_GetWorldNodesCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWorld.NodesCount]);
end;

function TXExtendedGameClient.Lua_GetWorldClipNodesCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWorld.ClipNodesCount]);
end;

function TXExtendedGameClient.Lua_GetWorldModelsCount(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWorld.ModelsCount]);
end;

function TXExtendedGameClient.Lua_GetWorldEntity(L: TLuaHandle): Int32;
var
  E: PWorldEntity;
begin
  E := GetWorld.GetEntity(lua_tostring(L, 1), lua_tostring(L, 2));

  if E = nil then
    Exit(TLua.Return(L, [nil]));

  Result := TLua.Return(L, [E.AbsoluteIndex]);
end;

function TXExtendedGameClient.Lua_GetWorldEntities(L: TLuaHandle): Int32;
var
  Ents: TArray<PWorldEntity>;
  I: Int;
begin
  Ents := GetWorld.GetEntities(lua_tostring(L, 1), lua_tostring(L, 2));

  if lua_checkstack(L, Length(Ents)) <> 0 then
    for I := Low(Ents) to High(Ents) do
      lua_pushinteger(L, Ents[I].AbsoluteIndex)
  else
    SetLength(Ents, 0);

  Result := Length(Ents);
end;

function TXExtendedGameClient.Lua_GetWorldRandomEntity(L: TLuaHandle): Int32;
var
  E: PWorldEntity;
begin
  E := GetWorld.GetRandomEntity(lua_tostring(L, 1), lua_tostring(L, 2));

  if E = nil then
    Exit(TLua.Return(L, [nil]));

  Result := TLua.Return(L, [E.AbsoluteIndex]);
end;

function TXExtendedGameClient.Lua_GetWorldEntityByClassName(L: TLuaHandle): Int32;
var
  E: PWorldEntity;
begin
  E := GetWorld.GetEntityByClassName(lua_tostring(L, 1));

  if E = nil then
    Exit(TLua.Return(L, [nil]));

  Result := TLua.Return(L, [E.AbsoluteIndex]);
end;

function TXExtendedGameClient.Lua_GetWorldEntitiesByClassName(L: TLuaHandle): Int32;
var
  Ents: TArray<PWorldEntity>;
  I: Int;
begin
  Ents := GetWorld.GetEntitiesByClassName(lua_tostring(L, 1));

  if lua_checkstack(L, Length(Ents)) <> 0 then
    for I := Low(Ents) to High(Ents) do
      lua_pushinteger(L, Ents[I].AbsoluteIndex)
  else
    SetLength(Ents, 0);

  Result := Length(Ents);
end;

function TXExtendedGameClient.Lua_GetWorldRandomEntityByClassName(L: TLuaHandle): Int32;
var
  E: PWorldEntity;
begin
  E := GetWorld.GetRandomEntityByClassName(lua_tostring(L, 1));

  if E = nil then
    Exit(TLua.Return(L, [nil]));

  Result := TLua.Return(L, [E.AbsoluteIndex]);
end;

function TXExtendedGameClient.Lua_GetWorldEntityField(L: TLuaHandle): Int32;
var
  S: PLStr;
begin
  S := GetWorld.Entities[lua_tointeger(L, 1)].GetValue(lua_tostring(L, 2));

  if S = nil then
    Result := TLua.Return(L, [''])
  else
    Result := TLua.Return(L, [S^]);
end;

function TXExtendedGameClient.Lua_GetModelForEntity(L: TLuaHandle): Int32;
var
  M: PWorldModel;
begin
  M := GetWorld.GetModelForEntity(GetWorld.Entities[lua_tointeger(L, 1)]);

  if M = nil then
    Result := TLua.Return(L, [nil])
  else
    Result := TLua.Return(L, [GetWorld.GetModelAbsoluteIndex(M)]);
end;

function TXExtendedGameClient.Lua_GetWorldModelMinS(L: TLuaHandle): Int32;
begin
  with GetWorld.Models[lua_tointeger(L, 1)] do
    Result := TLua.Return(L, [MinS.X, MinS.Y, MinS.Z]);
end;

function TXExtendedGameClient.Lua_GetWorldModelMaxS(L: TLuaHandle): Int32;
begin
  with GetWorld.Models[lua_tointeger(L, 1)] do
    Result := TLua.Return(L, [MaxS.X, MaxS.Y, MaxS.Z]);
end;

function TXExtendedGameClient.Lua_GetWorldModelOrigin(L: TLuaHandle): Int32;
begin
  with GetWorld.Models[lua_tointeger(L, 1)] do
    Result := TLua.Return(L, [Origin.X, Origin.Y, Origin.Z]);
end;

function TXExtendedGameClient.Lua_GetWorldModelVisLeafs(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWorld.Models[lua_tointeger(L, 1)].VisLeafs]);
end;

function TXExtendedGameClient.Lua_GetWorldModelFirstFace(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWorld.Models[lua_tointeger(L, 1)].FirstFace]);
end;

function TXExtendedGameClient.Lua_GetWorldModelNumFaces(L: TLuaHandle): Int32;
begin
  Result := TLua.Return(L, [GetWorld.Models[lua_tointeger(L, 1)].NumFaces]);
end;

end.
