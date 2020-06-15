unit XBaseGameClient;

interface

uses
  Windows,
  SysUtils,
  Classes,
  Generics.Collections,
  UrlMon,

  BZip2,
  MD5,
  Encode,
  XNativeClient,
  Network,
  Protocol,
  Resource,
  Delta,
  CVar,
  Command,
  GameEvent,
  Alias,
  Vector,
  Shared,
  Common,
  Default,
  Fragment,
  Buffer,
  Framer,
  Sound,
  Event,
  Weapon,
  Other,
  Entity;

type
  TOnDirectorEvent = procedure(Sender: TObject; ALastPrimaryObject, ALastSecondaryObject: UInt16; AFlags: Int32) of object;

const
  H_ENGINE = 'Engine';
  TEMP_ENTITY_LOG_LEVEL = 2;
  DIRECTOR_LOG_LEVEL = 2;
  SOUND_LOG_LEVEL = 3;
  EVENT_LOG_LEVEL = 3;
  LIGHTSTYLE_LOG_LEVEL = 2;
  RESOURCELIST_LOG_LEVEL = 3;
  VOICEDATA_LOG_LEVEL = 2;
  NEWUSERMSG_LOG_LEVEL = 2;
  CONSISTENCY_LOG_LEVEL = 2;
  UPDATEUSERINFO_LOG_LEVEL = 2;

type
  TXBaseGameClient = class(TXNativeClient)
  strict private
    FOnConnectionInitialized, // - starts awaiting challenge

    FOnConnectionAccepted,  // - received "B" packed
                            // - starts sending encoded (munged) packets
                            // - sending "new" command after this notify

    FOnGameEngineInitialized, // - deltas initialized (descriptions has been received)
                              // - serverinfo initialized
                              // - entities allocated, but still empty

    FOnGameInitialized: TNotifyEvent; // - signon 2
                                      // - starts receiving entities
                                      // - can be spawned in world
                                      // - vgui menus starts from here (such as joining team, joining class)

    FOnConnectionRedirected,
    FOnConnectionFinalized,
    FOnServerCommand,
    FOnCenterPrint: TOnEString;

    FOnDirectorEvent: TOnDirectorEvent;
    FOnDirectorCommand: TOnEString;

    FDownloadsTotal: UInt;
    FLastDownloadProgressPrintTime: UInt;

    FOnFileDownload: TOnEString;
    FOnStartDownloading: TOnEInt;
    FOnDownloadProgress: TOnEString;

    FNeedInitializationOfConnection: Boolean;

    FConnectionAttempts: UInt;
    FLastThinkedSequence: Int32;

    FFastPrimaryAttackState,
    FFastSecondaryAttackState: Boolean;

    FDuckJumpState: Boolean;

  strict protected // buffer overload 1
    FIngameDownloadForced: Boolean;
    FLastMessages: LStr; // protected for hltv usage

    FFirstMove: Boolean;

    ConnectionInitializingTime,
    PacketingInitializingTime,
    GameEngineInitializingTime,
    GameInitializingTime,
    ConnectionFinalizingTime: UInt;

    State: TClientState;
    Server: TNETAdr;
    Channel: TChannel;  // net_chan
    EngineType: TEngineType;
    Downloads: TList<LStr>;

    GameEvents: TGameEventList;
    Delta: TDeltaSystem;

    FragmentsReader,
    FileFragmentsReader: TFragmentReader;
    FragmentsWriter,
    FileFragmentsWriter: TFragmentWriter;

    GMSG: TBufferEx2; // reading game events

    DMSG: TBufferEx2; // svc_director
    DEM: TBufferEx2; // this
    BF: TBufferEx2;  // writing all clc_ messages

    UserInfo: TAliasList; // setinfo command use this

    // svc
    ProtocolVersion: Int32; // svc_version
    Time: Float;  // svc_time
    Players: TArray<TPlayer>;  // svc_serverinfo, this array is directly connected to the entities
    ClientData: TClientData;  // svc_clientdata
    WeaponData: TWeaponDataDynArray; // svc_clientdata
    Entities, // svc_packetentities
    Baseline, // svc_spawnbaseline
    InstancedBaseline: TArray<TEntity>;  // extra entities in svc_spawnbaseline
    EntitiesCount: Int16; //svc_packetentities, count
    MoveVars: TMoveVars;  // svc_newmovevars
    ExtraInfo: TExtraInfo;  // svc_sendextrainfo
    TimeScale: Float; // svc_timescale
    ServerInfo: TServerInfo;  // svc_serverinfo
    LightStyles: TArray<LStr>;  // svc_lightstyles
    Resources: TResources;  // svc_resourcelist
    ResourceLocation: LStr;  // svc_resoucrelocation
    SignonNum: UInt8;  // svc_signonnum
    IsHLTV: Boolean; // svc_hltv
    Intermission: UInt8; // svc_intermission, svc_cutscene, svc_finale
    Paused: Boolean; // svc_setpause
    VoiceCodec: LStr; // svc_voiceinit
    VoiceQuality: UInt8; // svc_voiceinit

    // clc
    UpdateMask: UInt8;  // clc_delta
    Move: TUserCmd;  // clc_move
    MyResources: TResources;  // clc_resourcelist

    // clc_move personal
    ViewAngles: TVec3F; // this will write every frame to our usercmd, no delete this
    ViewAnglesEx: TVec3F; // smooth view angles, smothly applies to simple CL_ViewAngles
                             // ..rename to CL_SmoothViewAngles ?
    ViewAnglesEx_Time: UInt32; // i need to know when disable smooth viewing

    IsDemoPlayback: Boolean;
    IsNewThinking: Boolean; // true if new packed was received in this frame

    //
    Consistencies: TAliasList;
    FakeCVars: TAliasList;

    //

  strict protected
    //UserInfo
    CL_Name,
    CL_Rate,
    CL_UpdateRate,
    CL_DLMax,
    CL_Model,
    CL_TopColor,
    CL_BottomColor,
    CL_LC,
    CL_LW,
    CL_Password: LStr;

    //
    CL_CDKey: LStr;
    CL_Timeout,
    CL_RejectionTimeout,
    CL_Connection_Attempts: Int32;

    CL_AllowRedirects: Boolean;
    CL_UserCMD_Count: UInt32;

    CL_Consistency,

    CL_AllowUpload,
    CL_AllowDownload,
    CL_DownloadImportantResources: Boolean;

    DEM_Playback_Speed: Int32;

    EX_Interp: Float;

    CL_SvenCoop: Boolean;

    procedure SlowFrame; override;
    procedure Frame; override;

    function CL_ReadPacket: Boolean; override;
    function CL_ConnectionLessPacket: Boolean; override;
    procedure CL_ReadFragments;
    procedure CL_CompleteFragments; virtual; // buffer overload 1
    procedure CL_DecompressPacket;
    procedure CL_ParseServerMessage; virtual;
    function CL_ParseGameEvent(B: UInt8): Boolean; virtual;
    procedure CL_ParseDemoMessage;

    procedure CL_TransmitPacket;

    procedure CL_CheckFragment(var AFragmentsWriter: TFragmentWriter; var AFragmentChannel: TFragmentChannel; var ABuffer: LStr);

    procedure CL_WriteFragments(var ABuffer: TBufferEx2; FragBuf, FileFragBuf: LStr); virtual; // buffer overload 1

    procedure CL_CreateFragments(var ABuffer: TBufferEx2; ASize: UInt32 = DEFAULT_FRAGMENT_SIZE; ACompression: Boolean = DEFAULT_FRAGMENT_COMPRESSION_STATE); overload; virtual;
    procedure CL_CreateFragments(ASize: UInt32 = DEFAULT_FRAGMENT_SIZE; ACompression: Boolean = DEFAULT_FRAGMENT_COMPRESSION_STATE); overload; virtual;

    procedure CL_CreateFileFragments(AFileName, AFileData: LStr; ASize: UInt32 = DEFAULT_FRAGMENT_SIZE; ACompression: Boolean = DEFAULT_FRAGMENT_COMPRESSION_STATE); virtual;

    procedure CL_CompressPacket(var ABuffer: TBufferEx2); overload;
    procedure CL_CompressPacket(var AData: LStr); overload;

    procedure CL_ParseChallenge; override;
    procedure CL_BadPassword;
    procedure CL_RejectConnection;
    procedure CL_AcceptedConnection(IsReconnect: Boolean = False);
    procedure CL_RedirectConnection;

    procedure CL_ParseDisconnect; virtual;
    procedure CL_ParseEvent; virtual;
    procedure CL_ParseVersion;
    procedure CL_ParseSetView;
    procedure CL_ParseSound; virtual;
    procedure CL_ParseTime;
    procedure CL_ParseStuffText;
    procedure CL_ParseSetAngle;
    procedure CL_ParseServerInfo;
    procedure CL_ParseLightStyle;
    procedure CL_ParseUpdateUserInfo; virtual;
    procedure CL_ParseDeltaDescription;
    procedure CL_ParseClientData; virtual;
    procedure CL_ParseStopSound; virtual;
    procedure CL_ParsePings; virtual;
    procedure CL_ParseParticle; virtual;
    procedure CL_ParseSpawnStatic; virtual;
    procedure CL_ParseEventReliable;
    procedure CL_ParseSpawnBaseline; //virtual;
    procedure CL_ParseTempEntity;
    procedure CL_ParseSetPause;
    procedure CL_ParseSignonNum; virtual;
    procedure CL_ParseCenterPrint;
    procedure CL_ParseSpawnStaticSound;
    procedure CL_ParseIntermission;
    procedure CL_ParseFinale;
    procedure CL_ParseCDTrack;
    procedure CL_ParseRestore;
    procedure CL_ParseCutScene;
    procedure CL_ParseWeaponAnim;
    procedure CL_ParseDecalName;
    procedure CL_ParseRoomType;
    procedure CL_ParseAddAngle;
    procedure CL_ParseNewUserMsg;
    procedure CL_ParsePacketEntities(IsDelta: Boolean);
    procedure CL_ParseChoke;
    procedure CL_ParseResourceList;
    procedure CL_ParseNewMoveVars;
    procedure CL_ParseResourceRequest; virtual;
    procedure CL_ParseCustomization;
    procedure CL_ParseCrosshairAngle;
    procedure CL_ParseSoundFade;
    procedure CL_ParseFileTxferFailed;
    procedure CL_ParseHLTV;
    procedure CL_ParseDirector;
    procedure CL_ParseVoiceInit;
    procedure CL_ParseVoiceData;
    procedure CL_ParseSendExtraInfo;
    procedure CL_ParseTimeScale;
    procedure CL_ParseResourceLocation;
    procedure CL_ParseSendCVarValue; virtual;
    procedure CL_ParseSendCVarValue2; virtual;

    procedure CL_ParseTEBeamPoints;
    procedure CL_ParseTEBeamEntPoint;
    procedure CL_ParseTEGunShot;
    procedure CL_ParseTEExplosion;
    procedure CL_ParseTETarExplosion;
    procedure CL_ParseTESmoke;
    procedure CL_ParseTETracer;
    procedure CL_ParseTELightning;
    procedure CL_ParseTEBeamEnts;
    procedure CL_ParseTESparks;
    procedure CL_ParseTELavaSplash;
    procedure CL_ParseTETeleport;
    procedure CL_ParseTEExplosion2;
    procedure CL_ParseTEBSPDecal;
    procedure CL_ParseTEImplosion;
    procedure CL_ParseTESpriteTrail;
    procedure CL_ParseTESprite;
    procedure CL_ParseTEBeamSprite;
    procedure CL_ParseTEBeamToRus;
    procedure CL_ParseTEBeamDisc;
    procedure CL_ParseTEBeamCylinder;
    procedure CL_ParseTEBeamFollow;
    procedure CL_ParseTEGlowSprite;
    procedure CL_ParseTEBeamRing;
    procedure CL_ParseTEStreakSplash;
    procedure CL_ParseTEDLight;
    procedure CL_ParseTEELight;
    procedure CL_ParseTETextMessage; virtual;
    procedure CL_ParseTELine;
    procedure CL_ParseTEBox;
    procedure CL_ParseTEKillBeam;
    procedure CL_ParseTELargeFunnel;
    procedure CL_ParseTEBloodStream;
    procedure CL_ParseTEShowLine;
    procedure CL_ParseTEBlood;
    procedure CL_ParseTEDecal;
    procedure CL_ParseTEFizz;
    procedure CL_ParseTEModel;
    procedure CL_ParseTEExplodeModel;
    procedure CL_ParseTEBreakModel;
    procedure CL_ParseTEGunShotDecal;
    procedure CL_ParseTESpriteSpray;
    procedure CL_ParseTEArmorRicochet;
    procedure CL_ParseTEPlayerDecal;
    procedure CL_ParseTEBubbles;
    procedure CL_ParseTEBubbleTrail;
    procedure CL_ParseTEBloodSprite;
    procedure CL_ParseTEWorldDecal;
    procedure CL_ParseTEWorldDecalHigh;
    procedure CL_ParseTEDecalHigh;
    procedure CL_ParseTEProjectile;
    procedure CL_ParseTESpray;
    procedure CL_ParseTEPlayerSprites;
    procedure CL_ParseTEParticleBurst;
    procedure CL_ParseTEFireField;
    procedure CL_ParseTEPlayerAttachment;
    procedure CL_ParseTEKillPlayerAttachments;
    procedure CL_ParseTEMultiGunShot;
    procedure CL_ParseTEUserTracer;

    procedure CL_ParseDirectorStart;
    procedure CL_ParseDirectorEvent;
    procedure CL_ParseDirectorStatus;
    procedure CL_ParseDirectorStuffText;

    procedure CL_WriteMove; virtual;
    procedure CL_WriteCommand(Data: LStr); overload; virtual;
    procedure CL_WriteCommand(Data: array of const); overload;
    procedure CL_WriteCommand; overload;
    procedure CL_WriteDelta;
    procedure CL_WriteResourceList; virtual;
    procedure CL_WriteFileConsistency; virtual;
    procedure CL_WriteVoiceData(const Buffer; Size: Int16);
    procedure CL_WriteCVarValue(Data: LStr); virtual;
    procedure CL_WriteCVarValue2(Index: Int32; CVar, Data: LStr); virtual;

    procedure CL_InitializeConnection(Address: TNETAdr); overload; virtual;
    procedure CL_InitializeConnection; overload;
    procedure CL_InitializePacketing; virtual;
    procedure CL_InitializeGameEngine; virtual;
    procedure CL_InitializeGame; virtual;

    procedure CL_FinalizeConnection(Reason: LStr; IsReconnect: Boolean = False); overload; virtual;
    procedure CL_FinalizeConnection(Reason: array of const; IsReconnect: Boolean = False); overload;
    procedure CL_FinalizeConnection(IsReconnect: Boolean = False); overload;

    procedure CL_WriteConnectPacket; virtual; abstract;

    procedure CL_AllocateEntities(ASize: UInt32);
    procedure CL_SignonReply;
    function CL_GetUserInfoString: LStr;

    procedure CL_PlaySound(ASound: TSound); virtual;

    procedure CL_CheckTimeouts;
    procedure CL_PreThink; virtual;
    procedure CL_Think; virtual;
    procedure CL_PostThink; virtual;

    function CL_NeedToDownloadResource(AResource: TResource; CustomName: LStr = ''): Boolean; virtual;
    function CL_CanExternalDownloading: Boolean;

    procedure CL_VerifyResources; virtual; // buffer overlaod 1
    procedure CL_StartHTTPDownload;
    procedure CL_ConfirmResources; virtual;

    function CL_GenerateCDKey: LStr;

    function CL_GetMessagesHistory: LStr;
    procedure CL_AddMessageToHistory(Data: LStr);

    function CL_IsNeedResourceConfirmation: Boolean;

    function CL_IsPlayerIndex(Index: Int32): Boolean;

    function CL_GetPlayerIndex(APlayer: TPlayer): Int; overload; // be careful:
    function CL_GetPlayerIndex(APlayer: PPlayer): Int; overload; // it return index in players array, not entities

    function CL_GetPlayer: PPlayer; // Players[ServerInfo.Index]
    function CL_GetEntity: PEntity; overload; // CL_GetPlayer.Entity

    function CL_GetGravity: Float;

    function CL_ServerTickCount: UInt32;

    function CL_IsOnLadder(APlayer: TPlayer): Boolean; overload;
    function CL_IsOnLadder: Boolean; overload; // cl_getentity

    procedure CL_MoveTo(APosition: TVec3F; ASpeed: Float); overload;
    procedure CL_MoveTo(APosition: TVec3F); overload;
    procedure CL_MoveTo(APlayer: TPlayer; ASpeed: Float); overload;
    procedure CL_MoveTo(APlayer: TPlayer); overload;
    procedure CL_MoveTo(AEntity: TEntity; ASpeed: Float); overload;
    procedure CL_MoveTo(AEntity: TEntity); overload;

    procedure CL_MoveOut(APosition: TVec3F; ASpeed: Float); overload;
    procedure CL_MoveOut(APosition: TVec3F); overload;
    procedure CL_MoveOut(APlayer: TPlayer; ASpeed: Float); overload;
    procedure CL_MoveOut(APlayer: TPlayer); overload;
    procedure CL_MoveOut(AEntity: TEntity; ASpeed: Float); overload;
    procedure CL_MoveOut(AEntity: TEntity); overload;

    procedure CL_LookAt(APosition: TVec3F); overload;
    procedure CL_LookAt(APlayer: TPlayer); overload;
    procedure CL_LookAt(AEntity: TEntity); overload;

    procedure CL_LookAtEx(APosition: TVec3F); overload;
    procedure CL_LookAtEx(APlayer: TPlayer); overload;
    procedure CL_LookAtEx(AEntity: TEntity); overload;

    procedure CL_PressButton(AButton: UInt16);
    procedure CL_UnPressButton(AButton: UInt16);
    function CL_IsButtonPressed(AButton: UInt16): Boolean;

    function CL_GetOrigin: TVec3F;
    function CL_GetVelocity: TVec3F;
    function CL_GetPunchAngle: TVec3F;
    function CL_GetWeaponIndex: Int32;
    function CL_GetFieldOfView: Float;

    function CL_GetDistance(APosition: TVec3F): Float; overload;
    function CL_GetDistance(APlayer: TPlayer): Float; overload;
    function CL_GetDistance(AEntity: TEntity): Float; overload;

    function CL_GetDistance2D(APosition: TVec3F): Float; overload;
    function CL_GetDistance2D(APlayer: TPlayer): Float; overload;
    function CL_GetDistance2D(AEntity: TEntity): Float; overload;

    function CL_IsWeaponExists(AIndex: UInt32): Boolean; overload;
    function CL_IsWeaponExists(AWeapon: TWeapon): Boolean; overload;

    function CL_IsClientFlagSet(AFlag: Int32): Boolean; // no publish it ? or publish ?

    function CL_IsCrouching: Boolean; // FL
    function CL_IsOnGround: Boolean; // FL
    function CL_IsSpectator: Boolean;

    function CL_GetWeaponData(AIndex: UInt32): PWeaponData; overload;
    function CL_GetWeaponData: PWeaponData; overload;

    function CL_HasWeaponData: Boolean;
    function CL_IsReloading: Boolean;
    function CL_GetMaxSpeed: Float;
    function CL_GetHealth: Float;
    function CL_CanAttack: Boolean;

    function CL_InFieldOfView(APosition: TVec3F): Boolean; overload;
    function CL_InFieldOfView(APlayer: TPlayer): Boolean; overload;
    function CL_InFieldOfView(AEntity: TEntity): Boolean; overload;

    function CL_IsAlive: Boolean;

    procedure CL_UseEnvironment;

    procedure CL_PrimaryAttack;
    procedure CL_SecondaryAttack;
    procedure CL_FastPrimaryAttack;
    procedure CL_FastSecondaryAttack;

    procedure CL_Jump;
    procedure CL_Duck;
    procedure CL_DuckJump;

    function CL_GetGroundedOrigin: TVec3F;

    function CL_GetGroundedDistance(APosition: TVec3F): Float; overload;
    function CL_GetGroundedDistance(APlayer: TPlayer): Float; overload;
    function CL_GetGroundedDistance(AEntity: TEntity): Float; overload;

    procedure CMD_RegisterCommands; override;
    procedure CMD_RegisterCVars; override;

    function CMD_ExecuteTokenizedText: Boolean; override;
    function CMD_ExecuteCommand: Boolean; override;
    function CMD_ExecuteCVar: Boolean; override;
    function CMD_ExecuteFakeCVar: Boolean;
    procedure CL_Rcon_F; override;
    procedure CL_ForwardToServer;
    procedure CL_Upload_F; virtual;
    procedure CL_Connect_F;
    procedure CL_Reconnect_F; virtual;
    procedure CL_Retry_F;
    procedure CL_Disconnect_F;
    procedure CL_SetInfo_F;
    procedure CL_Impulse_F;
    procedure CL_FullServerInfo_F;

    procedure CL_DebugResources_F;
    procedure CL_DebugEntities_F;
    procedure CL_DebugBaseline_F;
    procedure CL_DebugGameEvents_F;

    procedure CL_VoicePlayFromFile_F;

    procedure CL_PlayDemo_F;

    procedure CL_Consistency_F;
    procedure CL_FakeCVar_F;

  public
    constructor Create;
    destructor Destroy; override;

    // main
    property GetState: TClientState read State;
    property GetServer: TNETAdr read Server;
    property GetChannel: TChannel read Channel;
    property GetEngineType: TEngineType read EngineType;

    // sv ->
    property GetTime: Float read Time;
    property GetServerTickCount: UInt32 read CL_ServerTickCount;
    property GetClientData: TClientData read ClientData;
    property GetMoveVars: TMoveVars read MoveVars;
    property GetExtraInfo: TExtraInfo read ExtraInfo;
    property GetServerInfo: TServerInfo read ServerInfo;
    property GetLightStyles: TArray<LStr> read LightStyles;
    property GetResources: TResources read Resources;
    property GetIntermission: UInt8 read Intermission;
    property IsPaused: Boolean read Paused;

    property GetPlayers: TArray<TPlayer> read Players;
    property GetEntities: TArray<TEntity> read Entities;

    property GetEntitiesCount: Int16 read EntitiesCount;

    // cl ->
    property GetMove: TUserCmd read Move;

    // utils
    //  general
    property GetName: LStr read CL_Name;
    property GetCDKey: LStr read CL_CDKey;
    property GetMessagesHistory: LStr read CL_GetMessagesHistory;

    property GetPlayer: PPlayer read CL_GetPlayer;
    function GetEntity: PEntity; overload; // no property, because need two overloads to publishing

    function PlayersCount: UInt32; // <- f.
    property IsPlayerIndex[Index: Int32]: Boolean read CL_IsPlayerIndex;

    // natives
    procedure MoveTo(APosition: TVec3F; ASpeed: Float); overload;
    procedure MoveTo(APosition: TVec3F); overload;
    procedure MoveTo(APlayer: TPlayer; ASpeed: Float); overload;
    procedure MoveTo(APlayer: TPlayer); overload;
    procedure MoveTo(AEntity: TEntity; ASpeed: Float); overload;
    procedure MoveTo(AEntity: TEntity); overload;

    procedure MoveOut(APosition: TVec3F; ASpeed: Float); overload;
    procedure MoveOut(APosition: TVec3F); overload;
    procedure MoveOut(APlayer: TPlayer; ASpeed: Float); overload;
    procedure MoveOut(APlayer: TPlayer); overload;
    procedure MoveOut(AEntity: TEntity; ASpeed: Float); overload;
    procedure MoveOut(AEntity: TEntity); overload;

    procedure LookAt(APosition: TVec3F); overload;
    procedure LookAt(APlayer: TPlayer); overload;
    procedure LookAt(AEntity: TEntity); overload;

    procedure LookAtEx(APosition: TVec3F); overload;
    procedure LookAtEx(APlayer: TPlayer); overload;
    procedure LookAtEx(AEntity: TEntity); overload;

    property GetViewAngles: TVec3F read ViewAngles;
    property SetViewAngles: TVec3F write ViewAngles;

    procedure PressButton(AButton: UInt16);
    procedure UnPressButton(AButton: UInt16);
    property IsButtonPressed[Index: UInt16]: Boolean read CL_IsButtonPressed;

    property GetOrigin: TVec3F read CL_GetOrigin;
    property GetVelocity: TVec3F read CL_GetVelocity;
    property GetPunchAngle: TVec3F read CL_GetPunchAngle;
    property GetWeaponIndex: Int32 read CL_GetWeaponIndex;
    property GetFieldOfView: Float read CL_GetFieldOfView;

    function GetDistance(APosition: TVec3F): Float; overload;
    function GetDistance(APlayer: TPlayer): Float; overload;
    function GetDistance(AEntity: TEntity): Float; overload;

    function GetDistance2D(APosition: TVec3F): Float; overload;
    function GetDistance2D(APlayer: TPlayer): Float; overload;
    function GetDistance2D(AEntity: TEntity): Float; overload;

    function IsWeaponExists(AIndex: UInt32): Boolean; overload;
    function IsWeaponExists(AWeapon: TWeapon): Boolean; overload;

    property IsCrouching: Boolean read CL_IsCrouching;
    property IsOnGround: Boolean read CL_IsOnGround;
    property IsSpectator: Boolean read CL_IsSpectator;

    function GetWeaponData(AIndex: UInt32): PWeaponData; overload;
    function GetWeaponData: PWeaponData; overload;

    property HasWeaponData: Boolean read CL_HasWeaponData;
    property IsReloading: Boolean read CL_IsReloading;
    property GetMaxSpeed: Float read CL_GetMaxSpeed;
    property GetHealth: Float read CL_GetHealth;
    property CanAttack: Boolean read CL_CanAttack;

    function InFieldOfView(APosition: TVec3F): Boolean; overload;
    function InFieldOfView(APlayer: TPlayer): Boolean; overload;
    function InFieldOfView(AEntity: TEntity): Boolean; overload;

    //  extended
    property IsAlive: Boolean read CL_IsAlive;

    procedure UseEnvironment;

    procedure PrimaryAttack;
    procedure SecondaryAttack;
    procedure FastPrimaryAttack;
    procedure FastSecondaryAttack;

    procedure Jump;
    procedure Duck;
    procedure DuckJump;

    //  garbage
    function GetGroundedOrigin: TVec3F;

    function GetGroundedDistance(APosition: TVec3F): Float; overload;
    function GetGroundedDistance(APlayer: TPlayer): Float; overload;
    function GetGroundedDistance(AEntity: TEntity): Float; overload;

    // global events
    property OnConnectionInitialized: TNotifyEvent read FOnConnectionInitialized write FOnConnectionInitialized;
    property OnConnectionAccepted: TNotifyEvent read FOnConnectionAccepted write FOnConnectionAccepted;
    property OnConnectionRedirected: TOnEString read FOnConnectionRedirected write FOnConnectionRedirected;
    property OnGameEngineInitialized: TNotifyEvent read FOnGameEngineInitialized write FOnGameEngineInitialized;
    property OnGameInitialized: TNotifyEvent read FOnGameInitialized write FOnGameInitialized;
    property OnConnectionFinalized: TOnEString read FOnConnectionFinalized write FOnConnectionFinalized;

    property OnServerCommand: TOnEString read FOnServerCommand write FOnServerCommand;
    property OnCenterPrint: TOnEString read FOnCenterPrint write FOnCenterPrint;

    property OnDirectorEvent: TOnDirectorEvent read FOnDirectorEvent write FOnDirectorEvent;
    property OnDirectorCommand: TOnEString read FOnDirectorCommand write FOnDirectorCommand;

    property OnFileDownload: TOnEString read FOnFileDownload write FOnFileDownload; // xfakeplayers use this
    property OnStartDownloading: TOnEInt read FOnStartDownloading write FOnStartDownloading; // xfakeplayers use this
    property OnDownloadProgress: TOnEString read FOnDownloadProgress write FOnDownloadProgress;
  end;

