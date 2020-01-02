unit Protocol;

interface

uses
  SysUtils,
  UITypes,

  System.Generics.Collections,
  System.Generics.Defaults,


  MD5,  // tplayer, MD5 hash
  Default,
  Shared,
  Vector,

  Entity;

{$REGION 'Engine'}

const
  PROTOCOL_VERSION = 48;

type
  TEngineType = (E_NONE = 0, E_VALVE, E_CSTRIKE, E_CZERO, E_DMC, E_TFC, E_DOD, E_GEARBOX, E_RICOCHET);

  {$REGION 'Messages'}
    {$REGION 'General'}
type
  TEngineMsg = record
    Name: LStr;
    Index: UInt8;
  end;

const
  CLC_BAD = 0;
  CLC_NOP = 1;
  CLC_MOVE = 2;
  CLC_STRINGCMD = 3;
  CLC_DELTA = 4;
  CLC_RESOURCELIST = 5;
  CLC_TMOVE = 6;
  CLC_FILECONSISTENCY = 7;
  CLC_VOICEDATA = 8;
  CLC_HLTV = 9;
  CLC_CVARVALUE = 10;
  CLC_CVARVALUE2 = 11;

  CLC_FIRSTMSG = CLC_BAD;
  CLC_LASTMSG = CLC_CVARVALUE2;

const
  SVC_BAD = 0;
  SVC_NOP = 1;
  SVC_DISCONNECT = 2;
  SVC_EVENT = 3;
  SVC_VERSION = 4;
  SVC_SETVIEW = 5;
  SVC_SOUND = 6;
  SVC_TIME = 7;
  SVC_PRINT = 8;
  SVC_STUFFTEXT = 9;
  SVC_SETANGLE = 10;
  SVC_SERVERINFO = 11;
  SVC_LIGHTSTYLE = 12;
  SVC_UPDATEUSERINFO = 13;
  SVC_DELTADESCRIPTION = 14;
  SVC_CLIENTDATA = 15;
  SVC_STOPSOUND = 16;
  SVC_PINGS = 17;
  SVC_PARTICLE = 18;
  SVC_DAMAGE = 19;
  SVC_SPAWNSTATIC = 20;
  SVC_EVENT_RELIABLE = 21;
  SVC_SPAWNBASELINE = 22;
  SVC_TEMPENTITY = 23;
  SVC_SETPAUSE = 24;
  SVC_SIGNONNUM = 25;
  SVC_CENTERPRINT = 26;
  SVC_KILLEDMONSTER = 27;
  SVC_FOUNDSECRET = 28;
  SVC_SPAWNSTATICSOUND = 29;
  SVC_INTERMISSION = 30;
  SVC_FINALE = 31;
  SVC_CDTRACK = 32;
  SVC_RESTORE = 33;
  SVC_CUTSCENE = 34;
  SVC_WEAPONANIM = 35;
  SVC_DECALNAME = 36;
  SVC_ROOMTYPE = 37;
  SVC_ADDANGLE = 38;
  SVC_NEWUSERMSG = 39;
  SVC_PACKETENTITIES = 40;
  SVC_DELTAPACKETENTITIES = 41;
  SVC_CHOKE = 42;
  SVC_RESOURCELIST = 43;
  SVC_NEWMOVEVARS = 44;
  SVC_RESOURCEREQUEST = 45;
  SVC_CUSTOMIZATION = 46;
  SVC_CROSSHAIRANGLE = 47;
  SVC_SOUNDFADE = 48;
  SVC_FILETXFERFAILED = 49;
  SVC_HLTV = 50;
  SVC_DIRECTOR = 51;
  SVC_VOICEINIT = 52;
  SVC_VOICEDATA = 53;
  SVC_SENDEXTRAINFO = 54;
  SVC_TIMESCALE = 55;
  SVC_RESOURCELOCATION = 56;
  SVC_SENDCVARVALUE = 57;
  SVC_SENDCVARVALUE2 = 58;

  SVC_FIRSTMSG = SVC_BAD;
  SVC_LASTMSG = SVC_SENDCVARVALUE2;

const
  ClientEngineMsgs: array [CLC_FIRSTMSG..CLC_LASTMSG] of TEngineMsg =(
    (Name: 'Bad'; Index: CLC_BAD),
    (Name: 'Nop'; Index: CLC_NOP),
    (Name: 'Move'; Index: CLC_Move),
    (Name: 'StringCmd'; Index: CLC_STRINGCMD),
    (Name: 'Delta'; Index: CLC_DELTA),
    (Name: 'ResourceList'; Index: CLC_RESOURCELIST),
    (Name: 'TMove'; Index: CLC_TMOVE),
    (Name: 'FileConsistency'; Index: CLC_FILECONSISTENCY),
    (Name: 'VoiceData'; Index: CLC_VOICEDATA),
    (Name: 'HLTV'; Index: CLC_HLTV),
    (Name: 'CvarValue'; Index: CLC_CVARVALUE),
    (Name: 'CvarValue2'; Index: CLC_CVARVALUE2));

  ServerEngineMsgs: array [SVC_FIRSTMSG..SVC_LASTMSG] of TEngineMsg =(
    (Name: 'Bad'; Index: SVC_BAD),
    (Name: 'Nop'; Index: SVC_NOP),
    (Name: 'Disconnect'; Index: SVC_DISCONNECT),
    (Name: 'Event'; Index: SVC_EVENT),
    (Name: 'Version'; Index: SVC_VERSION),
    (Name: 'SetView'; Index: SVC_SETVIEW),
    (Name: 'Sound'; Index: SVC_SOUND),
    (Name: 'Time'; Index: SVC_TIME),
    (Name: 'Print'; Index: SVC_PRINT),
    (Name: 'StuffText'; Index: SVC_STUFFTEXT),
    (Name: 'SetAngle'; Index: SVC_SETANGLE),
    (Name: 'ServerInfo'; Index: SVC_SERVERINFO),
    (Name: 'LightStyle'; Index: SVC_LIGHTSTYLE),
    (Name: 'UpdateUserInfo'; Index: SVC_UPDATEUSERINFO),
    (Name: 'DeltaDescription'; Index: SVC_DELTADESCRIPTION),
    (Name: 'ClientData'; Index: SVC_CLIENTDATA),
    (Name: 'StopSound'; Index: SVC_STOPSOUND),
    (Name: 'Pings'; Index: SVC_PINGS),
    (Name: 'Particle'; Index: SVC_PARTICLE),
    (Name: 'Damage'; Index: SVC_DAMAGE),
    (Name: 'SpawnStatic'; Index: SVC_SPAWNSTATIC),
    (Name: 'EventReliable'; Index: SVC_EVENT_RELIABLE),
    (Name: 'SpawnBaseLine'; Index: SVC_SPAWNBASELINE),
    (Name: 'TempEntity'; Index: SVC_TEMPENTITY),
    (Name: 'SetPause'; Index: SVC_SETPAUSE),
    (Name: 'SignonNum'; Index: SVC_SIGNONNUM),
    (Name: 'CenterPrint'; Index: SVC_CENTERPRINT),
    (Name: 'KilledMonster'; Index: SVC_KILLEDMONSTER),
    (Name: 'FoundSecret'; Index: SVC_FOUNDSECRET),
    (Name: 'SpawnStaticSound'; Index: SVC_SPAWNSTATICSOUND),
    (Name: 'Intermission'; Index: SVC_INTERMISSION),
    (Name: 'Finale'; Index: SVC_FINALE),
    (Name: 'CDTrack'; Index: SVC_CDTRACK),
    (Name: 'Restore'; Index: SVC_RESTORE),
    (Name: 'CutScene'; Index: SVC_CUTSCENE),
    (Name: 'WeaponAnim'; Index: SVC_WEAPONANIM),
    (Name: 'DecalName'; Index: SVC_DECALNAME),
    (Name: 'RoomType'; Index: SVC_ROOMTYPE),
    (Name: 'AddAngle'; Index: SVC_ADDANGLE),
    (Name: 'NewUserMsg'; Index: SVC_NEWUSERMSG),
    (Name: 'PacketEntities'; Index: SVC_PACKETENTITIES),
    (Name: 'DeltaPacketEntities'; Index: SVC_DELTAPACKETENTITIES),
    (Name: 'Choke'; Index: SVC_CHOKE),
    (Name: 'ResourceList'; Index: SVC_RESOURCELIST),
    (Name: 'NewMoveVars'; Index: SVC_NEWMOVEVARS),
    (Name: 'ResourceRequest'; Index: SVC_RESOURCEREQUEST),
    (Name: 'Customization'; Index: SVC_CUSTOMIZATION),
    (Name: 'CrosshairAngle'; Index: SVC_CROSSHAIRANGLE),
    (Name: 'SoundFade'; Index: SVC_SOUNDFADE),
    (Name: 'FileTxferFailed'; Index: SVC_FILETXFERFAILED),
    (Name: 'HLTV'; Index: SVC_HLTV),
    (Name: 'Director'; Index: SVC_DIRECTOR),
    (Name: 'VoiceInit'; Index: SVC_VOICEINIT),
    (Name: 'VoiceData'; Index: SVC_VOICEDATA),
    (Name: 'SendExtraInfo'; Index: SVC_SENDEXTRAINFO),
    (Name: 'TimeScale'; Index: SVC_TIMESCALE),
    (Name: 'ResourceLocation'; Index: SVC_RESOURCELOCATION),
    (Name: 'SendCvarValue'; Index: SVC_SENDCVARVALUE),
    (Name: 'SendCvarValue2'; Index: SVC_SENDCVARVALUE2));

type
  TClientUserMsg = record
    Name: LStr;
    Index: UInt8;
    Size: Int32;
  end;
    {$ENDREGION}

    {$REGION 'Temp Entity'}
const
  TE_BEAMPOINTS = 0;        // Beam effect between two points
  TE_BEAMENTPOINT = 1;        // Beam effect between point and entity
  TE_GUNSHOT = 2;        // Particle effect plus ricochet sound
  TE_EXPLOSION = 3;        // Additive sprite, 2 dynamic lights, flickering particles, explosion sound, move vertically 8 pps
   TE_EXPLFLAG_NONE = 0;        // All flags clear makes default Half-Life explosion
   TE_EXPLFLAG_NOADDITIVE = 1 shl 0;       // Sprite will be drawn opaque (ensure that the sprite you send is a non-additive sprite)
   TE_EXPLFLAG_NODLIGHTS = 1 shl 1;        // Do not render dynamic lights
   TE_EXPLFLAG_NOSOUND = 1 shl 2;        // Do not play client explosion sound
   TE_EXPLFLAG_NOPARTICLES = 1 shl 3;        // Do not draw particles
  TE_TAREXPLOSION = 4;        // Quake1 "tarbaby" explosion with sound
  TE_SMOKE = 5;       // Alphablend sprite, move vertically 30 pps
  TE_TRACER = 6;        // Tracer effect from point to point
  TE_LIGHTNING = 7;        // TE_BEAMPOINTS with simplified parameters
  TE_BEAMENTS = 8;
  TE_SPARKS = 9;        // 8 random tracers with gravity, ricochet sprite
  TE_LAVASPLASH = 10;       // Quake1 lava splash
  TE_TELEPORT = 11;       // Quake1 teleport splash
  TE_EXPLOSION2 = 12;       // Quake1 colormaped (base palette) particle explosion with sound
  TE_BSPDECAL = 13;       // Decal from the .BSP file
  TE_IMPLOSION = 14;       // Tracers moving toward a point
  TE_SPRITETRAIL = 15;       // Line of moving glow sprites with gravity, fadeout, and collisions
  TE_UNKNOWN16 = 16;
  TE_SPRITE = 17;       // Additive sprite, plays 1 cycle
  TE_BEAMSPRITE = 18;       // A beam with a sprite at the end
  TE_BEAMTORUS = 19;       // Screen aligned beam ring, expands to max radius over lifetime
  TE_BEAMDISK = 20;       // Disk that expands to max radius over lifetime
  TE_BEAMCYLINDER = 21;       // Cylinder that expands to max radius over lifetime
  TE_BEAMFOLLOW = 22;       // Create a line of decaying beam segments until entity stops moving
  TE_GLOWSPRITE = 23;
  TE_BEAMRING = 24;       // Connect a beam ring to two entities
  TE_STREAK_SPLASH = 25;       // Oriented shower of tracers
  TE_UNKNOWN26 = 26;
  TE_DLIGHT = 27;       // Dynamic light, effect world, minor entity effect
  TE_ELIGHT = 28;       // Point entity light, no world effect
  TE_TEXTMESSAGE = 29;
  TE_LINE = 30;
  TE_BOX = 31;
  TE_UNKNOWN32 = 32;
  TE_UNKNOWN33 = 33;
  TE_UNKNOWN34 = 34;
  TE_UNKNOWN35 = 35;
  TE_UNKNOWN36 = 36;
  TE_UNKNOWN37 = 37;
  TE_UNKNOWN38 = 38;
  TE_UNKNOWN39 = 39;
  TE_UNKNOWN40 = 40;
  TE_UNKNOWN41 = 41;
  TE_UNKNOWN42 = 42;
  TE_UNKNOWN43 = 43;
  TE_UNKNOWN44 = 44;
  TE_UNKNOWN45 = 45;
  TE_UNKNOWN46 = 46;
  TE_UNKNOWN47 = 47;
  TE_UNKNOWN48 = 48;
  TE_UNKNOWN49 = 49;
  TE_UNKNOWN50 = 50;
  TE_UNKNOWN51 = 51;
  TE_UNKNOWN52 = 52;
  TE_UNKNOWN53 = 53;
  TE_UNKNOWN54 = 54;
  TE_UNKNOWN55 = 55;
  TE_UNKNOWN56 = 56;
  TE_UNKNOWN57 = 57;
  TE_UNKNOWN58 = 58;
  TE_UNKNOWN59 = 59;
  TE_UNKNOWN60 = 60;
  TE_UNKNOWN61 = 61;
  TE_UNKNOWN62 = 62;
  TE_UNKNOWN63 = 63;
  TE_UNKNOWN64 = 64;
  TE_UNKNOWN65 = 65;
  TE_UNKNOWN66 = 66;
  TE_UNKNOWN67 = 67;
  TE_UNKNOWN68 = 68;
  TE_UNKNOWN69 = 69;
  TE_UNKNOWN70 = 70;
  TE_UNKNOWN71 = 71;
  TE_UNKNOWN72 = 72;
  TE_UNKNOWN73 = 73;
  TE_UNKNOWN74 = 74;
  TE_UNKNOWN75 = 75;
  TE_UNKNOWN76 = 76;
  TE_UNKNOWN77 = 77;
  TE_UNKNOWN78 = 78;
  TE_UNKNOWN79 = 79;
  TE_UNKNOWN80 = 80;
  TE_UNKNOWN81 = 81;
  TE_UNKNOWN82 = 82;
  TE_UNKNOWN83 = 83;
  TE_UNKNOWN84 = 84;
  TE_UNKNOWN85 = 85;
  TE_UNKNOWN86 = 86;
  TE_UNKNOWN87 = 87;
  TE_UNKNOWN88 = 88;
  TE_UNKNOWN89 = 89;
  TE_UNKNOWN90 = 90;
  TE_UNKNOWN91 = 91;
  TE_UNKNOWN92 = 92;
  TE_UNKNOWN93 = 93;
  TE_UNKNOWN94 = 94;
  TE_UNKNOWN95 = 95;
  TE_UNKNOWN96 = 96;
  TE_UNKNOWN97 = 97;
  TE_UNKNOWN98 = 98;
  TE_KILLBEAM = 99;
  TE_LARGEFUNNEL = 100;
  TE_BLOODSTREAM = 101;      // Particle spray
  TE_SHOWLINE = 102;      // Line of particles every 5 units, dies in 30 seconds
  TE_BLOOD = 103;      // Particle spray
  TE_DECAL = 104;      // Decal applied to a brush entity (not the world)
  TE_FIZZ = 105;      // Create alpha sprites inside of entity, float upwards
  TE_MODEL = 106;      // Create a moving model that bounces and makes a sound when it hits
  TE_EXPLODEMODEL = 107;      // Spherical shower of models, picks from set
  TE_BREAKMODEL = 108;      // Box of models or sprites
  TE_GUNSHOTDECAL = 109;      // Decal and ricochet sound
  TE_SPRITE_SPRAY = 110;      // Spray of alpha sprites
  TE_ARMOR_RICOCHET = 111;      // Quick spark sprite, client ricochet sound.
  TE_PLAYERDECAL = 112;
  TE_BUBBLES = 113;      // Create alpha sprites inside of box, float upwards
  TE_BUBBLETRAIL = 114;      // Create alpha sprites along a line, float upwards
  TE_BLOODSPRITE = 115;      // Spray of opaque sprite1's that fall, single sprite2 for 1..2 secs (this is a high-priority tent)
  TE_WORLDDECAL = 116;      // Decal applied to the world brush
  TE_WORLDDECALHIGH = 117;      // Decal (with texture index > 256) applied to world brush
  TE_DECALHIGH = 118;      // Same as TE_DECAL, but the texture index was greater than 256
  TE_PROJECTILE = 119;      // Makes a projectile (like a nail) (this is a high-priority tent)
  TE_SPRAY = 120;      // Throws a shower of sprites or models
  TE_PLAYERSPRITES = 121;      // Sprites emit from a player's bounding box (ONLY use for players!)
  TE_PARTICLEBURST = 122;      // Very similar to lavasplash
  TE_FIREFIELD = 123;      // Makes a field of fire
   TEFIRE_FLAG_ALLFLOAT = 1 shl 0;        // All sprites will drift upwards as they animate
   TEFIRE_FLAG_SOMEFLOAT = 1 shl 1;        // Some of the sprites will drift upwards. (50% chance)
   TEFIRE_FLAG_LOOP = 1 shl 2;        // If set, sprite plays at 15 fps, otherwise plays at whatever rate stretches the animation over the sprite's duration.
   TEFIRE_FLAG_ALPHA = 1 shl 3;        // If set, sprite is rendered alpha blended at 50% else, opaque
   TEFIRE_FLAG_PLANAR = 1 shl 4;       // If set, all fire sprites have same initial Z instead of randomly filling a cube.
  TE_PLAYERATTACHMENT = 124;      // Attaches a TENT to a player (this is a high-priority tent)
  TE_KILLPLAYERATTACHMENTS = 125;      // Will expire all TENTS attached to a player.
  TE_MULTIGUNSHOT = 126;      // Much more compact shotgun message
  TE_USERTRACER = 127;      // Larger message than the standard tracer, but allows some customization.

  TE_FIRSTMSG = TE_BEAMPOINTS;
  TE_LASTMSG = TE_USERTRACER;

  TempEntityMsgs: array [TE_FIRSTMSG..TE_LASTMSG] of TEngineMsg =(
    (Name: 'BeamPoints'; Index: TE_BEAMPOINTS),
    (Name: 'BeamEntPoints'; Index: TE_BEAMENTPOINT),
    (Name: 'GunShot'; Index: TE_GUNSHOT),
    (Name: 'Explosion'; Index: TE_EXPLOSION),
    (Name: 'TarExplosion'; Index: TE_TAREXPLOSION),
    (Name: 'Smoke'; Index: TE_SMOKE),
    (Name: 'Tracer'; Index: TE_TRACER),
    (Name: 'Lightning'; Index: TE_LIGHTNING),
    (Name: 'BeamEnts'; Index: TE_BEAMENTS),
    (Name: 'Sparks'; Index: TE_SPARKS),
    (Name: 'LavaSplash'; Index: TE_LAVASPLASH),
    (Name: 'Teleport'; Index: TE_TELEPORT),
    (Name: 'Explosion2'; Index: TE_EXPLOSION2),
    (Name: 'BSPDecal'; Index: TE_BSPDECAL),
    (Name: 'Implosion'; Index: TE_IMPLOSION),
    (Name: 'SpriteTrail'; Index: TE_SPRITETRAIL),

    (Name: 'Unknown16'; Index: TE_UNKNOWN16),

    (Name: 'Sprite'; Index: TE_SPRITE),
    (Name: 'BeamSprite'; Index: TE_BEAMSPRITE),
    (Name: 'BeamTorus'; Index: TE_BEAMTORUS),
    (Name: 'BeamDisk'; Index: TE_BEAMDISK),
    (Name: 'BeamCylinder'; Index: TE_BEAMCYLINDER),
    (Name: 'BeamFollow'; Index: TE_BEAMFOLLOW),
    (Name: 'GlowSprite'; Index: TE_GLOWSPRITE),
    (Name: 'BeamRing'; Index: TE_BEAMRING),
    (Name: 'StreakSplash'; Index: TE_STREAK_SPLASH),

    (Name: 'Unknown26'; Index: TE_UNKNOWN26),

    (Name: 'DLight'; Index: TE_DLIGHT),
    (Name: 'ELight'; Index: TE_ELIGHT),
    (Name: 'TextMessage'; Index: TE_TEXTMESSAGE),
    (Name: 'Line'; Index: TE_LINE),
    (Name: 'Box'; Index: TE_BOX),

    (Name: 'Unknown32'; Index: TE_UNKNOWN32),
    (Name: 'Unknown33'; Index: TE_UNKNOWN33),
    (Name: 'Unknown34'; Index: TE_UNKNOWN34),
    (Name: 'Unknown35'; Index: TE_UNKNOWN35),
    (Name: 'Unknown36'; Index: TE_UNKNOWN36),
    (Name: 'Unknown37'; Index: TE_UNKNOWN37),
    (Name: 'Unknown38'; Index: TE_UNKNOWN38),
    (Name: 'Unknown39'; Index: TE_UNKNOWN39),
    (Name: 'Unknown40'; Index: TE_UNKNOWN40),
    (Name: 'Unknown41'; Index: TE_UNKNOWN41),
    (Name: 'Unknown42'; Index: TE_UNKNOWN42),
    (Name: 'Unknown43'; Index: TE_UNKNOWN43),
    (Name: 'Unknown44'; Index: TE_UNKNOWN44),
    (Name: 'Unknown45'; Index: TE_UNKNOWN45),
    (Name: 'Unknown46'; Index: TE_UNKNOWN46),
    (Name: 'Unknown47'; Index: TE_UNKNOWN47),
    (Name: 'Unknown48'; Index: TE_UNKNOWN48),
    (Name: 'Unknown49'; Index: TE_UNKNOWN49),
    (Name: 'Unknown50'; Index: TE_UNKNOWN50),
    (Name: 'Unknown51'; Index: TE_UNKNOWN51),
    (Name: 'Unknown52'; Index: TE_UNKNOWN52),
    (Name: 'Unknown53'; Index: TE_UNKNOWN53),
    (Name: 'Unknown54'; Index: TE_UNKNOWN54),
    (Name: 'Unknown55'; Index: TE_UNKNOWN55),
    (Name: 'Unknown56'; Index: TE_UNKNOWN56),
    (Name: 'Unknown57'; Index: TE_UNKNOWN57),
    (Name: 'Unknown58'; Index: TE_UNKNOWN58),
    (Name: 'Unknown59'; Index: TE_UNKNOWN59),
    (Name: 'Unknown60'; Index: TE_UNKNOWN60),
    (Name: 'Unknown61'; Index: TE_UNKNOWN61),
    (Name: 'Unknown62'; Index: TE_UNKNOWN62),
    (Name: 'Unknown63'; Index: TE_UNKNOWN63),
    (Name: 'Unknown64'; Index: TE_UNKNOWN64),
    (Name: 'Unknown65'; Index: TE_UNKNOWN65),
    (Name: 'Unknown66'; Index: TE_UNKNOWN66),
    (Name: 'Unknown67'; Index: TE_UNKNOWN67),
    (Name: 'Unknown68'; Index: TE_UNKNOWN68),
    (Name: 'Unknown69'; Index: TE_UNKNOWN69),
    (Name: 'Unknown70'; Index: TE_UNKNOWN70),
    (Name: 'Unknown71'; Index: TE_UNKNOWN71),
    (Name: 'Unknown72'; Index: TE_UNKNOWN72),
    (Name: 'Unknown73'; Index: TE_UNKNOWN73),
    (Name: 'Unknown74'; Index: TE_UNKNOWN74),
    (Name: 'Unknown75'; Index: TE_UNKNOWN75),
    (Name: 'Unknown76'; Index: TE_UNKNOWN76),
    (Name: 'Unknown77'; Index: TE_UNKNOWN77),
    (Name: 'Unknown78'; Index: TE_UNKNOWN78),
    (Name: 'Unknown79'; Index: TE_UNKNOWN79),
    (Name: 'Unknown80'; Index: TE_UNKNOWN80),
    (Name: 'Unknown81'; Index: TE_UNKNOWN81),
    (Name: 'Unknown82'; Index: TE_UNKNOWN82),
    (Name: 'Unknown83'; Index: TE_UNKNOWN83),
    (Name: 'Unknown84'; Index: TE_UNKNOWN84),
    (Name: 'Unknown85'; Index: TE_UNKNOWN85),
    (Name: 'Unknown86'; Index: TE_UNKNOWN86),
    (Name: 'Unknown87'; Index: TE_UNKNOWN87),
    (Name: 'Unknown88'; Index: TE_UNKNOWN88),
    (Name: 'Unknown89'; Index: TE_UNKNOWN89),
    (Name: 'Unknown90'; Index: TE_UNKNOWN90),
    (Name: 'Unknown91'; Index: TE_UNKNOWN91),
    (Name: 'Unknown92'; Index: TE_UNKNOWN92),
    (Name: 'Unknown93'; Index: TE_UNKNOWN93),
    (Name: 'Unknown94'; Index: TE_UNKNOWN94),
    (Name: 'Unknown95'; Index: TE_UNKNOWN95),
    (Name: 'Unknown96'; Index: TE_UNKNOWN96),
    (Name: 'Unknown97'; Index: TE_UNKNOWN97),
    (Name: 'Unknown98'; Index: TE_UNKNOWN98),

    (Name: 'KillBeam'; Index: TE_KILLBEAM),
    (Name: 'LargeFunnel'; Index: TE_LARGEFUNNEL),
    (Name: 'BloodStream'; Index: TE_BLOODSTREAM),
    (Name: 'ShowLine'; Index: TE_SHOWLINE),
    (Name: 'Blood'; Index: TE_BLOOD),
    (Name: 'Decal'; Index: TE_DECAL),
    (Name: 'Fizz'; Index: TE_FIZZ),
    (Name: 'Model'; Index: TE_MODEL),
    (Name: 'ExplodeModel'; Index: TE_EXPLODEMODEL),
    (Name: 'BreakModel'; Index: TE_BREAKMODEL),
    (Name: 'GunShotDecal'; Index: TE_GUNSHOTDECAL),
    (Name: 'SpriteSpray'; Index: TE_SPRITE_SPRAY),
    (Name: 'ArmorRicochet'; Index: TE_ARMOR_RICOCHET),
    (Name: 'PlayerDecal'; Index: TE_PLAYERDECAL),
    (Name: 'Bubbles'; Index: TE_BUBBLES),
    (Name: 'BubbleTrail'; Index: TE_BUBBLETRAIL),
    (Name: 'BloodSprite'; Index: TE_BLOODSPRITE),
    (Name: 'WorldDecal'; Index: TE_WORLDDECAL),
    (Name: 'WorldDecalHigh'; Index: TE_WORLDDECALHIGH),
    (Name: 'DecalHigh'; Index: TE_DECALHIGH),
    (Name: 'Projectile'; Index: TE_PROJECTILE),
    (Name: 'Spray'; Index: TE_SPRAY),
    (Name: 'PlayerSprites'; Index: TE_PLAYERSPRITES),
    (Name: 'ParticleBurst'; Index: TE_PARTICLEBURST),
    (Name: 'FireField'; Index: TE_FIREFIELD),
    (Name: 'PlayerAttachment'; Index: TE_PLAYERATTACHMENT),
    (Name: 'KillPlayerAttachments'; Index: TE_KILLPLAYERATTACHMENTS),
    (Name: 'MultiGunShot'; Index: TE_MULTIGUNSHOT),
    (Name: 'UserTracer'; Index: TE_USERTRACER));
    {$ENDREGION}

    {$REGION 'HLTV & Director'}
const
// sub commands of svc_hltv:
  HLTV_ACTIVE = 0; // tells client that he's an spectator and will get director commands
  HLTV_STATUS = 1; // send status infos about proxy
  HLTV_LISTEN = 2; // tell client to listen to a multicast stream