implementation

procedure TXBaseGameClient.SlowFrame;
begin
  inherited;

  FragmentsReader.CheckTimeouts;
  FileFragmentsReader.CheckTimeouts;
  FragmentsWriter.CheckTimeouts;
  FileFragmentsWriter.CheckTimeouts;
end;

procedure TXBaseGameClient.Frame;
var
  I: Int32;
begin
  inherited;

  if State >= CS_GAME then
    FrameDelta := 10
  else
    FrameDelta := 30;

  if FNeedInitializationOfConnection then
  begin
    CL_InitializeConnection;
    FNeedInitializationOfConnection := False;
  end;

  if IsDemoPlayback then
  begin
    for I := 1 to DEM_Playback_Speed do
    begin
      if DEM.Position >= DEM.Size then
      begin
        CL_FinalizeConnection;
        Break;
      end;

      CL_ParseDemoMessage;
    end;

    Exit;
  end;

  if State <= CS_DISCONNECTED then
    Exit;

  CL_CheckTimeouts;

  if State < CS_CONNECTION_ACCEPTED then
    Exit;

  if State = CS_VERIFYING_RESOURCES then
    if Downloads.Count = 0 then
      CL_ConfirmResources;

  if ((State >= CS_VERIFYING_RESOURCES) {and not SVENCOOP}) {or ((State >= CS_GAME) and SVENCOOP)} then
  begin
    CL_PreThink;
    CL_Think;
    CL_PostThink;
    CL_WriteMove;
  end;

  if State >= CS_GAME then
  begin
    CL_WriteDelta;

  end;

  CL_TransmitPacket;
end;

function TXBaseGameClient.CL_ReadPacket;
const T = 'CL_ReadPacket';
var
  Sequence, Acknowledgement: Int32;
  Reliable, Fragmented, ReliableAcknowledgement, Security: Boolean;
begin
  Result := True;

  if inherited then
    Exit;

  Result := False;

  if NET.From <> Server then
    Exit;

  if State < CS_CONNECTION_ACCEPTED then
    Exit;

  if MSG.Size <= 8 then
    Exit;

  MSG.Start;

  with Channel do
  begin
    IncomingTime := GetTickCount;

    Sequence := MSG.ReadInt32;
    Acknowledgement := MSG.ReadInt32;

    Reliable := Sequence and $80000000 > 0;
    Fragmented := Sequence and $40000000 > 0;
    ReliableAcknowledgement := Acknowledgement and $80000000 > 0;
    Security := Acknowledgement and $40000000 > 0;

    if Security then  // <- ?
      Exit(True);

    if not CL_SvenCoop then
      UnMunge(Pointer(UInt32(MSG.Memory) + 8), MSG.Size - 8, Sequence and $FF, MungifyTable2);

    Sequence := Sequence and $3FFFFFFF;
    Acknowledgement := Acknowledgement and $3FFFFFFF;

    if Sequence <= IncomingSequence then
      Exit(True);

    IncomingSequence := Sequence;
    IncomingAcknowledgement := Acknowledgement;

    if IncomingSequence >= OutgoingSequence then // calculate latency
      Latency := IncomingTime - OutgoingTime;

    if Reliable then
      OutgoingAcknowledgementReliable := not OutgoingAcknowledgementReliable;

    with Fragment do
      if Active and not CanSend and (IncomingAcknowledgement >= Sequence) then
        CanSend := True;

    with FileFragment do
      if Active and not CanSend and (IncomingAcknowledgement >= Sequence) then
        CanSend := True;

    if ReliableAcknowledgement <> IncomingAcknowledgementReliable then
    begin
      if Fragment.Active and Fragment.CanSend and (IncomingAcknowledgement >= Sequence) then
        Inc(Fragment.Count);

      if FileFragment.Active and FileFragment.CanSend and (IncomingAcknowledgement >= Sequence) then
        Inc(FileFragment.Count);
    end;

    IncomingAcknowledgementReliable := ReliableAcknowledgement;

    if Fragmented then
      CL_ReadFragments;

    CL_ParseServerMessage;

    if Fragmented then
      CL_CompleteFragments;
  end;

  Result := True;
end;

function TXBaseGameClient.CL_ConnectionLessPacket;
begin
  Result := True;

  if inherited then
    Exit;

  Result := False;

  MSG.SavePosition;

  case MSG.ReadLChar of
    '8': CL_BadPassword;
    '9': CL_RejectConnection;
    'B': CL_AcceptedConnection;
    'L': CL_RedirectConnection;
  else
    MSG.RestorePosition;
    Exit;
  end;

  Result := True;
end;

procedure TXBaseGameClient.CL_ReadFragments;
var
  I: Int32;
  Ready: array[1..2] of Boolean;
  Sequence: array[1..2] of UInt32;
  Offset, Size: array[1..2] of UInt16;

  Index,
  Downloaded,
  Total: Int;

  FileName: LStr;
begin
  for I := 1 to 2 do
    if MSG.ReadBool8 then
    begin
      Ready[I] := True;
      Sequence[I] := MSG.ReadInt32;

      if CL_SvenCoop then
      begin
        Offset[I] := MSG.ReadInt32;
        Size[I] := MSG.ReadInt32;
      end
      else
      begin
        Offset[I] := MSG.ReadInt16;
        Size[I] := MSG.ReadInt16;
      end
    end
    else
    begin
      Clear(Ready[I]);
      Clear(Sequence[I]);
      Clear(Offset[I]);
      Clear(Size[I]);
    end;

  for I := 1 to 2 do
    if Ready[I] then
    begin
      if Sequence[I] > 0 then
      begin
        MSG.Skip(Offset[I]);

        Index := Sequence[I] shl 16;
        Downloaded := Sequence[I] shr 16;
        Total := Sequence[I] and $FFFF;

        case I of
          1: FragmentsReader.Add(Index, Downloaded, Total, MSG.ReadLStr(Size[I]));
          2:
          begin
            FileFragmentsReader.Add(Index, Downloaded, Total, MSG.ReadLStr(Size[I]));

            if Downloaded <= 1 then
              FLastDownloadProgressPrintTime := GetTickCount;

            if DeltaTicks(FLastDownloadProgressPrintTime) > 2000 then
            begin
              with TBufferEx2.Create do
              begin
                Write(FileFragmentsReader[FileFragmentsReader.IndexOf(Index)].Defragmentate);
                Start;

                if Developer = 0 then
                  Print(['[', FDownloadsTotal - Downloads.Count + 1, '/', FDownloadsTotal, '] Downloading: "', PeekLStr, '", Progress: ', Trunc(100 + (Downloaded - Total) * 100 / Total), '%']);

                ReleaseEvent(OnDownloadProgress, StringFromVarRec(['[', FDownloadsTotal - Downloads.Count + 1, '/', FDownloadsTotal, '] ', PeekLStr, ' - ', Trunc(100 + (Downloaded - Total) * 100 / Total), '%']));

                Free;
              end;

              FLastDownloadProgressPrintTime := GetTickCount;
            end
          end
        end;
      end;

      if (I = 1) and Ready[2] then
        Dec(Offset[2], Size[1]);
    end;
end;

procedure TXBaseGameClient.CL_CompleteFragments;
var
  I, Size: Int32;
  FileName, FileData: LStr;
  Compressed: Boolean;
begin
  I := FragmentsReader.GetCompleted;

  while I <> -1 do
  begin
    MSG.Clear;
    MSG.Write(FragmentsReader[I].Defragmentate);
    MSG.Start;

    FragmentsReader.Delete(I);

    MSG.SavePosition;

    if MSG.ReadLStr = 'BZ2' then
      CL_DecompressPacket
    else
      MSG.RestorePosition;

    CL_ParseServerMessage;

    I := FragmentsReader.GetCompleted;
  end;

  I := FileFragmentsReader.GetCompleted;

  while I <> -1 do
  begin
    MSG.Clear;
    MSG.Write(FileFragmentsReader[I].Defragmentate);
    MSG.Start;

    FileFragmentsReader.Delete(I);

    FileName := MSG.ReadLStr;
    Compressed := MSG.ReadLStr = 'bz2';
    Size := MSG.ReadInt32;

    if MSG.Position >= MSG.Size then
      Break;

    if not IsSafeFilePath(FileName) then
      Break;
    
    if FileName[1] <> '!' then  // not MD5 or not decal
    begin
      if FileExists(FileName) then
        Break;
    
      if Compressed then
        CL_DecompressPacket;

      FileData := MSG.ReadLStr(rmEnd);

      WriteFile(ServerInfo.GameDir + '/' + FileName, FileData);
      Downloads.Remove(FileName);

      if FDownloadsTotal = 0 then
        Print(['Downloaded: "', FileName, '", Size: ', BytesToTraffStr(Length(FileData))])
      else
        Print(['[', FDownloadsTotal - Downloads.Count, '/', FDownloadsTotal, '] Downloaded: "', FileName, '", Size: ', BytesToTraffStr(Length(FileData))]);

      ReleaseEvent(OnFileDownload, FileName);

      I := FileFragmentsReader.GetCompleted;
    end;
  end;
end;

procedure TXBaseGameClient.CL_DecompressPacket;
const T = 'CL_DecompressPacket';
var
  S: LStr;
  OutBuf: Pointer;
  OutSize: Int32;
begin
  BZDecompressBuf(Pointer(UInt32(MSG.Memory) + MSG.Position), MSG.Size - MSG.Position, 0, OutBuf, OutSize);

  Debug(T, [MSG.Size - MSG.Position, ' -> ', OutSize]);

  MSG.Clear;
  MSG.Write(OutBuf^, OutSize);
  MSG.Start;
  FreeMem(OutBuf);
end;

procedure TXBaseGameClient.CL_ParseServerMessage;
const T = 'CL_ParseServerMessage';
var
  B: UInt8;
label
  L1;
begin
  Clear(FLastMessages);

  L1:
  if MSG.Position >= MSG.Size then
    Exit;

  B := MSG.ReadUInt8;

  if B > SVC_LASTMSG then
    if CL_ParseGameEvent(B) then
      goto L1
    else
      Exit;

  CL_AddMessageToHistory(ServerEngineMsgs[B].Name);

  case B of
    SVC_BAD:
    begin
      Error(T, [ServerEngineMsgs[B].Name]);
      Hint('Last parsed messages', [CL_GetMessagesHistory]);
      CL_FinalizeConnection;
      Exit;
    end;
    SVC_NOP: ;
    SVC_DISCONNECT: CL_ParseDisconnect;
    SVC_EVENT: CL_ParseEvent;
    SVC_VERSION: CL_ParseVersion;
    SVC_SETVIEW: CL_ParseSetView;
    SVC_SOUND: CL_ParseSound;
    SVC_TIME: CL_ParseTime;
    SVC_PRINT: CL_ParsePrint;
    SVC_STUFFTEXT: CL_ParseStuffText;
    SVC_SETANGLE: CL_ParseSetAngle;
    SVC_SERVERINFO: CL_ParseServerInfo;
    SVC_LIGHTSTYLE: CL_ParseLightStyle;
    SVC_UPDATEUSERINFO: CL_ParseUpdateUserInfo;
    SVC_DELTADESCRIPTION: CL_ParseDeltaDescription;
    SVC_CLIENTDATA: CL_ParseClientData;
    SVC_STOPSOUND: CL_ParseStopSound;
    SVC_PINGS: CL_ParsePings;
    SVC_PARTICLE: CL_ParseParticle;
    SVC_DAMAGE: ; // deprecated
    SVC_SPAWNSTATIC: CL_ParseSpawnStatic;
    SVC_EVENT_RELIABLE: CL_ParseEventReliable;
    SVC_SPAWNBASELINE: CL_ParseSpawnBaseLine;
    SVC_TEMPENTITY: CL_ParseTempEntity;
    SVC_SETPAUSE: CL_ParseSetPause;
    SVC_SIGNONNUM: CL_ParseSignonNum;
    SVC_CENTERPRINT: CL_ParseCenterPrint;
    SVC_KILLEDMONSTER: ; // deprecated
    SVC_FOUNDSECRET: ; // deprecated
    SVC_SPAWNSTATICSOUND: CL_ParseSpawnStaticSound;
    SVC_INTERMISSION: CL_ParseIntermission;
    SVC_FINALE: CL_ParseFinale;
    SVC_CDTRACK: CL_ParseCDTrack;
    SVC_RESTORE: CL_ParseRestore;
    SVC_CUTSCENE: CL_ParseCutScene;
    SVC_WEAPONANIM: CL_ParseWeaponAnim;
    SVC_DECALNAME: CL_ParseDecalName;
    SVC_ROOMTYPE: CL_ParseRoomType;
    SVC_ADDANGLE: CL_ParseAddAngle;
    SVC_NEWUSERMSG: CL_ParseNewUserMsg;
    SVC_PACKETENTITIES: CL_ParsePacketEntities(False);
    SVC_DELTAPACKETENTITIES: CL_ParsePacketEntities(True);
    SVC_CHOKE: CL_ParseChoke;
    SVC_RESOURCELIST: CL_ParseResourceList;
    SVC_NEWMOVEVARS: CL_ParseNewMoveVars;
    SVC_RESOURCEREQUEST: CL_ParseResourceRequest;
    SVC_CUSTOMIZATION: CL_ParseCustomization;
    SVC_CROSSHAIRANGLE: CL_ParseCrosshairAngle;
    SVC_SOUNDFADE: CL_ParseSoundFade;
    SVC_FILETXFERFAILED: CL_ParseFileTxferFailed;
    SVC_HLTV: CL_ParseHLTV;
    SVC_DIRECTOR: CL_ParseDirector;
    SVC_VOICEINIT: CL_ParseVoiceInit;
    SVC_VOICEDATA: CL_ParseVoiceData;
    SVC_SENDEXTRAINFO: CL_ParseSendExtraInfo;
    SVC_TIMESCALE: CL_ParseTimeScale;
    SVC_RESOURCELOCATION: CL_ParseResourceLocation;
    SVC_SENDCVARVALUE: CL_ParseSendCVarValue;
    SVC_SENDCVARVALUE2: CL_ParseSendCVarValue2;
  else
    Error(T, [Format('Illegal engine message %d', [B])]);
    Hint('Last parsed messages', [CL_GetMessagesHistory]);
    CL_FinalizeConnection;
    Exit;
  end;

  goto L1;
end;

function TXBaseGameClient.CL_ParseGameEvent(B: UInt8): Boolean;
const T = 'CL_ParseGameEvent';
var
  I: Int32;
begin
  Result := False;

  I := GameEvents.IndexOfIndex(B);

  if I = -1 then
  begin
    Error(T, [Format('Illegal game event %d', [B])]);
    Hint('Last parsed messages', [CL_GetMessagesHistory]);
    CL_FinalizeConnection;
    Exit;
  end;

  CL_AddMessageToHistory('E' + GameEvents[I].Name);

  if GameEvents[I].Size = 255 then
    GMSG.Write(MSG.ReadLStr(MSG.ReadUInt8))
  else
    GMSG.Write(MSG.ReadLStr(GameEvents[I].Size));

  Debug(T, [GameEvents[I].Name]);

  GMSG.Start;

  if Assigned(GameEvents[I].Callback) then
    GameEvents[I].Callback;

  GMSG.Clear;

  Result := True;
end;

procedure TXBaseGameClient.CL_ParseDemoMessage;
var
  FType: UInt8;
  Time: Float;
  SNumber,
  Size: UInt32;
  Data: LStr;
begin
  FType := DEM.ReadUInt8;
  Time := DEM.ReadFloat;
  SNumber := DEM.ReadUInt32;

  case FType of
    DEM_SERVERMSG,
    DEM_SERVERMSG2:
    begin
      DEM.Skip(220);

      DEM.ReadUInt32; // width
      DEM.ReadUInt32; // height wtf ?

      DEM.Skip(236);

      Size := DEM.ReadUInt32;

      if Size = 0 then
        Exit;

      MSG.ResetPositionHistory;
      MSG.Clear;
      MSG.Write(DEM.ReadLStr(Size));
      MSG.Start;

      CL_ParseServerMessage;
    end;

    DEM_NEXT: ; // ?
    DEM_COMMAND: DEM.Skip(64); // client command
    DEM_CLIENTDATA: DEM.Skip(32);
    DEM_LAST: ; // end of segment
    DEM_EVENT: DEM.Skip(84);
    DEM_WEAPONANIM: DEM.Skip(8);

    DEM_SOUND:
    begin
      DEM.Skip(4);
      DEM.Skip(DEM.ReadInt32 + 24 - 8);
    end;

    DEM_READBUFFER:
    begin
      DEM.Skip(4);
      DEM.Skip(DEM.ReadInt32 - 4);
    end;
  end;
end;

procedure TXBaseGameClient.CL_TransmitPacket;
var
  Sequence, Acknowledgement: Int32;
  FileFragmentBuffer, FragmentBuffer: LStr;
begin
  with Channel do
  begin
    OutgoingTime := GetTickCount;

    if BF.Size + 8 > MAX_NET_MESSAGE_LENGTH then
      CL_CreateFragments;

    CL_CheckFragment(FragmentsWriter, Fragment, FragmentBuffer);
    CL_CheckFragment(FileFragmentsWriter, FileFragment, FileFragmentBuffer);

    if (Fragment.Active and Fragment.CanSend)
    or (FileFragment.Active and FileFragment.CanSend) then
      OutgoingSequenceReliable := True;

    Sequence := OutgoingSequence
      or (Int32((Fragment.Active and Fragment.CanSend)or (FileFragment.Active and FileFragment.CanSend)) shl 30)
      or (Int32(OutgoingSequenceReliable) shl 31);

    Acknowledgement := IncomingSequence
      or (Int32(OutgoingAcknowledgementReliable) shl 31);

    OutgoingSequenceReliable := False;

    MSG.Clear;
    MSG.WriteInt32(Sequence);
    MSG.WriteInt32(Acknowledgement);

    if (Fragment.Active and Fragment.CanSend)
    or (FileFragment.Active and FileFragment.CanSend) then
      CL_WriteFragments(MSG, FragmentBuffer, FileFragmentBuffer);

    if MSG.Size + BF.Size < MAX_NET_MESSAGE_LENGTH then
    begin
      MSG.Write(BF.Memory^, BF.Size);
      BF.Clear;
    end;

    while MSG.Size < 16 do
      MSG.WriteUInt8(CLC_NOP);

    if not CL_SvenCoop then
      Munge(Pointer(UInt32(MSG.Memory) + 8), MSG.Size - 8, Sequence and $FF, MungifyTable2);

    NET.Send(Server, MSG);

    Inc(OutgoingSequence);
  end;
end;

procedure TXBaseGameClient.CL_CheckFragment(var AFragmentsWriter: TFragmentWriter; var AFragmentChannel: TFragmentChannel; var ABuffer: LStr);
label
  L0, L1;
begin
  L1: with AFragmentChannel do
    if Active then
      if CanSend then
        if Count > Total then
        begin
          Clear(AFragmentChannel);
          AFragmentsWriter.Delete(0);
          goto L0;
        end
        else
          ABuffer := AFragmentsWriter.GetFragment(Count)
      else
    else
      L0: if AFragmentsWriter.Count > 0 then
      begin
        Active := True;
        CanSend := True;
        Count := 1;
        Total := AFragmentsWriter[0].Total;
        goto L1;
      end;
end;