// director command types:
  DRC_CMD_NONE = 0;        // NULL director command
  DRC_CMD_START = 1;        // start director mode
  DRC_CMD_EVENT = 2;       // informs about director command
  DRC_CMD_MODE = 3;        // switches camera modes
  DRC_CMD_CAMERA = 4;        // set fixed camera
  DRC_CMD_TIMESCALE = 5;        // sets time scale
  DRC_CMD_MESSAGE = 6;        // send HUD centerprint
  DRC_CMD_SOUND = 7;        // plays a particular sound
  DRC_CMD_STATUS = 8;        // HLTV broadcast status
  DRC_CMD_BANNER = 9;        // set GUI banner
  DRC_CMD_STUFFTEXT = 10;        // like the normal svc_stufftext but as director command
  DRC_CMD_CHASE = 11;        // chase a certain player
  DRC_CMD_INEYE = 12;        // view player through own eyes
  DRC_CMD_MAP = 13;        // show overview map
  DRC_CMD_CAMPATH = 14;        //  camera waypoint
  DRC_CMD_WAYPOINTS = 15;        // start moving camera, inetranl message

  DRC_CMD_FIRST = DRC_CMD_NONE;
  DRC_CMD_LAST = DRC_CMD_WAYPOINTS;

  DrcCmdMessages: array [DRC_CMD_FIRST..DRC_CMD_LAST] of TEngineMsg =(
    (Name: 'None'; Index: DRC_CMD_NONE),
    (Name: 'Start'; Index: DRC_CMD_START),
    (Name: 'Event'; Index: DRC_CMD_EVENT),
    (Name: 'Mode'; Index: DRC_CMD_MODE),
    (Name: 'Camera'; Index: DRC_CMD_CAMERA),
    (Name: 'TimeScale'; Index: DRC_CMD_TIMESCALE),
    (Name: 'Message'; Index: DRC_CMD_MESSAGE),
    (Name: 'Sound'; Index: DRC_CMD_SOUND),
    (Name: 'Status'; Index: DRC_CMD_STATUS),
    (Name: 'Banner'; Index: DRC_CMD_BANNER),
    (Name: 'StuffText'; Index: DRC_CMD_STUFFTEXT),
    (Name: 'Chase'; Index: DRC_CMD_CHASE),
    (Name: 'InEye'; Index: DRC_CMD_INEYE),
    (Name: 'Map'; Index: DRC_CMD_MAP),
    (Name: 'CamPath'; Index: DRC_CMD_CAMPATH),
    (Name: 'Waypoints'; Index: DRC_CMD_WAYPOINTS));

// DRC_CMD_EVENT event flags
  DRC_FLAG_PRIO_MASK = $0F;	// priorities between 0 and 15 (15 most important)
  DRC_FLAG_SIDE = 1 shl 4;	//
  DRC_FLAG_DRAMATIC = 1 shl 5;	// is a dramatic scene
  DRC_FLAG_SLOWMOTION = 1 shl 6;  // would look good in SloMo
  DRC_FLAG_FACEPLAYER = 1 shl 7;  // player is doning something (reload/defuse bomb etc)
  DRC_FLAG_INTRO = 1 shl 8;	// is a introduction scene
  DRC_FLAG_FINAL = 1 shl 9;	// is a final scene
  DRC_FLAG_NO_RANDOM = 1 shl 10;	// don't randomize event data

// DRC_CMD_WAYPOINT flags
  DRC_FLAG_STARTPATH = 1;	// end with speed 0.0
  DRC_FLAG_SLOWSTART = 2;	// start with speed 0.0
  DRC_FLAG_SLOWEND = 4;	// end with speed 0.0
    {$ENDREGION}

    {$REGION 'Demonstration'}
const
  DEM_SERVERMSG = 0;
  DEM_SERVERMSG2 = 1;
  DEM_NEXT = 2;
  DEM_COMMAND = 3;
  DEM_CLIENTDATA = 4;
  DEM_LAST = 5;
  DEM_EVENT = 6;
  DEM_WEAPONANIM = 7;
  DEM_SOUND = 8;
  DEM_READBUFFER = 9;
    {$ENDREGION}

    {$REGION 'Other'}
const
  OUTOFBAND_PREFIX = -1;
  SPLIT_PREFIX = -2;
    {$ENDREGION}
  {$ENDREGION}

  {$REGION 'Network'}
type
  TFragmentChannel = record
    Active: Boolean;
    Sequence, Count, LastCount, LastTime, Total: UInt32;
    CanSend: Boolean;
  end;

  TChannel = record
    IncomingTime: UInt32;
    IncomingSequence: Int32;
    IncomingAcknowledgement: Int32;
    IncomingAcknowledgementReliable: Boolean;

    OutgoingTime: UInt32;
    OutgoingSequence: Int32;
    OutgoingSequenceReliable: Boolean;
    OutgoingAcknowledgementReliable: Boolean;

    Fragment: TFragmentChannel;
    FileFragment: TFragmentChannel;

    Latency: UInt16;
  end;
  {$ENDREGION}

  {$REGION 'Delta'}
type
  PClientData = ^TClientData; // 476
  TClientData = record
    Origin, Velocity: TVec3F;
    ViewModel: Int32;
    PunchAngle: TVec3F;
    Flags, WaterLevel, WaterType: Int32;
    ViewOffset: TVec3F;
    Health: Float;
    InDuck, Weapons, TimeStepSound, DuckTime, SwimTime, WaterJumpTime: Int32;
    MaxSpeed, FOV: Float;
    WeaponAnim, ID, AmmoShells, AmmoNails, AmmoCells, AmmoRockets: Int32;  // id is cur. weapon index
    NextAttack: Float;
    TFState, PushMSec, DeadFlag: Int32;
    PhysInfo: LStr;
    IUser1, IUser2, IUser3, IUser4: Int32;   // IUser1 - spec mode.   // IUser2: player index, 0 = you
    FUser1, FUser2, FUser3, FUser4: Float;
    VUser1, VUser2, VUser3, VUser4: TVec3F;
  end;

  PWeaponData = ^TWeaponData;
  TWeaponData = record
    ID, Clip: Int32;
    NextPrimaryAttack, NextSecondaryAttack, TimeWeaponIdle: Float;
    InReload, InSpecialReload: Int32;
    NextReload, PumpTime, ReloadTime, AimedDamage, NextAimBonus: Float;
    InZoom, WeaponState: Int32;
    IUser1, IUser2, IUser3, IUser4: Int32;
    FUser1, FUser2, FUser3, FUser4: Float;
  end;

  TWeaponDataDynArray = array of TWeaponData;

const
  WeaponDataCleared: TWeaponData = ();

type
  PUserCmd = ^TUserCmd;
  TUserCmd = packed record
    LerpMSec: Int16; // Interpolation time on client
    MSec: UInt8; // Duration in ms of command
    ViewAngles: TVec3F; // Command view angles.
    ForwardMove, // Forward velocity.
    SideMove, // Sideways velocity.
    UpMove: Float; // Upward velocity.
    LightLevel: UInt8; // Light level at spot where we are standing.
    Buttons: UInt16; // Attack buttons
    Impulse, // Impulse command issued.
    WeaponSelect: UInt8; // Current weapon id
    // Experimental player impact stuff.
    ImpactIndex: Int32;
    ImpactPosition: TVec3F;
  end;

const
  UserCmdCleared: TUserCmd = ();

type
  PPhysEnt = ^TPhysEnt; // 224
  TPhysEnt = record
    Name: array[1..32] of LChar;
    Player: Int32;
    Origin: TVec3F; // +36
   // Model: PModel; // +48
   // StudioModel: PModel; // +52
   // MinS, MaxS: TVec3F; // +56, +68
    Info: Int32; // +80
    Angles: TVec3F; // +84
    Solid: Int32; // +96
    Skin: Int32; // +100
    RenderMode: Int32; // +104
    Frame: Single; // +108
    Sequence: Int32; // +112
    Controller: array[0..3] of Byte; // +116
    Blending: array[0..1] of Byte; // +120
    MoveType, TakeDamage, BloodDecal, Team, ClassNumber: Int32;
    IUser1, IUser2, IUser3, IUser4: Int32;
    FUser1, FUser2, FUser3, FUser4: Single;
    VUser1, VUser2, VUser3, VUser4: TVec3F;
  end;

const
  PhysEntCleared: TPhysEnt = ();

  {$ENDREGION}
{$ENDREGION}

{$REGION 'PM'}
const
  PM_TRACELINE_PHYSENTSONLY = 0;
  PM_TRACELINE_ANYVISIBLE = 1;

{$ENDREGION}

{$REGION 'DEMO'}
const
  DEM_MAGIC = 'HLDEMO';

const
  DEM_HEADER_SIZE = 544;
  DEM_DIRECTORY_ENTRY_SIZE = 92;
{$ENDREGION}

{$REGION 'Game'}

// edict->flags
const
  FL_FLY = 1 shl 0; // changes the SV_Movestep() behavior to not need to be on ground
  FL_SWIM = 1 shl 1; // changes the SV_Movestep() behavior to not need to be on ground (but stay in water)
  FL_CONVEYOR = 1 shl 2;
  FL_CLIENT = 1 shl 3;
  FL_INWATER = 1 shl 4;
  FL_MONSTER = 1 shl 5;
  FL_GODMODE = 1 shl 6;
  FL_NOTARGET = 1 shl 7;
  FL_SKIPLOCALHOST = 1 shl 8; // don't send entity to local host, it's predicting this entity itself
  FL_ONGROUND = 1 shl 9; // at rest / on the ground
  FL_PARTIALGROUND = 1 shl 10; // not all corners are valid
  FL_WATERJUMP = 1 shl 11; // player jumping out of water
  FL_FROZEN = 1 shl 12; // player is frozen for 3rd person camera
  FL_FAKECLIENT = 1 shl 13; // JAC: fake client, simulated server side; don't send network messages to them
  FL_DUCKING = 1 shl 14; // player flag -- player is fully crouched
  FL_FLOAT = 1 shl 15; // apply floating force to this entity when in water
  FL_GRAPHED = 1 shl 16; // worldgraph has this ent listed as something that blocks a connection
  FL_IMMUNE_WATER = 1 shl 17;
  FL_IMMUNE_SLIME = 1 shl 18;
  FL_IMMUNE_LAVA = 1 shl 19;
  FL_PROXY = 1 shl 20; // this is a spectator proxy
  FL_ALWAYSTHINK = 1 shl 21; // brush model flag -- call think every frame regardless of nextthink - ltime (for constantly changing velocity/path)
  FL_BASEVELOCITY = 1 shl 22; // base velocity has been applied this frame (used to convert base velocity into momentum)
  FL_MONSTERCLIP = 1 shl 23; // only collide in with monsters who have FL_MONSTERCLIP set
  FL_ONTRAIN = 1 shl 24; // player is _controlling_ a train, so movement commands should be ignored on client during prediction.
  FL_WORLDBRUSH = 1 shl 25; // not moveable/removeable brush entity (really part of the world, but represented as an entity for transparency or something)
  FL_SPECTATOR = 1 shl 26; // this client is a spectator, don't run touch functions, etc.
  FL_CUSTOMENTITY = 1 shl 29; // this is a custom entity
  FL_KILLME = 1 shl 30; // this entity is marked for death -- this allows the engine to kill ents at the appropriate time
  FL_DORMANT = 1 shl 31; // entity is dormant, no updates to client

// walkmove modes
const
  WALKMOVE_NORMAL = 0; // normal walkmove
  WALKMOVE_WORLDONLY = 1; // doesn't hit ANY entities, no matter what the solid type
  WALKMOVE_CHECKONLY = 2; // move, but don't touch triggers

// edict->movetype values
const
  MOVETYPE_NONE = 0; // never moves
  MOVETYPE_ANGLENOCLIP = 1;
  MOVETYPE_ANGLECLIP = 2;
  MOVETYPE_WALK = 3; // Player only - moving on the ground
  MOVETYPE_STEP = 4; // gravity, special edge handling -- monsters use this
  MOVETYPE_FLY = 5; // No gravity, but still collides with stuff
  MOVETYPE_TOSS = 6; // gravity/collisions
  MOVETYPE_PUSH = 7; // no clip to world, push and crush
  MOVETYPE_NOCLIP = 8; // No gravity, no collisions, still do velocity/avelocity
  MOVETYPE_FLYMISSILE = 9; // extra size to monsters
  MOVETYPE_BOUNCE = 10; // Just like Toss, but reflect velocity when contacting surfaces
  MOVETYPE_BOUNCEMISSILE = 11; // bounce w/o gravity
  MOVETYPE_FOLLOW = 12; // track movement of aiment
  MOVETYPE_PUSHSTEP = 13; // BSP model that needs physics/world collisions (uses nearest hull for world collision)

// edict->solid values
// NOTE: Some movetypes will cause collisions independent of SOLID_NOT/SOLID_TRIGGER when the entity moves
// SOLID only effects OTHER entities colliding with this one when they move - UGH!
const
  SOLID_NOT = 0; // no interaction with other objects
  SOLID_TRIGGER = 1; // touch on edge, but not blocking
  SOLID_BBOX = 2; // touch on edge, block
  SOLID_SLIDEBOX = 3; // touch on edge, but not an onground
  SOLID_BSP = 4; // bsp clip, touch on edge, block

// edict->deadflag values
const
  DEAD_NO = 0; // alive
  DEAD_DYING = 1; // playing death animation or still falling off of a ledge waiting to hit ground
  DEAD_DEAD = 2; // dead. lying still.
  DEAD_RESPAWNABLE = 3;
  DEAD_DISCARDBODY = 4;

const
  DAMAGE_NO = 0;
  DAMAGE_YES = 1;
  DAMAGE_AIM = 2;

// entity effects
const
  EF_BRIGHTFIELD = 1 shl 0; // swirling cloud of particles
  EF_MUZZLEFLASH = 1 shl 1; // single frame ELIGHT on entity attachment 0
  EF_BRIGHTLIGHT = 1 shl 2; // DLIGHT centered at entity origin
  EF_DIMLIGHT = 1 shl 3; // player flashlight
  EF_INVLIGHT = 1 shl 4; // get lighting from ceiling
  EF_NOINTERP = 1 shl 5; // don't interpolate the next frame
  EF_LIGHT = 1 shl 6; // rocket flare glow sprite
  EF_NODRAW = 1 shl 7; // don't draw entity
  EF_NIGHTVISION = 1 shl 8; // player nightvision
  EF_SNIPERLASER = 1 shl 9; // sniper laser effect
  EF_FIBERCAMERA = 1 shl 10; // fiber camera

// clc_move buttons
const
  IN_ATTACK = 1 shl 0;
  IN_JUMP = 1 shl 1;
  IN_DUCK = 1 shl 2;
  IN_FORWARD = 1 shl 3;
  IN_BACK = 1 shl 4;
  IN_USE = 1 shl 5;
  IN_CANCEL = 1 shl 6;
  IN_LEFT = 1 shl 7;
  IN_RIGHT = 1 shl 8;
  IN_MOVELEFT = 1 shl 9;
  IN_MOVERIGHT = 1 shl 10;
  IN_ATTACK2 = 1 shl 11;
  IN_RUN = 1 shl 12;
  IN_RELOAD = 1 shl 13;
  IN_ALT1 = 1 shl 14;
  IN_SCORE = 1 shl 15;

const
  ENTITY_NORMAL = 1 shl 0;
  ENTITY_BEAM = 1 shl 1;


// Instant damage values for use with gmsgDamage 3rd value write_long(BIT)
const
  DMG_GENERIC = 0; // Generic damage was done
  DMG_CRUSH = 1 shl 0; // Crushed by falling or moving object
  DMG_BULLET = 1 shl 1; // Shot
  DMG_SLASH = 1 shl 2; // Cut, clawed, stabbed
  DMG_BURN = 1 shl 3; // Heat burned
  DMG_FREEZE = 1 shl 4; // Frozen
  DMG_FALL = 1 shl 5; // Fell too far
  DMG_BLAST = 1 shl 6; // Explosive blast damage
  DMG_CLUB = 1 shl 7; // Crowbar, punch, headbutt
  DMG_SHOCK = 1 shl 8; // Electric shock
  DMG_SONIC = 1 shl 9; // Sound pulse shockwave
  DMG_ENERGYBEAM = 1 shl 10; // Laser or other high energy beam
  DMG_NEVERGIB = 1 shl 12; // With this bit OR'd in, no damage type will be able to gib victims upon death
  DMG_ALWAYSGIB = 1 shl 13; // With this bit OR'd in, any damage type can be made to gib victims upon death.
  DMG_DROWN = 1 shl 14; // Drowning
  DMG_PARALYZE = 1 shl 15; // Slows affected creature down
  DMG_NERVEGAS = 1 shl 16; // Nerve toxins, very bad
  DMG_POISON = 1 shl 17; // Blood poisioning
  DMG_RADIATION = 1 shl 18; // Radiation exposure
  DMG_DROWNRECOVER = 1 shl 19; // Drowning recovery
  DMG_ACID = 1 shl 20; // Toxic chemicals or acid burns
  DMG_SLOWBURN = 1 shl 21; // In an oven
  DMG_SLOWFREEZE = 1 shl 22; // In a subzero freezer
  DMG_MORTAR = 1 shl 23; // Hit by air raid (done to distinguish grenade from mortar)
  DMG_TIMEBASED = not $3FFF; //(~(0x3fff)) // Mask for time-based damage

// engfunc(EngFunc_PointContents, Float:origin) return values
const
  CONTENTS_EMPTY = -1;
  CONTENTS_SOLID = -2;
  CONTENTS_WATER = -3;
  CONTENTS_SLIME = -4;
  CONTENTS_LAVA = -5;
  CONTENTS_SKY = -6;
  CONTENTS_ORIGIN = -7; // Removed at csg time
  CONTENTS_CLIP = -8; // Changed to contents_solid
  CONTENTS_CURRENT_0 = -9;
  CONTENTS_CURRENT_90 = -10;
  CONTENTS_CURRENT_180 = -11;
  CONTENTS_CURRENT_270 = -12;
  CONTENTS_CURRENT_UP = -13;
  CONTENTS_CURRENT_DOWN = -14;
  CONTENTS_TRANSLUCENT = -15;
  CONTENTS_LADDER = -16;
  CONTENT_FLYFIELD = -17;
  CONTENT_GRAVITY_FLYFIELD = -18;
  CONTENT_FOG = -19;

// The fNoMonsters parameter of EngFunc_TraceLine, EngFunc_TraceMonsterHull, EngFunc_TraceHull, and EngFunc_TraceSphere
const
  DONT_IGNORE_MONSTERS = 0;
  IGNORE_MONSTERS = 1;
  IGNORE_MISSILE = 2;
  IGNORE_GLASS = $100;

// The hullnumber paramater of EngFunc_TraceHull, EngFunc_TraceModel and DLLFunc_GetHullBounds
const
  HULL_POINT = 0;
  HULL_HUMAN = 1;
  HULL_LARGE = 2;
  HULL_HEAD = 3;

// global_get(glb_trace_flags)
const
  FTRACE_SIMPLEBOX = 1shl 0; // Traceline with a simple box

// Used with get/set_es(es_handle, ES_eFlags, ...) (entity_state data structure)
const
  EFLAG_SLERP = 1; // Do studio interpolation of this entity

// pev(entity, pev_spawnflags) values
// Many of these flags apply to specific entities
// func_train
const
  SF_TRAIN_WAIT_RETRIGGER = 1;
  SF_TRAIN_START_ON = 4; // Train is initially moving
  SF_TRAIN_PASSABLE = 8; // Train is not solid -- used to make water trains

// func_wall_toggle
  SF_WALL_START_OFF = $0001;

// func_converyor
  SF_CONVEYOR_VISUAL = $0001;
  SF_CONVEYOR_NOTSOLID = $0002;

// func_button
  SF_BUTTON_DONTMOVE = 1;
  SF_BUTTON_TOGGLE = 32; // Button stays pushed until reactivated
  SF_BUTTON_SPARK_IF_OFF = 64; // Button sparks in OFF state
  SF_BUTTON_TOUCH_ONLY = 256; // Button only fires as a result of USE key.

// func_rot_button
  SF_ROTBUTTON_NOTSOLID = 1;

// env_global
  SF_GLOBAL_SET = 1; // Set global state to initial state on spawn

// multisource
  SF_MULTI_INIT = 1;

// momentary_rot_button
  SF_MOMENTARY_DOOR = $0001;

// button_target
  SF_BTARGET_USE = $0001;
  SF_BTARGET_ON = $0002;

// func_door, func_water, func_door_rotating, momementary_door
  SF_DOOR_ROTATE_Y = 0;
  SF_DOOR_START_OPEN = 1;
  SF_DOOR_ROTATE_BACKWARDS = 2;
  SF_DOOR_PASSABLE = 8;
  SF_DOOR_ONEWAY = 16;
  SF_DOOR_NO_AUTO_RETURN = 32;
  SF_DOOR_ROTATE_Z = 64;
  SF_DOOR_ROTATE_X = 128;
  SF_DOOR_USE_ONLY = 256; // Door must be opened by player's use button
  SF_DOOR_NOMONSTERS = 512; // Monster can't open
  SF_DOOR_SILENT = $80000000;

// gibshooter
  SF_GIBSHOOTER_REPEATABLE = 1; // Allows a gibshooter to be refired

// env_funnel
  SF_FUNNEL_REVERSE = 1; // Funnel effect repels particles instead of attracting them

// env_bubbles
  SF_BUBBLES_STARTOFF = $0001;

// env_blood
  SF_BLOOD_RANDOM = $0001;
  SF_BLOOD_STREAM = $0002;
  SF_BLOOD_PLAYER = $0004;
  SF_BLOOD_DECAL = $0008;

// env_shake
  SF_SHAKE_EVERYONE = $0001; // Don't check radius
  SF_SHAKE_DISRUPT = $0002; // Disrupt controls
  SF_SHAKE_INAIR = $0004; // Shake players in air

// env_fade
  SF_FADE_IN = $0001; // Fade in, not out
  SF_FADE_MODULATE = $0002; // Modulate, don't blend
  SF_FADE_ONLYONE = $0004;

// env_beam, env_lightning
  SF_BEAM_STARTON = $0001;
  SF_BEAM_TOGGLE = $0002;
  SF_BEAM_RANDOM = $0004;
  SF_BEAM_RING = $0008;
  SF_BEAM_SPARKSTART = $0010;
  SF_BEAM_SPARKEND = $0020;
  SF_BEAM_DECALS = $0040;
  SF_BEAM_SHADEIN = $0080;
  SF_BEAM_SHADEOUT = $0100;
  SF_BEAM_TEMPORARY = $8000;

// env_sprite
  SF_SPRITE_STARTON = $0001;
  SF_SPRITE_ONCE = $0002;
  SF_SPRITE_TEMPORARY = $8000;

// env_message
  SF_MESSAGE_ONCE = $0001; // Fade in, not out
  SF_MESSAGE_ALL = $0002; // Send to all clients

// env_explosion
  SF_ENVEXPLOSION_NODAMAGE = 1 shl 0; // When set, ENV_EXPLOSION will not actually inflict damage
  SF_ENVEXPLOSION_REPEATABLE = 1 shl 1; // Can this entity be refired?
  SF_ENVEXPLOSION_NOFIREBALL = 1 shl 2; // Don't draw the fireball
  SF_ENVEXPLOSION_NOSMOKE = 1 shl 3; // Don't draw the smoke
  SF_ENVEXPLOSION_NODECAL = 1 shl 4; // Don't make a scorch mark
  SF_ENVEXPLOSION_NOSPARKS = 1 shl 5; // Don't make a scorch mark

// func_tank
  SF_TANK_ACTIVE = $0001;
  SF_TANK_PLAYER = $0002;
  SF_TANK_HUMANS = $0004;
  SF_TANK_ALIENS = $0008;
  SF_TANK_LINEOFSIGHT = $0010;
  SF_TANK_CANCONTROL = $0020;
  SF_TANK_SOUNDON = $8000;

// grenade
  SF_DETONATE = $0001;

// item_suit
  SF_SUIT_SHORTLOGON = $0001;

// game_score
  SF_SCORE_NEGATIVE = $0001;
  SF_SCORE_TEAM = $0002;

// game_text
  SF_ENVTEXT_ALLPLAYERS = $0001;

// game_team_master
  SF_TEAMMASTER_FIREONCE = $0001;
  SF_TEAMMASTER_ANYTEAM = $0002;

// game_team_set
  SF_TEAMSET_FIREONCE = $0001;
  SF_TEAMSET_CLEARTEAM = $0002;

// game_player_hurt
  SF_PKILL_FIREONCE = $0001;

// game_counter
  SF_GAMECOUNT_FIREONCE = $0001;
  SF_GAMECOUNT_RESET = $0002;

// game_player_equip
  SF_PLAYEREQUIP_USEONLY = $0001;

// game_player_team
  SF_PTEAM_FIREONCE = $0001;
  SF_PTEAM_KILL = $0002;
  SF_PTEAM_GIB = $0004;

// func_trackchange
  SF_PLAT_TOGGLE = $0001;
  SF_TRACK_ACTIVATETRAIN = $00000001;
  SF_TRACK_RELINK = $00000002;
  SF_TRACK_ROTMOVE = $00000004;
  SF_TRACK_STARTBOTTOM = $00000008;
  SF_TRACK_DONT_MOVE = $00000010;

// func_tracktrain
  SF_TRACKTRAIN_NOPITCH = $0001;
  SF_TRACKTRAIN_NOCONTROL = $0002;
  SF_TRACKTRAIN_FORWARDONLY = $0004;
  SF_TRACKTRAIN_PASSABLE = $0008;
  SF_PATH_DISABLED = $00000001;
  SF_PATH_FIREONCE = $00000002;
  SF_PATH_ALTREVERSE = $00000004;
  SF_PATH_DISABLE_TRAIN = $00000008;
  SF_PATH_ALTERNATE = $00008000;
  SF_CORNER_WAITFORTRIG = $001;
  SF_CORNER_TELEPORT = $002;
  SF_CORNER_FIREONCE = $004;

// trigger_push
  SF_TRIGGER_PUSH_START_OFF = 2;            // Spawnflag that makes trigger_push spawn turned OFF

// trigger_hurt
  SF_TRIGGER_HURT_TARGETONCE = 1;            // Only fire hurt target once
  SF_TRIGGER_HURT_START_OFF = 2;            // Spawnflag that makes trigger_push spawn turned OFF
  SF_TRIGGER_HURT_NO_CLIENTS = 8;            // Spawnflag that makes trigger_push spawn turned OFF
  SF_TRIGGER_HURT_CLIENTONLYFIRE = 16;           // Trigger hurt will only fire its target if it is hurting a client
  SF_TRIGGER_HURT_CLIENTONLYTOUCH = 32;           // Only clients may touch this trigger

// trigger_auto
  SF_AUTO_FIREONCE = $0001;

// trigger_relay
  SF_RELAY_FIREONCE = $0001;

// multi_manager
  SF_MULTIMAN_CLONE = $80000000;
  SF_MULTIMAN_THREAD = $00000001;

// env_render - Flags to indicate masking off various render parameters that are normally copied to the targets
  SF_RENDER_MASKFX = 1 shl 0;
  SF_RENDER_MASKAMT = 1 shl 1;
  SF_RENDER_MASKMODE = 1 shl 2;
  SF_RENDER_MASKCOLOR = 1 shl 3;

// trigger_changelevel
  SF_CHANGELEVEL_USEONLY = $0002;

// trigger_endsection
  SF_ENDSECTION_USEONLY = $0001;

// trigger_camera
  SF_CAMERA_PLAYER_POSITION = 1;
  SF_CAMERA_PLAYER_TARGET = 2;
  SF_CAMERA_PLAYER_TAKECONTROL = 4;

// func_rotating
  SF_BRUSH_ROTATE_Y_AXIS = 0;
  SF_BRUSH_ROTATE_INSTANT = 1;
  SF_BRUSH_ROTATE_BACKWARDS = 2;
  SF_BRUSH_ROTATE_Z_AXIS = 4;
  SF_BRUSH_ROTATE_X_AXIS = 8;
  SF_PENDULUM_AUTO_RETURN = 16;
  SF_PENDULUM_PASSABLE = 32;
  SF_BRUSH_ROTATE_SMALLRADIUS = 128;
  SF_BRUSH_ROTATE_MEDIUMRADIUS = 256;
  SF_BRUSH_ROTATE_LARGERADIUS = 512;

// triggers
  SF_TRIGGER_ALLOWMONSTERS = 1; // Monsters allowed to fire this trigger
  SF_TRIGGER_NOCLIENTS = 2; // Players not allowed to fire this trigger
  SF_TRIGGER_PUSHABLES = 4; // Only pushables can fire this trigger

  SF_TRIG_PUSH_ONCE = 1;

// func_breakable
  SF_BREAK_TRIGGER_ONLY = 1; // May only be broken by trigger
  SF_BREAK_TOUCH = 2; // Can be 'crashed through' by running player (plate glass)
  SF_BREAK_PRESSURE = 4; // Can be broken by a player standing on it
  SF_BREAK_CROWBAR = 256; // Instant break if hit with crowbar

// func_pushable (it's also func_breakable, so don't collide with those flags)
  SF_PUSH_BREAKABLE = 128;

// light_spawn
  SF_LIGHT_START_OFF = 1;
  SPAWNFLAG_NOMESSAGE = 1;
  SPAWNFLAG_NOTOUCH = 1;
  SPAWNFLAG_DROIDONLY = 4;
  SPAWNFLAG_USEONLY = 1; // Can't be touched, must be used (buttons)

// Monster Spawnflags
  SF_MONSTER_WAIT_TILL_SEEN = 1; // Spawnflag that makes monsters wait until player can see them before attacking
  SF_MONSTER_GAG = 2; // No idle noises from this monster
  SF_MONSTER_HITMONSTERCLIP = 4;
  SF_MONSTER_PRISONER = 16; // Monster won't attack anyone, no one will attacke him
  SF_MONSTER_WAIT_FOR_SCRIPT = 128; // Spawnflag that makes monsters wait to check for attacking until the script is done or they've been attacked
  SF_MONSTER_PREDISASTER = 256; // This is a predisaster scientist or barney; influences how they speak
  SF_MONSTER_FADECORPSE = 512; // Fade out corpse after death
  SF_MONSTER_FALL_TO_GROUND = $80000000;
  SF_MONSTER_TURRET_AUTOACTIVATE = 32;
  SF_MONSTER_TURRET_STARTINACTIVE = 64;
  SF_MONSTER_WAIT_UNTIL_PROVOKED = 64; // Don't attack the player unless provoked