procedure TXBaseGameClient.CL_WriteFragments(var ABuffer: TBufferEx2; FragBuf, FileFragBuf: LStr);
  procedure _WriteHeader(var Frag: TFragmentChannel; Size, Offset: UInt32);
  begin
    with Frag do
    begin
      ABuffer.WriteUInt8(UInt8(Active));

      if Active then
      begin
        if LastCount < Count then
          Sequence := Channel.OutgoingSequence;

        CanSend := False;

        LastCount := Count;

        ABuffer.WriteUInt16(Total);
        ABuffer.WriteUInt16(Count);

        if CL_SvenCoop then
        begin
          ABuffer.WriteInt32(Offset);
          ABuffer.WriteInt32(Size);
        end
        else
        begin
          ABuffer.WriteInt16(Offset);
          ABuffer.WriteInt16(Size);
        end;
      end;
    end;
  end;
begin
  _WriteHeader(Channel.Fragment, Length(FragBuf), 0);
  _WriteHeader(Channel.FileFragment, Length(FileFragBuf), Length(FragBuf));

  ABuffer.Write(FragBuf);
  ABuffer.Write(FileFragBuf);
end;

procedure TXBaseGameClient.CL_CreateFragments(var ABuffer: TBufferEx2; ASize: UInt32 = DEFAULT_FRAGMENT_SIZE; ACompression: Boolean = DEFAULT_FRAGMENT_COMPRESSION_STATE);
var
  S: LStr;
begin
  Clear(S);

  if IsDemoPlayback then
    Exit;

  if ACompression then
  begin
    CL_CompressPacket(ABuffer);
    WriteString(S, 'BZ2');
  end;

  ABuffer.Start;

  S := S + ABuffer.ReadLStr(rmEnd);

  ABuffer.Clear;

  FragmentsWriter.CreateNewBuffer(S, ASize);
end;

procedure TXBaseGameClient.CL_CreateFragments(ASize: UInt32 = DEFAULT_FRAGMENT_SIZE; ACompression: Boolean = DEFAULT_FRAGMENT_COMPRESSION_STATE);
begin
  CL_CreateFragments(BF, ASize, ACompression);
end;

procedure TXBaseGameClient.CL_CreateFileFragments(AFileName, AFileData: LStr; ASize: UInt32 = DEFAULT_FRAGMENT_SIZE; ACompression: Boolean = DEFAULT_FRAGMENT_COMPRESSION_STATE);
begin
  if IsDemoPlayback then
    Exit;

  with TBufferEx2.Create do
  begin
    WriteLStr(AFileName);

    if ACompression then
    begin
      WriteLStr('bz2');
      CL_CompressPacket(AFileData);
    end
    else
      WriteLStr('uncompressed');

    WriteInt32(Length(AFileData));
    Write(AFileData);

    Start;

    FileFragmentsWriter.CreateNewBuffer(ReadLStr(rmEnd), ASize);

    Free;
  end;
end;

procedure TXBaseGameClient.CL_CompressPacket(var ABuffer: TBufferEx2);
var
  InBuffer,
  OutBuf: Pointer;
  InSize,
  OutSize: Int32;
begin
  InBuffer := ABuffer.Memory;
  InSize := ABuffer.Size;

  BZCompressBuf(InBuffer, InSize, OutBuf, OutSize);

  ABuffer.Clear;
  ABuffer.Write(OutBuf^, OutSize);
  ABuffer.Start;
  FreeMem(OutBuf);
end;

procedure TXBaseGameClient.CL_CompressPacket(var AData: LStr);
var
  ABuffer: TBufferEx2;
begin
  ABuffer := TBufferEx2.Create;
  ABuffer.Write(AData);
  CL_CompressPacket(ABuffer);
  Clear(AData);
  AData := ABuffer.ReadLStr(rmEnd);
  ABuffer.Free;
end;

procedure TXBaseGameClient.CL_ParseChallenge;
begin
  inherited;

  if MSG.Size < 10 then
    Exit;

  CMD.Tokenize(MSG.ReadLStr(rmEnd));

  if CMD.Count <= 1 then
    Exit;

  if not IsNumbers(CMD.Tokens[1]) then
    Exit;

  Challenge.Save(NET.From, StrToInt64(CMD.Tokens[1]));

  if State <> CS_WAIT_CHALLENGE then
    Exit;

  State := CS_CONNECTING;

  MSG.Clear;
  CL_WriteConnectPacket;
  CL_SendOutOfBandPacket(Server);
end;

procedure TXBaseGameClient.CL_BadPassword;
begin
  if State = CS_CONNECTING then
    CL_FinalizeConnection('Bad password');
end;

procedure TXBaseGameClient.CL_RejectConnection;
var
  S: LStr;
begin
  S := RemoveTBytes(MSG.ReadLStr);

  if State = CS_CONNECTING then
    CL_FinalizeConnection(S);
end;

procedure TXBaseGameClient.CL_AcceptedConnection(IsReconnect: Boolean = False);
begin
  if (State <> CS_CONNECTING) and not IsReconnect then
    Exit;

  CL_InitializePacketing;
  ReleaseEvent(OnConnectionAccepted);
  ExecuteCommand('new');
  Print(['Connection accepted by ' + Server.ToString]);
end;

procedure TXBaseGameClient.CL_RedirectConnection;
var
  S: LStr;
begin
  S := ParseBefore(MSG.ReadLStr(rmNullTerminatedOrLinebreak), ';');

  ReleaseEvent(OnConnectionRedirected, S);

  Print(['Connection redirected to ' + S]);

  if CL_AllowRedirects then
    ExecuteCommand('connect ' + S)
  else
    Print(['Redirects are not allowed']);
end;

procedure TXBaseGameClient.CL_ParseDisconnect;
const T = 'CL_ParseDisconnect';
var
  Reason: LStr;
begin
  Reason := ReadLine(MSG.ReadLStr);

  Debug(T, [Reason]);

  if State >= CS_CONNECTING then
    CL_FinalizeConnection(Reason);
end;

procedure TXBaseGameClient.CL_ParseEvent;
const T = 'CL_ParseEvent';
var
  I: Int;
  E: TEventInfo;
begin
  MSG.StartBitReading;

  for I := 0 to MSG.ReadUBits(5) - 1 do
  begin
    Clear(E);

    E.Packet := -1;
    E.Entity := -1;

    E.Index := MSG.ReadUBits(10); // index of event

    if MSG.ReadBit then
      E.Packet := MSG.ReadUBits(11);

    if MSG.ReadBit then
      Delta.Read(MSG, E.Args);

    if MSG.ReadBit then
      E.FireTime := MSG.ReadUBits(16);

    Debug(T, [E.ToString], EVENT_LOG_LEVEL);
  end;

  MSG.EndBitReading;
end;

procedure TXBaseGameClient.CL_ParseVersion;
const T = 'CL_ParseVersion';
begin
  ProtocolVersion := MSG.ReadInt32;
  Debug(T, [ProtocolVersion]);
end;

procedure TXBaseGameClient.CL_ParseSetView;
const T = 'CL_ParseSetView';
var
  Value: Int16;
begin
  Value := MSG.ReadInt16;

  Debug(T, [Value]);
end;

procedure TXBaseGameClient.CL_ParseSound;
const T = 'CL_ParseSound';
var
  Sound: TSound;
begin
  MSG.StartBitReading;

  with Sound do
  begin
    Volume := VOL_NORM;
    Attenuation := ATTN_NORM;
    Pitch := PITCH_NORM;

    Flags := MSG.ReadUBits(9);

    if Flags and SND_VOLUME > 0 then
      Volume := MSG.ReadUBits(8);

    if Flags and SND_ATTN > 0 then
      Attenuation := MSG.ReadUBits(8);

    Channel := MSG.ReadUBits(3); // if chan = 6 then static sound ? (from ida)
    Entity := MSG.ReadUBits(11);

    if Flags and SND_LONG_INDEX > 0 then
      Index := MSG.ReadUBits(16)
    else
      Index := MSG.ReadUBits(8);

    Origin := MSG.ReadBitVec3F;

    if Flags and SND_PITCH > 0 then
      Pitch := MSG.ReadUBits(8);
  end;

  MSG.EndBitReading;

  Debug(T, [Sound.ToString], SOUND_LOG_LEVEL);

  CL_PlaySound(Sound);
end;

procedure TXBaseGameClient.CL_ParseTime;
begin
  Time := MSG.ReadFloat;
end;

procedure TXBaseGameClient.CL_ParseStuffText;
const T = 'CL_ParseStuffText';
var
  S: LStr;
begin
  S := Trim(MSG.ReadLStr);
  Debug(T, [S]);
  ReleaseEvent(OnServerCommand, S);
  CMD_ExecuteConsoleCommand(S);
end;

procedure TXBaseGameClient.CL_ParseSetAngle;
const T = 'CL_ParseSetAngle';
begin
  ViewAngles.X := MSG.ReadHiResAngle;
  ViewAngles.Y := MSG.ReadHiResAngle;
  ViewAngles.Z := MSG.ReadHiResAngle;

  Debug(T, [ViewAngles.ToString]);
end;

procedure TXBaseGameClient.CL_ParseServerInfo;
const T = 'CL_ParseServerInfo';
begin
  with ServerInfo do
  begin
    Protocol := MSG.ReadInt32;
    SpawnCount := MSG.ReadInt32;
    MapCheckSum := MSG.ReadInt32;
    DLLCRC := MSG.ReadLStr(16);
    MaxPlayers := MSG.ReadUInt8;

    SetLength(Players, MaxPlayers);

    Index := MSG.ReadUInt8;

    UnMunge(@MapCheckSum, 4, Byte(not Index), MungifyTable3);

    MSG.ReadUInt8; // UInt((coop.Value = 0) and (deathmatch.Value <> 0))

    GameDir := MSG.ReadLStr;
    Name := Utf8ToAnsi(MSG.ReadLStr);
    Map := MSG.ReadLStr;
    MapList := MSG.ReadLStr;

    MSG.ReadUInt8;

    Debug(T, ['Protocol: ', Protocol]);
    Debug(T, ['SpawnCount: ', SpawnCount]);
    Debug(T, ['MapCheckSum: ', MapCheckSum]);
    Debug(T, ['MaxPlayers: ', MaxPlayers]);
    Debug(T, ['Index: ', Index]);
    Debug(T, ['GameDir: ', GameDir]);
    Debug(T, ['HostName: ', Name]);
    Debug(T, ['Map: ', Map]);
//    Debug(T, ['MapList: ', MapList]);

    if not (Protocol in [46..48]) then
    begin
      CL_FinalizeConnection(['Server is using unsupported protocol version: ', Protocol]);
      Exit;
    end;

    CL_InitializeGameEngine;
    ExecuteCommand('sendres');
  end;
end;

procedure TXBaseGameClient.CL_ParseLightStyle;
const T = 'CL_ParseLightStyle';
var
  AIndex: UInt8;