// info_decal
  SF_DECAL_NOTINDEATHMATCH = 2048;

// worldspawn
  SF_WORLD_DARK = $0001; // Fade from black at startup
  SF_WORLD_TITLE = $0002; // Display game title at startup
  SF_WORLD_FORCETEAM = $0004; // Force teams

// Set this bit on guns and stuff that should never respawn
  SF_NORESPAWN = 1 shl 30;


// custom
const
  SV_UPDATE_BACKUP = 8;
  SV_UPDATE_MASK = SV_UPDATE_BACKUP - 1;

//  CL_UPDATE_BACKUP =
//  CL_UPDATE_MASK = CL_UPDATE_BACKUP - 1;

  CMD_MAXBACKUP = 28; // confirmed
  MAX_GMSG_LENGTH = 192;
  MAX_MOTD_TEXT_LENGTH = MAX_GMSG_LENGTH - 2;
  MAX_SHOWMENU_TEXT_LENGTH = MAX_GMSG_LENGTH - 5;
  MAX_NET_MESSAGE_LENGTH = 1400;
  DEFAULT_FRAGMENT_SIZE = 512;
  DEFAULT_FRAGMENT_COMPRESSION_STATE = True;
  MAX_DYN_ENTITIES = 1060;
  MAX_RESOURCE_NAME = 64;
  MAX_USERINFO_LENGTH = 256;
  MAX_UNITS = 8192;
  MAX_WEAPONS = 32;
  MAX_PLAYER_NAME = 32;

  HUMAN_HEIGHT = 36;
  HUMAN_HEIGHT_HALF = HUMAN_HEIGHT div 2;

  HUMAN_HEIGHT_STAND = HUMAN_HEIGHT;
  HUMAN_HEIGHT_DUCK = HUMAN_HEIGHT_STAND div 2;

  HUMAN_WIDTH = 32;
  HUMAN_WIDTH_HALF = HUMAN_WIDTH div 2;

  FLASHBAT_MAX = 100;

// vgui menu indexes
const
  VGUI_CHOOSE_TEAM = 2; // cs, cz, tfc
  VGUI_CHOOSE_CLASS_TFC = 3; // tfc
  VGUI_CHOOSE_CLASS_ALLIES = 10; // dod
  VGUI_CHOOSE_CLASS_BRITISH = 12; // dod
  VGUI_CHOOSE_CLASS_AXIS = 13; // dod
  VGUI_CHOOSE_MODEL_T = 26; // cs, cz
  VGUI_CHOOSE_MODEL_CT = 27; // cs, cz

const
  TUTORTEXT_TYPE_DEFAULT = 1 shl 0; // 1<<0 | GREEN  | INFO
  TUTORTEXT_TYPE_FRIENDDEATH = 1 shl 1; // 1<<1 | RED    | SKULL
  TUTORTEXT_TYPE_ENEMYDEATH = 1 shl 2; // 1<<2 | BLUE   | SKULL
  TUTORTEXT_TYPE_SCENARIO = 1 shl 3; // 1<<3 | YELLOW | INFO
  TUTORTEXT_TYPE_BUY = 1 shl 4; // 1<<4 | GREEN  | INFO
  TUTORTEXT_TYPE_CAREER = 1 shl 5; // 1<<5 | GREEN  | INFO
  TUTORTEXT_TYPE_HINT = 1 shl 6; // 1<<6 | GREEN  | INFO
  TUTORTEXT_TYPE_INGAMEHINT = 1 shl 7; // 1<<7 | GREEN  | INFO
  TUTORTEXT_TYPE_ENDGAME = 1 shl 8; // 1<<8 | YELLOW | INFO

const
  SCORE_ATTRIB_FLAG_DEAD = 1 shl 0;
  SCORE_ATTRIB_FLAG_BOMB = 1 shl 1;
  SCORE_ATTRIB_FLAG_VIP = 1 shl 2;

const
  MENU_KEY_1 = 1 shl 0;
  MENU_KEY_2 = 1 shl 1;
  MENU_KEY_3 = 1 shl 2;
  MENU_KEY_4 = 1 shl 3;
  MENU_KEY_5 = 1 shl 4;
  MENU_KEY_6 = 1 shl 5;
  MENU_KEY_7 = 1 shl 6;
  MENU_KEY_8 = 1 shl 7;
  MENU_KEY_9 = 1 shl 8;
  MENU_KEY_0 = 1 shl 9;

  MENU_KEY_ANY = MENU_KEY_1 or MENU_KEY_2 or MENU_KEY_3 or MENU_KEY_4 or MENU_KEY_5
   or MENU_KEY_6 or MENU_KEY_7 or MENU_KEY_8 or MENU_KEY_9 or MENU_KEY_0;

  MENU_MAX_TIME = MaxUInt8;

const
  FFADE_IN = 0; // Just here so we don't pass 0 into the function
  FFADE_OUT = 1 shl 0; // Fade out (not in)
  FFADE_MODULATE = 1 shl 1; // Modulate (don't blend)
  FFADE_STAYOUT = 1 shl 2; // ignores the duration, stays faded out until new ScreenFade message received

// 0x01 (SOH) - Use normal color from this point forward
// 0x02 (STX) - Use team color up to the end of the player name.  This only works at the start of the LStr, and precludes using the other control characters.
// 0x03 (ETX) - Use team color from this point forward
// 0x04 (EOT) - Use green color from this point forward

  TEXT_COLOR_NORMAL = 1;
  TEXT_COLOR_TEAM_END = 2;
  TEXT_COLOR_TEAM = 3;
  TEXT_COLOR_GREEN = 4;

const
  HIDEHUD_WEAPONS = 1 shl 0; // crosshair, ammo, weapons list
  HIDEHUD_FLASHLIGHT = 1 shl 1; // flashlight
  HIDEHUD_ALL = 1 shl 2; // all
  HIDEHUD_HEALTH = 1 shl 3; // radar, health, armor, +
  HIDEHUD_TIMER = 1 shl 4; // timer, +
  HUDEHUD_MONEY = 1 shl 5; // money, +
  HIDEHUD_CROSSHAIR = 1 shl 6; // crosshair
  HIDEHUD_7 = 1 shl 7; // + <- ?

type
  TParticle = record
    Origin, Direction: TVec3F;
    Count, Color: UInt8;
  end;
{$ENDREGION}

{$REGION 'Teams'}
type
  PTeam = ^TTeam;
  TTeam = record
    Name: LStr;
    Score: Int16;
    Deaths: Int16; // tfc use it
  end;

  PTeams = ^TTeams;
  TTeams = array of TTeam;
{$ENDREGION}

{$REGION 'Players'}
type
  TCSPlayerTeam = (
    CS_TEAM_NONE = 0,   // unassigned
    CS_TEAM_T,
    CS_TEAM_CT,
    CS_TEAM_SPECTATOR);

  TTFCPlayerTeam = (
    TFC_TEAM_NONE = 0,
    TFC_TEAM_BLUE,
    TFC_TEAM_RED
    // yellow and .. ?
    {TFC_TEAM_SPECTATOR});

  PPlayer = ^TPlayer;
  TPlayer = record
    // from svc msgs
    UserID: Int32;
    UserInfo: LStr;
    MD5: TMD5Digest;
    Kills, Deaths, Ping, Loss: Int32;
    Entity: PEntity;

    // from gmsgs
    Team: LStr;
    ClassID, TeamID: Int16;

    // - cstrike
    Health: UInt8; // event hltv
    ScoreAttrib: UInt8; // event scoreattrib
    Location: LStr; // event location
    Radar: TVec3F; // event radar

    // utils
    function GetOrigin: TVec3F; // for radar usage

    function GetHeadOrigin: TVec3F;
    function GetFootOrigin: TVec3F;

    function GetName: LStr;
    function GetStatus(AEngine: TEngineType): LStr;
    function GetLatency: LStr;
    function GetTeam(AEngine: TEngineType): LStr;

    function IsCSAlive: Boolean;
    function IsCSBomber: Boolean;
    function IsCSVIP: Boolean;

    function GetCSPlayerTeam: TCSPlayerTeam;
    function GetTFCPlayerTeam: TTFCPlayerTeam;
    function GetPlayerColor(AEngine: TEngineType; CheckForDead: Boolean = False; CheckForBomb: Boolean = False; CheckForVIP: Boolean = False): TColor;
  end;

  {PCSPlayerInfo = ^TCSPlayerInfo;
  TCSPlayerInfo = packed record
    Kills, Deaths: Int16;
    ClassID, IsVIP, HasBomb: Int32;
    Radar: TVec3F;
    UpdateCount, MinUpdate, MaxUpdate: Int32;
    SBarTeam, Team: Int16;
    TeamName: LStr;
    IsDead: Int32;
    NextUpdateTime: Float;
    Health: Int32;
    Location: LStr;
  end;}
{$ENDREGION}

{$REGION 'Types'}
type
  TServerState = (
    SS_NONE,
    SS_CONNECTION_ACCEPTED,
    SS_SPAWNED,
    SS_GAME);

  TClientState = (
    CS_NONE = 0,
    CS_HTTP_DOWNLOADING,
    CS_DISCONNECTED,
    CS_WAIT_CHALLENGE,
    CS_CONNECTING,
    CS_CONNECTION_ACCEPTED,
    CS_VERIFYING_RESOURCES, // or downloading resources
    CS_SPAWNED,
    CS_GAME);

  TSimplePlayer = record
    Slot: UInt8;
    Name: LStr;
    Kills: Int32;
    Time: Float;
  end;

  TSimpleRule = record
    CVar, Value: LStr;
  end;

  TBombState = record
    Active: Boolean; // EBombPickup disables it
    Position: TVec3F;
    IsPlanted: Boolean;
  end;

  TAuthType = (
    AUTH_UNDEFINED = 0,
    AUTH_HLTV = 1,
    AUTH_NON_STEAM = 2,
    AUTH_STEAM = 3,
    AUTH_NON_STEAM_WON = 4);

  TDeathMsg = record
    Killer,
    Victim: PPlayer;
    IsHeadshot: Boolean;
    Weapon: LStr;
  end;

  TTextMsg = record
    DType: UInt8;
    Data, S1, S2, S3, S4: LStr;
  end;

  TSimpleMenu = record
    Keys: Int16;
    Time: UInt8;
    Data: LStr;
  end;

  TVGUIMenu = record
    Index: UInt8;
    Keys: Int16;
    Time: UInt8;
    Name: LStr;
  end;

  TSayText = record
    Player: PPlayer;
    S1, S2, S3, S4: LStr;
  end;

  TServerInfo = record
    Protocol: Int32;
    SpawnCount: Int32;
    MapCheckSum: Int32;
    DLLCRC: LStr;
    MaxPlayers: UInt8;
    Index: UInt8;    // your slot at server
    //unk_byte1: Uint8;
    GameDir: LStr;
    Name: LStr;
    Map: LStr;
    MapList: LStr;
    //unk_byte2: UInt8;

    function ResolveMapName: LStr;
  end;

  TExtraInfo = record
    FallbackDir: LStr;
    AllowCheats: Boolean;
  end;

  TSimpleServerInfo = record
    Address: LStr;
    Name: LStr;
    Map: LStr;
    Folder: LStr;
    Game: LStr;
    Players: UInt8;
    MaxPlayers: UInt8;
    Protocol: UInt8;
    ServerType: UInt8;
    Environment: UInt8;
    Visibility: Boolean;
    HMod: UInt8;
      Link: LStr;   // URL to mod website.
      DownloadLink: LStr;  // URL to download the mod.
      NByte: UInt8;  // NULL byte (0x00)
      Version: Int32;  // Version of mod installed on server.
      Size: Int32;  // Space (in bytes) the mod takes up.
      HType: UInt8;  // Indicates the type of mod:
                     // 0 for Float and multiplayer mod
                     // 1 for multiplayer only mod
      HDLL: UInt8;  // Indicates whether mod uses its own DLL:
                     // 0 if it uses the Half-Life DLL
                     // 1 if it uses its own DLL
    VAC: Boolean;
    Bots: UInt8;
    GameVersion: LStr;
  end;

  TScreenShake = record
    Amplitude, Duration, Frequency: UInt16;
  end;

  TScreenFade = record
    Duration, HoldTime: UInt16;
    StartTime: UInt32; // custom
    Flags: UInt16;
    Color: TRGBA;
  end;

type
  TMoveVars = record
    Gravity, StopSpeed, MaxSpeed, SpectatorMaxSpeed, Accelerate, AirAccelerate, WaterAccelerate,
    Friction, EdgeFriction, WaterFriction, EntGravity, Bounce, StepSize, MaxVelocity, ZMax,
    WaveHeight: Float;
    Footsteps: Int32;
    SkyName: LStr;
    RollAngle, RollSpeed, SkyColorR, SkyColorG, SkyColorB: Float;
    SkyVec: TVec3F;
  end;

  PClientInfo = ^TClientInfo;
  TClientInfo = record
    Protocol: Byte;
    Challenge: LStr;
    ProtInfo: LStr;
    UserInfo: LStr;
    Certificate: LStr;
    AuthType: TAuthType;
    Name: LStr;
  end;

type
  TProtType = (
    PT_HLTV = 2,
    PT_STEAM = 3);

  TTitle = record
    Name: LStr;
    Data: LStr;
    NamePos: LongInt;
  end;

  TMenuCallBack = procedure(Key: UInt16) of object;

  PStatusIcon = ^TStatusIcon;
  TStatusIcon = record
    Status: UInt8;
    Name: LStr;
    Color: TRGB;
  end;

  PStatusIcons = ^TStatusIcons;
  TStatusIcons = array of TStatusIcon;
  {$ENDREGION}

// huge data

  {$REGION 'Game Titles Table'}
const
  GameTitles: array[1..294] of TTitle = (
  (Name: '#Game_connected'; Data: '%s connected'),
  (Name: '#Game_disconnected'; Data: '%s has left the game'),
  (Name: '#Game_bomb_drop'; Data: '%s dropped the bomb'),
  (Name: '#Game_bomb_pickup'; Data: '%s picked up the bomb'),
  (Name: '#Game_join_terrorist_auto'; Data: '%s is joining the Terrorist force (auto)'),
  (Name: '#Game_join_ct_auto'; Data: '%s is joining the Counter-Terrorist force (auto)'),

  (Name: '#Game_join_terrorist'; Data: '%s is joining the Terrorist force'),
  (Name: '#Game_join_ct'; Data: '%s is joining the Counter-Terrorist force'),

  (Name: '#Game_scoring'; Data: 'Scoring will not start until both teams have players'),

  (Name : '#Game_radio_location'; Data: '%s @ %s (RADIO): %s'; NamePos: 0),  // cz
  (Name : '#Cstrike_Chat_CT_Loc'; Data: '(Counter-Terrorist) %s @ %s : %s'; NamePos: 20),  // cz
  (Name : '#Cstrike_Chat_T_Loc'; Data: '(Terrorist) %s @ %s : %s'; NamePos: 12),  // cz

  (Name: '#Game_radio'; Data: '%s (RADIO): %s'; NamePos: 0),
  (Name: '#Cstrike_Chat_CT_Dead'; Data: '*DEAD* (Counter-Terrorist) %s : %s'; NamePos: 27),
  (Name: '#Cstrike_Chat_T_Dead'; Data: '*DEAD* (Terrorist) %s : %s'; NamePos: 19),
  (Name: '#Cstrike_Chat_Spec'; Data: '(Spectator) %s : %s'; NamePos: 12),
  (Name: '#Cstrike_Chat_AllDead'; Data: '*DEAD* %s : %s'; NamePos: 7),
  (Name: '#Cstrike_Chat_AllSpec'; Data: '*SPEC* %s : %s'; NamePos: 7),
  (Name: '#Cstrike_Name_Change'; Data: '%s changed name to %s'; NamePos: 0),

  (Name: '#Cstrike_Chat_CT'; Data: '(Counter-Terrorist) %s : %s'; NamePos: 20),
  (Name: '#Cstrike_Chat_T'; Data: '(Terrorist) %s : %s'; NamePos: 12),
  (Name: '#Cstrike_Chat_All'; Data: '%s : %s'; NamePos: 0),

  (Name: '#Cover_me'; Data: 'Cover Me!'),
  (Name: '#You_take_the_point'; Data: 'You Take the Point.'),
  (Name: '#Hold_this_position'; Data: 'Hold This Position.'),
  (Name: '#Regroup_team'; Data: 'Regroup Team.'),
  (Name: '#Follow_me'; Data: 'Follow Me.'),
  (Name: '#Taking_fire'; Data: 'Taking Fire...Need Assistance!'),
  (Name: '#Go_go_go'; Data: 'Go go go!'),
  (Name: '#Team_fall_back'; Data: 'Team, fall back!'),
  (Name: '#Stick_together_team'; Data: 'Stick together, team.'),
  (Name: '#Get_in_position_and_wait'; Data: 'Get in position and wait for my go.'),
  (Name: '#Storm_the_front'; Data: 'Storm the Front!'),
  (Name: '#Report_in_team'; Data: 'Report in, team.'),
  (Name: '#Affirmative'; Data: 'Affirmative.'),
  (Name: '#Roger_that'; Data: 'Roger that.'),
  (Name: '#Enemy_spotted'; Data: 'Enemy spotted.'),
  (Name: '#Need_backup'; Data: 'Need backup.'),
  (Name: '#Sector_clear'; Data: 'Sector clear.'),
  (Name: '#In_position'; Data: 'I''m in position.'),
  (Name: '#Reporting_in'; Data: 'Reporting in.'),
  (Name: '#Get_out_of_there'; Data: 'Get out of there, it''s gonna blow!'),
  (Name: '#Negative'; Data: 'Negative.'),
  (Name: '#Enemy_down'; Data: 'Enemy down.'),
  (Name: '#Hostage_down'; Data: 'Hostage down.'),
  (Name: '#Fire_in_the_hole'; Data: 'Fire in the hole!'),

  (Name: '#Game_teammate_attack'; Data: '%s attacked a teammate'; NamePos: 0),
  (Name: '#Game_teammate_kills'; Data: 'Teammate kills: %s of 3';),
  (Name: '#Game_required_votes'; Data: 'Required number of votes for a new map = %s'),
  (Name: '#Game_unknown_command'; Data: 'Unknown command: %s'),
  (Name: '#Game_will_restart_in_console'; Data: 'The game will restart in %s %s'),

  (Name: '#Name_change_at_respawn'; Data: 'Your name will be changed after your next respawn.'),
  (Name: '#Game_timelimit'; Data: 'Time Remaining: %s:%s'),

  //25 Aug 2014
  (Name: '#CTs_Win'; Data: 'Counter-Terrorists Win!'),
  (Name: '#Terrorists_Win'; Data: 'Terrorists Win!'),
  (Name: '#Bomb_Defused'; Data: 'The bomb has been defused!'),
  (Name: '#Bomb_Planted'; Data: 'The bomb has been planted!'),
  (Name: '#Spec_Help_Title'; Data: 'Spectator Mode'),
  (Name: '#Spec_ListPlayers'; Data: 'List Players'),
  (Name: '#Spec_Map'; Data: 'Map'),
  (Name: '#Spec_Mode1'; Data: 'Locked Chase Cam'),
  (Name: '#Spec_Mode2'; Data: 'Free Chase Cam'),
  (Name: '#Spec_Mode3'; Data: 'Free Look'),
  (Name: '#Spec_Mode4'; Data: 'First Person'),
  (Name: '#Spec_Mode5'; Data: 'Free Overview'),
  (Name: '#Spec_Mode6'; Data: 'Chase Overview'),
  (Name: '#Spec_NoPlayers'; Data: 'No Players to Spectate'),
  (Name: '#Spec_NoTarget'; Data: 'No valid targets. Cannot switch to Chase-Camera Mode.'),
  (Name: '#Spec_No_PIP'; Data: 'Picture-In-Picture is not available in First-Person mode while playing.'),

  (Name: '#Target_Bombed'; Data: 'Target Successfully Bombed!'),
  (Name: '#Target_Saved'; Data:	'Target has been saved!'),
  (Name: '#Game_Commencing'; Data: 'Game Commencing!'),
  (Name: '#Auto_Team_Balance_Next_Round'; Data: '*** Auto-Team Balance next round ***'),

  (Name: '#Round_Draw'; Data: 'Round Draw!'),
  (Name: '#Command_Not_Available'; Data: 'This command is not available to you at this point'),

  (Name: '#Hostages_Not_Rescued'; Data: 'Hostages have not been rescued!'),
  (Name: '#All_Hostages_Rescued'; Data: 'All Hostages have been rescued!'),

  (Name: '#Game_will_restart_in'; Data:	'The game will restart in %s %s'),
  (Name: '#Only_1_Team_Change'; Data:	'Only 1 team change is allowed.'),

  (Name: '#C4_Plant_At_Bomb_Spot'; Data: 'C4 must be planted at a bomb site!'),
  (Name: '#Cant_buy'; Data: '%s seconds have passed. You can''t buy anything now!'),

  // cz strings
  (Name: '#BombsiteA'; Data: 'Bombsite A'),
  (Name: '#BombsiteB'; Data: 'Bombsite B'),
  (Name: '#BombsiteC'; Data: 'Bombsite C'),
  (Name: '#Hostages'; Data: 'Hostages'),
  (Name: '#HostageRescueZone'; Data: 'Hostage Rescue Zone'),
  (Name: '#VipRescueZone'; Data: 'VIP Rescue Zone'),
  (Name: '#CTSpawn'; Data: 'CT Spawn'),
  (Name: '#TSpawn'; Data: 'T Spawn'),
  (Name: '#Bridge'; Data: 'Bridge'),
  (Name: '#Middle'; Data: 'Middle'),
  (Name: '#House'; Data: 'House'),
  (Name: '#Apartment'; Data: 'Apartment'),
  (Name: '#Apartments'; Data: 'Apartments'),
  (Name: '#Market'; Data: 'Market'),
  (Name: '#Sewers'; Data: 'Sewers'),
  (Name: '#Tunnel'; Data: 'Tunnel'),
  (Name: '#Ducts'; Data: 'Ducts'),
  (Name: '#Village'; Data: 'Village'),
  (Name: '#Roof'; Data: 'Roof'),
  (Name: '#Upstairs'; Data: 'Upstairs'),
  (Name: '#Downstairs'; Data: 'Downstairs'),
  (Name: '#Basement'; Data: 'Basement'),
  (Name: '#Crawlspace'; Data: 'Crawlspace'),
  (Name: '#Kitchen'; Data: 'Kitchen'),
  (Name: '#Inside'; Data: 'Inside'),
  (Name: '#Outside'; Data: 'Outside'),
  (Name: '#Tower'; Data: 'Tower'),
  (Name: '#WineCellar'; Data: 'Wine Cellar'),
  (Name: '#Garage'; Data: 'Garage'),
  (Name: '#Courtyard'; Data: 'Courtyard'),
  (Name: '#Water'; Data: 'Water'),
  (Name: '#FrontDoor'; Data: 'Front Door'),
  (Name: '#BackDoor'; Data: 'Back Door'),
  (Name: '#SideDoor'; Data: 'Side Door'),
  (Name: '#BackWay'; Data: 'Back Way'),
  (Name: '#FrontYard'; Data: 'Front Yard'),
  (Name: '#BackYard'; Data: 'Back Yard'),
  (Name: '#SideYard'; Data: 'Side Yard'),
  (Name: '#Lobby'; Data: 'Lobby'),
  (Name: '#Vault'; Data: 'Vault'),
  (Name: '#Elevator'; Data: 'Elevator'),
  (Name: '#DoubleDoors'; Data: 'Double Doors'),
  (Name: '#SecurityDoors'; Data: 'Security Doors'),
  (Name: '#LongHall'; Data: 'Long Hall'),
  (Name: '#SideHall'; Data: 'Side Hall'),
  (Name: '#FrontHall'; Data: 'Front Hall'),
  (Name: '#BackHall'; Data: 'Back Hall'),
  (Name: '#MainHall'; Data: 'Main Hall'),
  (Name: '#FarSide'; Data: 'Far Side'),
  (Name: '#Windows'; Data: 'Windows'),
  (Name: '#Window'; Data: 'Window'),
  (Name: '#Attic'; Data: 'Attic'),
  (Name: '#StorageRoom'; Data: 'Storage Room'),
  (Name: '#ProjectorRoom'; Data: 'Projector Room'),
  (Name: '#MeetingRoom'; Data: 'Meeting Room'),
  (Name: '#ConferenceRoom'; Data: 'Conference Room'),
  (Name: '#ComputerRoom'; Data: 'Computer Room'),
  (Name: '#BigOffice'; Data: 'Big Office'),
  (Name: '#LittleOffice'; Data: 'Little Office'),
  (Name: '#Dumpster'; Data: 'Dumpster'),
  (Name: '#Airplane'; Data: 'Airplane'),
  (Name: '#Underground'; Data: 'Underground'),
  (Name: '#Bunker'; Data: 'Bunker'),
  (Name: '#Mines'; Data: 'Mines'),
  (Name: '#Front'; Data: 'Front'),
  (Name: '#Back'; Data: 'Back'),
  (Name: '#Rear'; Data: 'Rear'),
  (Name: '#Side'; Data: 'Side'),
  (Name: '#Ramp'; Data: 'Ramp'),
  (Name: '#Underpass'; Data: 'Underpass'),
  (Name: '#Overpass'; Data: 'Overpass'),
  (Name: '#Stairs'; Data: 'Stairs'),
  (Name: '#Ladder'; Data: 'Ladder'),
  (Name: '#Gate'; Data: 'Gate'),
  (Name: '#GateHouse'; Data: 'Gate House'),
  (Name: '#LoadingDock'; Data: 'Loading Dock'),
  (Name: '#GuardHouse'; Data: 'Guard House'),
  (Name: '#Entrance'; Data: 'Entrance'),
  (Name: '#VendingMachines'; Data: 'Vending Machines'),
  (Name: '#Loft'; Data: 'Loft'),
  (Name: '#Balcony'; Data: 'Balcony'),
  (Name: '#Alley'; Data: 'Alley'),
  (Name: '#BackAlley'; Data: 'Back Alley'),
  (Name: '#SideAlley'; Data: 'Side Alley'),
  (Name: '#FrontRoom'; Data: 'Front Room'),
  (Name: '#BackRoom'; Data: 'Back Room'),
  (Name: '#SideRoom'; Data: 'Side Room'),
  (Name: '#Crates'; Data: 'Crates'),
  (Name: '#Truck'; Data: 'Truck'),
  (Name: '#Bedroom'; Data: 'Bedroom'),
  (Name: '#FamilyRoom'; Data: 'Family Room'),
  (Name: '#Bathroom'; Data: 'Bathroom'),
  (Name: '#LivingRoom'; Data: 'Living Room'),
  (Name: '#Den'; Data: 'Den'),
  (Name: '#Office'; Data: 'Office'),
  (Name: '#Atrium'; Data: 'Atrium'),
  (Name: '#Entryway'; Data: 'Entryway'),
  (Name: '#Foyer'; Data: 'Foyer'),
  (Name: '#Stairwell'; Data: 'Stairwell'),
  (Name: '#Fence'; Data: 'Fence'),
  (Name: '#Deck'; Data: 'Deck'),
  (Name: '#Porch'; Data: 'Porch'),
  (Name: '#Patio'; Data: 'Patio'),
  (Name: '#Wall'; Data: 'Wall'),

  (Name: '#Got_bomb'; Data: 'You picked up the bomb!'),

  (Name: '#Game_idle_kick'; Data: '%s has been idle for too long and has been kicked'),
  (Name: '#C4_Plant_Must_Be_On_Ground'; Data: 'You must be standing on the ground to plant the C4!'),

  // tfc teams

  (Name: '#Team_Blue'; Data: 'Blue'),
  (Name: '#Team_Red'; Data: 'Red'),
  (Name: '#Team_Green'; Data: 'Green'),
  (Name: '#Team_Yellow'; Data: 'Yellow'),
  (Name: '#Hunted_team1'; Data: 'The Hunted'),
  (Name: '#Hunted_team2'; Data: 'Bodyguards'),
  (Name: '#Hunted_team3'; Data: 'Assassins'),
  (Name: '#Dustbowl_team1'; Data: 'Attackers'),
  (Name: '#Dustbowl_team2'; Data: 'Defenders'),

  (Name: '#Terrorists_Full'; Data: 'The terrorist team is full!'),
  (Name: '#All_Teams_Full'; Data: 'All teams are full!'),
  (Name: '#CTs_Full'; Data: 'The CT team is full!'),

  // DOD

  (Name: '#class_allied_garand'; Data: 'Rifleman'),
  (Name: '#class_allied_carbine'; Data: 'Staff Sergeant'),
  (Name: '#class_allied_thompson'; Data: 'Master Sergeant'),
  (Name: '#class_allied_grease'; Data: 'Sergeant'),
  (Name: '#class_allied_sniper'; Data: 'Sniper'),
  (Name: '#class_allied_heavy'; Data: 'Support Infantry'),
  (Name: '#class_allied_mg'; Data: 'Machine Gunner'),
  (Name: '#class_allied_bazooka'; Data: 'Bazooka'),
  (Name: '#class_allied_mortar'; Data: 'Mortar'),

  (Name: '#class_axis_kar98'; Data: 'Grenadier'),
  (Name: '#class_axis_k43'; Data: 'Stosstruppe'),
  (Name: '#class_axis_mp40'; Data: 'Unteroffizier'),
  (Name: '#class_axis_mp44'; Data: 'Sturmtruppe'),
  (Name: '#class_axis_sniper'; Data: 'Scharfschutze'),
  (Name: '#class_axis_mg34'; Data: 'MG34-Schutze'),
  (Name: '#class_axis_mg42'; Data: 'MG42-Schutze'),
  (Name: '#class_axis_pschreck'; Data: 'Panzerjager'),
  (Name: '#class_axis_mortar'; Data: 'Morserschutze'),

  (Name: '#class_brit_light'; Data: 'Rifleman'),
  (Name: '#class_brit_medium'; Data: 'Sergeant Major'),
  (Name: '#class_brit_sniper'; Data: 'Marksman'),
  (Name: '#class_brit_heavy'; Data: 'Gunner'),
  (Name: '#class_brit_piat'; Data: 'PIAT'),
  (Name: '#class_brit_mortar'; Data: 'Mortar'),

  (Name: '#class_alliedpara_garand'; Data: 'Rifleman'),
  (Name: '#class_alliedpara_carbine'; Data: 'Staff Sergeant'),
  (Name: '#class_alliedpara_thompson'; Data: 'Master Sergeant'),
  (Name: '#class_alliedpara_grease'; Data: 'Sergeant'),
  (Name: '#class_alliedpara_spring'; Data: 'Sniper'),
  (Name: '#class_alliedpara_bar'; Data: 'Support Infantry'),
  (Name: '#class_alliedpara_30cal'; Data: 'Machine Gunner'),
  (Name: '#class_alliedpara_bazooka'; Data: 'Bazooka'),
  (Name: '#class_alliedpara_mortar'; Data: 'Mortar'),
  (Name: '#class_alliedpara_random'; Data: 'Random'),

  (Name: '#class_axispara_kar98'; Data: 'Grenadier'),
  (Name: '#class_axispara_k43'; Data: 'Stosstruppe'),
  (Name: '#class_axispara_scopedkar'; Data: 'Scharfschutze'),
  (Name: '#class_axispara_mp40'; Data: 'Unteroffizier'),
  (Name: '#class_axispara_mp44'; Data: 'Sturmtruppe'),
  (Name: '#class_axispara_fg42bipod'; Data: 'Fg42-Zweibein'),
  (Name: '#class_axispara_fg42scope'; Data: 'Fg42-Zielfernrohr'),
  (Name: '#class_axispara_mg34'; Data: 'MG34-Schutze'),
  (Name: '#class_axispara_mg42'; Data: 'MG42-Schutze'),
  (Name: '#class_axispara_pschreck'; Data: 'Panzerjager'),
  (Name: '#class_axispara_mortar'; Data: 'Morserschutze'),

  (Name: '#class_random'; Data: 'Random'),
  (Name: '#class_random_para'; Data: 'Random'),

  (Name: '#game_no_spawns'; Data: 'No free spawnpoints. Will re-check every 1 sec.'),
  (Name: '#game_bogus_round'; Data: 'This round will not count, not enough players'),
  (Name: '#game_not_enough'; Data: 'Not enough players available. Next check in 20 seconds'),
  (Name: '#game_joined_game'; Data: '%s has joined the game'),
  (Name: '#game_disconnected'; Data: '%s has left the game'),
  (Name: '#game_joined_team'; Data: '*%s joined %s'),
  (Name: '#game_kick_tk'; Data: '%s has team killed too many times. Now being kicked!'),
  (Name: '#game_has_object'; Data: '%s has %s!'),
  (Name: '#game_lost_object'; Data: '%s lost %s!'),
  (Name: '#game_capture_object'; Data: '%s captured %s!'),
  (Name: '#game_left_object'; Data: '(1 object to go!)'),
  (Name: '#game_left_plural_object'; Data: '(%s objects to go!)'),
  (Name: '#game_score_allie_point'; Data: 'Allies score 1 point'),
  (Name: '#game_score_allie_points'; Data: 'Allies score %s points'),
  (Name: '#game_score_axis_point'; Data: 'Axis score 1 point'),
  (Name: '#game_score_axis_points'; Data: 'Axis score %s points'),
  (Name: '#game_capture_broken_allie'; Data: 'Allies capture broken'),
  (Name: '#game_capture_broken_axis'; Data: 'Axis capture broken'),
  (Name: '#game_time_left1'; Data: 'Time left:  %s:%s'),
  (Name: '#game_time_left2'; Data: 'No time limit set on server'),
  (Name: '#game_chat_on'; Data: 'Chat turned ON'),
  (Name: '#game_chat_off'; Data: 'Chat turned OFF'),
  (Name: '#game_deathmsg_on'; Data: 'Death messages turned ON'),
  (Name: '#game_deathmsg_off'; Data: 'Death messages turned OFF'),
  (Name: '#game_dont_cheat'; Data: 'Please dont cheat!'),
  (Name: '#game_unknown_command'; Data: 'Unknown command: %s'),
  (Name: '#game_cant_change_name'; Data: 'Not allowed to change name when dead or spectating!'),
  (Name: '#game_nextmap'; Data: 'Next map : %s'),
  (Name: '#game_spawn_as'; Data: '*You will spawn as %s'),
  (Name: '#game_respawn_as'; Data: '*You will respawn as %s'),
  (Name: '#game_spawn_asrandom'; Data: '*You will spawn as random class'),
  (Name: '#game_respawn_asrandom'; Data: '*You will respawn as a random class'),
  (Name: '#game_now_as'; Data: '*Your player class is now: %s'),
  (Name: '#game_will_spawn'; Data: '*You will respawn when you have selected a class'),

  (Name: '#game_roundstart_allie1'; Data: 'Platoon, move out and stay low!'),
  (Name: '#game_roundstart_allie2'; Data: 'Squad, charge your weapons we''re moving up!'),
  (Name: '#game_roundstart_brit1'; Data: 'Platoon, move out and stay low!'),
  (Name: '#game_roundstart_brit2'; Data: 'Squad, charge your weapons we''re moving up!'),
  (Name: '#game_roundstart_axis1'; Data: 'Disembark and prepare for the attack!'),
  (Name: '#game_roundstart_axis2'; Data: 'Go! Go! Prepare for the assault!'),
  (Name: '#game_class_limit'; Data: '*Server has reached the limit of number of %s'),
  (Name: '#game_changed_name'; Data: '* %s changed name to %s'),
  (Name: '#game_shoulder_pschreck'; Data: 'You must shoulder your Panzerschreck to fire!'),
  (Name: '#game_shoulder_piat'; Data: 'You must shoulder your Piat to fire!'),
  (Name: '#game_shoulder_bazooka'; Data: 'You must shoulder your Bazooka to fire!'),
  (Name: '#game_cannot_drop'; Data: 'You cannot drop this weapon.'),
  (Name: '#game_cannot_drop_while'; Data: 'You cannot drop this weapon while it is deployed.'));
  {$ENDREGION}

  {$REGION 'Shared'}