begin
  AIndex := MSG.ReadUInt8;

  if AIndex > High(LightStyles) then
    SetLength(LightStyles, AIndex + 1);

  LightStyles[AIndex] := MSG.ReadLStr;

  Debug(T, ['Index: ', AIndex, ', Data: "', LightStyles[AIndex], '"'], LIGHTSTYLE_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseUpdateUserInfo;
const T = 'CL_ParseUpdateUserInfo';
var
  Index: UInt8;
begin
  Index := MSG.ReadUInt8;

  if CL_IsPlayerIndex(Index + 1) then
    with Players[Index] do
    begin
      UserID := MSG.ReadInt32;
      UserInfo := MSG.ReadLStr;
      MSG.Read(MD5, SizeOf(MD5));

      Debug(T, ['Index: ', Index, ', UserID: ', UserID, ', Data: "', UserInfo, '"'], UPDATEUSERINFO_LOG_LEVEL);
    end;
end;

procedure TXBaseGameClient.CL_ParseDeltaDescription;
const T = 'CL_ParseDeltaDescription';
var
  Name: LStr;
begin
  Name := MSG.ReadLStr;
  MSG.StartBitReading;
  Delta.Add(MSG, Name, MSG.ReadUBits(16));
  MSG.EndBitReading;

  Debug(T, [Name]);
end;

procedure TXBaseGameClient.CL_ParseClientData;
var
  Index: Int32;
begin
  if IsHLTV then
    Exit;

  MSG.StartBitReading;

  if MSG.ReadBit then
    MSG.ReadUBits(8);

  Delta.Read(MSG, ClientData);

  while MSG.ReadBit do
  begin
    if ServerInfo.Protocol < 47 then
      Index := MSG.ReadUBits(5)
    else
      Index := MSG.ReadUBits(6);

    if Index > High(WeaponData) then // allocate more weapondata if need
      SetLength(WeaponData, Index + 1);

    Delta.Read(MSG, WeaponData[Index - 1]);
  end;

  MSG.EndBitReading;
end;

procedure TXBaseGameClient.CL_ParseStopSound;
const T = 'CL_ParseStopSound';
var
  Index: Int16;
begin
  Index := MSG.ReadInt16;

  Debug(T, [Index]);
end;

procedure TXBaseGameClient.CL_ParsePings;
begin
  MSG.StartBitReading;

  while MSG.ReadBit do
    with Players[MSG.ReadUBits(5)] do
    begin
      Ping := MSG.ReadUBits(12);
      Loss := MSG.ReadUBits(7);
    end;

  MSG.EndBitReading;
end;

procedure TXBaseGameClient.CL_ParseParticle;
const T = 'CL_ParseParticle';
var
  Particle: TParticle;
begin
  with Particle do
  begin
    Origin := MSG.ReadCoord3;

    Direction.X := MSG.ReadUInt8;
    Direction.Y := MSG.ReadUInt8;
    Direction.Z := MSG.ReadUInt8;

    Count := MSG.ReadUInt8;
    Color := MSG.ReadUInt8;

    Debug(T, [
      'Origin: [', Origin.ToString, '], ',
      'Direction: [', Direction.ToString, '], ',
      'Count: ', Count, ', ',
      'Color: ', Color]);
  end;
end;

procedure TXBaseGameClient.CL_ParseSpawnStatic;
const T = 'CL_ParseSpawnStatic';
var
  Index: Int16;
  Entity: TEntity;
begin
  Clear(Entity);

  Index := MSG.ReadInt16; // ent index

  with Entity do
  begin
    Sequence := MSG.ReadUInt8;
    Frame := MSG.ReadUInt8;
    ColorMap := MSG.ReadUInt16;
    Skin := MSG.ReadUInt8;

    Origin.X := MSG.ReadCoord;
    Angles.X := MSG.ReadAngle;

    Origin.Y := MSG.ReadCoord;
    Angles.Y := MSG.ReadAngle;

    Origin.Z := MSG.ReadCoord;
    Angles.Z := MSG.ReadAngle;

    RenderMode := MSG.ReadUInt8;

    if RenderMode <> 0 then
    begin
      RenderAmt := MSG.ReadUInt8;
      MSG.Read(RenderColor, SizeOf(RenderColor));
      RenderFX := MSG.ReadUInt8;
    end;

    Debug(T, [
      'Index: ', Index, ', ',
      'Origin: [', Origin.ToString, '], ',
      'Angles: [', Angles.ToString, '], ',
      'Sequence: ', Sequence, ', ',
      'Frame: ', Frame, ', ',
      'ColorMap: ', ColorMap, ', ',
      'Skin: ', Skin, ', ',
      'RenderMode: ', RenderMode]);
  end;
end;

procedure TXBaseGameClient.CL_ParseEventReliable;
const T = 'CL_ParseEventReliable';
var
  E: TEventInfo;
begin
  Clear(E);

  E.Packet := -1;
  E.Entity := -1;

  MSG.StartBitReading;

  E.Index := MSG.ReadUBits(10);

  Delta.Read(MSG, E.Args);

  if MSG.ReadBit then
    E.FireTime := MSG.ReadUBits(16);

  MSG.EndBitReading;

  Debug(T, [
    'Index: ', E.Index, ', ',
    'FireTime: ', E.FireTime, ', ',
    E.Args.ToString], EVENT_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseSpawnBaseline;
var
  I, Index: Int32;
begin
  MSG.StartBitReading;

  while MSG.PeekUBits(16) <> 65535 do
  begin
    Index := MSG.ReadUBits(11);

    if Index > High(Baseline) then
      SetLength(Baseline, Index + 1);

    if MSG.ReadUBits(2) and ENTITY_BEAM > 0 then
      Delta.Read(MSG, Baseline[Index], ENT_CUSTOM)
    else
      if CL_IsPlayerIndex(Index) then
        Delta.Read(MSG, Baseline[Index], ENT_PLAYER)
      else
        Delta.Read(MSG, Baseline[Index], ENT_STANDART);
  end;

  // setup entities

  CL_AllocateEntities(Length(Baseline));

  for I := Low(Entities) to High(Entities) do
    Entities[I] := Baseline[I];

  MSG.SkipBits(16); //must be 65535

  SetLength(InstancedBaseline, MSG.ReadUBits(6));

  for I := Low(InstancedBaseline) to High(InstancedBaseline) do
    Delta.Read(MSG, InstancedBaseline[I], ENT_STANDART);

  MSG.EndBitReading;

  Print([Length(Baseline), ' baseline entities received']);

  if Length(InstancedBaseline) > 0 then
    Print([Length(InstancedBaseline), ' instanced baseline entities received']);
end;

procedure TXBaseGameClient.CL_ParseTempEntity;
const T = 'CL_ParseTempEntity';
var
  Index: UInt8;
begin
  Index := MSG.ReadUInt8;

  Debug(T, [TempEntityMsgs[Index].Name]);

  CL_AddMessageToHistory('TE' + TempEntityMsgs[Index].Name);

  case Index of
    TE_BEAMPOINTS: CL_ParseTEBeamPoints;
    TE_BEAMENTPOINT: CL_ParseTEBeamEntPoint;
    TE_GUNSHOT: CL_ParseTEGunShot;
    TE_EXPLOSION: CL_ParseTEExplosion;
    TE_TAREXPLOSION: CL_ParseTETarExplosion;
    TE_SMOKE: CL_ParseTESmoke;
    TE_TRACER: CL_ParseTETracer;
    TE_LIGHTNING: CL_ParseTELightning;
    TE_BEAMENTS: CL_ParseTEBeamEnts;
    TE_SPARKS: CL_ParseTESparks;
    TE_LAVASPLASH: CL_ParseTELavaSplash;
    TE_TELEPORT: CL_ParseTETeleport;
    TE_EXPLOSION2: CL_ParseTEExplosion2;
    TE_BSPDECAL: CL_ParseTEBSPDecal;
    TE_IMPLOSION: CL_ParseTEImplosion;
    TE_SPRITETRAIL: CL_ParseTESpriteTrail;
    TE_SPRITE: CL_ParseTESprite;
    TE_BEAMSPRITE: CL_ParseTEBeamSprite;
    TE_BEAMTORUS: CL_ParseTEBeamToRus;
    TE_BEAMDISK: CL_ParseTEBeamDisc;
    TE_BEAMCYLINDER: CL_ParseTEBeamCylinder;
    TE_BEAMFOLLOW: CL_ParseTEBeamFollow;
    TE_GLOWSPRITE: CL_ParseTEGlowSprite;
    TE_BEAMRING: CL_ParseTEBeamRing;
    TE_STREAK_SPLASH: CL_ParseTEStreakSplash;
    TE_DLIGHT: CL_ParseTEDLight;
    TE_ELIGHT: CL_ParseTEELight;
    TE_TEXTMESSAGE: CL_ParseTETextMessage;
    TE_LINE: CL_ParseTELine;
    TE_BOX: CL_ParseTEBox;
    TE_KILLBEAM: CL_ParseTEKillBeam;
    TE_LARGEFUNNEL: CL_ParseTELargeFunnel;
    TE_BLOODSTREAM: CL_ParseTEBloodStream;
    TE_SHOWLINE: CL_ParseTEShowLine;
    TE_BLOOD: CL_ParseTEBlood;
    TE_DECAL: CL_ParseTEDecal;
    TE_FIZZ: CL_ParseTEFizz;
    TE_MODEL: CL_ParseTEModel;
    TE_EXPLODEMODEL: CL_ParseTEExplodeModel;
    TE_BREAKMODEL: CL_ParseTEBreakModel;
    TE_GUNSHOTDECAL: CL_ParseTEGunShotDecal;
    TE_SPRITE_SPRAY: CL_ParseTESpriteSpray;
    TE_ARMOR_RICOCHET: CL_ParseTEArmorRicochet;
    TE_PLAYERDECAL: CL_ParseTEPlayerDecal;
    TE_BUBBLES: CL_ParseTEBubbles;
    TE_BUBBLETRAIL: CL_ParseTEBubbleTrail;
    TE_BLOODSPRITE: CL_ParseTEBloodSprite;
    TE_WORLDDECAL: CL_ParseTEWorldDecal;
    TE_WORLDDECALHIGH: CL_ParseTEWorldDecalHigh;
    TE_DECALHIGH: CL_ParseTEDecalHigh;
    TE_PROJECTILE: CL_ParseTEProjectile;
    TE_SPRAY: CL_ParseTESpray;
    TE_PLAYERSPRITES: CL_ParseTEPlayerSprites;
    TE_PARTICLEBURST: CL_ParseTEParticleBurst;
    TE_FIREFIELD: CL_ParseTEFireField;
    TE_PLAYERATTACHMENT: CL_ParseTEPlayerAttachment;
    TE_KILLPLAYERATTACHMENTS: CL_ParseTEKillPlayerAttachments;
    TE_MULTIGUNSHOT: CL_ParseTEMultiGunShot;
    TE_USERTRACER: CL_ParseTEUserTracer;
  end;
end;

procedure TXBaseGameClient.CL_ParseSetPause;
const T = 'CL_ParseSetPause';
begin
  Paused := MSG.ReadBool8;

  Debug(T, [Paused]);
end;

procedure TXBaseGameClient.CL_ParseSignonNum;
const T = 'CL_ParseSignonNum';
var
  Index: UInt8;
begin
  Index := MSG.ReadUInt8;

  if Index < SignonNum then
  begin
    Error(T, ['received signon ', Index, ' when at ', SignonNum]);
    CL_FinalizeConnection;
    Exit;
  end;

  SignonNum := Index;

  CL_SignonReply;
end;

procedure TXBaseGameClient.CL_ParseCenterPrint;
const T = 'CL_ParseCenterPrint';
var
  Data: LStr;
begin
  Data := MSG.ReadLStr;

  Debug(T, ['"', Data, '"']);

  ReleaseEvent(OnCenterPrint, Data);
end;

procedure TXBaseGameClient.CL_ParseSpawnStaticSound;
const T = 'CL_ParseSpawnStaticSound';
var
  Sound: TSound;
  Unk1: UInt8;
begin
{Start playback of a sound, loaded into the static portion of the channel array.
 This should be used for looping ambient sounds, looping sounds that should not non-creature sentences, and one-shot ambient streaming sounds.
 It can also play 'regular' sounds one-shot, in case designers want to trigger regular game sounds.
 The sound can be spawned either from a fixed position or from an entity.

Note: To use it on a fixed position, provide a valid origin and set EntityIndex with 0.
Note: To use it from an entity, so position is updated, provide a valid EntityIndex and set Origin with a null vector.
Note: To stop a sound with SVC_STOPSOUND, a valid EntityIndex is needed.
Note: Volume has to be scaled by 255 and Attenuation by 64.
Note: Use SND_SENTENCE (1<<4) as flag for sentence sounds.
Note: It can be sent to one player.}

{From WIKI
Name: 	 SVC_SPAWNSTATICSOUND
 Structure:
 coord 	 OriginX
 coord 	 OriginY
 coord 	 OriginZ
 short 	 SoundIndex
 byte 	 Volume * 255
 byte 	 Attenuation * 64
 short 	 EntityIndex
 byte 	 Flags}

 {From IDA Pro
   *&v10 = MSG_ReadCoord(net_message);
  v11 = MSG_ReadCoord(net_message);
  v12 = MSG_ReadCoord(net_message);
  v1 = MSG_ReadShort();
  v7 = MSG_ReadByte() / 255.0;
  v8 = MSG_ReadByte() * 0.015625;
  v3 = MSG_ReadShort();
  v2 = MSG_ReadByte();
  v0 = MSG_ReadByte();}

  with Sound do
  begin
    Origin := MSG.ReadCoord3;
    Index := MSG.ReadInt16;
    Volume := MSG.ReadUInt8;
    Attenuation := MSG.ReadUInt8;
    Entity := MSG.ReadInt16;
    Flags := MSG.ReadUInt8;
  end;

  Unk1 := MSG.ReadUInt8;

  Debug(T, [Sound.ToString, ', ', 'Unk1: ', Unk1]);
end;

procedure TXBaseGameClient.CL_ParseIntermission;
const T = 'CL_ParseIntermission';
begin
  Debug(T, ['this']);

  Intermission := 1;
end;

procedure TXBaseGameClient.CL_ParseFinale;
const T = 'CL_ParseFinale';
var
  Data: LStr;
begin
  Data := MSG.ReadLStr;

  Debug(T, [Data]);

  Intermission := 2;
end;

procedure TXBaseGameClient.CL_ParseCDTrack;
const T = 'CL_ParseCDTrack';
var
  Index, Loop: UInt8;
begin
  Index := MSG.ReadUInt8;
  Loop := MSG.ReadUInt8;

  Debug(T, ['Index: ', Index, ', Loop: ', Loop]);
end;

procedure TXBaseGameClient.CL_ParseRestore;
const T = 'CL_ParseRestore';
var
  v1, Map: LStr;
  I: Int32;
begin
  v1 := MSG.ReadLStr;  //directory?
  Debug(T, [v1]);

  for I := 0 to MSG.ReadUInt8 - 1 do
    Map := MSG.ReadLStr;
end;

procedure TXBaseGameClient.CL_ParseCutScene;
const T = 'CL_ParseCutScene';
var
  Data: LStr;
begin
{Shows the intermission camera view, and writes-out text passed in first parameter.

Note: Intermission mode 3.
Note: This text will keep showing on clients in future intermissions.  Name: 	 SVC_CUTSCENE
  Name: 	 SVC_CUTSCENE
  Structure:
  LStr 	 Text}

  Data := MSG.ReadLStr;

  Debug(T, [Data]);

  Intermission := 3;
end;

procedure TXBaseGameClient.CL_ParseWeaponAnim;
const T = 'CL_ParseWeaponAnim';
var
  Sequence, Group: UInt8;
begin
{ Plays a weapon sequence.

  Name: 	 SVC_WEAPONANIM
  Structure:
  byte 	 SequenceNumber
  byte 	 WeaponmodelBodygroup}

  Sequence := MSG.ReadUInt8;
  Group := MSG.ReadUInt8;

  Debug(T, ['Sequence: ', Sequence, ', Group: ', Group]);
end;

procedure TXBaseGameClient.CL_ParseDecalName;
const T = 'CL_ParseDecalName';
var
  Index: UInt8;
  Decal: LStr;
begin
{ Allows to set, into the client's decals array and at specific position index (0->511), a decal name.
  E.g: let's say you send a message to set a decal "{break" at index 200.
  As result, when a message TE_ will be used to show a decal at index 200, we will see "{break".

  Note: If there is already an existing decal at the provided index, it will be overwritten.
  Note: It appears we can play only with decals from decals.wad.

   Name: 	 SVC_DECALNAME
   Structure:
   byte 	 PositionIndex
   LStr 	 DecalName}

  Index := MSG.ReadUInt8;
  Decal := MSG.ReadLStr;

  Debug(T, ['Index: ', Index, ', Decal: "', Decal, '"']);
end;

procedure TXBaseGameClient.CL_ParseRoomType;
const T = 'CL_ParseRoomType';
var
  Index: Int16;
begin
{ Sets client room_type cvar to provided value.
  0 = Normal (off)
  1 = Generic
  2 = Metal Small
  3 = Metal Medium
  4 = Metal Large
  5 = Tunnel Small
  6 = Tunnel Medium
  7 = Tunnel Large
  8 = Chamber Small
  9 = Chamber Medium
  10 = Chamber Large
  11 = Bright Small
  12 = Bright Medium
  13 = Bright Large
  14 = Water 1
  15 = Water 2
  16 = Water 3
  17 = Concrete Small
  18 = Concrete Medium
  19 = Concrete Large
  20 = Big 1
  21 = Big 2
  22 = Big 3
  23 = Cavern Small
  24 = Cavern Medium
  25 = Cavern Large
  26 = Weirdo 1
  27 = Weirdo 2
  28 = Weirdo 3

  Name: SVC_ROOMTYPE

  Structure:
  short 	 Value}
  
  Index := MSG.ReadInt16;

  Debug(T, [Index]);
end;

procedure TXBaseGameClient.CL_ParseAddAngle;
begin
{ Add an angle on the yaw axis of the current client's view angle.
  Note: When pev->fixangle is set to 2, this message is called to add pev->avelocity[1] as value.
  Note: The value needs to be scaled by ( 65536 / 360 ).}

  ViewAngles.X := ViewAngles.X + MSG.ReadHiResAngle;
end;

procedure TXBaseGameClient.CL_ParseNewUserMsg;
const T = 'CL_ParseNewUserMsg';
var
  Index, Size: UInt8;
  Name: LStr;
begin
  Index := MSG.ReadUInt8;
  Size := MSG.ReadUInt8;
  Name := ReadString(MSG.ReadLStr(16)); // FIX

  Debug(T, ['Index: ', Index, ', Size: ', Size, ', Name: "', Name, '"'], NEWUSERMSG_LOG_LEVEL);

  GameEvents.Add(Index, Size, Name);
end;

procedure TXBaseGameClient.CL_ParsePacketEntities(IsDelta: Boolean);
const T = 'CL_ParsePacketEntities';
var
  Mask: UInt8;
  Index, LastLength: Int32;
  Custom, RemoveEntity, Increment, B, LengthChanged: Boolean;
begin
  if SignonNum = 1 then
  begin
    SignonNum := 2;
    CL_SignonReply;
  end;

  EntitiesCount := MSG.ReadInt16; // currently visible entities count

  if IsDelta then
    Mask := MSG.ReadUInt8; // last updatemask (clc_delta)

  UpdateMask := Channel.IncomingSequence and $FF; // setup new update mask

  MSG.StartBitReading;

  Clear(Index);
  Clear(LengthChanged);

  LastLength := Length(Entities);

  while MSG.PeekUBits(16) <> 0 do
  begin
    if IsDelta then
      RemoveEntity := MSG.ReadBit;

    if IsDelta then
      Increment := False
    else
      Increment := MSG.ReadBit;

    if Increment then
      Inc(Index)
    else
      if MSG.ReadBit then // is absolute entity index ?
        Index := MSG.ReadUBits(11)
      else
        Inc(Index, MSG.ReadUBits(6));

    if Index > High(Entities) then // allocate new entities if need
    begin
      LengthChanged := True;
      CL_AllocateEntities(Index + 1);
    end;

    if IsDelta and RemoveEntity then // remove this entity, because server wants it (only if IsDelta)
    begin
      Entities[Index].IsActive := False;
      Continue;
    end;

    Custom := MSG.ReadBit;

    Clear(B);

    if Length(InstancedBaseline) > 0 then
      if MSG.ReadBit then
      begin
        B := True;
        Entities[Index] := InstancedBaseline[MSG.ReadUBits(6)];
      end;

    if not IsDelta and not B then
      if MSG.ReadBit then
        Entities[Index] := Baseline[MSG.ReadUBits(6)];

    if Custom then
      Delta.Read(MSG, Entities[Index], ENT_CUSTOM)
    else
      if CL_IsPlayerIndex(Index) then
        Delta.Read(MSG, Entities[Index], ENT_PLAYER)
      else
        Delta.Read(MSG, Entities[Index], ENT_STANDART);

    Entities[Index].IsActive := True;
  end;

  MSG.ReadUBits(16); // must be 0

  MSG.EndBitReading;

  if LengthChanged then
    Debug(T, [(Length(Entities) - LastLength), ' new entities allocated, total ', Length(Entities)]);
end;

procedure TXBaseGameClient.CL_ParseChoke;
begin
  Debug('CL_ParseChoke', ['this']);  // FIX
end;

procedure TXBaseGameClient.CL_ParseResourceList;
const T = 'CL_ParseResourceList';
var
  I: Int32;
  R: TResource;
begin
  MSG.StartBitReading;

  SetLength(Resources, MSG.ReadUBits(12));

  for I := Low(Resources) to  High(Resources) do
    with Resources[I] do
    begin
      RType := MSG.ReadUBits(4);
      Name := MSG.ReadBitLStr;
      Index := MSG.ReadUBits(12);
      Size := MSG.ReadUBits(24);
      Flags := MSG.ReadUBits(3);

      if Flags and RES_CUSTOM > 0 then
        MSG.ReadUBits(MD5, SizeOf(MD5));

      if MSG.ReadBit then
      begin
        Reserved := MSG.ReadBitLStr(32);
        UnMunge(Pointer(UInt32(Reserved)), 32, ServerInfo.SpawnCount, MungifyTable1);
      end;
    end;

  Clear(I);

  if MSG.ReadBit then
    while MSG.ReadBit do
    begin
      if MSG.ReadBit then
        Inc(I, MSG.ReadUBits(5))
      else
        I := MSG.ReadUBits(10);

      Resources[I].Flags := Resources[I].Flags or RES_CHECKFILE;
    end;

  MSG.EndBitReading;

  for I := Low(Resources) to  High(Resources) do
    Debug(T, [Resources[I].ToString], RESOURCELIST_LOG_LEVEL);

  Print([Length(Resources), ' resources received']);

  State := CS_VERIFYING_RESOURCES;

  CL_VerifyResources;
end;

procedure TXBaseGameClient.CL_ParseNewMoveVars;
const T = 'CL_ParseNewMoveVars';
begin
  with MoveVars do
  begin
    Gravity := MSG.ReadFloat;
    StopSpeed := MSG.ReadFloat;
    MaxSpeed := MSG.ReadFloat;
    SpectatorMaxSpeed := MSG.ReadFloat;
    Accelerate := MSG.ReadFloat;
    AirAccelerate := MSG.ReadFloat;
    WaterAccelerate := MSG.ReadFloat;
    Friction := MSG.ReadFloat;
    EdgeFriction := MSG.ReadFloat;
    WaterFriction := MSG.ReadFloat;
    EntGravity := MSG.ReadFloat;
    Bounce := MSG.ReadFloat;
    StepSize := MSG.ReadFloat;
    MaxVelocity := MSG.ReadFloat;
    ZMax := MSG.ReadFloat;
    WaveHeight := MSG.ReadFloat;
    FootSteps := MSG.ReadUInt8;
    RollAngle := MSG.ReadFloat;
    RollSpeed := MSG.ReadFloat;
    SkyColorR := MSG.ReadFloat;
    SkyColorG := MSG.ReadFloat;
    SkyColorB := MSG.ReadFloat;
    SkyVec := MSG.ReadVec3F;
    SkyName := MSG.ReadLStr;


    Debug(T, [
      'Gravity: ', Gravity, ', ',
      'StopSpeed: ', StopSpeed, ', ',
      'MaxSpeed: ', MaxSpeed, ', ',
      'SpectatorMaxSpeed: ', SpectatorMaxSpeed, ', ',
      'Accelerate: ', Accelerate, ', ',
      'AirAccelerate: ', AirAccelerate, ', ',
      'WaterAccelerate: ', WaterAccelerate, ', ',
      'Friction: ', Friction, ', ',
      'EdgeFriction: ', EdgeFriction, ', ',
      'WaterFriction: ', WaterFriction, ', ',
      'EntGravity: ', EntGravity, ', ',
      'Bounce: ', Bounce, ', ',
      'StepSize: ', StepSize, ', ',
      'MaxVelocity: ', MaxVelocity, ', ',
      'ZMax: ', ZMax, ', ',
      'WaveHeight: ', WaveHeight, ', ',
      'FootSteps: ', FootSteps, ', ',
      'RollAngle: ', RollAngle, ', ',
      'RollSpeed: ', RollSpeed, ', ',
      'SkyColor: [R: ', SkyColorR, ', G: ', SkyColorG, ', B: ', SkyColorB, '], ',
      'SkyVec: [', SkyVec.ToString, '], ',
      'SkyName: "', SkyName, '"']);
  end;
end;

procedure TXBaseGameClient.CL_ParseResourceRequest;
const T = 'CL_ParseResourceRequest';
var
  I, ServerNum, Range: Int32;
  S: LStr;
begin
  ServerNum := MSG.ReadInt32;

  if ServerNum = ServerInfo.SpawnCount then
  begin
    Range := MSG.ReadInt32;

    if Range = 0 then
    begin
      CL_WriteResourceList;
      CL_CreateFragments(DEFAULT_FRAGMENT_SIZE, False);
    end
    else
      Error(T, ['Custom resource list request out of range (', Range, ')']);
  end
  else
    Error(T, ['Index (', ServerNum, ') <> SpawnCount (', ServerInfo.SpawnCount, ')']);
end;

procedure TXBaseGameClient.CL_ParseCustomization;
const T = 'CL_ParseCustomization';
var
  Index: UInt8;
  Resource: TResource;
begin
  Index := MSG.ReadUInt8;

  with Resource do
  begin
    RType := MSG.ReadUInt8;
    Name := MSG.ReadLStr;
    Index := MSG.ReadInt16;
    Size := MSG.ReadInt32;
    Flags := MSG.ReadUInt8;

    if Flags and RES_CUSTOM > 0 then
      MSG.Read(MD5, SizeOf(MD5));
  end;

  Debug(T, [Resource.ToString]);
end;

procedure TXBaseGameClient.CL_ParseCrosshairAngle;
const T = 'CL_ParseCrosshairAngle';
var
  Pitch, Yaw: UInt8;
begin

  {Adjusts the weapon's crosshair angle.
   Basically, the weapon position on the player's view can have a different origin.

    Note: Called by pfnCrosshairAngle. So, the same as EngFunc_CrosshairAngle.
    Note: If you use the engine call, no need to scale by 5.
    Note: Use 0 for both to get the default position.

      Name: 	 SVC_CROSSHAIRANGLE
      Structure:
      char 	 PitchAngle * 5
      char 	 YawAngle * 5}

  Pitch := MSG.ReadUInt8;
  Yaw := MSG.ReadUInt8;

  Debug(T, ['Pitch: ', Pitch, ', Yaw: ', Yaw]);
end;

procedure TXBaseGameClient.CL_ParseSoundFade;
const T = 'CL_ParseSoundFade';
var
  InitialPercent,
  HoldTime,
  FadeInTime,
  FadeOutTime: UInt8;
begin
  { Updates client side sound fade.
    It's used to modulate sound volume on the client.
    Such functionality is part of a main function where the purpose would be to update sound subsystem and cd audio.
    Note : EngFunc_FadeClientVolume sends that message to client

    Name: 	 SVC_SOUNDFADE

    Structure:
    byte  InitialPercent
    byte  HoldTime
    byte  FadeInTime
    byte  FadeOutTime}
  
  InitialPercent := MSG.ReadUInt8;
  HoldTime := MSG.ReadUInt8;
  FadeInTime := MSG.ReadUInt8;
  FadeOutTime := MSG.ReadUInt8;

  Debug(T, [
    'InitialPercent: ', InitialPercent, ', ',
    'HoldTime: ', HoldTime, ', ',
    'FadeInTime: ', FadeInTime, ', ',
    'FadeOutTime: ', FadeOutTime]);
end;

procedure TXBaseGameClient.CL_ParseFileTxferFailed;
var
  I: Int32;
  FileName: LStr;
label
  L1;
begin
  FileName := MSG.ReadLStr;

  Downloads.Remove(FileName);

  Print(['Server failed to transmit file: "', FileName, '"']);
end;

procedure TXBaseGameClient.CL_ParseHLTV;
const T = 'CL_ParseHLTV';
var
  Mode: UInt8;
begin
  Mode := MSG.ReadUInt8;

  case Mode of
    0: begin
      if SignonNum < 1 then
        IsHLTV := True;
    end;
    1: begin
      {MSG.ReadInt32;
      MSG.ReadInt16;
      MSG.ReadUInt16;
      MSG.ReadInt32;
      MSG.ReadInt32;
      MSG.ReadUInt16;}
      MSG.Skip(18);
    end;
    2: begin
      SignonNum := 2;
      //MSG.ReadString;
      MSG.Skip(8);
    end
  end;

  Debug(T, [Mode]);
end;

procedure TXBaseGameClient.CL_ParseDirector;
const T = 'CL_ParseDirector';
var
  S: LStr;
  Index: UInt8;
begin
  DMSG.Clear;
  DMSG.Write(MSG.ReadLStr(MSG.ReadUInt8));
  DMSG.Start;

  Index := DMSG.ReadUInt8;

  if not (Index in [DRC_CMD_FIRST..DRC_CMD_LAST]) then
  begin
    Error(T, [Format('Illegal Director Command %d', [Index])]);
    Hint('Last parsed messages', [CL_GetMessagesHistory]);
    CL_FinalizeConnection;
    Exit;
  end;

  Debug(T, ['Index: ', Index, ', Name: "', DrcCmdMessages[Index].Name + '"']);

  case Index of
    DRC_CMD_NONE: ;
    DRC_CMD_START: CL_ParseDirectorStart;
    DRC_CMD_EVENT: CL_ParseDirectorEvent;
    DRC_CMD_MODE: ;
    DRC_CMD_CAMERA: ;
    DRC_CMD_TIMESCALE: ;
    DRC_CMD_MESSAGE: ;
    DRC_CMD_SOUND: ;
    DRC_CMD_STATUS: CL_ParseDirectorStatus;
    DRC_CMD_BANNER: ;
    DRC_CMD_STUFFTEXT: CL_ParseDirectorStuffText;
    DRC_CMD_CHASE: ;
    DRC_CMD_INEYE: ;
    DRC_CMD_MAP: ;
    DRC_CMD_CAMPATH: ;
    DRC_CMD_WAYPOINTS: ;
  end;
end;

procedure TXBaseGameClient.CL_ParseVoiceInit;
const T = 'CL_ParseVoiceInit';
begin
  VoiceCodec := MSG.ReadLStr;

  if ServerInfo.Protocol > 46 then
  begin
    VoiceQuality := MSG.ReadUInt8;
    Debug(T, ['Codec: "', VoiceCodec, '", Quality: ', VoiceQuality]);
  end
  else
    Debug(T, ['Codec: "', VoiceCodec, '"']);
end;

procedure TXBaseGameClient.CL_ParseVoiceData;
const T = 'CL_ParseVoiceData';
var
  ClientIndex, Size: Int32;
begin
  ClientIndex := MSG.ReadUInt8 + 1;  // +1 ?

  Size := MSG.ReadInt16;

  if Size > 8192 then
    Size := 8192;

  MSG.Skip(Size);

  Debug(T, ['Size: ', Size], VOICEDATA_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseSendExtraInfo;
const T = 'CL_ParseSendExtraInfo';
begin
  with ExtraInfo do
  begin
    FallbackDir := MSG.ReadLStr;
    AllowCheats := MSG.ReadBool8;

    Debug(T, ['FallbackDir: "', FallbackDir, '", AllowCheats: ', AllowCheats]);
  end;
end;

procedure TXBaseGameClient.CL_ParseTimeScale;
const T = 'CL_ParseTimeScale';
begin
  TimeScale := MSG.ReadFloat;

  Debug(T, [TimeScale]);
end;

procedure TXBaseGameClient.CL_ParseResourceLocation;
const T = 'CL_ParseResourceLocation';
begin
  ResourceLocation := MSG.ReadLStr;

  Debug(T, [ResourceLocation]);
end;

procedure TXBaseGameClient.CL_ParseSendCVarValue;
const T = 'CL_ParseSendCVarValue';
  BadCVarRequest = 'Bad CVAR request';
var
  CVar, Response: LStr;
  A, C: Int32;
label
  L1;
begin
  CVar := MSG.ReadLStr;

  C := CVars.IndexOf(CVar);
  A := FakeCVars.IndexOf(CVar);   // FIX

  if C = -1 then // try to find fake cvar
    if A <> -1 then
      if Length(FakeCVars[A].Value) > 0 then
        Response := FakeCVars[A].Value
      else
        Response := BadCVarRequest
    else
      Response := BadCVarRequest
  else
    if CVars[C].Flags and CVAR_PRIVATE > 0 then
    begin
      if A <> -1 then
        if Length(FakeCVars[A].Value) > 0 then
          Response := FakeCVars[A].Value
        else
          Response := BadCVarRequest
      else
        Response := BadCVarRequest;

      Hint(H_ENGINE, ['QCC blocked for: "', CVar, '"']);
    end
    else
      Response := CVars[C].{ToString}Data;

  if (Response = BadCVarRequest) and (C = -1) then
    Hint(H_ENGINE, ['QCC bad request for: "', CVar, '"']);

  Debug(T, ['CVar: "', CVar, '"']);

  CL_WriteCVarValue(Response);
end;

procedure TXBaseGameClient.CL_ParseSendCVarValue2;
const T = 'CL_ParseSendCVarValue2';
  BadCVarRequest = 'Bad CVAR request';
var
  Index: Int32;
  CVar, Response: LStr;
  A, C: Int32;
begin
  Index := MSG.ReadInt32;
  CVar := MSG.ReadLStr;

  C := CVars.IndexOf(CVar);
  A := FakeCVars.IndexOf(CVar); // FIX

  if C = -1 then // try to find fake cvar
    if A <> -1 then
      if Length(FakeCVars[A].Value) > 0 then
        Response := FakeCVars[A].Value
      else
        Response := BadCVarRequest
    else
      Response := BadCVarRequest
  else
    if CVars[C].Flags and CVAR_PRIVATE > 0 then
    begin
      if A <> -1 then
        if Length(FakeCVars[A].Value) > 0 then
          Response := FakeCVars[A].Value
        else
          Response := BadCVarRequest
      else
        Response := BadCVarRequest;

      Hint(H_ENGINE, ['QCC2 blocked for: "', CVar, '"']);
    end
    else
      Response := CVars[C].{ToString}Data;

  if (Response = BadCVarRequest) and (C = -1) then
    Hint(H_ENGINE, ['QCC2 bad request for: "', CVar, '"']);

  Debug(T, ['Index: ', Index, ', CVar: "', CVar, '"']);

  CL_WriteCVarValue2(Index, CVar, Response);
end;

procedure TXBaseGameClient.CL_ParseTEBeamPoints;
const T = 'CL_ParseTEBeamPoints';
var
  Vec1, Vec2: TVec3F;
  SpriteIndex: Int16;
  Color: TRGB;
  StartingFrame, FrameRate, Life, LineWidth, NoiseAmp, Brightness, ScrollSpeed: UInt8;
begin
// write_byte(TE_BEAMPOINTS)
// write_coord(startposition.x)
// write_coord(startposition.y)
// write_coord(startposition.z)
// write_coord(endposition.x)
// write_coord(endposition.y)
// write_coord(endposition.z)
// write_short(sprite index)
// write_byte(starting frame)
// write_byte(frame rate in 0.1's)
// write_byte(life in 0.1's)
// write_byte(line width in 0.1's)
// write_byte(noise amplitude in 0.01's)
// write_byte(red)
// write_byte(green)
// write_byte(blue)
// write_byte(brightness)
// write_byte(scroll speed in 0.1's)

  Vec1 := MSG.ReadCoord3;
  Vec2 := MSG.ReadCoord3;
  SpriteIndex := MSG.ReadInt16;
  StartingFrame := MSG.ReadUInt8;
  FrameRate := MSG.ReadUInt8;
  Life := MSG.ReadUInt8;
  LineWidth := MSG.ReadUInt8;
  NoiseAmp := MSG.ReadUInt8;
  MSG.Read(Color, SizeOf(Color));
  Brightness := MSG.ReadUInt8;
  ScrollSpeed := MSG.ReadUInt8;
end;

procedure TXBaseGameClient.CL_ParseTEBeamEntPoint;
const T = 'CL_ParseTEBeamEntPoint';
var
  StartEntity: Int16;
  Vec2: TVec3F;
  SpriteIndex: Int16;
  StartingFrame, FrameRate, Life, LineWidth, NoiseAmp, R, G, B, Brightness, ScrollSpeed: UInt8;
begin
  StartEntity := MSG.ReadInt16;
  Vec2 := MSG.ReadCoord3;
  SpriteIndex := MSG.ReadInt16;
  StartingFrame := MSG.ReadUInt8;
  FrameRate := MSG.ReadUInt8;
  Life := MSG.ReadUInt8;
  LineWidth := MSG.ReadUInt8;
  NoiseAmp := MSG.ReadUInt8;
  R := MSG.ReadUInt8;
  G := MSG.ReadUInt8;
  B := MSG.ReadUInt8;
  Brightness := MSG.ReadUInt8;
  ScrollSpeed := MSG.ReadUInt8;
end;

procedure TXBaseGameClient.CL_ParseTEGunShot;
const T = 'CL_ParseTEGunShot';
var
  Position: TVec3F;
begin
  Position := MSG.ReadCoord3;

  Debug(T, ['Position: [', Position.ToString, ']'], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTEExplosion;
const T = 'CL_ParseTEExplosion';
var
  Position: TVec3F;
  SpriteIndex: Int16;
  Scale, FrameRate, Flags: UInt8;
begin
// write_byte(TE_EXPLOSION)
// write_coord(position.x)
// write_coord(position.y)
// write_coord(position.z)
// write_short(sprite index)
// write_byte(scale in 0.1's)
// write_byte(framerate)
// write_byte(flags)

  Position := MSG.ReadCoord3;
  SpriteIndex := MSG.ReadInt16;
  Scale := MSG.ReadUInt8;
  FrameRate := MSG.ReadUInt8;
  Flags := MSG.ReadUInt8;

  Debug(T, [
    'Position: [', Position.ToString, '], ',
    'SpriteIndex: ', SpriteIndex, ', ',
    'Scale: ', Scale, ', ',
    'FrameRate: ', FrameRate, ', ',
    'Flags: ', Flags], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTETarExplosion;
const T = 'CL_ParseTETarExplosion';
var
  Position: TVec3F;
begin
  Position := MSG.ReadCoord3;

  Debug(T, ['Position: [', Position.ToString, ']'], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTESmoke;
const T = 'CL_ParseTESmoke';
var
  Position: TVec3F;
  SpriteIndex: Int16;
  Scale, FrameRate: UInt8;
begin
  Position := MSG.ReadCoord3;
  SpriteIndex := MSG.ReadInt16;
  Scale := MSG.ReadUInt8;
  FrameRate := MSG.ReadUInt8;

  Debug(T, [
    'Position: [', Position.ToString, '], ',
    'SpriteIndex: ', SpriteIndex, ', ',
    'Scale: ', Scale, ', ',
    'FrameRate: ', FrameRate], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTETracer;
const T = 'CL_ParseTETracer';
begin
  MSG.ReadCoord3;
  MSG.ReadCoord3;
end;

procedure TXBaseGameClient.CL_ParseTELightning;
const T = 'CL_ParseTELightning';
begin
  MSG.ReadCoord3;
  MSG.ReadCoord3;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadInt16;
end;

procedure TXBaseGameClient.CL_ParseTEBeamEnts;
const T = 'CL_ParseTEBeamEnts';
begin
  MSG.ReadInt16; //start ent
  MSG.ReadInt16; //end ent
  MSG.ReadInt16; //sprite index
  MSG.ReadUInt8;  //starting frame
  MSG.ReadUInt8;  //frame rate
  MSG.ReadUInt8;  //life
  MSG.ReadUInt8;  //line width
  MSG.ReadUInt8;  //noise amplitude
  MSG.ReadUInt8;  //R
  MSG.ReadUInt8;  //G
  MSG.ReadUInt8;  //B
  MSG.ReadUInt8;  //brightness
  MSG.ReadUInt8;  //scroll spd
end;

procedure TXBaseGameClient.CL_ParseTESparks;
const T = 'CL_ParseTESparks';
var
  Position: TVec3F;
begin
  Position := MSG.ReadCoord3;

  Debug(T, ['Position: [', Position.ToString, ']'], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTELavaSplash;
const T = 'CL_ParseTELavaSplash';
var
  Position: TVec3F;
begin
  Position := MSG.ReadCoord3;

  Debug(T, ['Position: [', Position.ToString, ']', TEMP_ENTITY_LOG_LEVEL]);
end;

procedure TXBaseGameClient.CL_ParseTETeleport;
const T = 'CL_ParseTETeleport';
var
  Position: TVec3F;
begin
  Position := MSG.ReadCoord3;

  Debug(T, ['Position: [', Position.ToString, ']'], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTEExplosion2;
const T = 'CL_ParseTEExplosion2';
var
  Position: TVec3F;
  StartColor, NumColors: UInt8;
begin
  Position := MSG.ReadCoord3;
  StartColor := MSG.ReadUInt8;
  NumColors := MSG.ReadUInt8;

  Debug(T, [
    'Position: [', Position.ToString, '], ',
    'StartColor: ', StartColor, ', ',
    'NumColors: ', NumColors], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTEBSPDecal;
const T = 'CL_ParseTEBSPDecal';
var
  Position: TVec3F;
  TextureIndex, EntityIndex, ModelIndex: Int16;
begin
  Position := MSG.ReadCoord3;
  TextureIndex := MSG.ReadInt16;
  EntityIndex := MSG.ReadInt16;

  Clear(ModelIndex);

  if EntityIndex > 0 then
    ModelIndex := MSG.ReadInt16;

  Debug(T, [
    'Position: [', Position.ToString, '], ',
    'TextureIndex: ', TextureIndex, ', ',
    'EntityIndex: ', EntityIndex, ', ',
    'ModelIndex: ', ModelIndex], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTEImplosion;
const T = 'CL_ParseTEImplosion';
var
  Position: TVec3F;
  Radius, Count, Life: UInt8;
begin
  Position := MSG.ReadCoord3;
  Radius := MSG.ReadUInt8;
  Count := MSG.ReadUInt8;
  Life := MSG.ReadUInt8;

  Debug(T, [
    'Position: [', Position.ToString, '], ',
    'Radius: ', Radius, ', ',
    'Count: ', Count, ', ',
    'Life: ', Life], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTESpriteTrail;
const T = 'CL_ParseTESpriteTrail';
begin
  MSG.ReadCoord3;
  MSG.ReadCoord3;
  MSG.ReadInt16;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
end;

procedure TXBaseGameClient.CL_ParseTESprite;
const T = 'CL_ParseTESprite';
var
  Position: TVec3F;
  SpriteIndex: Int16;
  Scale, Brightness: UInt8;
begin
  Position := MSG.ReadCoord3;
  Spriteindex := MSG.ReadInt16;
  Scale := MSG.ReadUInt8;
  Brightness := MSG.ReadUInt8;

  Debug(T, [
    'Position: [', Position.ToString, '], ',
    'SpriteIndex: ', SpriteIndex, ', ',
    'Scale: ', Scale, ', ',
    'Brightness: ', Brightness], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTEBeamSprite;
const T = 'CL_ParseTEBeamSprite';
var
  StartPos, EndPos: TVec3F;
  BeamSprite, EndSprite: Int16;
begin
  StartPos := MSG.ReadCoord3;
  EndPos := MSG.ReadCoord3;
  BeamSprite := MSG.ReadInt16;
  EndSprite := MSG.ReadInt16;

  Debug(T, [
    'StartPos: [', StartPos.ToString, '], ',
    'EndPos: [', EndPos.ToString, '], ',
    'BeamSprite: ', BeamSprite, ', ',
    'EndSprite: ', EndSprite], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTEBeamToRus;
const T = 'CL_ParseTEBeamToRus';
var
  Origin, Axis: TVec3F;
  Sprite: Int16;
  StartFrame,
  FrameRate,
  Life,
  Width,
  Noise,
  ScrollSpeed: UInt8;
  Color: TRGBA;
begin
  // Screen aligned beam ring, expands to max radius over lifetime

  Origin := MSG.ReadCoord3;
  Axis := MSG.ReadCoord3;
  Sprite := MSG.ReadInt16;
  StartFrame := MSG.ReadUInt8;
  FrameRate := MSG.ReadUInt8;
  Life := MSG.ReadUInt8;
  Width := MSG.ReadUInt8;
  Noise := MSG.ReadUInt8;
  MSG.Read(Color, SizeOf(Color));
  ScrollSpeed := MSG.ReadUInt8;

  Debug(T, [
    'Origin: [', Origin.ToString, '], ',
    'Axis: [', Axis.ToString, '], ',
    'Sprite: ', Sprite, ', ',
    'StartFrame: ', StartFrame, ', ',
    'FrameRate: ', FrameRate, ', ',
    'Life: ', Life, ', ',
    'Width: ', Width, ', ',
    'Noise: ', Noise, ', ',
    'Color: [', Color.ToString, '], ',
    'ScrollSpeed: ', ScrollSpeed], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTEBeamDisc;
const T = 'CL_ParseTEBeamDisc';
begin
  MSG.ReadCoord3;
  MSG.ReadCoord3;
  MSG.ReadInt16;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
end;

procedure TXBaseGameClient.CL_ParseTEBeamCylinder;
const T = 'CL_ParseTEBeamCylinder';
begin
  MSG.ReadCoord3;
  MSG.ReadCoord3;
  MSG.ReadInt16;

  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
end;

procedure TXBaseGameClient.CL_ParseTEBeamFollow;
const T = 'CL_ParseTEBeamFollow';
var
  Entity, Sprite: Int16;
  Color: TRGB;
  Life, LineWidth, Brightness: UInt8;
begin
  Entity := MSG.ReadInt16;
  Sprite := MSG.ReadInt16;
  Life := MSG.ReadUInt8;
  LineWidth := MSG.ReadUInt8;
  MSG.Read(Color, SizeOf(Color));
  Brightness := MSG.ReadUInt8;

  Debug(T, [
    'Entity: ', Entity, ', ',
    'Sprite: ', Sprite, ', ',
    'Life: ', Life, ', ',
    'LineWidth: ', LineWidth, ', ',
    'Color [', Color.ToString, '], ',
    'Brightness: ', Brightness], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTEGlowSprite;
const T = 'CL_ParseTEGlowSprite';
begin
  MSG.ReadCoord3;
  MSG.ReadInt16;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
end;

procedure TXBaseGameClient.CL_ParseTEBeamRing;
const T = 'CL_ParseTEBeamRing';
begin
  MSG.ReadInt16;
  MSG.ReadInt16;
  MSG.ReadInt16;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
end;

procedure TXBaseGameClient.CL_ParseTEStreakSplash;
const T = 'CL_ParseTEStreakSplash';
begin
  MSG.ReadCoord3;
  MSG.ReadCoord3;
  MSG.ReadUInt8;
  MSG.ReadInt16;
  MSG.ReadInt16;
  MSG.ReadInt16;
end;

procedure TXBaseGameClient.CL_ParseTEDLight;
const T = 'CL_ParseTEDLight';
var
  Position: TVec3F;
  Radius, Life, DecayRate: UInt8;
  Color: TRGB;
begin
// write_byte(TE_DLIGHT)
// write_coord(position.x)
// write_coord(position.y)
// write_coord(position.z)
// write_byte(radius in 10's)
// write_byte(red)
// write_byte(green)
// write_byte(blue)
// write_byte(brightness)     // <- ?
// write_byte(life in 10's)
// write_byte(decay rate in 10's)

  Position := MSG.ReadCoord3;
  Radius := MSG.ReadUInt8;
  MSG.Read(Color, SizeOf(Color));
//  Brightness := MSG.ReadUInt8;
  Life := MSG.ReadUInt8;
  DecayRate := MSG.ReadUInt8;

  Debug(T, [
    'Position: [', Position.ToString, '], ',
    'Radius: ', Radius, ', ',
    'Color: [', Color.ToString, '], ',
    'Life: ', Life, ', ',
    'DecayRate: ', DecayRate], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTEELight;
const T = 'CL_ParseTEELight';
begin
  MSG.ReadInt16;
  MSG.ReadCoord3;
  MSG.ReadCoord;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadCoord;
end;

procedure TXBaseGameClient.CL_ParseTETextMessage;
const T = 'CL_ParseTETextMessage';
var
  Chan, Effect: UInt8;
  Position: TVec2F;
  TextColor, EffectColor: TRGBA;
  FadeInTime, FadeOutTime, HoldTime, FxTime: Int16;
  Data: LStr;
begin
// write_byte(TE_TEXTMESSAGE)
// write_byte(channel)
// write_short(x) -1 = center)
// write_short(y) -1 = center)
// write_byte(effect) 0 = fade in/fade out, 1 is flickery credits, 2 is write out (training room)
// write_byte(red) - text color
// write_byte(green)
// write_byte(blue)
// write_byte(alpha)
// write_byte(red) - effect color
// write_byte(green)
// write_byte(blue)
// write_byte(alpha)
// write_short(fadein time)
// write_short(fadeout time)
// write_short(hold time)
// [optional] write_short(fxtime) time the highlight lags behing the leading text in effect 2
// write_string(text message) 512 chars max string size

  Chan := MSG.ReadUInt8;
  Position.X := MSG.ReadInt16;
  Position.Y := MSG.ReadInt16;
  Effect := MSG.ReadUInt8;
  MSG.Read(TextColor, SizeOf(TextColor));
  MSG.Read(EffectColor, SizeOf(EffectColor));
  FadeInTime := MSG.ReadInt16;
  FadeOutTime := MSG.ReadInt16;
  HoldTime := MSG.ReadInt16;

  Clear(FxTime);

  if Effect = 2 then
    FxTime := MSG.ReadInt16;

  Data := MSG.ReadLStr;

  Debug(T, [
    'Channel: ', Chan, ', ',
    'Position: [', Position.ToString, '], ',
    'Effect: ', Effect, ', ',
    'TextColor: [', TextColor.ToString, '], ',
    'EffectColor: [', EffectColor.ToString, '], ',
    'FadeInTime: ', FadeInTime, ', ',
    'FadeOutTime: ', FadeOutTime, ', ',
    'HoldTime: ', HoldTime, ', ',
    'Data: "', Data, '"'], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTELine;
const T = 'CL_ParseTELine';
var
  StartPosition, EndPosition: TVec3F;
  LifeTime: Int16;
  Color: TRGB;
begin
// write_byte(TE_LINE)
// write_coord(startposition.x)
// write_coord(startposition.y)
// write_coord(startposition.z)
// write_coord(endposition.x)
// write_coord(endposition.y)
// write_coord(endposition.z)
// write_short(life in 0.1 s)
// write_byte(red)
// write_byte(green)
// write_byte(blue)

  StartPosition := MSG.ReadCoord3;
  EndPosition := MSG.ReadCoord3;
  LifeTime := MSG.ReadInt16;
  MSG.Read(Color, SizeOf(Color));

  Debug(T, [
    'StartPosition: [', StartPosition.ToString, '], ',
    'EndPosition: [', EndPosition.ToString, '], ',
    'Color: [', Color.ToString, '], ',
    'LifeTime: ', LifeTime], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTEBox;
const T = 'CL_ParseTEBox';
begin
  MSG.ReadCoord3;
  MSG.ReadCoord3;
  MSG.ReadInt16;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
end;

procedure TXBaseGameClient.CL_ParseTEKillBeam;
const T = 'CL_ParseTEKillBeam';
begin
  MSG.ReadInt16;
end;

procedure TXBaseGameClient.CL_ParseTELargeFunnel;
const T = 'CL_ParseTELargeFunnel';
begin
  MSG.ReadCoord3;
  MSG.ReadInt16;
  MSG.ReadInt16;
end;

procedure TXBaseGameClient.CL_ParseTEBloodStream;
const T = 'CL_ParseTEBloodStream';
begin
  MSG.ReadCoord3;
  MSG.ReadCoord3;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
end;

procedure TXBaseGameClient.CL_ParseTEShowLine;
const T = 'CL_ParseTEShowLine';
begin
  MSG.ReadCoord3;
  MSG.ReadCoord3;
end;

procedure TXBaseGameClient.CL_ParseTEBlood;
const T = 'CL_ParseTEBlood';
begin
  MSG.ReadCoord3;
  MSG.ReadCoord3;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
end;

procedure TXBaseGameClient.CL_ParseTEDecal;
const T = 'CL_ParseTEDecal';
begin
  MSG.ReadCoord3;
  MSG.ReadUInt8;
  MSG.ReadInt16;
end;

procedure TXBaseGameClient.CL_ParseTEFizz;
const T = 'CL_ParseTEFizz';
begin
  MSG.ReadInt16;
  MSG.ReadInt16;
  MSG.ReadUInt8;
end;

procedure TXBaseGameClient.CL_ParseTEModel;
const T = 'CL_ParseTEModel';
begin
  MSG.ReadCoord3;
  MSG.ReadCoord3;
  MSG.ReadAngle;
  MSG.ReadInt16;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
end;

procedure TXBaseGameClient.CL_ParseTEExplodeModel;
const T = 'CL_ParseTEExplodeModel';
begin
  MSG.ReadCoord3;
  MSG.ReadCoord;
  MSG.ReadInt16;
  MSG.ReadInt16;
  MSG.ReadUInt8;
end;

procedure TXBaseGameClient.CL_ParseTEBreakModel;
const T = 'CL_ParseTEBreakModel';
begin
  MSG.ReadCoord3;
  MSG.ReadCoord3;
  MSG.ReadCoord3;
  MSG.ReadUInt8;
  MSG.ReadInt16;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
end;

procedure TXBaseGameClient.CL_ParseTEGunShotDecal;
const T = 'CL_ParseTEGunShotDecal';
begin
  MSG.ReadCoord3;
  MSG.ReadInt16;
  MSG.ReadUInt8;
end;

procedure TXBaseGameClient.CL_ParseTESpriteSpray;
const T = 'CL_ParseTESpriteSpray';
begin
  MSG.ReadCoord3;
  MSG.ReadCoord3;
  MSG.ReadInt16;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
end;

procedure TXBaseGameClient.CL_ParseTEArmorRicochet;
const T = 'CL_ParseTEArmorRicochet';
begin
  MSG.ReadCoord3;
  MSG.ReadUInt8;
end;

procedure TXBaseGameClient.CL_ParseTEPlayerDecal;
const T = 'CL_ParseTEPlayerDecal';
var
  PlayerIndex, DecalNumber: UInt8;
  Position: TVec3F;
  EntityIndex: Int16;
  ModelIndex: Int16;
begin
  PlayerIndex := MSG.ReadUInt8;
  Position := MSG.ReadCoord3;
  EntityIndex := MSG.ReadInt16;
  DecalNumber := MSG.ReadUInt8;

  Clear(ModelIndex);

  Debug(T, [
    'Position: [', Position.ToString, '], ',
    'PlayerIndex: ', PlayerIndex, ', ',
    'EntityIndex: ', EntityIndex, ', ',
    'DecalNumber: ', DecalNumber, ', ',
    'ModelIndex: ', ModelIndex], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTEBubbles;
const T = 'CL_ParseTEBubbles';
begin
  MSG.ReadCoord3;
  MSG.ReadCoord3;
  MSG.ReadCoord;
  MSG.ReadInt16;
  MSG.ReadUInt8;
  MSG.ReadCoord;
end;

procedure TXBaseGameClient.CL_ParseTEBubbleTrail;
const T = 'CL_ParseTEBubbleTrail';
begin
  MSG.ReadCoord3;
  MSG.ReadCoord3;
  MSG.ReadCoord;
  MSG.ReadInt16;
  MSG.ReadUInt8;
  MSG.ReadCoord;
end;

procedure TXBaseGameClient.CL_ParseTEBloodSprite;
const T = 'CL_ParseTEBloodSprite';
var
  Position: TVec3F;
  Sprite1, Sprite2: Int16;
  Color, Scale: UInt8;
begin
  Position := MSG.ReadCoord3;
  Sprite1 := MSG.ReadInt16;
  Sprite2 := MSG.ReadInt16;
  Color := MSG.ReadUInt8;
  Scale := MSG.ReadUInt8;

  Debug(T, [
    'Position: [', Position.ToString, '], ',
    'Sprite1: ', Sprite1, ', ',
    'Sprite2: ', Sprite2, ', ',
    'Color: ', Color, ', ',
    'Scale: ', Scale], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTEWorldDecal;
const T = 'CL_ParseTEWorldDecal';
var
  Position: TVec3F;
  TextureIndex: UInt8;
begin
  Position := MSG.ReadCoord3;
  TextureIndex := MSG.ReadUInt8;

  Debug(T, [
    'Position: [', Position.ToString, '], ',
    'TextureIndex: ', TextureIndex], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTEWorldDecalHigh;
const T = 'CL_ParseTEWorldDecalHigh';
begin
  MSG.ReadCoord3;
  MSG.ReadUInt8;
end;

procedure TXBaseGameClient.CL_ParseTEDecalHigh;
const T = 'CL_ParseTEDecalHigh';
begin
  MSG.ReadCoord3;
  MSG.ReadUInt8;
  MSG.ReadInt16;
end;

procedure TXBaseGameClient.CL_ParseTEProjectile;
const T = 'CL_ParseTEProjectile';
begin
  MSG.ReadCoord3;
  MSG.ReadCoord3;
  MSG.ReadInt16;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
end;

procedure TXBaseGameClient.CL_ParseTESpray;
const T = 'CL_ParseTESpray';
var
  Position, Direction: TVec3F;
  Model: Int16;
  Count, Speed, Noise, RenderMode: UInt8;
begin
  Position := MSG.ReadCoord3;
  Direction := MSG.ReadCoord3;
  Model := MSG.ReadInt16;
  Count := MSG.ReadUInt8;
  Speed := MSG.ReadUInt8;
  Noise := MSG.ReadUInt8;
  RenderMode := MSG.ReadUInt8;

  Debug(T,
   ['Position: [', Position.ToString, '], ',
    'Direction: [', Direction.ToString, '], ',
    'Model: ', Model, ', ',
    'Count: ', Count, ', ',
    'Speed: ', Speed, ', ',
    'Noise: ', Noise, ', ',
    'RenderMode: ', RenderMode], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTEPlayerSprites;
const T = 'CL_ParseTEPlayerSprites';
var
  Player, Sprite: Int16;
  Count, Variance: UInt8;
begin
  Player := MSG.ReadInt16;
  Sprite := MSG.ReadInt16;
  Count := MSG.ReadUInt8;
  Variance := MSG.ReadUInt8;
end;

procedure TXBaseGameClient.CL_ParseTEParticleBurst;
const T = 'CL_ParseTEParticleBurst';
var
  Origin: TVec3F;
  Radius: Int16;
  Color, Duration: UInt8;
begin
  Origin := MSG.ReadCoord3;
  Radius := MSG.ReadInt16;
  Color := MSG.ReadUInt8;
  Duration := MSG.ReadUInt8;

  Debug(T,
   ['Origin: [', Origin.ToString, '], ',
    'Radius: ', Radius, ', ',
    'Color: ', Color, ', ',
    'Duration: ', Duration], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTEFireField;
const T = 'CL_ParseTEFireField';
var
  Origin: TVec3F;
  Radius, Model: Int16;
  Count, Flags, Duration: UInt8;
begin
  // fire is made in a square around origin. -radius, -radius to radius, radius

  Origin := MSG.ReadCoord3;
  Radius := MSG.ReadInt16;
  Model := MSG.ReadInt16;
  Count := MSG.ReadUInt8;
  Flags := MSG.ReadUInt8;
  Duration := MSG.ReadUInt8; // in seconds, will be randomized a bit

  Debug(T,
   ['Origin: [', Origin.ToString, '], ',
    'Radius: ', Radius, ', ',
    'Model: ', Model, ', ',
    'Count: ', Count, ', ',
    'Flags: ', Flags, ', ',
    'Duration: ', Duration], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTEPlayerAttachment;
const T = 'CL_ParseTEPlayerAttachment';
var
  Entity: UInt8;
  Offset: Float;
  Model, Life: Int16;
begin
  Entity := MSG.ReadUInt8; //player id
  Offset := MSG.ReadCoord;
  Model := MSG.ReadInt16;
  Life := MSG.ReadInt16;

  Debug(T, [
    'Entity: ', Entity, ', ',
    'Offset: ', Offset, ', ',
    'Model: ', Model, ', ',
    'Life: ', Life], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTEKillPlayerAttachments;
const T = 'CL_ParseTEKillPlayerAttachments';
var
  EntityIndexOfPlayer: UInt8;
begin
// write_byte(TE_KILLPLAYERATTACHMENTS)
// write_byte(entity index of player)

  EntityIndexOfPlayer := MSG.ReadUInt8;

  Debug(T, ['EntityIndexOfPlayer: ', EntityIndexOfPlayer], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTEMultiGunShot;
const T = 'CL_ParseTEMultiGunShot';
var
  Origin, Direction: TVec3F;
  Noise: TVec2F;
  Count, BulletHoleDecalIndex: UInt8;
begin
// This message is used to make a client approximate a 'spray' of gunfire.
// Any weapon that fires more than one bullet per frame and fires in a bit of a spread is
// a good candidate for MULTIGUNSHOT use. (shotguns)
//
// NOTE: This effect makes the client do traces for each bullet, these client traces ignore
//		 entities that have studio models.Traces are 4096 long.
//
// write_byte(TE_MULTIGUNSHOT)
// write_coord(origin.x)
// write_coord(origin.y)
// write_coord(origin.z)
// write_coord(direction.x)
// write_coord(direction.y)
// write_coord(direction.z)
// write_coord(x noise * 100)
// write_coord(y noise * 100)
// write_byte(count)
// write_byte(bullethole decal texture index)

  Origin := MSG.ReadCoord3;
  Direction := MSG.ReadCoord3;
  Noise := MSG.ReadCoord2;

  Count := MSG.ReadUInt8;
  BulletHoleDecalIndex := MSG.ReadUInt8;

  Debug(T, [
    'Origin: [', Origin.ToString, '], ',
    'Direction: [', Direction.ToString, '], ',
    'Noise: [', Noise.ToString, '], ',
    'Count: ', Count, ', ',
    'BulletHoleDecalIndex: ', BulletHoleDecalIndex], TEMP_ENTITY_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseTEUserTracer;
const T = 'CL_ParseTEUserTracer';
begin
// write_byte(TE_USERTRACER)
// write_coord(origin.x)
// write_coord(origin.y)
// write_coord(origin.z)
// write_coord(velocity.x)
// write_coord(velocity.y)
// write_coord(velocity.z)
// write_byte(life * 10)
// write_byte(color) this is an index into an array of color vectors in the engine. (0 - )
// write_byte(length * 10)

  MSG.ReadCoord3;
  MSG.ReadCoord3;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
  MSG.ReadUInt8;
end;

procedure TXBaseGameClient.CL_ParseDirectorStart;
begin
  // nothing
end;

procedure TXBaseGameClient.CL_ParseDirectorEvent;
const T = 'CL_ParseDirectorEvent';
var
  LastPrimaryObject, LastSecondaryObject: UInt16;
  Flags: Int32;
begin
  LastPrimaryObject := DMSG.ReadUInt16;
  LastSecondaryObject := DMSG.ReadUInt16;
  Flags := DMSG.ReadInt32;

  Debug(T, [
    'LastPrimaryObject: ', LastPrimaryObject, ', ',
    'LastSecondaryObject: ', LastSecondaryObject, ', ',
    'Flags: ', Flags], DIRECTOR_LOG_LEVEL);

  if Assigned(OnDirectorEvent) then
  begin
    Lock;
    OnDirectorEvent(Self, LastPrimaryObject, LastSecondaryObject, Flags);
    UnLock;
  end;
end;

procedure TXBaseGameClient.CL_ParseDirectorStatus;
const T = 'CL_ParseDirectorStatus';
var
  SpecSlots, SpecCount: Int32;
  RelayProxies: UInt16;
begin
  SpecSlots := DMSG.ReadInt32;
  SpecCount := DMSG.ReadInt32;
  RelayProxies := DMSG.ReadUInt16;

  Debug(T, [
    'SpecSlots: ', SpecSlots, ', ',
    'SpecCount: ', SpecCount, ', ',
    'RelayProxies: ', RelayProxies], DIRECTOR_LOG_LEVEL);
end;

procedure TXBaseGameClient.CL_ParseDirectorStuffText;
const T = 'CL_ParseDirectorStuffText';
var
  S: LStr;
begin
  S := Trim(DMSG.ReadLStr);
  Debug(T, [S], DIRECTOR_LOG_LEVEL);
  ReleaseEvent(OnDirectorCommand, S);
  CMD_ExecuteConsoleCommand(S);
end;

procedure TXBaseGameClient.CL_WriteMove;
const T = 'CL_WriteMove';
var
  I, O, C: Int32;
begin
  if CL_UserCMD_Count > CMD_MAXBACKUP then
  begin
    Error(T, ['UserCMD Count (', CL_UserCMD_Count, ') > CMD_MAXBACKUP (', CMD_MAXBACKUP, '), decreasing..']);
    CL_UserCMD_Count := CMD_MAXBACKUP;
  end;

  if not FFirstMove then
  begin
    C := 0;
    FFirstMove := True;
  end
  else
    C := CL_UserCMD_Count;

  O := BF.Size;

  BF.WriteUInt8(CLC_MOVE);
  BF.WriteUInt8(0); // size
  BF.WriteUInt8(0); // checksum
  BF.WriteUInt8(0); // flags; send net_drops or bad clc_delta count ? 8th bit is voiceloopback flag, munge starts from here
  BF.WriteUInt8(0); // backup (cl_cmdbackup), can be zero, it's ok
  BF.WriteUInt8(C); // cmds, can be 1, it's ok

  for I := 1 to C do
  begin
    BF.StartBitWriting;
    Delta.Write(BF, Move, UserCmdCleared);
    BF.EndBitWriting;
  end;

  PUInt8(Pointer(UInt32(BF.Memory) + O + 1))^ := BF.Size - O - 3;
  PUInt8(Pointer(UInt32(BF.Memory) + O + 2))^ := UInt8(BlockSequenceCRCByte(Pointer(UInt32(BF.Memory) + O + 3), BF.Size - O - 3, Channel.OutgoingSequence));
  Munge(Pointer(UInt32(BF.Memory) + O + 3), BF.Size - O - 3, Channel.OutgoingSequence, MungifyTable1);
end;

procedure TXBaseGameClient.CL_WriteCommand(Data: LStr);
const T = 'CL_WriteCommand';
begin
  if IsDemoPlayback then
    Exit;

  if State < CS_CONNECTION_ACCEPTED then
  begin
    Error(T, ['Connection not accepted yet. Command rejected.']);
    Exit;
  end;

  Channel.OutgoingSequenceReliable := True;

  BF.WriteUInt8(CLC_STRINGCMD);
  BF.WriteLStr(Data);

  Debug(T, [Data]);
end;

procedure TXBaseGameClient.CL_WriteCommand(Data: array of const);
begin
  CL_WriteCommand(StringFromVarRec(Data));
end;

procedure TXBaseGameClient.CL_WriteCommand;
begin
  if State < CS_CONNECTION_ACCEPTED then
  begin
    Print([Format(S_CMD_CANNOT_CONNECTED, [CMD.Tokens[0]])]);
    Exit;
  end;

  CL_WriteCommand(CMD.UnTokenized);
end;

procedure TXBaseGameClient.CL_WriteDelta;
begin
  BF.WriteUInt8(CLC_DELTA);

  if CL_SvenCoop then
  begin
    BF.StartBitWriting;
    BF.WriteUBits(UpdateMask, 16);
    BF.EndBitWriting;
  end
  else
    BF.WriteUInt8(UpdateMask);
end;

procedure TXBaseGameClient.CL_WriteResourceList;
const T = 'CL_WriteResourceList';
var
  I: Int32;
begin
  BF.WriteUInt8(CLC_RESOURCELIST);
  BF.WriteInt16(Length(MyResources));

  for I := 0 to Length(MyResources) - 1 do
    with MyResources[I] do
    begin
      BF.WriteLStr(Name);
      BF.WriteUInt8(RType);
      BF.WriteInt16(I);
      BF.WriteInt32(Size);
      BF.WriteUInt8(Flags);

      if Flags and RES_CUSTOM > 0 then
        BF.Write(MD5, SizeOf(MD5));

      Debug(T, [ToString], RESOURCELIST_LOG_LEVEL);
    end;

  Print([Length(MyResources), ' resources sent']);
end;

procedure TXBaseGameClient.CL_WriteFileConsistency;
const T = 'CL_WriteFileConsistency';
var
  I, J, C, O: Int32;
  P: PPackedConsistency;
  M: TMD5Digest;
begin
  O := BF.Size;

  BF.WriteUInt8(CLC_FILECONSISTENCY);
  BF.WriteInt16(0); // size
  BF.StartBitWriting;

  Clear(C);

  for I := Low(Resources) to High(Resources) do
    with Resources[I] do
    begin
      if Flags and RES_CHECKFILE = 0 then
        Continue;

      Inc(C);

      BF.WriteBit(True);
      BF.WriteUBits(I, 12);

      if Reserved = '' then
      begin
        J := Consistencies.IndexOf(NormalizePath(ServerInfo.GameDir + Slash2 + Name), True);

        if (EngineType <> E_VALVE) and (J = -1) then
          J := Consistencies.IndexOf(NormalizePath('valve' + Slash2 + Name), True);

        if (EngineType = E_CZERO) and (J = -1) then
          J := Consistencies.IndexOf(NormalizePath('cstrike' + Slash2 + Name), True);

        if J = -1 then
          if FileExists(ServerInfo.GameDir + Slash2 + Name) then
            M := MD5File(ServerInfo.GameDir + Slash2 + Name)
          else
            if (EngineType <> E_VALVE) and (FileExists('valve' + Slash2 + Name)) then
              M := MD5File('valve' + Slash2 + Name)
            else
              if (EngineType = E_CZERO) and (FileExists('cstrike' + Slash2 + Name)) then
                M := MD5File('cstrike' + Slash2 + Name)
              else
        else
        begin
          J := StrToIntDef(Consistencies[J].Value, 0);

          if J <> 0 then
            M.AsLongs[0] := J;
        end;

        BF.WriteUBits(M.AsLongs[0], 32);

        Debug(T, [
          'Name: "', Name, '", ',
          'MD5: ', M.AsLongs[0]], CONSISTENCY_LOG_LEVEL);
      end
      else
      begin
        P := @Reserved[1];

        BF.WriteUBits(WriteVec3F(P.MinS));
        BF.WriteUBits(WriteVec3F(P.MaxS));

        Debug(T, [
          'Name: "', Name, '", ',
          'ForceType: ', P.ForceType, ', ',
          'MinS: [', P.MinS.ToString, '], ',
          'MaxS: [', P.MaxS.ToString, ']'], CONSISTENCY_LOG_LEVEL);
      end;
    end;

  BF.WriteBit(False);
  BF.EndBitWriting;

//  PInt16(Pointer(UInt32(BF.Memory) + O + 1))^ := BF.Size - O - 2; // cause size is 2 bytes length
//  Munge(Pointer(UInt32(BF.Memory) + O + 3), BF.Size - O - 3, ServerInfo.SpawnCount);

  Print([C, ' consistencies sent']);
end;

procedure TXBaseGameClient.CL_WriteVoiceData(const Buffer; Size: Int16);
begin
  BF.WriteUInt8(CLC_VOICEDATA);
  BF.WriteInt16(Size);
  BF.Write(Buffer, Size);
end;

procedure TXBaseGameClient.CL_WriteCVarValue(Data: LStr);
const T = 'CL_WriteCVarValue';
begin
  BF.WriteUInt8(CLC_CVARVALUE);
  BF.WriteLStr(Data);

  Debug(T, ['Data: "', Data, '"']);
end;

procedure TXBaseGameClient.CL_WriteCVarValue2(Index: Int32; CVar, Data: LStr);
const T = 'CL_WriteCVarValue2';
begin
  BF.WriteUInt8(CLC_CVARVALUE2);
  BF.WriteInt32(Index);
  BF.WriteLStr(CVar);
  BF.WriteLStr(Data);

  Debug(T, ['Index: ', Index, ', CVar: "', CVar, '", Data: "', Data, '"']);
end;

procedure TXBaseGameClient.CL_InitializeConnection(Address: TNETAdr);
const T = 'CL_InitializeConnection';
begin
  State := CS_WAIT_CHALLENGE;
  ConnectionInitializingTime := GetTickCount;

  Inc(FConnectionAttempts);

  Server := Address;

  if Server.Port = 0 then
    Server.Port := 27015;

  MSG.Clear;

  MSG.WriteLStr('getchallenge steam', wmLineBreak);

  CL_SendOutOfBandPacket(Server);

  ReleaseEvent(OnConnectionInitialized);

  if FConnectionAttempts - 1 > 0 then
    if NET.HasAssociatedProxy then
      Print(Format('Retrying connection to %s (%d) via %s', [Server.ToString, FConnectionAttempts - 1, NET.AssociatedProxy.ToString]))
    else
      Print(Format('Retrying connection to %s (%d)', [Server.ToString, FConnectionAttempts - 1]))
  else
    if NET.HasAssociatedProxy then
      Print(Format('Initializing connection to %s via %s', [Server.ToString, NET.AssociatedProxy.ToString]))
    else
      Print(Format('Initializing connection to %s', [Server.ToString]))
end;

procedure TXBaseGameClient.CL_InitializeConnection;
begin
  CL_InitializeConnection(Server);
end;

procedure TXBaseGameClient.CL_InitializePacketing;
begin
  State := CS_CONNECTION_ACCEPTED;
  PacketingInitializingTime := GetTickCount;
  Inc(Channel.OutgoingSequence);
  Channel.IncomingTime := GetTickCount;
end;

procedure TXBaseGameClient.CL_InitializeGameEngine;
const T = 'CL_InitializeGameEngine';
begin
  Delta.Initialize;
  EngineType := GetEngineTypeFromName(ServerInfo.GameDir);
  CL_AllocateEntities(ServerInfo.MaxPlayers + 1);
  GameEngineInitializingTime := GetTickCount;
  ReleaseEvent(OnGameEngineInitialized);

  Print(['engine directory is ', ServerInfo.GameDir]);
end;

procedure TXBaseGameClient.CL_InitializeGame;
begin
  State := CS_GAME;

  GameInitializingTime := GetTickCount;

  if EngineType = E_CSTRIKE then
  begin
    CL_WriteCommand('specmode 3');
    CL_WriteCommand('specmode 3');
    CL_WriteCommand('unpause '#10);
    CL_WriteCommand('unpause '#10);
    CL_WriteCommand('unpause '#10);
    CL_WriteCommand('unpause '#10);
  end;

  ReleaseEvent(OnGameInitialized);

  Print([PlayersCount, ' of ', ServerInfo.MaxPlayers, ' players, at ', ServerInfo.ResolveMapName, ' initialized']);
end;

procedure TXBaseGameClient.CL_FinalizeConnection(Reason: LStr; IsReconnect: Boolean = False);
const T = 'CL_FinalizeConnection';
begin
  ConnectionFinalizingTime := GetTickCount;

  if State < CS_WAIT_CHALLENGE then
  begin
    Error(T, ['Can''t drop, not initialized']);
    Exit;
  end;

  if (State >= CS_CONNECTION_ACCEPTED) and not IsReconnect then
  begin
    CL_WriteCommand('dropclient');
    CL_TransmitPacket;
  end;

  FFirstMove := False;

  if not IsReconnect then
  begin
    Delta.Finalize;
    GameEvents.Clear;
  end;

  // NOTE: no delete server address, we need able to retry

  Clear(FIngameDownloadForced);
  Clear(FDownloadsTotal);

  // main
  if not IsReconnect then
  begin
    State := CS_DISCONNECTED;

    Clear(Channel);
    Clear(EngineType);
    Downloads.Clear;
  end
  else
    State := CS_CONNECTING;

  // svc
  if not IsReconnect then
  begin
    Clear(ProtocolVersion);
    Clear(Time);
    Clear(Players);
    Clear(ClientData);
    Clear(WeaponData);
    Clear(Entities);
    Clear(Baseline);
    Clear(InstancedBaseline);
    Clear(MoveVars);
    Clear(ExtraInfo);
    Clear(ServerInfo);
    Clear(LightStyles);
    Clear(Resources);
    Clear(ResourceLocation);
  end;

  Clear(SignonNum);

  if not IsReconnect then
  begin
    Clear(IsHLTV);
    Clear(Intermission);
    Clear(Paused);
  end;

  // clc
  Clear(UpdateMask);
  Clear(Move);
  //Clear(MyResources);

  // simple components
  Clear(FConnectionAttempts);
  Clear(ConnectionInitializingTime);
  Clear(PacketingInitializingTime);
  Clear(GameEngineInitializingTime);
  Clear(GameInitializingTime);

  FragmentsReader.Clear;
  FileFragmentsReader.Clear;
//  Clear(FragmentsReader);
 // Clear(FileFragmentsReader);
 // FragmentsWriter.ClearAllBuffers;
 // FileFragmentsWriter.ClearAllBuffers;

  if not IsReconnect then
    ReleaseEvent(OnConnectionFinalized, Reason);

  // dem
  IsDemoPlayback := False;
  DEM.Clear;

  Print(['Disconnected, reason "' + Reason + '"']);
end;

procedure TXBaseGameClient.CL_FinalizeConnection(Reason: array of const; IsReconnect: Boolean = False);
begin
  CL_FinalizeConnection(StringFromVarRec(Reason), IsReconnect);
end;

procedure TXBaseGameClient.CL_FinalizeConnection(IsReconnect: Boolean = False);
begin
  CL_FinalizeConnection('Client sent ''drop''', IsReconnect);
end;

procedure TXBaseGameClient.CL_AllocateEntities(ASize: UInt32);
var
  I: Int32;
begin
  SetLength(Entities, ASize);

  for I := Low(Entities) to High(Entities) do
    if CL_IsPlayerIndex(I) then
      Players[I - 1].Entity := @Entities[I];
end;

procedure TXBaseGameClient.CL_SignonReply;
const T = 'CL_SignonReply';
var
  I: Int32;
begin
  Debug(T, ['Index: ', SignonNum]);

  case SignonNum of
    1: ExecuteCommand('sendents');
    2: CL_InitializeGame;
  else
    Error(T, ['Unknown Index: ', SignonNum]);
  end;
end;

function TXBaseGameClient.CL_GetUserInfoString: LStr;
var
  I: Int32;
begin
  Clear(Result);

  for I := 0 to CVars.Count - 1 do
    with CVars, CVars[I] do
      if Flags and CVAR_USERINFO > 0 then
        if Length(ToString) > 0 then
          Info_Add(Result, Name, ToString);

  for I := 0 to UserInfo.Count - 1 do
    with UserInfo, UserInfo[I] do
      if Length(Value) > 0 then
        Info_Add(Result, Key, Value);
end;

procedure TXBaseGameClient.CL_PlaySound(ASound: TSound);
begin
  //
end;

procedure TXBaseGameClient.CL_CheckTimeouts;
begin
  if State < CS_CONNECTION_ACCEPTED then
    if GetTickCount - ConnectionInitializingTime > CL_RejectionTimeout * 1000 then
      if FConnectionAttempts <= CL_Connection_Attempts then
        CL_InitializeConnection
      else
        if NET.HasAssociatedProxy then
          CL_FinalizeConnection(Format('Cannot connect to %s via %s', [Server.ToString, NET.AssociatedProxy.ToString]))
        else
          CL_FinalizeConnection(Format('Cannot connect to %s', [Server.ToString]))
    else
  else
    if GetTickCount - Channel.IncomingTime > CL_Timeout * 1000 then
      CL_FinalizeConnection('Timeout');
end;

procedure TXBaseGameClient.CL_PreThink;
begin
  IsNewThinking := FLastThinkedSequence <> Channel.IncomingSequence;
  FLastThinkedSequence := Channel.IncomingSequence;

  if (State < CS_GAME) or IsNewThinking then // SEE, AFTER GAME START I CLEAR DIS ONLY ONCE PER PACKET, FIX
    Clear(Move);
end;

procedure TXBaseGameClient.CL_Think;
begin
  if CL_IsOnGround then
    FDuckJumpState := False;

  if FDuckJumpState then
    CL_Duck;

  if EX_Interp >= 0.11 then
  begin
    EX_Interp := 0.1;
    Print(['ex_interp forced down to 100 msec']);
  end;

  with Move do
  begin
    LerpMSec := Round(EX_Interp * 1000);
    MSec := GetRealDelta;

    if SignonNum >= 1 then
      Move.ViewAngles := Self.ViewAngles;
  end;
end;

procedure TXBaseGameClient.CL_PostThink;
begin
  if DeltaTicks(ViewAnglesEx_Time) < 2000 then
    ViewAngles := ViewAngles.InterpolateAngles(ViewAnglesEx, 1 / (100 / GetRealDelta));

  with Move do
  begin
    if SignonNum >= 1 then
      Move.ViewAngles := Self.ViewAngles;

    //
  end;
end;

function TXBaseGameClient.CL_NeedToDownloadResource(AResource: TResource; CustomName: LStr = ''): Boolean;
var
  S: LStr;
begin
  if CustomName <> '' then
    S := CustomName
  else
    S := AResource.Name;

  if FileExists(ServerInfo.GameDir + Slash2 + S) then // file is exist, stop checking
    Exit(False);

  // we can found our resource in valve folder

  if (EngineType <> E_VALVE) and FileExists('valve' + Slash2 + S) then
    Exit(False);

  // czero can use cstrike resources
  // TODO: add file md5 checking - if not equals then download

  if (EngineType = E_CZERO) and FileExists('cstrike' + Slash2 + S) then
    Exit(False);

  // downloading fatal resource if user wants it (cvar cl_downloadfatalresources must equals 1)

  if (AResource.Flags and RES_FATALIFMISSING > 0) and CL_DownloadImportantResources then
    Exit(True);

  if AResource.Flags and RES_CHECKFILE > 0 then // server will check this resource
  begin
    if AResource.Reserved <> '' then // we not need to download file with consistency, thanks valve
      Exit(False);

    if Consistencies.IndexOf(NormalizePath(ServerInfo.GameDir + Slash2 + S), True) >= 0 then // defined by consistency command
      Exit(False);

    // if we playing not half-life - consistency may be in valve section

    if (EngineType <> E_VALVE) and (Consistencies.IndexOf(NormalizePath('valve' + Slash2 + S), True) >= 0) then
      Exit(False);

    // if we playing in czero - consistency may be in cstrike section

    if (EngineType = E_CZERO) and (Consistencies.IndexOf(NormalizePath('cstrike' + Slash2 + S), True) >= 0) then
      Exit(False);

    // consistency isn't found anywhere

    Exit(True);
  end;

  Result := False;
end;

function TXBaseGameClient.CL_CanExternalDownloading: Boolean;
begin
  Result := (ResourceLocation <> '') and not FIngameDownloadForced;
end;

procedure TXBaseGameClient.CL_VerifyResources;
var
  PackToFragments: Boolean;
  S: LStr;
  I: Int32;
begin
  PackToFragments := False;

  for I := Low(Resources) to High(Resources) do
    with Resources[I] do
    begin
      case RType of
        RT_SOUND: S := 'sound/' + Name;
        RT_MODEL:
          if Name[1] <> '*' then
            S := Name
          else
            Continue;

        RT_GENERIC:
          if IsSafeFileToDownload(Name) then
            S := Name
          else
            Continue;
      else
        Continue;
      end;

      if CL_NeedToDownloadResource(Resources[I], S) then // resource not present, download it from server
      begin
        if not CL_AllowDownload then
          Continue;

        Downloads.Add(S);

        if CL_CanExternalDownloading then
          Continue;

        CL_WriteCommand('dlfile ' + S);
        PackToFragments := True;
      end;
    end;

  if PackToFragments then
  begin
    CL_CreateFragments;
    FDownloadsTotal := Downloads.Count;
  end;

  if Downloads.Count > 0 then
  begin
    Print([Downloads.Count, ' missing resources will be downloaded']);
    ReleaseEvent(OnStartDownloading, Downloads.Count);

    if CL_CanExternalDownloading then
      CL_StartHTTPDownload;
  end;
end;

procedure TXBaseGameClient.CL_StartHTTPDownload;
var
  SavedDownloads: TArray<LStr>;
  SavedResourceLocation,
  SavedGameDir,
  S: LStr;
  I: Int32;
begin
  SavedDownloads := Downloads.ToArray;
  SavedResourceLocation := ResourceLocation;
  SavedGameDir := ServerInfo.GameDir;

  CL_FinalizeConnection;

  State := CS_HTTP_DOWNLOADING;

  for I := Low(SavedDownloads) to High(SavedDownloads) do
  begin
    S := SavedGameDir + '/' + SavedDownloads[I];

    FixSlashes(S);

    if ExtractFileDir(S) <> '' then
      if not DirectoryExists(ExtractFileDir(S)) then
        ForceDirectories(GetCurrentDir + '\' + ExtractFileDir(S));

    if URLDownloadToFileA(nil, PLChar(SavedResourceLocation + SavedDownloads[I]), PLChar(S), 0, nil) = 0 then
    begin
      Print(['[', I, '/', High(SavedDownloads), '] Downloaded: "', S, '"']);
      ReleaseEvent(OnFileDownload, S);
    end
    else
      Print(['[', I, '/', High(SavedDownloads), '] Download failed on "', S, '"'])
  end;

  CL_InitializeConnection;
  FIngameDownloadForced := True;
end;

procedure TXBaseGameClient.CL_ConfirmResources;
const T = 'CL_ConfirmResources';
var
  MapCheckSum, I: Int32;
  S: LStr;
begin
  if CL_IsNeedResourceConfirmation then
    CL_WriteFileConsistency
  else
    Print(['confirmation of resources isn''t required']);

  State := CS_SPAWNED;

  MapCheckSum := ServerInfo.MapCheckSum;

  Munge(@MapCheckSum, 4, Byte(not ServerInfo.SpawnCount), MungifyTable2);

  CL_WriteCommand(['spawn ', ServerInfo.SpawnCount, ' ', MapCheckSum]);

  CL_CreateFragments(128, False);
end;

function TXBaseGameClient.CL_GenerateCDKey: LStr;
var
  I: Int32;
begin
  for I := 1 to 32 do
    if Chance(50) then
      WriteUInt8(Result, Ord('0') + Random(9))
    else
      WriteUInt8(Result, Ord('a') + Random(6))
end;

function TXBaseGameClient.CL_GetMessagesHistory: LStr;
begin
  Result := FLastMessages;
end;

procedure TXBaseGameClient.CL_AddMessageToHistory(Data: LStr);
begin
  WriteBuf(FLastMessages, Data + '. ');
end;

function TXBaseGameClient.CL_IsNeedResourceConfirmation: Boolean;
var
  I: Int32;
begin
  Result := False;

  if IsHLTV then
    Exit;

  if not CL_Consistency then
    Exit;

  for I := Low(Resources) to High(Resources) do
    if Resources[I].Flags and RES_CHECKFILE > 0 then
      Exit(True);
end;

function TXBaseGameClient.CL_IsPlayerIndex(Index: Int32): Boolean;
begin
  Result := Index in [1..ServerInfo.MaxPlayers];
end;

function TXBaseGameClient.CL_GetPlayerIndex(APlayer: TPlayer): Int;
var
  I: Int;
begin
  Result := -1;

  for I := Low(Players) to High(Players) do
    if Players[I].UserID = APlayer.UserID then
      Exit(I);
end;

function TXBaseGameClient.CL_GetPlayerIndex(APlayer: PPlayer): Int;
begin
  if APlayer = nil then
    Exit(-1);

  Result := (UInt32(APlayer) - UInt32(@Players[0])) div SizeOf(TPlayer);
end;

function TXBaseGameClient.CL_GetPlayer: PPlayer;
begin
  Result := nil;

  if Length(Players) > 0 then
    if ServerInfo.Index in [Low(Players)..High(Players)] then
      Result := @Players[ServerInfo.Index];
end;

function TXBaseGameClient.CL_GetEntity: PEntity;
begin
  Result := nil;

  if CL_GetPlayer <> nil then
    Result := CL_GetPlayer.Entity;
end;

function TXBaseGameClient.CL_GetGravity: Float;
begin
  Result := MoveVars.Gravity;
end;

function TXBaseGameClient.CL_ServerTickCount: UInt32;
begin
  Result := Trunc(Time * 1000);
end;

function TXBaseGameClient.CL_IsOnLadder(APlayer: TPlayer): Boolean;
begin
  Result := APlayer.Entity.MoveType = MOVETYPE_FLY;
end;

function TXBaseGameClient.CL_IsOnLadder: Boolean;
begin
  if CL_GetEntity <> nil then
    Result := CL_IsOnLadder(CL_GetPlayer^)
  else
    Result := False;
end;

procedure TXBaseGameClient.CL_MoveTo(APosition: TVec3F; ASpeed: Float);
var
  F: Float;
begin
  with Move do
  begin
    F := ViewAngles.Y - CL_GetOrigin.ViewTo(APosition).Y ;

    ForwardMove := Cos((F) * M_PI / 180) * ASpeed;
    SideMove := Sin((F) * M_PI / 180) * ASpeed;
  end;
end;

procedure TXBaseGameClient.CL_MoveTo(APosition: TVec3F);
begin
  CL_MoveTo(APosition, CL_GetMaxSpeed);
end;

procedure TXBaseGameClient.CL_MoveTo(APlayer: TPlayer; ASpeed: Float);
begin
  CL_MoveTo(APlayer.GetOrigin, ASpeed);
end;

procedure TXBaseGameClient.CL_MoveTo(APlayer: TPlayer);
begin
  CL_MoveTo(APlayer, CL_GetMaxSpeed);
end;

procedure TXBaseGameClient.CL_MoveTo(AEntity: TEntity; ASpeed: Float);
begin
  CL_MoveTo(AEntity.Origin, ASpeed);
end;

procedure TXBaseGameClient.CL_MoveTo(AEntity: TEntity);
begin
  CL_MoveTo(AEntity, CL_GetMaxSpeed);
end;

procedure TXBaseGameClient.CL_MoveOut(APosition: TVec3F; ASpeed: Float);
begin
  CL_MoveTo(APosition, ASpeed);

  with Move do
  begin
    ForwardMove := -ForwardMove;
    SideMove := -SideMove;
  end;
end;

procedure TXBaseGameClient.CL_MoveOut(APosition: TVec3F);
begin
  CL_MoveOut(APosition, CL_GetMaxSpeed);
end;

procedure TXBaseGameClient.CL_MoveOut(APlayer: TPlayer; ASpeed: Float);
begin
  CL_MoveOut(APlayer.GetOrigin, ASpeed);
end;

procedure TXBaseGameClient.CL_MoveOut(APlayer: TPlayer);
begin
  CL_MoveOut(APlayer, CL_GetMaxSpeed);
end;

procedure TXBaseGameClient.CL_MoveOut(AEntity: TEntity; ASpeed: Float);
begin
  CL_MoveOut(AEntity.Origin, ASpeed);
end;

procedure TXBaseGameClient.CL_MoveOut(AEntity: TEntity);
begin
  CL_MoveOut(AEntity, CL_GetMaxSpeed);
end;

procedure TXBaseGameClient.CL_LookAt(APosition: TVec3F);
begin
  ViewAngles := CL_GetOrigin.ViewTo(APosition);
end;

procedure TXBaseGameClient.CL_LookAt(APlayer: TPlayer);
begin
  CL_LookAt(APlayer.GetOrigin);
end;

procedure TXBaseGameClient.CL_LookAt(AEntity: TEntity);
begin
  CL_LookAt(AEntity.Origin);
end;

procedure TXBaseGameClient.CL_LookAtEx(APosition: TVec3F);
begin
  ViewAnglesEx := CL_GetOrigin.ViewTo(APosition);
  ViewAnglesEx_Time := GetTickCount;
end;

procedure TXBaseGameClient.CL_LookAtEx(APlayer: TPlayer);
begin
  CL_LookAtEx(APlayer.GetOrigin);
end;

procedure TXBaseGameClient.CL_LookAtEx(AEntity: TEntity);
begin
  CL_LookAtEx(AEntity.Origin);
end;

procedure TXBaseGameClient.CL_PressButton(AButton: UInt16);
begin
  Move.Buttons := Move.Buttons or AButton
end;

procedure TXBaseGameClient.CL_UnPressButton(AButton: UInt16);
begin
  Move.Buttons := Move.Buttons and not AButton
end;

function TXBaseGameClient.CL_IsButtonPressed(AButton: UInt16): Boolean;
begin
  Result := Move.Buttons and AButton > 0;
end;

function TXBaseGameClient.CL_GetOrigin: TVec3F;
begin
  Result := ClientData.Origin;
end;

function TXBaseGameClient.CL_GetVelocity: TVec3F;
begin
  Result := ClientData.Velocity;
end;

function TXBaseGameClient.CL_GetPunchAngle: TVec3F;
begin
  Result := ClientData.PunchAngle;
end;

function TXBaseGameClient.CL_GetWeaponIndex: Int32;
begin
  Result := ClientData.ID;
end;

function TXBaseGameClient.CL_GetFieldOfView;
begin
  Result := ClientData.FOV;
end;

function TXBaseGameClient.CL_GetDistance(APosition: TVec3F): Float;
begin
  Result := CL_GetOrigin.Distance(APosition);
end;

function TXBaseGameClient.CL_GetDistance(APlayer: TPlayer): Float;
begin
  Result := CL_GetDistance(APlayer.GetOrigin);
end;

function TXBaseGameClient.CL_GetDistance(AEntity: TEntity): Float;
begin
  Result := CL_GetDistance(AEntity.Origin);
end;

function TXBaseGameClient.CL_GetDistance2D(APosition: TVec3F): Float;
begin
  Result := CL_GetOrigin.Distance2D(APosition);
end;

function TXBaseGameClient.CL_GetDistance2D(APlayer: TPlayer): Float;
begin
  Result := CL_GetDistance2D(APlayer.GetOrigin);
end;

function TXBaseGameClient.CL_GetDistance2D(AEntity: TEntity): Float;
begin
  Result := CL_GetDistance2D(AEntity.Origin);
end;

function TXBaseGameClient.CL_IsWeaponExists(AIndex: UInt32): Boolean;
begin
  Result := ClientData.Weapons and (1 shl AIndex) <> 0;
end;

function TXBaseGameClient.CL_IsWeaponExists(AWeapon: TWeapon): Boolean;
begin
  Result := CL_IsWeaponExists(AWeapon.Index);
end;

function TXBaseGameClient.CL_IsClientFlagSet(AFlag: Int32): Boolean;
begin
  Result := ClientData.Flags and AFlag > 0; // FL_*
end;

function TXBaseGameClient.CL_IsOnGround: Boolean;
begin
  Result := CL_IsClientFlagSet(FL_ONGROUND);
end;

function TXBaseGameClient.CL_IsSpectator;
begin
  Result := CL_IsClientFlagSet(FL_SPECTATOR)
end;

function TXBaseGameClient.CL_IsCrouching: Boolean;
begin
  Result := CL_IsClientFlagSet(FL_DUCKING);
end;

function TXBaseGameClient.CL_GetWeaponData(AIndex: UInt32): PWeaponData;
begin
  Result := nil;

  if not (AIndex - 1 in [Low(WeaponData)..High(WeaponData)]) then
    Exit;

  Result := @WeaponData[AIndex - 1];
end;

function TXBaseGameClient.CL_GetWeaponData: PWeaponData;
begin
  Result := CL_GetWeaponData(CL_GetWeaponIndex);
end;

function TXBaseGameClient.CL_HasWeaponData;
begin
  Result := CL_GetWeaponData <> nil;
end;

function TXBaseGameClient.CL_IsReloading: Boolean;  // delete it later
begin
  if CL_HasWeaponData then
    Result := CL_GetWeaponData.InReload > 0
  else
    Result := False;
end;

function TXBaseGameClient.CL_GetMaxSpeed: Float;
begin
  if ClientData.MaxSpeed = 0 then     // this can be a mistake
    Result := MoveVars.MaxSpeed
  else
    Result := ClientData.MaxSpeed;
end;

function TXBaseGameClient.CL_GetHealth: Float;
begin
  Result := ClientData.Health;
end;

function TXBaseGameClient.CL_CanAttack: Boolean;
begin
  Result := ClientData.NextAttack <= 0;
end;

function TXBaseGameClient.CL_InFieldOfView(APosition: TVec3F): Boolean;
const T = 'CL_InFieldOfView';
var
  F: Float;
  V: TVec3F;
begin
  Result := True;

  F := CL_GetFieldOfView;

  if F <> 0 then
    F := F / 2
  else
    F := 45;

  try
    V := (GetViewAngles.NormalizeAngles - GetOrigin.ViewTo(APosition).NormalizeAngles).NormalizeAngles;
    Result := (V.Y > -F) and (V.Y < F);
  except
    Error(T, ['Angles: [', GetViewAngles.ToString, '], Origin: [', GetOrigin.ToString, '], FOV: ', F * 2]);
  end;
end;

function TXBaseGameClient.CL_InFieldOfView(APlayer: TPlayer): Boolean;
begin
  Result := CL_InFieldOfView(APlayer.GetOrigin);
end;

function TXBaseGameClient.CL_InFieldOfView(AEntity: TEntity): Boolean;
begin
  Result := CL_InFieldOfView(AEntity.Origin);
end;

function TXBaseGameClient.CL_IsAlive: Boolean;
begin
  if CL_GetPlayer <> nil then
    Result := (CL_GetHealth > 0)
        and not CL_IsSpectator
        and (CL_GetOrigin <> 0)
        and CL_GetPlayer.IsCSAlive // cs
        and (ClientData.DeadFlag = DEAD_NO) // tfc
  else
    Result := False;
end;

procedure TXBaseGameClient.CL_UseEnvironment;
begin
  CL_PressButton(IN_USE);
end;

procedure TXBaseGameClient.CL_PrimaryAttack;
begin
  CL_PressButton(IN_ATTACK);
end;

procedure TXBaseGameClient.CL_SecondaryAttack;
begin
  CL_PressButton(IN_ATTACK2);
end;

procedure TXBaseGameClient.CL_FastPrimaryAttack;
begin
  if FFastPrimaryAttackState then
    CL_PrimaryAttack;

  FFastPrimaryAttackState := not FFastPrimaryAttackState;
end;

procedure TXBaseGameClient.CL_FastSecondaryAttack;
begin
  if FFastSecondaryAttackState then
    CL_SecondaryAttack;

  FFastSecondaryAttackState := not FFastSecondaryAttackState;
end;

procedure TXBaseGameClient.CL_Jump;
begin
  CL_PressButton(IN_JUMP);
end;

procedure TXBaseGameClient.CL_Duck;
begin
  CL_PressButton(IN_DUCK);
end;

procedure TXBaseGameClient.CL_DuckJump;
begin
  CL_Jump;

  FDuckJumpState := True;
end;

function TXBaseGameClient.CL_GetGroundedOrigin: TVec3F;
begin
  Result := CL_GetOrigin;

  if CL_IsCrouching then
    Result.Z := Result.Z - HUMAN_HEIGHT_DUCK
  else
    Result.Z := Result.Z - HUMAN_HEIGHT_STAND;
end;

function TXBaseGameClient.CL_GetGroundedDistance(APosition: TVec3F): Float;
begin
  Result := CL_GetGroundedOrigin.Distance(APosition);
end;

function TXBaseGameClient.CL_GetGroundedDistance(APlayer: TPlayer): Float;
begin
  Result := CL_GetGroundedDistance(APlayer.GetOrigin);
end;

function TXBaseGameClient.CL_GetGroundedDistance(AEntity: TEntity): Float;
begin
  Result := CL_GetGroundedDistance(AEntity.Origin);
end;

procedure TXBaseGameClient.CMD_RegisterCommands;
begin
  inherited;

  with Commands do
  begin
    Add('cmd', CL_ForwardToServer, 'forward command to server', CMD_ONLY_IN_GAME);

    Add('new', CL_WriteCommand, 'initialize connection');
    Add('sendres', CL_WriteCommand, 'request resources');
    Add('spawn', CL_WriteCommand, 'spawn command');
    Add('sendents', CL_WriteCommand, 'request entities');
    Add('dlfile', CL_WriteCommand, 'download file from server');

    Add('upload', CL_Upload_F, 'upload file to server', CMD_ONLY_IN_GAME);
    Add('connect', CL_Connect_F, 'connect to specified server');
    Add('reconnect', CL_Reconnect_F, 'start connection again', CMD_ONLY_IN_GAME);
    Add('retry', CL_Retry_F, 'retry connection to last server');
    Add('disconnect', CL_Disconnect_F, 'disconnect from server');
    Add('setinfo', CL_SetInfo_F, 'set/show userinfo values');
    Add('impulse', CL_Impulse_F, 'impulse command', CMD_ONLY_IN_GAME);

    Add('fullserverinfo', CL_FullServerInfo_F, 'full server info', CMD_HIDE); // <- some kind of shit

    Add('dropclient', CL_WriteCommand, 'drop client command'); // <- need
    Add('say', CL_WriteCommand, 'send chat message');
    Add('timeleft', CL_WriteCommand, 'prints the time remaining in the match');
    Add('fullupdate', CL_WriteCommand, 'full info update');
    Add('menuselect', CL_WriteCommand, 'select menu item');
    Add('ping', CL_WriteCommand, 'request pings from server');
    Add('status', CL_WriteCommand, 'request status from server');
    Add('kill', CL_WriteCommand, 'suicide command');
    Add('drop', CL_WriteCommand, 'drop current item');

    // custom
    Add('debug_resources', CL_DebugResources_F, 'Show resources debug info', CMD_ONLY_IN_GAME or CMD_PROTECTED);
    Add('debug_entities', CL_DebugEntities_F, 'Show entities debug info', CMD_ONLY_IN_GAME or CMD_PROTECTED);
    Add('debug_baseline', CL_DebugBaseline_F, 'Show baseline debug info', CMD_ONLY_IN_GAME or CMD_PROTECTED);
    Add('debug_game_events', CL_DebugGameEvents_F, 'Show game events debug info', CMD_ONLY_IN_GAME or CMD_PROTECTED);

    Add('voice_playfromfile', CL_VoicePlayFromFile_F, 'play file via voice game cannel', CMD_ONLY_IN_GAME or CMD_PROTECTED);

    Add('playdemo', CL_PlayDemo_F, 'play demo file', CMD_PROTECTED);

    Add('consistency', CL_Consistency_F, 'consistency command', CMD_PROTECTED);
    Add('fake_cvar', CL_FakeCVar_F, 'fake cvar command', CMD_PROTECTED);
  end;
end;

procedure TXBaseGameClient.CMD_RegisterCVars;
begin
  inherited;

  with CVars do
  begin
    // userinfo, must be as strings only
    Add('cl_dlmax', @CL_DLMax, '512', 'Client Maximal Fragment Size', CVAR_USERINFO);
    Add('cl_lc', @CL_LC, '1', 'Client Lag Compensation', CVAR_USERINFO);
    Add('cl_lw', @CL_LW, '1', 'Client Weapon Prediction', CVAR_USERINFO);
    Add('cl_updaterate', @CL_UpdateRate, '101', 'Client Update Rate', CVAR_USERINFO);
    Add('model', @CL_Model, 'gordon', 'Client Model', CVAR_USERINFO);
    Add('rate', @CL_Rate, '25000', 'Client Rate', CVAR_USERINFO);
    Add('topcolor', @CL_TopColor, '0', 'Client Top Color', CVAR_USERINFO);
    Add('bottomcolor', @CL_BottomColor, '0', 'Client Bottom Color', CVAR_USERINFO);
    Add('name', @CL_Name, 'Player', 'Client Name', CVAR_USERINFO);
    Add('password', @CL_Password, '', 'Client Password', CVAR_USERINFO);

    //
    Add('cl_cdkey', @CL_CDKey, CL_GenerateCDKey, 'Client CDKey', CVAR_PRIVATE or CVAR_HIDE);

    Add('cl_timeout', @CL_Timeout, 35, 'Client Timeout');
    Add('cl_rejection_timeout', @CL_RejectionTimeout, 2, 'Client Rejection Timeout', CVAR_HIDE or CVAR_PRIVATE);
    Add('cl_connection_attempts', @CL_Connection_Attempts, 3, 'Client Connection Attempts', CVAR_PRIVATE);

    Add('cl_allowredirects', @CL_AllowRedirects, True, 'Client Allow Redirects', CVAR_PRIVATE);
    Add('cl_usercmd_count', @CL_UserCMD_Count, 1, 'UserCMD Multiplier', CVAR_PRIVATE);

    Add('cl_consistency', @CL_Consistency, True, 'Client Allow Consistency', CVAR_PRIVATE);

    Add('cl_allowupload', @CL_AllowUpload, True, 'Client Allow Upload', CVAR_HIDE);
    Add('cl_allowdownload', @CL_AllowDownload, True, 'Client Allow Download', CVAR_PROTECTED);

    Add('cl_download_important_resources', @CL_DownloadImportantResources, False, 'Client Will Download Fatal Resources', CVAR_PRIVATE);

    Add('dem_playback_speed', @DEM_Playback_Speed, 1, 'Demo Playback Speed', CVAR_PRIVATE);

    Add('ex_interp', @EX_Interp, 0.1, 'Interpolation');

    Add('cl_svencoop', @CL_SvenCoop, False, 'Implementation of engine for Sven-Coop 5', CVAR_PRIVATE);
  end;
end;

function TXBaseGameClient.CMD_ExecuteTokenizedText: Boolean;
var
  I: Int32;
begin
  Result := True;

  if CMD.Count = 0 then
  begin
    Print([S_CMD_EMPTY_COMMAND]);
    Exit;
  end;

  if CMD_ExecuteCVar then
    Exit;

  if CMD_ExecuteCommand then
    Exit;

  if CMD_ExecuteAlias then
    Exit;

  if CMD_ExecuteFakeCVar then
    Exit;

  Print([Format('Unknown command "%s"', [AnsiLowerCase(CMD.Tokens[0])])]);

  if State >= CS_CONNECTION_ACCEPTED then
  begin
    CL_WriteCommand;
    Exit;
  end;

  Result := False;
end;

function TXBaseGameClient.CMD_ExecuteCommand: Boolean;
var
  I: Int32;
begin
  Result := True;

  I := Commands.IndexOf(AnsiLowerCase(CMD.Tokens[0]));

  if I = -1 then
    Exit(False);

  if (Commands[I].Flags and CMD_PROTECTED > 0) and CurrentCommand.IsOutside then
    Exit(False);

  if (Commands[I].Flags and CMD_ONLY_IN_GAME > 0) and (State < CS_CONNECTION_ACCEPTED) then
  begin
    Print([Format(S_CMD_CANNOT_CONNECTED, [CMD.Tokens[0]])]);
    Exit;
  end;

  Commands[I].Callback;
end;

function TXBaseGameClient.CMD_ExecuteCVar: Boolean;
var
  I: Int32;
begin
  Result := True;

  I := CVars.IndexOf(AnsiLowerCase(CMD.Tokens[0]));

  if I = -1 then
    Exit(False);

  with CVars.List[I] do
  begin
    if Flags and CVAR_HIDE > 0 then
      Exit(False); // false

    if (Flags and CVAR_PROTECTED > 0) and CurrentCommand.IsOutside then
      Exit(False); // false

    if CMD.Count < 2 then
    begin
      Print([Format(S_CMD_SENDVALUE, [Name, ToString + ' (' + Data + ')'])]);
      Exit;
    end;

    if (CVars[I].Flags and CVAR_USERINFO > 0) and (State >= CS_CONNECTION_ACCEPTED) then
      CL_WriteCommand('setinfo "' + CMD.Tokens[0] + '" "' + CMD.Tokens[1] + '"');

    Data := CMD.Tokens[1];

    case VType of
      V_BOOL:
      begin
        if (CMD.Tokens[1] <> '0') and (CMD.Tokens[1] <> '1') then
        begin
          Print([Format(S_CMD_MUST_BE_BOOLEAN, [CMD.Tokens[1]])]);
          Exit;
        end;

        Write(Boolean(StrToInt(CMD.Tokens[1])));
      end;

      V_INT:
      begin
        if not IsNumbers(CMD.Tokens[1]) then
        begin
          Print([Format(S_CMD_MUST_BE_INTEGER, [CMD.Tokens[1]])]);
          Exit;
        end;

        Write(StrToIntDef(CMD.Tokens[1], 0));
      end;

      V_FLOAT: Write(StrToFloatDefDot(CMD.Tokens[1], 0));
      V_STR: Write(CMD.Tokens[1]);
    end;

    Print([Format(S_CMD_ACCEPTED, [Name, CMD.Tokens[1]])]);
  end;
end;

function TXBaseGameClient.CMD_ExecuteFakeCVar: Boolean;
var
  I: Int32;
begin
  Result := True;

  I := FakeCVars.IndexOf(AnsiLowerCase(CMD.Tokens[0]));

  if I = -1 then
    Exit(False);

  with FakeCVars.List[I] do
  begin
    if CMD.Count < 2 then
    begin
      Print([Format(S_CMD_SENDVALUE, [Key + ' (fake)', Value])]);
      Exit;
    end;

    Value := CMD.Tokens[1];
    Print([Format(S_CMD_ACCEPTED, [Key + ' (fake)', Value])]);
  end;
end;

procedure TXBaseGameClient.CL_Rcon_F;
var
  S: LStr;
  I: UInt32;
begin              //rcon_address 127.0.0.1:27015; rcon_password 123456; rcon hostname
  if Length(Rcon_Password) = 0 then
  begin
    Print(['You must set ''rcon_password'' before issuing an rcon command.']);
    Exit;
  end;

  if CMD.Count < 2 then
  begin
    Print(['Empty rcon string']);
    Exit;
  end;

  if State >= CS_GAME then
    CL_GetServiceChallenge(Server, 'rcon')
  else
  begin
    if Length(Rcon_Address) = 0 then
    begin
      Print(['You must either set the ''rcon_address'' cvar to issue rcon commands or connect to the game server']);
      Exit;
    end;

    CL_GetServiceChallenge(TNETAdr.Create(Rcon_Address), 'rcon');
  end;

  Clear(Rcon_LastCommand);

  for I := 1 to CMD.Count - 1 do
    Rcon_LastCommand := Rcon_LastCommand + ' "' + CMD.Tokens[I] + '"';
end;

procedure TXBaseGameClient.CL_ForwardToServer;
begin
  if CMD.Count < 2 then
  begin
    PrintCMDUsage(['command']);
    Exit;
  end;

  CL_WriteCommand(CMD.Tokens[1]);
end;

procedure TXBaseGameClient.CL_Upload_F;
const Title = 'CL_Upload_F';
var
  FileName: LStr;
  FileData: LStr;
begin
  if CMD.Count < 2 then
  begin
    PrintCMDUsage(['your filename', '(server filename)']);
    Exit;
  end;

  if not FileExists(CMD.Tokens[1]) then
  begin
    Error(Title, ['File not found: "', CMD.Tokens[1], '"']);
    Exit;
  end;

  Clear(FileData);

  with TMemoryStream.Create do
  begin
    LoadFromFile(CMD.Tokens[1]);
    SetLength(FileData, Size);
    Read(FileData[1], Size);
    Free;
  end;

  if CMD.Count >= 3 then
    FileName := CMD.Tokens[2]
  else
    FileName := CMD.Tokens[1];

  CL_CreateFileFragments(FileName, FileData);
end;

procedure TXBaseGameClient.CL_Connect_F;
var
  S: LStr;
begin
  if CMD.Count < 2 then
  begin
    PrintCMDUsage(['server']);
    Exit;
  end;

  if State > CS_DISCONNECTED then
    CL_FinalizeConnection;

  CL_InitializeConnection(TNETAdr.Create(CMD.Tokens[1]));
end;

procedure TXBaseGameClient.CL_Reconnect_F;
begin
  CL_FinalizeConnection(True);
  CL_AcceptedConnection(True);
end;

procedure TXBaseGameClient.CL_Retry_F;
begin
  if Server = NET_LOCAL_ADDR then
  begin
    Print(['Can''t retry, no previous connection']);
    Exit;
  end;

  if State > CS_DISCONNECTED then
    CL_FinalizeConnection;

  Print(['Commencing connection retry to ', Server.ToString]);

  //CL_InitializeConnection;
  FNeedInitializationOfConnection := True;
end;

procedure TXBaseGameClient.CL_Disconnect_F;
begin
  if State < CS_WAIT_CHALLENGE then
  begin
    Print([Format(S_CMD_CANNOT_CONNECTED, [CMD.Tokens[0]])]);
    Exit;
  end;

  CL_FinalizeConnection;
end;

procedure TXBaseGameClient.CL_SetInfo_F;
var
  C, I: Int32;
  S: LStr;
label
  L1;
begin
  if CMD.Count > 1 then
    if CMD.Count > 2 then
    begin
      C := CVars.IndexOf(CMD.Tokens[1]);

      if C <> -1 then
        if (CVars[C].Flags and CVAR_USERINFO) > 0 then
          ExecuteCommand(CMD.Tokens[1] + SS + '"' + CMD.Tokens[2] + '"')
        else
          goto L1
      else
      begin
        L1: UserInfo.Add(CMD.Tokens[1], CMD.Tokens[2]);

        if CurrentCommand.IsOutside then 
          CL_WriteCommand;
      end
    end
    else
      PrintCMDUsage(['key', 'value'])
  else
  begin
    for I := 0 to CVars.Count - 1 do
      with CVars, CVars[I] do
        if Flags and CVAR_USERINFO <> 0 then
          Print([Name + ' = ' + ToString + ' (CVar)']);

    for I := 0 to UserInfo.Count - 1 do
      with UserInfo, UserInfo[I] do
        Print([Key + ' = ' + Value]);
  end;
end;

procedure TXBaseGameClient.CL_Impulse_F;
begin
  if CMD.Count < 2 then
  begin
    PrintCMDUsage(['index']);
    Exit;
  end;

  if not IsNumbers(CMD.Tokens[1]) then
  begin
    Print([Format(S_CMD_MUST_BE_INTEGER, [CMD.Tokens[1]])]);
    Exit;
  end;

  Move.Impulse := StrToIntDef(CMD.Tokens[1], 0);
end;

procedure TXBaseGameClient.CL_FullServerInfo_F;
var
  Data: LStr;
begin
  if CMD.Count < 2 then
  begin
    PrintCMDUsage(['infostring']);
    Exit;
  end;

  Data := CMD.Tokens[1];
end;

procedure TXBaseGameClient.CL_DebugResources_F;
var
  I: Int32;
begin
  for I := Low(Resources) to High(Resources) do
    Print([I, ') ', Resources[I].ToString]);
end;

procedure TXBaseGameClient.CL_DebugEntities_F;
var
  I: Int32;
begin
  for I := Low(Entities) to High(Entities) do
    with Entities[I] do
    begin
      if not IsActive then
        Continue;

      Print([
        I, ') ',
        'T: ', EntityType, ', ',
//          'Number: ', Number, ', ',
//          'MessageNum: ', MessageNum, ', ',
//          'Skin: ', Skin, ', ',
        'Solid: ', Solid, ', ',
        'MoveType: ', MoveType, ', ',
        'Effects: ', Effects, ', ',
//          'EFlags: ', EFlags, ', ',
//          'Body: ', Body, ', ',
        'Origin: [',Origin.ToString, '], ',
        'Model: ', GetResource(@Resources, RT_MODEL, ModelIndex).Name]);
    end;
end;

procedure TXBaseGameClient.CL_DebugBaseline_F;
var
  I: Int32;
begin
  for I := Low(Baseline) to High(Baseline) do
    with Baseline[I] do
      Print([
        I, ') ',
        'T: ', EntityType, ', ',
//        'Number: ', Number, ', ',
//        'MessageNum: ', MessageNum, ', ',
//        'Skin: ', Skin, ', ',
        'Solid: ', Solid, ', ',
        'MoveType: ', MoveType, ', ',
        'Effects: ', Effects, ', ',
 //       'EFlags: ', EFlags, ', ',
//        'Body: ', Body, ', ',
        'Origin: [',Origin.ToString, '], '
        //'Model: ', GetResourceByIndex(Resources, ModelIndex, RT_MODEL).Name
        ]);
end;

procedure TXBaseGameClient.CL_DebugGameEvents_F;
var
  I: Int;
begin
  for I := 0 to GameEvents.Count - 1 do
    with GameEvents[I] do
      Print(['Name: "', Name, '", Index: ', Index, ', Size: ', Size, ', HasCallback: ', Assigned(Callback)]);
end;

procedure TXBaseGameClient.CL_VoicePlayFromFile_F;
begin
  //
end;

procedure TXBaseGameClient.CL_PlayDemo_F;
const T = 'CL_PlayDemo_F';
var
  I: Int32;

  DemoProtocol,
  NetworkProtocol,
  MapCheckSum,
  DirectoryEntriesOffset,
  DirectoryEntriesNum,
  DirEntryNum: UInt32;

  Map,
  GameDir,
  DirEntryTitle: LStr;

  DirEntryTime: Float;
begin
  if State > CS_DISCONNECTED then
    CL_FinalizeConnection;

  if CMD.Count < 2 then
  begin
    PrintCMDUsage(['filename']);
    Exit;
  end;

  if not FileExists(CMD.Tokens[1]) then
  begin
    Print(['File not found "', CMD.Tokens[1], '"']);
    Exit;
  end;

  DEM.LoadFromFile(CMD.Tokens[1]);
  DEM.Start;

  if DEM.ReadLStr <> DEM_MAGIC then
  begin
    Print(['Bad demo magic']);
    Exit;
  end;

  if DEM.Size < DEM_HEADER_SIZE then
  begin
    Print(['Bad demo size']);
    Exit;
  end;

  DEM.Skip(1); // ?

  DemoProtocol := DEM.ReadUInt32;

  if DemoProtocol <> 5 then
  begin
    Print(['Unknown demo protocol ', DemoProtocol, ', should be 5.']);
    Exit;
  end;

  NetworkProtocol := DEM.ReadUInt32;

  if not (NetworkProtocol in [47..48]) then
  begin
    Print(['Unsupported network protocol ', NetworkProtocol, ', only 47 and 48 are supported.']);
    Exit;
  end;

  Map := ReadString(DEM.ReadLStr(260));
  Debug(T, ['Map: ', Map]);

  GameDir := ReadString(DEM.ReadLStr(260));
  Debug(T, ['GameDir: ', GameDir]);

  MapCheckSum := DEM.ReadUInt32;
  Debug(T, ['MapCheckSum: ', MapCheckSum]);

  DirectoryEntriesOffset := DEM.ReadUInt32;
  Debug(T, ['DirectoryEntriesOffset: ', DirectoryEntriesOffset]);

  if DirectoryEntriesOffset <> DEM.Size - 4 - (DEM_DIRECTORY_ENTRY_SIZE * 2) then
  begin
    Print(['Corrupted directory entries offset. ', DirectoryEntriesOffset, ' <> ', DEM.Size - 4 - (DEM_DIRECTORY_ENTRY_SIZE * 2)]);
    Exit;
  end;

  DEM.Skip(DirectoryEntriesOffset - DEM.Position);

  DirectoryEntriesNum := DEM.ReadUInt32;
  Debug(T, ['DirectoryEntriesNum: ', DirectoryEntriesNum]);

  if DirectoryEntriesNum <> 2 then
  begin
    Print(['Corrupted directory entries number. ', DirectoryEntriesNum, ' <> 2']);
    Exit;
  end;

  for I := 0 to DirectoryEntriesNum - 1 do
  begin
    DirEntryNum := DEM.ReadUInt32;
    DirEntryTitle := ReadString(DEM.ReadLStr(64));
    DEM.Skip(8);
    DirEntryTime := DEM.ReadFloat;
    DEM.Skip(12);

    Debug(T, ['DirEntry: ', DirEntryNum, ', Name: "', DirEntryTitle, '", Time: ', SecToTimeStr(Trunc(DirEntryTime))]);
  end;

  DEM.Position := DEM_HEADER_SIZE;

  IsDemoPlayback := True;

  CL_InitializePacketing;
end;

procedure TXBaseGameClient.CL_Consistency_F;
var
  S: LStr;
  I: Int32;
begin
  with Consistencies do
    if CMD.Count > 2 then
      Add(FixSlashes2(CMD.Tokens[1]), CMD.Tokens[2], False)
    else
      if Count > 0 then
      begin
        WriteLine(S, 'consistencies: ');

        for I := 0 to Count - 1 do
          with Consistencies[I] do
            WriteLine(S, SS + SS + IntToStr(I + 1) + ')' + SS + Key + ': "' + Value + '"');

        Print([S]);
      end
      else
      begin
        Print(['no consistencies registered.']);
        PrintCMDUsage(['filename', 'checksum']);
      end;
end;

procedure TXBaseGameClient.CL_FakeCVar_F;
var
  I: Int32;
  S: LStr;
begin
  with FakeCVars do
    if CMD.Count > 1 then
      if CVars.IndexOf(AnsiLowerCase(CMD.Tokens[1])) <> -1 then
      begin
      //  Print([CMD.Word(2), ' already exists as cvar']);
        Exit;
      end
      else
        if Commands.IndexOf(AnsiLowerCase(CMD.Tokens[1])) <> -1 then
        begin
        //  Print([CMD.Word(2), ' already exists as command']);
          Exit;
        end
        else
          if CMD.Count > 2 then
            Add(CMD.Tokens[1], CMD.Tokens[2])
          else
            PrintCMDUsage(['name', 'cmd'])
    else
      if Count > 0 then
      begin
        WriteLine(S, 'Fake CVars: ');

        for I := 0 to Count - 1 do
          with FakeCVars[I] do
            WriteLine(S, SS + SS + IntToStr(I + 1) + ')' + SS + Key + ' - ' + Value);

        Print([S]);
      end
      else
      begin
        Print(['no fake cvars registered.']);
        PrintCMDUsage(['name', 'cmd']);
      end;
end;

constructor TXBaseGameClient.Create;
begin
  inherited;

  Server := NET_LOCAL_ADDR;

  BF := TBufferEx2.Create;
  GMSG := TBufferEx2.Create;
  DMSG := TBufferEx2.Create;
  DEM := TBufferEx2.Create;

  FragmentsReader := TFragmentReader.Create;
  FileFragmentsReader := TFragmentReader.Create;
  FragmentsWriter := TFragmentWriter.Create;
  FileFragmentsWriter := TFragmentWriter.Create;

  Delta := TDeltaSystem.Create;
  Delta.OnError := Error;

  UserInfo := TAliasList.Create;

  GameEvents := TGameEventList.Create;

  Downloads := TList<LStr>.Create;

  Consistencies := TAliasList.Create;
  FakeCVars := TAliasList.Create;

{  SetLength(MyResources, 1); // only in cs, cz ?
  MyResources[0] := TResource.Create('tempdecal.wad', RT_DECAL, 0, 6296, 0, 0);}
end;

destructor TXBaseGameClient.Destroy;
begin
  if State > CS_DISCONNECTED then
    CL_FinalizeConnection;

  BF.Free;
  GMSG.Free;
  DMSG.Free;
  DEM.Free;
  FragmentsReader.Free;
  FileFragmentsReader.Free;
  FragmentsWriter.Free;
  FileFragmentsWriter.Free;
  Delta.Free;
  UserInfo.Free;
  GameEvents.Free;
  Downloads.Free;
  Consistencies.Free;
  FakeCVars.Free;

  inherited;
end;

function TXBaseGameClient.GetEntity: PEntity;
begin
  Result := CL_GetEntity;
end;

function TXBaseGameClient.PlayersCount: UInt32;
var
  I: Int32;
begin
  Clear(Result);

  for I := Low(Players) to High(Players) do
    if Players[I].GetName <> '' then
      Inc(Result);
end;

procedure TXBaseGameClient.MoveTo(APosition: TVec3F; ASpeed: Float);
begin
  CL_MoveTo(APosition, ASpeed);
end;

procedure TXBaseGameClient.MoveTo(APosition: TVec3F);
begin
  CL_MoveTo(APosition);
end;

procedure TXBaseGameClient.MoveTo(APlayer: TPlayer; ASpeed: Float);
begin
  CL_MoveTo(APlayer, ASpeed);
end;

procedure TXBaseGameClient.MoveTo(APlayer: TPlayer);
begin
  CL_MoveTo(APlayer);
end;

procedure TXBaseGameClient.MoveTo(AEntity: TEntity; ASpeed: Float);
begin
  CL_MoveTo(AEntity, ASpeed);
end;

procedure TXBaseGameClient.MoveTo(AEntity: TEntity);
begin
  CL_MoveTo(AEntity);
end;

procedure TXBaseGameClient.MoveOut(APosition: TVec3F; ASpeed: Float);
begin
  CL_MoveOut(APosition, ASpeed);
end;

procedure TXBaseGameClient.MoveOut(APosition: TVec3F);
begin
  CL_MoveOut(APosition);
end;

procedure TXBaseGameClient.MoveOut(APlayer: TPlayer; ASpeed: Float);
begin
  CL_MoveOut(APlayer, ASpeed);
end;

procedure TXBaseGameClient.MoveOut(APlayer: TPlayer);
begin
  CL_MoveOut(APlayer);
end;

procedure TXBaseGameClient.MoveOut(AEntity: TEntity; ASpeed: Float);
begin
  CL_MoveOut(AEntity, ASpeed);
end;

procedure TXBaseGameClient.MoveOut(AEntity: TEntity);
begin
  CL_MoveOut(AEntity);
end;

procedure TXBaseGameClient.LookAt(APosition: TVec3F);
begin
  CL_LookAt(APosition);
end;

procedure TXBaseGameClient.LookAt(APlayer: TPlayer);
begin
  CL_LookAt(APlayer);
end;

procedure TXBaseGameClient.LookAt(AEntity: TEntity);
begin
  CL_LookAt(AEntity);
end;

procedure TXBaseGameClient.LookAtEx(APosition: TVec3F);
begin
  CL_LookAtEx(APosition);
end;

procedure TXBaseGameClient.LookAtEx(APlayer: TPlayer);
begin
  CL_LookAtEx(APlayer);
end;

procedure TXBaseGameClient.LookAtEx(AEntity: TEntity);
begin
  CL_LookAtEx(AEntity);
end;

procedure TXBaseGameClient.PressButton(AButton: UInt16);
begin
  CL_PressButton(AButton);
end;

procedure TXBaseGameClient.UnPressButton(AButton: UInt16);
begin
  CL_UnPressButton(AButton);
end;

function TXBaseGameClient.GetDistance(APosition: TVec3F): Float;
begin
  Result := CL_GetDistance(APosition)
end;

function TXBaseGameClient.GetDistance(APlayer: TPlayer): Float;
begin
  Result := CL_GetDistance(APlayer);
end;

function TXBaseGameClient.GetDistance(AEntity: TEntity): Float;
begin
  Result := CL_GetDistance(AEntity);
end;

function TXBaseGameClient.GetDistance2D(APosition: TVec3F): Float;
begin
  Result := CL_GetDistance2D(APosition);
end;

function TXBaseGameClient.GetDistance2D(APlayer: TPlayer): Float;
begin
  Result := CL_GetDistance2D(APlayer);
end;

function TXBaseGameClient.GetDistance2D(AEntity: TEntity): Float;
begin
  Result := CL_GetDistance2D(AEntity);
end;

function TXBaseGameClient.IsWeaponExists(AIndex: UInt32): Boolean;
begin
  Result := CL_IsWeaponExists(AIndex);
end;

function TXBaseGameClient.IsWeaponExists(AWeapon: TWeapon): Boolean;
begin
  Result := CL_IsWeaponExists(AWeapon);
end;

function TXBaseGameClient.GetWeaponData(AIndex: UInt32): PWeaponData;
begin
  Result := CL_GetWeaponData(AIndex);
end;

function TXBaseGameClient.GetWeaponData: PWeaponData;
begin
  Result := CL_GetWeaponData;
end;

function TXBaseGameClient.InFieldOfView(APosition: TVec3F): Boolean;
begin
  Result := CL_InFieldOfView(APosition)
end;

function TXBaseGameClient.InFieldOfView(APlayer: TPlayer): Boolean;
begin
  Result := CL_InFieldOfView(APlayer)
end;

function TXBaseGameClient.InFieldOfView(AEntity: TEntity): Boolean;
begin
  Result := CL_InFieldOfView(AEntity)
end;

procedure TXBaseGameClient.UseEnvironment;
begin
  CL_UseEnvironment;
end;

procedure TXBaseGameClient.PrimaryAttack;
begin
  CL_PrimaryAttack;
end;

procedure TXBaseGameClient.SecondaryAttack;
begin
  CL_SecondaryAttack;
end;

procedure TXBaseGameClient.FastPrimaryAttack;
begin
  CL_FastPrimaryAttack;
end;

procedure TXBaseGameClient.FastSecondaryAttack;
begin
  CL_FastSecondaryAttack;
end;

procedure TXBaseGameClient.Jump;
begin
  CL_Jump;
end;

procedure TXBaseGameClient.Duck;
begin
  CL_Duck;
end;

procedure TXBaseGameClient.DuckJump;
begin
  CL_DuckJump;
end;

function TXBaseGameClient.GetGroundedOrigin: TVec3F;
begin
  Result := CL_GetGroundedOrigin;
end;

function TXBaseGameClient.GetGroundedDistance(APosition: TVec3F): Float;
begin
  Result := CL_GetGroundedDistance(APosition)
end;

function TXBaseGameClient.GetGroundedDistance(APlayer: TPlayer): Float;
begin
  Result := CL_GetGroundedDistance(APlayer)
end;

function TXBaseGameClient.GetGroundedDistance(AEntity: TEntity): Float;
begin
  Result := CL_GetGroundedDistance(AEntity)
end;

end.