function FindGameTitleByName(Data: LStr): Int32;

// teams
function FindTeamByName(ATeams: PTeams; AName: LStr): PTeam;

function GetMenuKeyIndex(Key: UInt8): Int16;
function ResolveFileNameExtention(Data: LStr; Separator: LChar = '/'): LStr;
function ResolveFileExtention(Data: LStr): LStr;

function GetEngineTypeFromName(AName: LStr): TEngineType;

function GameTitle(Data: LStr): LStr;

function IsStatusIconExists(AStatusIcons: PStatusIcons; AName: LStr): Boolean;
function FindStatusIconByName(AStatusIcons: PStatusIcons; AName: LStr): PStatusIcon;
procedure AddStatusIcon(var AStatusIcons: TStatusIcons; AStatus: UInt8; AName: LStr; AColor: TRGB); overload;
procedure AddStatusIcon(var AStatusIcons: TStatusIcons; AStatus: UInt8; AName: LStr); overload;

  {$ENDREGION}

  {$REGION 'Clear'}
// network
procedure Clear(var Data: TChannel); overload; inline;
procedure Clear(var Data: TFragmentChannel); overload; inline;

// delta
procedure Clear(var Data: TClientData); overload; inline;
procedure Clear(var Data: TWeaponData); overload; inline;
procedure Clear(var Data: TWeaponDataDynArray); overload; inline;
procedure Clear(var Data: TUserCmd); overload; inline;
procedure Clear(var Data: TEntity); overload; inline;
procedure Clear(var Data: PEntity); overload; inline;
procedure Clear(var Data: TArray<TEntity>); overload; inline;
procedure Clear(var Data: TArray<PEntity>); overload; inline;

// players
procedure Clear(var Data: TPlayer); overload; inline;
procedure Clear(var Data: PPlayer); overload; inline;
procedure Clear(var Data: TArray<TPlayer>); overload; inline;

// teams
procedure Clear(var Data: TTeam); overload; inline;
procedure Clear(var Data: PTeam); overload; inline;
procedure Clear(var Data: TTeams); overload; inline;

procedure Clear(var Data: TMoveVars); overload; inline;
procedure Clear(var Data: TClientInfo); overload; inline;
procedure Clear(var Data: TServerInfo); overload; inline;
procedure Clear(var Data: TExtraInfo); overload; inline;

procedure Clear(var Data: TStatusIcon); overload; inline;
procedure Clear(var Data: TStatusIcons); overload; inline;

procedure Clear(var Data: TBombState); overload; inline;

procedure Clear(var Data: TTextMsg); overload; inline;
procedure Clear(var Data: TDeathMsg); overload; inline;

procedure Clear(var Data: TSimpleMenu); overload; inline;
procedure Clear(var Data: TVGUIMenu); overload; inline;
procedure Clear(var Data: TCSPlayerTeam); overload; inline;
procedure Clear(var Data: TTFCPlayerTeam); overload; inline;
procedure Clear(var Data: TEngineType); overload; inline;
procedure Clear(var Data: TClientState); overload; inline;

procedure Clear(var Data: TScreenFade); overload; inline;

  {$ENDREGION}

implementation

{$REGION 'TPlayer'}
function TPlayer.GetOrigin: TVec3F;
begin
  Clear(Result);

  if Entity.IsActive then
    Result := Entity.Origin
  else
    if Radar <> 0 then
      Result := Radar;
end;

function TPlayer.GetHeadOrigin: TVec3F;
var
  Origin: TVec3F;
begin
  if not Entity.IsActive then
    Exit;

  Origin := GetOrigin;

  Result := TVec3F.Create(Origin.X, Origin.Y, Origin.Z + HUMAN_HEIGHT_HALF);
end;

function TPlayer.GetFootOrigin: TVec3F;
var
  Origin: TVec3F;
begin
  if not Entity.IsActive then
    Exit;

  Origin := GetOrigin;

  Result := TVec3F.Create(Origin.X, Origin.Y, Origin.Z - HUMAN_HEIGHT_HALF);
end;

function TPlayer.GetName: LStr;
begin
  Clear(Result);
  Info_Read(UserInfo, 'name', Result);
end;

function TPlayer.GetStatus(AEngine: TEngineType): LStr;
begin
  Clear(Result);

  case AEngine of
    E_NONE: ;
    E_VALVE: ;

    E_CSTRIKE,
    E_CZERO:
      if ScoreAttrib and SCORE_ATTRIB_FLAG_DEAD = 0 then
        if ScoreAttrib and SCORE_ATTRIB_FLAG_BOMB > 0 then
          Result := 'Bomb'
        else
          if ScoreAttrib and SCORE_ATTRIB_FLAG_VIP > 0 then
            Result := 'VIP'
          else
      else
        Result := 'Dead';
    E_DMC: ;
    E_TFC: ;
    E_DOD: ;
    E_GEARBOX: ;
    E_RICOCHET: ;
  end;
end;

function TPlayer.GetLatency: LStr;
begin
  if Info_Read(UserInfo, '*bot') = '1' then
      Result := 'BOT'
    else
      if Loss > 0 then
        Result := IntToStr(Ping) + '/' + IntToStr(Loss)
      else
        Result := IntToStr(Ping);
end;

function TPlayer.GetTeam(AEngine: TEngineType): LStr;
begin
  Result := Team;

  case AEngine of
    E_NONE: ;
    E_VALVE: ;
    E_CSTRIKE,
    E_CZERO:
      case GetCSPlayerTeam of
        CS_TEAM_T: Result := 'T';
        CS_TEAM_CT: Result := 'CT';
        CS_TEAM_SPECTATOR: Result := 'SPEC';
      end;
    E_DMC: ;
    E_TFC: ;
    E_DOD: ;
    E_GEARBOX: ;
    E_RICOCHET: ;
  end;
end;

function TPlayer.IsCSAlive;
begin
  Result := ScoreAttrib and SCORE_ATTRIB_FLAG_DEAD = 0;
end;

function TPlayer.IsCSBomber;
begin
  Result := ScoreAttrib and SCORE_ATTRIB_FLAG_BOMB > 0;
end;

function TPlayer.IsCSVIP;
begin
  Result := ScoreAttrib and SCORE_ATTRIB_FLAG_VIP > 0;
end;

function TPlayer.GetCSPlayerTeam: TCSPlayerTeam;
begin
  Clear(Result);

  if Team = '' then
    Exit;

  if Team = 'TERRORIST' then
    Result := CS_TEAM_T
  else
    if Team = 'CT' then
      Result := CS_TEAM_CT
    else
      if Team = 'SPECTATOR' then
        Result := CS_TEAM_SPECTATOR;
end;

function TPlayer.GetTFCPlayerTeam: TTFCPlayerTeam;
begin
  Clear(Result);

  if Team = '' then
    Exit;

  if Team = 'Blue' then
    Result := TFC_TEAM_BLUE
  else
    if Team = 'Red' then
      Result := TFC_TEAM_RED;
end;

function TPlayer.GetPlayerColor(AEngine: TEngineType; CheckForDead: Boolean = False; CheckForBomb: Boolean = False; CheckForVIP: Boolean = False): TColor;
begin
  case AEngine of
    E_VALVE: Result := TColorRec.Yellow;

    E_CSTRIKE,
    E_CZERO:
    begin
      case GetCSPlayerTeam of
        CS_TEAM_T: Result := TColorRec.Red;
        CS_TEAM_CT: Result := TColorRec.Aqua;
        CS_TEAM_SPECTATOR: Result := TColorRec.Silver;
      else
        Result := TColorRec.Gray;
      end;

      if CheckForBomb then
        if ScoreAttrib and SCORE_ATTRIB_FLAG_BOMB > 0 then
          Result := TColorRec.Lime;

      if CheckForVIP then
        if ScoreAttrib and SCORE_ATTRIB_FLAG_VIP > 0 then
          Result := TColorRec.Lime;

      if CheckForDead then
        if ScoreAttrib and SCORE_ATTRIB_FLAG_DEAD > 0 then
          Result := TColorRec.Gray;
    end;

    E_DMC: Result := TColorRec.Yellow;

    E_TFC:
      case GetTFCPlayerTeam of
        TFC_TEAM_BLUE: Result := TColorRec.Aqua;
        TFC_TEAM_RED: Result := TColorRec.Red;
      else
        Result := TColorRec.Gray;
      end;
  else
    Result := TColorRec.Gray;
  end;
end;
{$ENDREGION}

{$REGION 'TServerInfo'}
function TServerInfo.ResolveMapName: LStr;
begin
  Result := ParseBefore(Reverse(ParseBefore(Reverse(Map), '/')), '.')
end;
{$ENDREGION}

{$REGION 'Shared'}
function FindGameTitleByName(Data: LStr): Int32;
begin
  for Result := Low(GameTitles) to High(GameTitles) do
    if Data = GameTitles[Result].Name then
      Exit;

  Result := 0;
end;

{$REGION 'Teams'}
function FindTeamByName(ATeams: PTeams; AName: LStr): PTeam;
var
  I: Int32;
begin
  Result := nil;

  for I := Low(ATeams^) to High(ATeams^) do
    if ATeams^[I].Name = AName then
      Exit(@ATeams^[I]);
end;
{$ENDREGION}

function GetMenuKeyIndex(Key: UInt8): Int16;
begin
  case Key of
    1: Result := MENU_KEY_1;
    2: Result := MENU_KEY_2;
    3: Result := MENU_KEY_3;
    4: Result := MENU_KEY_4;
    5: Result := MENU_KEY_5;
    6: Result := MENU_KEY_6;
    7: Result := MENU_KEY_7;
    8: Result := MENU_KEY_8;
    9: Result := MENU_KEY_9;
    0: Result := MENU_KEY_0;
  end;
end;


function ResolveFileNameExtention(Data: LStr; Separator: LChar = '/'): LStr;
begin
  Result := Reverse(ParseBefore(Reverse(Data), Separator));
end;

function ResolveFileExtention(Data: LStr): LStr;
begin
  Result := Reverse(ParseBefore(Reverse(Data), '.'));
end;

function GetEngineTypeFromName(AName: LStr): TEngineType;
begin
  if AName = 'valve' then
    Result := E_VALVE
  else
    if AName = 'cstrike' then
      Result := E_CSTRIKE
    else
      if AName = 'czero' then
        Result := E_CZERO
      else
        if AName = 'dmc' then
          Result := E_DMC
        else
          if AName = 'tfc' then
            Result := E_TFC
          else
            if AName = 'dod' then
              Result := E_DOD
            else
              if AName = 'gearbox' then
                Result := E_GEARBOX
              else
                if AName = 'ricochet' then
                  Result := E_RICOCHET;
end;

function GameTitle(Data: LStr): LStr;
begin
  Result := Data;

  if FindGameTitleByName(Result) > 0 then
    Result := GameTitles[FindGameTitleByName(Result)].Data;
end;

function IsStatusIconExists(AStatusIcons: PStatusIcons; AName: LStr): Boolean;
var
  I: Int32;
begin
  Result := False;

  for I := Low(AStatusIcons^) to High(AStatusIcons^) do
    if AStatusIcons^[I].Name = AName then
      Exit(True);
end;

function FindStatusIconByName(AStatusIcons: PStatusIcons; AName: LStr): PStatusIcon;
var
  I: Int32;
begin
  Result := nil;

  for I := Low(AStatusIcons^) to High(AStatusIcons^) do
    if AStatusIcons^[I].Name = AName then
      Exit(@AStatusIcons^[I]);
end;

procedure AddStatusIcon(var AStatusIcons: TStatusIcons; AStatus: UInt8; AName: LStr; AColor: TRGB);
begin
  SetLength(AStatusIcons, Length(AStatusIcons) + 1);

  with AStatusIcons[High(AStatusIcons)] do
  begin
    Status := AStatus;
    Name := AName;
    Color := AColor;
  end;
end;

procedure AddStatusIcon(var AStatusIcons: TStatusIcons; AStatus: UInt8; AName: LStr);
var
  C: TRGB;
begin
  Clear(C);
  AddStatusIcon(AStatusIcons, AStatus, AName, C);
end;
{$ENDREGION}

{$REGION 'Clear'}
  {$REGION 'Network'}
procedure Clear(var Data: TChannel);
begin
  with Data do
  begin
    Clear(IncomingTime);
    Clear(IncomingSequence);
    Clear(IncomingAcknowledgement);
    Clear(IncomingAcknowledgementReliable);
    Clear(OutgoingTime);
    Clear(OutgoingSequence);
    Clear(OutgoingAcknowledgementReliable);
    Clear(Fragment);
    Clear(FileFragment);
    Clear(Latency);
  end;
end;

procedure Clear(var Data: TFragmentChannel);
begin
  with Data do
  begin
    Clear(Active);
    Clear(Sequence);
    Clear(Count);
    Clear(LastCount);
    Clear(LastTime);
    Clear(Total);
    Clear(CanSend);
  end;
end;
  {$ENDREGION}

  {$REGION 'Delta'}
procedure Clear(var Data: TClientData);
begin
  with Data do
  begin
    Clear(Origin);
    Clear(Velocity);
    Clear(ViewModel);
    Clear(PunchAngle);
    Clear(Flags);
    Clear(WaterLevel);
    Clear(WaterType);
    Clear(ViewOffset);
    Clear(Health);
    Clear(InDuck);
    Clear(Weapons);
    Clear(TimeStepSound);
    Clear(DuckTime);
    Clear(SwimTime);
    Clear(WaterJumpTime);
    Clear(MaxSpeed);
    Clear(FOV);
    Clear(WeaponAnim);
    Clear(ID);
    Clear(AmmoShells);
    Clear(AmmoNails);
    Clear(AmmoCells);
    Clear(AmmoRockets);
    Clear(NextAttack);
    Clear(TFState);
    Clear(PushMSec);
    Clear(DeadFlag);
    Clear(PhysInfo);
    Clear(IUser1);
    Clear(IUser2);
    Clear(IUser3);
    Clear(IUser4);
    Clear(FUser1);
    Clear(FUser2);
    Clear(FUser3);
    Clear(FUser4);
    Clear(VUser1);
    Clear(VUser2);
    Clear(VUser3);
    Clear(VUser4);
  end;
end;

procedure Clear(var Data: TWeaponData);
begin
  with Data do
  begin
    Clear(ID);
    Clear(Clip);
    Clear(NextPrimaryAttack);
    Clear(NextSecondaryAttack);
    Clear(TimeWeaponIdle);
    Clear(InReload);
    Clear(InSpecialReload);
    Clear(NextReload);
    Clear(PumpTime);
    Clear(ReloadTime);
    Clear(AimedDamage);
    Clear(NextAimBonus);
    Clear(InZoom);
    Clear(WeaponState);
    Clear(IUser1);
    Clear(IUser2);
    Clear(IUser3);
    Clear(IUser4);
    Clear(FUser1);
    Clear(FUser2);
    Clear(FUser3);
    Clear(FUser4);
  end;
end;

procedure Clear(var Data: TWeaponDataDynArray);
var
  I: Int32;
begin
  for I := Low(Data) to High(Data) do
    Clear(Data[I]);

  SetLength(Data, 0);
end;

procedure Clear(var Data: TUserCmd);
begin
  with Data do
  begin
    Clear(LerpMSec);
    Clear(MSec);
    Clear(ViewAngles);
    Clear(ForwardMove);
    Clear(SideMove);
    Clear(UpMove);
    Clear(LightLevel);
    Clear(Buttons);
    Clear(Impulse);
    Clear(WeaponSelect);
    Clear(ImpactIndex);
    Clear(ImpactPosition);
  end;
end;

procedure Clear(var Data: TEntity);
begin
  with Data do
  begin
    Clear(EntityType);
    Clear(Number); // revalidate
    Clear(MsgTime);

    Clear(MessageNum);

    Clear(Origin);
    Clear(Angles);

    Clear(ModelIndex);
    Clear(Sequence);
    Clear(Frame);
    Clear(ColorMap);
    Clear(Skin);
    Clear(Solid);
    Clear(Effects);
    Clear(Scale);

    Clear(EFlags);

    Clear(RenderMode);
    Clear(RenderAmt);
    Clear(RenderColor);
    Clear(RenderFX);

    Clear(MoveType);
    Clear(AnimTime);
    Clear(FrameRate);
    Clear(Body);

    Clear(Controller[0]);
    Clear(Controller[1]);
    Clear(Controller[2]);
    Clear(Controller[3]);

    Clear(Blending[0]);
    Clear(Blending[1]);
    Clear(Blending[2]);
    Clear(Blending[3]);

    Clear(Velocity);

    Clear(MinS);
    Clear(MaxS);

    Clear(AimEnt);
    Clear(Owner);

    Clear(Friction);
    Clear(Gravity);

    Clear(Team);
    Clear(PlayerClass);
    Clear(Health);
    Clear(Spectator);
    Clear(WeaponModel);
    Clear(GaitSequence);

    Clear(BaseVelocity);
    Clear(UseHull);
    Clear(OldButtons);
    Clear(OnGround);
    Clear(StepLeft);

    Clear(FallVelocity);

    Clear(FOV);
    Clear(WeaponAnim);

    Clear(StartPos);
    Clear(EndPos);
    Clear(ImpactTime);
    Clear(StartTime);

    Clear(IUser1);
    Clear(IUser2);
    Clear(IUser3);
    Clear(IUser4);
    Clear(FUser1);
    Clear(FUser2);
    Clear(FUser3);
    Clear(FUser4);
    Clear(VUser1);
    Clear(VUser2);
    Clear(VUser3);
    Clear(VUser4);

    Clear(IsActive);
  end;
end;

procedure Clear(var Data: PEntity);
begin
  Data := nil;
end;

procedure Clear(var Data: TArray<TEntity>);
var
  I: Int32;
begin
  for I := Low(Data) to High(Data) do
    Clear(Data[I]);

  SetLength(Data, 0);
end;

procedure Clear(var Data: TArray<PEntity>);
var
  I: Int32;
begin
  for I := Low(Data) to High(Data) do
    Clear(Data[I]);

  SetLength(Data, 0);
end;
  {$ENDREGION}

  {$REGION 'Players'}
procedure Clear(var Data: TPlayer);
begin
  with Data do
  begin
    Clear(UserID);
    Clear(UserInfo);
   // Clear(MD5);     FIX
    Clear(Kills);
    Clear(Deaths);
    Clear(Ping);
    Clear(Loss);
    Clear(Entity);

    Clear(Team);

    Clear(Health);
    Clear(ScoreAttrib);
    Clear(Location);
    Clear(Radar);
  end;
end;

procedure Clear(var Data: PPlayer);
begin
  Data := nil;
end;

procedure Clear(var Data: TArray<TPlayer>);
var
  I: Int32;
begin
  for I := Low(Data) to High(Data) do
    Clear(Data[I]);

  SetLength(Data, 0);
end;
  {$ENDREGION}

  {$REGION 'Teams'}
procedure Clear(var Data: TTeam);
begin
  with Data do
  begin
    Clear(Name);
    Clear(Score);
  end;
end;

procedure Clear(var Data: PTeam);
begin
  Data := nil;
end;

procedure Clear(var Data: TTeams);
var
  I: Int32;
begin
  for I := Low(Data) to High(Data) do
    Clear(Data[I]);

  SetLength(Data, 0);
end;
  {$ENDREGION}

procedure Clear(var Data: TMoveVars);
begin
  with Data do
  begin
    Clear(Gravity);
    Clear(StopSpeed);
    Clear(MaxSpeed);
    Clear(SpectatorMaxSpeed);
    Clear(Accelerate);
    Clear(AirAccelerate);
    Clear(WaterAccelerate);
    Clear(Friction);
    Clear(EdgeFriction);
    Clear(WaterFriction);
    Clear(EntGravity);
    Clear(Bounce);
    Clear(StepSize);
    Clear(MaxVelocity);
    Clear(ZMax);
    Clear(WaveHeight);
    Clear(Footsteps);
    Clear(SkyName);
    Clear(RollAngle);
    Clear(RollSpeed);
    Clear(SkyColorR);
    Clear(SkyColorG);
    Clear(SkyColorB);
    Clear(SkyVec);
  end;
end;

procedure Clear(var Data: TClientInfo);
begin
  with Data do
  begin
   Clear(Protocol);
   Clear(Challenge);
   Clear(ProtInfo);
   Clear(UserInfo);
   Clear(Certificate);
   AuthType := AUTH_UNDEFINED;
   Clear(Name);
  end;
end;

procedure Clear(var Data: TServerInfo);
begin
  with Data do
  begin
    Clear(Protocol);
    Clear(SpawnCount);
    Clear(MapCheckSum);
    Clear(DLLCRC);
    Clear(MaxPlayers);
    Clear(Index);
    Clear(GameDir);
    Clear(Name);
    Clear(Map);
    Clear(MapList);
  end;
end;

procedure Clear(var Data: TExtraInfo);
begin
  with Data do
  begin
    Clear(FallbackDir);
    Clear(AllowCheats);
  end;
end;

procedure Clear(var Data: TStatusIcon); overload;
begin
  with Data do
  begin
    Clear(Status);
    Clear(Name);
    Clear(Color);
  end;
end;

procedure Clear(var Data: TStatusIcons); overload;
var
  I: Int32;
begin
  for I := Low(Data) to High(Data) do
    Clear(Data[I]);

  SetLength(Data, 0);
end;

procedure Clear(var Data: TBombState);
begin
  with Data do
  begin
    Clear(Position);
    Clear(IsPlanted);
  end;
end;

procedure Clear(var Data: TTextMsg);
begin
  with Data do
  begin
    Clear(DType);
    Clear(Data);
    Clear(S1);
    Clear(S2);
    Clear(S3);
    Clear(S4);
  end;
end;

procedure Clear(var Data: TDeathMsg);
begin
  with Data do
  begin
    Clear(Killer);
    Clear(Victim);
    Clear(IsHeadshot);
    Clear(Weapon);
  end;
end;

procedure Clear(var Data: TSimpleMenu);
begin
  with Data do
  begin
    Clear(Keys);
    Clear(Time);
    Clear(Data);
  end;
end;

procedure Clear(var Data: TVGUIMenu);
begin
  with Data do
  begin
    Clear(Index);
    Clear(Keys);
    Clear(Time);
    Clear(Name);
  end;
end;

procedure Clear(var Data: TCSPlayerTeam);
begin
  Data := TCSPlayerTeam(0);
end;

procedure Clear(var Data: TTFCPlayerTeam);
begin
  Data := TTFCPlayerTeam(0);
end;

procedure Clear(var Data: TEngineType);
begin
  Data := TEngineType(0);
end;

procedure Clear(var Data: TClientState);
begin
  Data := TClientState(0);
end;

procedure Clear(var Data: TScreenFade);
begin
  with Data do
  begin
    Clear(Duration);
    Clear(HoldTime);
    Clear(StartTime);
    Clear(Flags);
    Clear(Color);
  end;
end;
{$ENDREGION}

end.
