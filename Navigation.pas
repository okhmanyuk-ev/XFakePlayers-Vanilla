unit Navigation;

{ Introduction:

 A Navigation Mesh represents the "walkable areas" of a map.
  This data is required by Bots and Hostages in Counter-Strike: Source and Counter-Strike: Global Offensive,
  AI Bots and the Horseless Headless Horsemann in Team Fortress 2, and Bots and Infected in Left 4 Dead
   and Left 4 Dead 2, allowing them to "know" how to move around in the environment.

  Navigation Mesh data is stored in a NAV file corresponding to the map file (.bsp) for which it is used.
  For example, the nav mesh for cstrike\maps\de_dust.bsp is stored in cstrike\maps\de_dust.nav.}

{ Version History:
 1 - hiding spots as plain vector array
 2 - hiding spots as HidingSpot objects
 3 - Encounter spots use HidingSpot ID's instead of storing vector again
 4 - Includes size of source bsp file to verify nav data correlation
 ---- Beta Release at V4 -----
 5 - Added Place info
 ---- Conversion to Src ------
 6 - Added Ladder info
 7 - Areas store ladder ID's so ladders can have one-way connections
 8 - Added earliest occupy times (2 floats) to each area
 9 - Promoted CNavArea's attribute flags to a short
 10 - Added sub-version number to allow derived classes to have custom area data
 11 - Added light intensity to each area
 12 - Storing presence of unnamed areas in the PlaceDirectory
 13 - Widened NavArea attribute bits from unsigned short to int
 14 - Added a bool for if the nav needs analysis
 15 - removed approach areas
 16 - Added visibility data to the base mesh}

interface

uses
  SysUtils,
  System.Generics.Collections,
  Default,
  Vector,
  Math,
  Buffer,
  IOUtils,
  Protocol,
  Tokenizer,
  World,
  Shared;

const
  NAV_MAGIC = $FEEDFACE;
  NAV_VERSION_LAST = 16;

type
  TNavLoadResult = (
    NAV_LOAD_OK = 0,
    NAV_LOAD_FILE_NOT_FOUND,
    NAV_LOAD_BAD_MAGIC,
    NAV_LOAD_BAD_VERSION,
    NAV_LOAD_BAD_DATA);

  TNavSaveResult = (
    NAV_SAVE_OK = 0,
    NAV_SAVE_FILE_ALREADY_EXISTS,
    NAV_SAVE_BAD_DATA);

  TNavDirection = (
    NAV_NORTH = 0,
    NAV_EAST,
    NAV_SOUTH,
    NAV_WEST,

    NAV_NUM_DIRECTIONS);

const
  NAV_DIRECTION_MIN: TNavDirection = NAV_NORTH;
  NAV_DIRECTION_MAX: TNavDirection = NAV_WEST;

type
  // Defines possible ways to move from one area to another
  TNavTraverseType = (
    NAV_GO_NORTH = 0,
    NAV_GO_EAST,
    NAV_GO_SOUTH,
    NAV_GO_WEST,

    NAV_GO_LADDER_UP,
    NAV_GO_LADDER_DOWN,
    NAV_GO_JUMP,
    NAV_GO_ELEVATOR_UP,
    NAV_GO_ELEVATOR_DOWN,

    NAV_NUM_TRAVERSE_TYPES);

  TNavCorner = (
    NAV_NORTH_WEST = 0,
    NAV_NORTH_EAST,
    NAV_SOUTH_EAST,
    NAV_SOUTH_WEST,

    NAV_NUM_CORNERS);

  TNavRelativeDirection = (
    NAV_FORWARD = 0,
    NAV_RIGHT,
    NAV_BACKWARD,
    NAV_LEFT,
    NAV_UP,
    NAV_DOWN,

    NAV_NUM_RELATIVE_DIRECTIONS);

  TNavLadderDirection = (
    NAV_LADDER_UP = 0,
    NAV_LADDER_DOWN,

    NAV_NUM_LADDER_DIRECTIONS);

const
  NAV_LADDER_DIRECTION_MIN: TNavLadderDirection = (NAV_LADDER_UP);
  NAV_LADDER_DIRECTION_MAX: TNavLadderDirection = (NAV_LADDER_DOWN);

const
  NAV_NONE = 0;
  NAV_AREA_INVALID = NAV_NONE; // for source engine
  NAV_AREA_CROUCH = 1 shl 0; // must crouch to use this node/area
  NAV_AREA_JUMP = 1 shl 1; // must jump to traverse this area
  NAV_AREA_PRECISE = 1 shl 2; // do not adjust for obstacles, just move along area. NAV_AREA_DANGER is synonim ? не использовать AI_ObstacleAvoidance ?
  NAV_AREA_NO_JUMP = 1 shl 3; // inhibit discontinuity jumping

  // source engine :
  NAV_AREA_STOP = 1 shl 4; // must stop when entering this area
  NAV_AREA_RUN = 1 shl 5; // must run to traverse this area
  NAV_AREA_WALK = 1 shl 6; // must walk to traverse this area
  NAV_AREA_AVOID = 1 shl 7; // avoid this area unless alternatives are too dangerous
  NAV_AREA_TRANSIENT = 1 shl 8; // area may become blocked, and should be periodically checked
  NAV_AREA_DONT_HIDE = 1 shl 9; // area should not be considered for hiding spot generation
  NAV_AREA_STAND = 1 shl 10; // bots hiding in this area should stand
  NAV_AREA_NO_HOSTAGES = 1 shl 11; // hostages shouldn't use this area
  NAV_AREA_STAIRS = 1 shl 12; // this area represents stairs, do not attempt to climb or jump them - just walk up
  NAV_AREA_NO_MERGE = 1 shl 13; // don't merge this area with adjacent areas
  NAV_AREA_OBSTACLE_TOP = 1 shl 14; // this nav area is the climb point on the tip of an obstacle
  NAV_AREA_CLIFF = 1 shl 15; // this nav area is adjacent to a drop of at least CliffHeight

  NAV_AREA_CUSTOM_START = 1 shl 16; // apps may define custom app-specific bits starting with this value
  // custom area flags must be between this two
  NAV_AREA_CUSTOM_END = 1 shl 26; // apps must not define custom app-specific bits higher than with this value

  NAV_AREA_FUNC_COST = 1 shl 29; // area has designer specified cost controlled by func_nav_cost entities
  NAV_AREA_HAS_ELEVATOR = 1 shl 30; // area is in an elevator's path
  NAV_AREA_NAV_BLOCKER = 1 shl 31; // area is blocked by nav blocker ( Alas, needed to hijack a bit in the attributes to get within a cache line [7/24/2008 tom])

const
  NAV_SPOT_IN_COVER = 1 shl 0; // in a corner with good hard cover nearby
  NAV_SPOT_GOOD_SNIPER_SPOT = 1 shl 1; // had at least one decent sniping corridor
  NAV_SPOT_IDEAL_SNIPER_SPOT = 1 shl 2; // can see either very far, or a large area, or both
  NAV_SPOT_EXPOSED = 1 shl 3; // spot in the open, usually on a ledge or cliff (source engine)

const
  MAX_NAV_APPROACHES = 16;
  MAX_NAV_TEAMS = 2;
  MAX_NAV_CORNERS = 4;
  NAV_STEP_SIZE = 25;

const
  MAX_DISTANCE = MaxUInt32;
  MAX_CHAIN_LENGTH = MaxUInt16;

type
  PNavArea = ^TNavArea; // for post loading
  PNavLadder = ^TNavLadder; // same

  // A HidingSpot is a good place for a bot to crouch and wait for enemies

  PNavHidingSpot = ^TNavHidingSpot;
  TNavHidingSpot = record
  private
    FParent: UInt32;
  public
    Index: UInt32; // id of spot, not of area
    Position: TVec3F;
    Flags: UInt8; // spot flag

    Parent: PNavArea; // parent area of this spot, custom added by me

    //
    DrawTime: UInt32;

    class operator Equal(A, B: TNavHidingSpot): Boolean;
    class operator NotEqual(A, B: TNavHidingSpot): Boolean;

    function Distance(APosition: TVec3F): Float;
  end;

  // An approach area is an area representing a place where players
  // move into/out of our local neighborhood of areas.
  PNavApproach = ^TNavApproach;
  TNavApproach = record
  private
    FHere,
    FPrev,
    FNext,
    FParent: UInt32;
  public
    Here: PNavArea; // the approach area
    Prev: PNavArea; // the area just before the approach area on the path
    PrevToHereHow: TNavTraverseType;
    Next: PNavArea; // the area just after the approach area on the path
    HereToNextHow: TNavTraverseType;
    Parent: PNavArea; // my stuff
  end;

  // Stores a pointer to an interesting "spot", and a parametric distance along a path

  PNavEncounterSpot = ^TNavEncounterSpot;
  TNavEncounterSpot = record
  private
    FSpot: UInt32;
  public
    Spot: PNavHidingSpot;
    T: UInt8; // parametric distance along ray where this spot first has LOS to our path
  end;

// This struct stores possible path segments thru an Area, and the dangerous spots
// to look at as we traverse that path segment.

  PNavEncounter = ^TNavEncounter;
  TNavEncounter = record
  private
    FFrom,
    FDest: UInt32;
  public
    From: PNavArea;
    FromDir: TNavDirection;
    Dest: PNavArea;
    DestDir: TNavDirection;
    Spots: TArray<TNavEncounterSpot>;

    function HasSpots: Boolean;
    function SpotsCount: UInt32;
    function GetRandomSpot: PNavEncounterSpot;
  end;

  PNavVisibility = ^TNavVisibility;
  TNavVisibility = record
  private
    FArea: UInt32;
  public
    Area: PNavArea;
    Flags: UInt8;
  end;

  // A NavArea is a rectangular region defining a walkable area in the environment
  // contains some other interesting information to orientation in world
  TNavArea = record
  private
    FConnections: array[0..3] of TArray<UInt32>;
    FLadders: array[0..1] of TArray<UInt32>;
    FInheritVisibilityFrom: UInt32;

    // pathfinding:
    FVisited: Boolean;
    FParent: PNavArea;
    FCostToStart,
    FCostToFinish,
    FCostTotal: Float;
  public
    Index: UInt32; // unique area index
    Flags: UInt32; // set of attribute bit flags
    Extent: TExtent; // area position in world
    Connections: array[0..3] of TArray<PNavArea>; // a list of adjacent areas for each direction
    HidingSpots: TArray<PNavHidingSpot>; // available hiding spots in this area
    Approaches: TArray<TNavApproach>;
    Encounters: TArray<TNavEncounter>; // list of possible ways to move thru this area, and the spots to look at as we do
    Ladders: array[0..1] of TArray<PNavLadder>; // list of ladders leading up and down from this area
    OccupyTimes, // min time to reach this spot from spawn
    LightIntensity: TArray<Float>; // 0..1 light intensity at corners
    Visibles: TArray<TNavVisibility>; // list of areas potentially visible from inside this area
    InheritVisibilityFrom: PNavArea; // if non-NULL, Visibles becomes a list of additions and deletions (NOT_VISIBLE) to the list of this area
    Location: PLStr; // place descriptor
    _unk1: UInt8;

    //
    DrawTime: UInt32;

    class operator Equal(A, B: TNavArea): Boolean;
    class operator NotEqual(A, B: TNavArea): Boolean;

    class function Create(LeftTop, RightTop, LeftDown, RightDown: TVec3F): TNavArea; static;

    function HasConnections(ADirection: TNavDirection): Boolean; overload;
    function HasConnections: Boolean; overload;
    function HasHidingSpots: Boolean;
    function HasApproaches: Boolean;
    function HasEncounters: Boolean;
    function HasLadders: Boolean;
    function HasOccupyTimes: Boolean;
    function HasLightIntensity: Boolean;
    function HasVisibles: Boolean;
    function HasLocation: Boolean;

    function ConnectionsCount(ADirection: TNavDirection): UInt32; overload;
    function ConnectionsCount: UInt32; overload;
    function HidingSpotsCount: UInt32;
    function ApproachesCount: UInt32;
    function EncountersCount: UInt32;
    function LaddersCount(ADirection: TNavLadderDirection): UInt32; overload;
    function LaddersCount: UInt32; overload;
    function VisiblesCount: UInt32;

    function GetRandomConnection(ADirection: TNavDirection): PNavArea; overload;
    function GetRandomConnection: PNavArea; overload;
    function GetRandomHidingSpot: PNavHidingSpot;
    function GetRandomApproach: PNavApproach;
    function GetRandomEncounter: PNavEncounter;
    // GetRandomLadder must be here
    function GetRandomVisible: PNavVisibility;

    function GetCenter: TVec3F; // returns center position in area
    function GetSize: Float; // the length of the diagonal

    function GetSide(ADirection: TNavDirection): TVec3FLine; // returns side coords
    function GetCorner(ACorner: TNavCorner): TVec3F; // return coord of the corner

    function GetDistance(Position: TVec3F): Float; overload; // from center to 'Position'
    function GetDistance(Position: TVec2F): Float; overload; // ...
    function GetDistance(AArea: TNavArea): Float; overload; // from center to 'AArea' center
    function GetDistance(ASpot: TNavHidingSpot): Float; overload; // from center to spot position

    function GetDistanceEx(Position: TVec3F): Float; overload; // from nearest portal to 'Position'
    function GetDistanceEx(Position: TVec2F): Float; overload; // ...

    function IsContains(Origin: TVec3F): Boolean; overload; // is area include 'Origin'
    function IsContains(Origin: TVec2F): Boolean; overload; // ...

    function IsConnected(AArea: TNavArea): Boolean; // is area connected with us
    function IsConnectedViaLadder(AArea: TNavArea): Boolean;

    function IsNear(AArea: TNavArea): Boolean; // is equals or connected and bi linked

    function AtLocation(ALocation: LStr): Boolean; // compares location

    function GetDirection(Position: TVec2F): TNavDirection; overload; // direction from this area to the given point
    function GetDirection(Position: TVec3F): TNavDirection; overload; // direction from this area to the given point
    function GetDirection(AArea: TNavArea): TNavDirection; overload; // direction from this area to the given area

    function GetWindow(AArea: TNavArea): TVec3FLine; // window is portal side
    function GetWindowEx(AArea: TNavArea): TVec3FLine; // GetWindow with cuted human half width

    function GetPortal(AArea: TNavArea): TVec3FLine; overload; // 'ray' vector between two areas
    function GetPortal(AArea: TNavArea; StartPos, EndPos: TVec3F): TVec3FLine; overload;

    function GetEncounter(AFrom, ADest: TNavArea): PNavEncounter;

    function IsContour(ADirection: TNavDirection): Boolean; // is side space is not fully connected with areas

    function IsBiLinked(AArea: TNavArea): Boolean; overload; // bilinked with area
    function IsBiLinked(ADirection: TNavDirection): Boolean; overload; // is bilinked at least with one area at given direction

    function IsEdge(ADirection: TNavDirection): Boolean;
    function IsClosedCell: Boolean; // if all of 4 directions are connected with others

    function GetLadderTo(AArea: TNavArea): PNavLadder;
    function GetLadderDirectionTo(AArea: TNavArea): TNavLadderDirection;

    function ToString: LStr;

    procedure Connect(AArea: TNavArea; ADirection: TNavDirection); deprecated 'Use TNavMesh';
    procedure BiConnect(AArea: TNavArea; ADirection: TNavDirection); deprecated 'Use TNavMesh';

    procedure Disconnect(AArea: TNavArea); deprecated 'Use TNavMesh';
    procedure BiDisconnect(AArea: TNavArea); deprecated 'Use TNavMesh';
  end;

  TNavChain = TArray<PNavArea>;

  TNavLadder = record
  private
    FTopForwardArea,
    FTopLeftArea,
    FTopRightArea,
    FTopBehindArea,
    FBottomArea: UInt32;
  public
    Index: UInt32;
    Top, Bottom: TVec3F;
    Width, Length: Float;
    Direction: TNavDirection;
    IsDangling: Boolean;
    TopForwardArea,
    TopLeftArea,
    TopRightArea,
    TopBehindArea,
    BottomArea: PNavArea;

    TL, BL: TVec3FLine; // custom by me

    class operator Equal(A, B: TNavLadder): Boolean;
    class operator NotEqual(A, B: TNavLadder): Boolean;
  end;

type
  TCostMultiplier = function(AArea: TNavArea): Float;

  PNavMesh = ^TNavMesh;
  TNavMesh = class
  public
    Version: UInt32;
    SubVersion: UInt32; // The sub-version number is maintained and owned by classes derived from CNavMesh and CNavArea and allows them to track their custom data just as we do at this top level
    Name: LStr;
    WorldSize: UInt32; // store the size of source bsp file in the nav file, so we can test if the bsp changed since the nav file was made
    Analyzed: Boolean; // Store the analysis state
    HasUnnamedAreas: Boolean;
    Locations: TArray<LStr>;
    Areas: TArray<TNavArea>;
    HidingSpots: TArray<TNavHidingSpot>;
    Ladders: TArray<TNavLadder>;
  public
    constructor Create;
    destructor Destroy; override;

    function LoadFromFile(AFileName: LStr; AGameDir: LStr = ''): TNavLoadResult;
    function SaveToFile(AFileName: LStr; OverwriteExisting: Boolean = True): TNavSaveResult;

    function ReallocatePointers: TNavLoadResult;

    procedure LoadLaddersFromWorld(AWorld: PWorld);

    function HasLocations: Boolean; overload;
    function HasLocation(ALocation: LStr): Boolean; overload;
    function HasAreas: Boolean; overload;
    function HasAreas(ALocation: LStr): Boolean; overload;
    function HasLadders: Boolean;
    function HasHidingSpots: Boolean;

    function LocationsCount: UInt32;
    function AreasCount: UInt32;
    function LaddersCount: UInt32;
    function HidingSpotsCount: UInt32;
    function ApproachesCount: UInt32;
    function EncountersCount: UInt32;

    function GetAreas(ALocation: LStr): TArray<PNavArea>;

    function GetArea(AIndex: UInt32): PNavArea; overload;
    function GetArea(APosition: TVec3F; GetNearestOnFailure: Boolean = True): PNavArea; overload;
    function GetArea(APosition: TVec3F; ALocation: LStr): PNavArea; overload;
    function GetArea(APosition: TVec2F): PNavArea; overload;

    function GetAbsoluteIndex(AArea: TNavArea): Int32; overload;
    function GetAbsoluteIndex(AArea: PNavArea): Int32; overload;

    function GetAbsoluteIndex(AHidingSpot: TNavHidingSpot): Int32; overload;
    function GetAbsoluteIndex(AHidingSpot: PNavHidingSpot): Int32; overload;

    function GetHidingSpots(APosition: TVec3F; ARadius: Float): TArray<PNavHidingSpot>;

    function GetHidingSpot(AIndex: UInt32): PNavHidingSpot; overload;
    function GetHidingSpot(APosition: TVec3F): PNavHidingSpot; overload;
    function GetHidingSpot(APosition: TVec3F; ARadius: Float): PNavHidingSpot; overload;
    function GetHidingSpot(APosition: TVec2F): PNavHidingSpot; overload;
    function GetHidingSpot(AArea: TNavArea): PNavHidingSpot; overload; // returns random hiding spot at this area, or nearest hiding spot if no spots exists in this area

    function GetLadder(AIndex: UInt32): PNavLadder; overload;
    // .. 'get ladder by position'


    function GetRandomArea: PNavArea; overload;
    function GetRandomArea(ALocation: LStr): PNavArea; overload;

    function GetRandomHidingSpot: PNavHidingSpot; overload;
    function GetRandomHidingSpot(APosition: TVec3F; ARadius: Float): PNavHidingSpot; overload;

    // procedures
    function GetChain(AFrom, ATo: PNavArea; ACostMultiplier: TCostMultiplier = nil; ExceptAreaFlags: UInt32 = 0; Optimization: Boolean = True): TNavChain;

    procedure RemoveFlagFromAllAreas(AFlag: UInt32);

    //

    procedure Connect(A1, A2: TNavArea; ADirection: TNavDirection);
    procedure BiConnect(A1, A2: TNavArea; ADirection: TNavDirection);

    procedure Disconnect(A1, A2: TNavArea);
    procedure BiDisconnect(A1, A2: TNavArea);

    procedure Merge(A1, A2: TNavArea);
    procedure Delete(AArea: TNavArea);

    procedure Generate(AWorld: TWorld);
    procedure MergeAreas;
    procedure FindWalkableSpace(AWorld: TWorld);
    procedure FloodFill(AWorld: TWorld);
    function AddNodeArea(AWorld: TWorld; AOrigin: TVec3F): PNavArea;
    function AddArea(AArea: TNavArea): PNavArea;
  end;

type
  TArrayPNavAreaHelper = record helper for TArray<PNavArea>
  public
    function IndexOf(AArea: TNavArea): Int32;
    function IsContains(AArea: TNavArea): Boolean;
  end;

function OppositeNavDirection(ADirection: TNavDirection): TNavDirection; inline;
function NavDirectionLeft(ADirection: TNavDirection): TNavDirection; inline;
function NavDirectionRight(ADirection: TNavDirection): TNavDirection; inline;
function NavDirectionToAngle(ADirection: TNavDirection): Float; inline;
function AngleToNavDirection(AAngle: Float): TNavDirection; inline;
function RandomNavDirection: TNavDirection; inline;

function GetNavChainLength(AChain: TNavChain): Float;
procedure OptimizeNavChain(var AChain: TNavChain);

function GetNavFlagsStr(AFlags: UInt32): LStr;
function GetNavFlagStr(AFlag: UInt32): LStr;

procedure Clear(var Data: TNavDirection); overload; inline;
procedure Clear(var Data: TNavTraverseType); overload; inline;
procedure Clear(var Data: TNavCorner); overload; inline;
procedure Clear(var Data: TNavRelativeDirection); overload; inline;
procedure Clear(var Data: TNavLadderDirection); overload; inline;

procedure Clear(var Data: TNavHidingSpot); overload; inline;
procedure Clear(var Data: PNavHidingSpot); overload; inline;
procedure Clear(var Data: TNavApproach); overload; inline;
procedure Clear(var Data: TNavEncounterSpot); overload; inline;
procedure Clear(var Data: TNavEncounter); overload; inline;
procedure Clear(var Data: PNavLadder); overload; inline;
procedure Clear(var Data: TNavVisibility); overload; inline;
procedure Clear(var Data: TNavArea); overload; inline;
procedure Clear(var Data: PNavArea); overload; inline;
procedure Clear(var Data: TNavLadder); overload; inline;

implementation

function TNavEncounter.HasSpots: Boolean;
begin
  Result := SpotsCount > 0;
end;

function TNavEncounter.SpotsCount: UInt32;
begin
  Result := Length(Spots);
end;

function TNavEncounter.GetRandomSpot: PNavEncounterSpot;
begin
  Result := nil;

  if HasSpots then
    Result := @Spots[Random(SpotsCount)];
end;

class operator TNavHidingSpot.Equal(A, B: TNavHidingSpot): Boolean;
begin
  Result := A.Index = B.Index;
end;

class operator TNavHidingSpot.NotEqual(A, B: TNavHidingSpot): Boolean;
begin
  Result := A.Index <> B.Index;
end;

function TNavHidingSpot.Distance(APosition: TVec3F): Float;
begin
  Result := Position.Distance(APosition);
end;

class operator TNavArea.Equal(A, B: TNavArea): Boolean;
begin
  Result := A.Index = B.Index;
end;

class operator TNavArea.NotEqual(A, B: TNavArea): Boolean;
begin
  Result := A.Index <> B.Index;
end;

class function TNavArea.Create(LeftTop, RightTop, LeftDown, RightDown: TVec3F): TNavArea;
var
  I: Int32;
begin
  with Result do
  begin
    Clear(Result);
    Extent := TExtent.Create(LeftTop, RightTop, LeftDown, RightDown);
  end;
end;

function TNavArea.HasConnections(ADirection: TNavDirection): Boolean;
begin
  Result := ConnectionsCount(ADirection) > 0;
end;

function TNavArea.HasConnections: Boolean;
begin
  Result := ConnectionsCount > 0;
end;

function TNavArea.HasHidingSpots: Boolean;
begin
  Result := HidingSpotsCount > 0;
end;

function TNavArea.HasApproaches: Boolean;
begin
  Result := ApproachesCount > 0;
end;

function TNavArea.HasEncounters: Boolean;
begin
  Result := EncountersCount > 0;
end;

function TNavArea.HasLadders: Boolean;
begin
  Result := LaddersCount > 0;
end;

function TNavArea.HasOccupyTimes: Boolean;
begin
  Result := Length(OccupyTimes) > 0;
end;

function TNavArea.HasLightIntensity: Boolean;
begin
  Result := Length(LightIntensity) > 0;
end;

function TNavArea.HasVisibles: Boolean;
begin
  Result := VisiblesCount > 0;
end;

function TNavArea.HasLocation: Boolean;
begin
  Result := Location <> nil;
end;

function TNavArea.ConnectionsCount(ADirection: TNavDirection): UInt32;
begin
  Clear(Result);

  if not (ADirection in [NAV_DIRECTION_MIN..NAV_DIRECTION_MAX]) then
    Exit;

  Result := Length(Connections[UInt32(ADirection)]);
end;

function TNavArea.ConnectionsCount: UInt32;
var
  I: Int32;
begin
  Clear(Result);

  for I := UInt32(NAV_DIRECTION_MIN) to UInt32(NAV_DIRECTION_MAX) do
    Inc(Result, ConnectionsCount(TNavDirection(I)));
end;

function TNavArea.HidingSpotsCount: UInt32;
begin
  Result := Length(HidingSpots);
end;

function TNavArea.ApproachesCount: UInt32;
begin
  Result := Length(Approaches);
end;

function TNavArea.EncountersCount: UInt32;
begin
  Result := Length(Encounters);
end;

function TNavArea.LaddersCount(ADirection: TNavLadderDirection): UInt32;
begin
  Clear(Result);

  if not (ADirection in [NAV_LADDER_DIRECTION_MIN..NAV_LADDER_DIRECTION_MAX]) then
    Exit;

  Result := Length(Ladders[UInt32(ADirection)]);
end;

function TNavArea.LaddersCount: UInt32;
var
  I: Int32;
begin
  Clear(Result);

  for I := UInt32(NAV_LADDER_DIRECTION_MIN) to UInt32(NAV_LADDER_DIRECTION_MAX) do
    Inc(Result, LaddersCount(TNavLadderDirection(I)));
end;

function TNavArea.VisiblesCount: UInt32;
begin
  Result := Length(Visibles);
end;

function TNavArea.GetRandomConnection(ADirection: TNavDirection): PNavArea;
begin
  Result := nil;

  if not HasConnections(ADirection) then
    Exit;

  Result := Connections[UInt32(ADirection)][Random(ConnectionsCount(ADirection))];
end;

function TNavArea.GetRandomConnection: PNavArea;
begin
  Result := nil;

  if not HasConnections then
    Exit;

  repeat
    Result := GetRandomConnection(RandomNavDirection);
  until Assigned(Result);
end;

function TNavArea.GetRandomHidingSpot: PNavHidingSpot;
begin
  Result := nil;

  if HasHidingSpots then
    Result := @HidingSpots[Random(HidingSpotsCount)];
end;

function TNavArea.GetRandomApproach: PNavApproach;
begin
  Result := nil;

  if HasApproaches then
    Result := @Approaches[Random(ApproachesCount)];
end;

function TNavArea.GetRandomEncounter: PNavEncounter;
begin
  Result := nil;

  if HasEncounters then
    Result := @Encounters[Random(EncountersCount)];
end;

function TNavArea.GetRandomVisible: PNavVisibility;
begin
  Result := nil;

  if HasVisibles then
    Result := @Visibles[Random(VisiblesCount)];
end;

function TNavArea.GetCenter: TVec3F;
begin
  Result := Extent.Center;
end;

function TNavArea.GetSize: Float;
begin
  Result := Extent.Size;
end;

function TNavArea.GetSide(ADirection: TNavDirection): TVec3FLine;
begin                       // comments based on de_dust2.bsp via nav viewer
  with Result do
    case ADirection of
      NAV_NORTH:
      // ---Hi
      //    |
      //    |
      // ---Lo
      begin
        Hi.X := Extent.Lo.X;
        Hi.Y := Extent.Hi.Y;
        Hi.Z := Extent.Heights.X;

        Lo := Extent.Hi;
      end;

      NAV_EAST:
      // Hi------Lo
      //  |      |
      //  |      |
      begin
        Lo.X := Extent.Lo.X;
        Lo.Y := Extent.Hi.Y;
        Lo.Z := Extent.Heights.X;

        Hi := Extent.Lo;
      end;

      NAV_SOUTH:
      // Hi---
      // |
      // |
      // Lo---
      begin
        Hi := Extent.Lo;

        Lo.X := Extent.Hi.X;
        Lo.Y := Extent.Lo.Y;
        Lo.Z := Extent.Heights.Y;
      end;

      NAV_WEST:
      //  |      |
      //  |      |
      // Hi------Lo
      begin
        Hi.X := Extent.Hi.X;
        Hi.Y := Extent.Lo.Y;
        Hi.Z := Extent.Heights.Y;

        Lo := Extent.Hi;
      end;
    end;
end;

function TNavArea.GetCorner(ACorner: TNavCorner): TVec3F;
begin
  case ACorner of
    NAV_NORTH_WEST: Result := Extent.Lo;
    NAV_NORTH_EAST: Result := TVec3F.Create(Extent.Hi.X, Extent.Lo.Y, Extent.Heights.Y);
    NAV_SOUTH_EAST: Result := Extent.Hi;
    NAV_SOUTH_WEST: Result := TVec3F.Create(Extent.Lo.X, Extent.Hi.Y, Extent.Heights.X);
  end;
end;

function TNavArea.GetDistance(Position: TVec3F): Float;
begin
  if IsContains(Position) then
    Exit(0);

  Result := GetCenter.Distance(Position);
end;

function TNavArea.GetDistance(Position: TVec2F): Float;
begin
  if IsContains(Position) then
    Exit(0);

  Result := GetCenter.Distance(Position);
end;

function TNavArea.GetDistance(AArea: TNavArea): Float;
begin
  Result := GetDistance(AArea.GetCenter);
end;

function TNavArea.GetDistance(ASpot: TNavHidingSpot): Float;
begin
  Result := GetDistance(ASpot.Position);
end;

function TNavArea.GetDistanceEx(Position: TVec3F): Float;
var
  S1, S2: TVec3FLine;
  V1, V2: TVec2FLine;
  P: TVec2F;
begin
  if IsContains(Position) then
    Exit(0);

  S1 := GetSide(GetDirection(Position));
  S2 := TVec3FLine.Create(GetCenter, Position);

  V1 := TVec2FLine.Create(S1.Hi.X, S1.Hi.Y, S1.Lo.X, S1.Lo.Y);
  V2 := TVec2FLine.Create(S2.Hi.X, S2.Hi.Y, S2.Lo.X, S2.Lo.Y);

  if not V1.IsIntersected(V2) then
    Exit(GetDistance(Position));

  P := V1.GetIntersectPoint(V2);

  Result := TVec3F.Create(P.X, P.Y, GetSide(GetDirection(Position)).Center.Z).Distance(Position);

  //Result := GetSide(GetDirection(Position)).Center.Distance(Position);
end;

function TNavArea.GetDistanceEx(Position: TVec2F): Float;
begin
  if IsContains(Position) then
    Exit(0);

  Result := GetSide(GetDirection(Position)).Center.Distance(Position);
end;

function TNavArea.IsContains(Origin: TVec3F): Boolean;
const
  ZTolerance = 30;
begin
  Result := (Origin.X >= Extent.Hi.X)
        and (Origin.Y >= Extent.Hi.Y)
        and (Origin.X <= Extent.Lo.X)
        and (Origin.Y <= Extent.Lo.Y)

        // find min & max heights of area, and check if we are between this values
        and (Origin.Z >= Max(Min(Extent.Hi.Z, Extent.Lo.Z), Min(Extent.Heights.X, Extent.Heights.Y)) - ZTolerance)
        and (Origin.Z <= Max(Max(Extent.Hi.Z, Extent.Lo.Z), Max(Extent.Heights.X, Extent.Heights.Y)) + ZTolerance);
end;

function TNavArea.IsContains(Origin: TVec2F): Boolean;
const
  ZTolerance = 30;
begin
  Result := (Origin.X >= Extent.Hi.X)
        and (Origin.Y >= Extent.Hi.Y)
        and (Origin.X <= Extent.Lo.X)
        and (Origin.Y <= Extent.Lo.Y);
end;

function TNavArea.IsConnected(AArea: TNavArea): Boolean;
var
  I: Int32;
begin
  Result := False;

  for I := Low(Connections) to High(Connections) do
    if Connections[I].IsContains(AArea) then
      Exit(True);
end;

function TNavArea.IsConnectedViaLadder(AArea: TNavArea): Boolean;
var
  I, J: Int32;
begin
  Result := False;

  for I := Low(Ladders) to High(Ladders) do
    for J := Low(Ladders[I]) to High(Ladders[I]) do
      case I of
        UInt32(NAV_LADDER_UP):
          if Ladders[I][J].TopForwardArea^ = AArea then
            Exit(True);

        UInt32(NAV_LADDER_DOWN):
          if Ladders[I][J].BottomArea^ = AArea then
            Exit(True);
      end;
end;

function TNavArea.IsNear(AArea: TNavArea): Boolean;
begin
  Result := (Self = AArea) or IsBiLinked(AArea);
end;

function TNavArea.AtLocation(ALocation: LStr): Boolean;
begin
  if not HasLocation then
    Exit(False);

  Result := Location^ = ALocation;
end;

function TNavArea.GetDirection(Position: TVec2F): TNavDirection;
var
  V: TVec2F;
begin
  if (Position.X >= Extent.Lo.X) and (Position.X <= Extent.Hi.X) then
    if Position.Y < Extent.Lo.Y then
      Exit(NAV_NORTH)
    else
      if Position.Y > Extent.Hi.Y then
        Exit(NAV_SOUTH)
      else
  else
    if (Position.Y >= Extent.Lo.Y) and (Position.Y <= Extent.Hi.Y) then
      if Position.X < Extent.Lo.X then
        Exit(NAV_WEST)
      else
        if Position.X > Extent.Hi.X then
          Exit(NAV_EAST);

  V := Position - TVec2F.Create(GetCenter.X, GetCenter.Y);

  if Abs(V.X) > Abs(V.Y) then
    if V.X > 0 then
      Exit(NAV_EAST)
    else
      Exit(NAV_WEST)
  else
    if V.Y > 0 then
      Exit(NAV_SOUTH)
    else
      Exit(NAV_NORTH);

  Result := NAV_NUM_DIRECTIONS;
end;

function TNavArea.GetDirection(Position: TVec3F): TNavDirection;
begin
  Result := GetDirection(TVec2F.Create(Position.X, Position.Y));
end;

function TNavArea.GetDirection(AArea: TNavArea): TNavDirection;
var
  I: TNavDirection;
  J: Int32;
begin
  for I := NAV_DIRECTION_MIN to NAV_DIRECTION_MAX do
    for J := Low(Connections[UInt32(I)]) to High(Connections[UInt32(I)]) do
      if Connections[UInt32(I)][J]^ = AArea then
        Exit(I);

  Result := GetDirection(AArea.GetCenter);
end;

function TNavArea.GetWindow(AArea: TNavArea): TVec3FLine;
var
  D: TNavDirection;
  S1, S2: TVec3FLine; // sides
  L: PNavLadder;
begin
  if IsConnectedViaLadder(AArea) then
  begin
    L := GetLadderTo(AArea);

    if L = nil then
      Exit;

    if L.BottomArea^ = AArea then
      Result := L.TL
    else
      Result := L.BL;

    Exit;
  end;

  if not IsConnected(AArea) then
    Error(['Navigation.GetWindow: "Self" isn''t connected with AArea']);

  D := GetDirection(AArea); // from Self to AArea

  S1 := GetSide(D); // self
  S2 := AArea.GetSide(OppositeNavDirection(D));

  case D of
    NAV_NORTH,
    NAV_SOUTH:
      if (S1.Hi.X >= S2.Hi.X) and (S1.Lo.X <= S2.Lo.X) then // S2 in or equals S1
        Result := S2
      else
        if (S1.Hi.X < S2.Hi.X) and (S1.Lo.X > S2.Lo.X) then // S1 in S2
          Result := S1
        else
          if S1.Hi.X < S2.Hi.X then // top corner of S1 is greather than S2, bottom corner of S1 may be equals to S2
          begin
            Result.Hi := S1.Hi;
            Result.Lo := S2.Lo;
          end
          else // bottom corner of S2 is greather than S1
          begin
            Result.Hi := S2.Hi;
            Result.Lo := S1.Lo;
          end;

    NAV_EAST,
    NAV_WEST:
      if (S1.Hi.Y >= S2.Hi.Y) and (S1.Lo.Y <= S2.Lo.Y) then // S2 in or equals S1
        Result := S2
      else
        if (S1.Hi.Y < S2.Hi.Y) and (S1.Lo.Y > S2.Lo.Y) then // S1 in S2
          Result := S1
        else
          if S1.Hi.Y < S2.Hi.Y then // top corner of S1 is greather than S2, bottom corner of S1 may be equals to S2
          begin
            Result.Hi := S1.Hi;
            Result.Lo := S2.Lo;
          end
          else // bottom corner of S2 is greather than S1
          begin
            Result.Hi := S2.Hi;
            Result.Lo := S1.Lo;
          end;
  end;
end;

function TNavArea.GetWindowEx(AArea: TNavArea): TVec3FLine;
begin
  Result := GetWindow(AArea);

  if IsConnectedViaLadder(AArea) then
    Exit;

  if Result.Length <= HUMAN_WIDTH then
    Exit;

  case GetDirection(AArea) of
    NAV_NORTH,
    NAV_SOUTH:
    begin
      Result.Hi.X := Result.Hi.X - HUMAN_WIDTH_HALF;
      Result.Lo.X := Result.Hi.X + HUMAN_WIDTH_HALF;
    end;

    NAV_EAST,
    NAV_WEST:
    begin
      Result.Hi.Y := Result.Hi.Y - HUMAN_WIDTH_HALF;
      Result.Lo.Y := Result.Lo.Y + HUMAN_WIDTH_HALF;
    end;
  end;
end;

function TNavArea.GetPortal(AArea: TNavArea): TVec3FLine;  // add z calculation
var
  D: TNavDirection;
  S1, S2: TVec3FLine; // sides
  L: PNavLadder;
begin
  if IsConnectedViaLadder(AArea) then
  begin
    L := GetLadderTo(AArea);

    if L = nil then
      Exit;

    if L.BottomArea^ = AArea then
    begin
      Result.Hi := L.Bottom;
      Result.Lo := L.Top;
    end
    else
    begin
      Result.Hi := L.Top;
      Result.Lo := L.Bottom;
    end;

    Exit;
  end;

  if not IsConnected(AArea) then
    Error(['Navigation.GetPortal: "Self" isn''t connected with AArea']);

  D := GetDirection(AArea); // from Self to AArea

  S1 := GetSide(D); // self
  S2 := AArea.GetSide(OppositeNavDirection(D));

  // Result
  //
  // ----------|
  //           |
  //           |
  //    Self   |   |--------------
  //           |   |
  //          Hi - Lo
  //           |   |
  // ----------|   |
  //               |   AArea
  //               |
  //               |--------------

  case D of
    NAV_NORTH,
    NAV_SOUTH:
    begin
      if (S1.Hi.X >= S2.Hi.X) and (S1.Lo.X <= S2.Lo.X) then // S2 in or equals S1

        // ---------------S1.Hi
        //                  |
        //                S2.Hi---------------
        //      Self        |       AArea
        //               -> | < - portal must be here
        //                  |
        //                S2.Lo---------------
        //                  |
        //                  |
        // ---------------S1.Lo

        Result.Hi.X := S2.Center.X
      else
        if (S1.Hi.X < S2.Hi.X) and (S1.Lo.X > S2.Lo.X) then // S1 in S2

          //                S2.Hi---------------
          //                  |
          // ---------------S1.Hi
          //                  |
          //       Self    -> | < - portal must be here
          //                  |
          // ---------------S1.Lo
          //                  |      AArea
          //                  |
          //                S2.Lo---------------

          Result.Hi.X := S1.Center.X
        else
          if S1.Hi.X < S2.Hi.X then // top corner of S1 is greather than S2, bottom corner of S1 may be equals to S2

            //                S2.Hi---------------
            //                  |
            //                  |       AArea
            // ---------------S1.Hi
            //                  |
            //               -> | < - portal must be here
            //                  |
            //                S2.Lo---------------
            //       Self       |
            //                  |
            // ---------------S1.Lo


            Result.Hi.X := S1.Hi.X + ((S2.Lo.X - S1.Hi.X) / 2)
          else // bottom corner of S2 is greather than S1

            // ---------------S1.Hi
            //                  |
            //                  |
            //      Self      S2.Hi---------------
            //                  |
            //               -> | < - portal must be here
            //                  |
            // ---------------S1.Lo
            //                  |      AArea
            //                  |
            //                S2.Lo---------------

            Result.Hi.X := S2.Hi.X + ((S1.Lo.X - S2.Hi.X) / 2);

      Result.Hi.Y := S1.Center.Y;
      Result.Hi.Z := S1.Center.Z;

      Result.Lo.X := Result.Hi.X;
      Result.Lo.Y := S2.Center.Y;
      Result.Lo.Z := S2.Center.Z;
    end;

    NAV_EAST,
    NAV_WEST:
    begin
      if (S1.Hi.Y >= S2.Hi.Y) and (S1.Lo.Y <= S2.Lo.Y) then // S2 in or equals S1
        Result.Hi.Y := S2.Center.Y
      else
        if (S1.Hi.Y < S2.Hi.Y) and (S1.Lo.Y > S2.Lo.Y) then // S1 in S2
          Result.Hi.Y := S1.Center.Y
        else
          if S1.Hi.Y < S2.Hi.Y then // top corner of S1 is greather than S2, bottom corner of S1 may be equals to S2

            //    |                             |
            //    |         AArea               |
            //    |                             |
            //    |                    \/       |
            //  S2.Hi--------S1.Hi------------S2.Lo--------S1.Lo
            //                 |       ^                     |
            //                 |  portal must                |
            //                 |   be here          Self     |
            //                 |                             |

            Result.Hi.Y := S1.Hi.Y + ((S2.Lo.Y - S1.Hi.Y) / 2)
          else // bottom corner of S2 is greather than S1
            Result.Hi.Y := S2.Hi.Y + ((S1.Lo.Y - S2.Hi.Y) / 2);

      Result.Hi.X := S1.Center.X;
      Result.Hi.Z := S1.Center.Z;//(S1.Hi.Z + S2.Lo.Z) / 2;

      Result.Lo.X := S2.Center.X;
      Result.Lo.Y := Result.Hi.Y;
      Result.Lo.Z := S2.Center.Z;
    end;
  end;
end;

function TNavArea.GetPortal(AArea: TNavArea; StartPos, EndPos: TVec3F): TVec3FLine;
var
  W3: TVec3FLine;
  W, V: TVec2FLine;
  P: TVec2F;
begin
  W3 := GetWindow(AArea);
  W := TVec2FLine.Create(W3.Hi.X, W3.Hi.Y, W3.Lo.X, W3.Lo.Y);
  V := TVec2FLine.Create(StartPos.X, StartPos.Y, EndPos.X, EndPos.Y);

  if W.IsIntersected(V) then
  begin
    P := W.GetIntersectPoint(V);
    Result := TVec3FLine.Create(P.X, P.Y, W3.Hi.Z, P.X, P.Y, W3.Lo.Z);
  end
  else
    Result := GetPortal(AArea);
end;

function TNavArea.GetEncounter(AFrom: TNavArea; ADest: TNavArea): PNavEncounter;
var
  I: Int32;
begin
  Result := nil;

  for I := Low(Encounters) to High(Encounters) do
    if (AFrom = Encounters[I].From^) and (ADest = Encounters[I].Dest^) then
      Exit(@Encounters[I]);
end;

function TNavArea.IsContour(ADirection: TNavDirection): Boolean;
begin
  Result := False;

  if not HasConnections(ADirection) then // if side has no connections then side is 100% contour
    Exit(True);

  case ADirection of // WRITE THIS CODE NAOW!!!
    NAV_NORTH: ;
    NAV_EAST: ;
    NAV_SOUTH: ;
    NAV_WEST: ;
  end;
end;

function TNavArea.IsBiLinked(AArea: TNavArea): Boolean;
begin
  Result := IsConnected(AArea) and AArea.IsConnected(Self);
end;

function TNavArea.IsBiLinked(ADirection: TNavDirection): Boolean;
var
  I: Int32;
begin
  Result := False;

  for I := Low(Connections[UInt32(ADirection)]) to High(Connections[UInt32(ADirection)]) do
    if Connections[UInt32(ADirection)][I].IsBiLinked(Self) then
      Exit(True);
end;

function TNavArea.IsEdge(ADirection: TNavDirection): Boolean;
begin
  Result := ConnectionsCount(ADirection) = 0;
end;

function TNavArea.IsClosedCell: Boolean;
begin
  Result := HasConnections(NAV_NORTH) and HasConnections(NAV_EAST)
    and HasConnections(NAV_SOUTH) and HasConnections(NAV_WEST);
end;

function TNavArea.GetLadderTo(AArea: TNavArea): PNavLadder;
var
  I, J: Int32;
begin
  if not Self.IsConnectedViaLadder(AArea) then
    Exit;

  Result := nil;

  for I := Low(Ladders) to High(Ladders) do
    for J := Low(Ladders[I]) to High(Ladders[I]) do
      with Ladders[I][J]^ do
        case I of
          UInt32(NAV_LADDER_UP):
            if (TopForwardArea^ = AArea) {or (TopLeftArea^ = AArea) or (TopRightArea^ = AArea)
             or (TopBehindArea^ = AArea)} then
              Exit(Ladders[I][J]);

          UInt32(NAV_LADDER_DOWN):
            if BottomArea^ = AArea then
              Exit(Ladders[I][J]);
        end;
end;

function TNavArea.GetLadderDirectionTo(AArea: TNavArea): TNavLadderDirection;
var
  I, J: Int32;
begin
  if not Self.IsConnectedViaLadder(AArea) then
    Exit;

  Result := NAV_NUM_LADDER_DIRECTIONS;

  for I := Low(Ladders) to High(Ladders) do
    for J := Low(Ladders[I]) to High(Ladders[I]) do
      with Ladders[I][J]^ do
        case I of
          UInt32(NAV_LADDER_UP):
            if (TopForwardArea^ = AArea) or (TopLeftArea^ = AArea) or (TopRightArea^ = AArea)
             or (TopBehindArea^ = AArea) then
              Exit(TNavLadderDirection(I));

          UInt32(NAV_LADDER_DOWN):
            if BottomArea^ = AArea then
              Exit(TNavLadderDirection(I));
        end;
end;

function TNavArea.ToString: LStr;
begin
  if HasLocation then
    Result := StringFromVarRec([GameTitle('#' + Location^), ' ', Index])
  else
    Result := StringFromVarRec(['area ', Index]);
end;

procedure TNavArea.Connect(AArea: TNavArea; ADirection: TNavDirection);
begin
  if IsConnected(AArea) then
    Exit;

  SetLength(FConnections[Int32(ADirection)], Length(FConnections[Int32(ADirection)]) + 1);
  FConnections[Int32(ADirection)][High(FConnections[Int32(ADirection)])] := AArea.Index;
end;

procedure TNavArea.BiConnect(AArea: TNavArea; ADirection: TNavDirection);
begin
  Self.Connect(AArea, ADirection);
  AArea.Connect(Self, OppositeNavDirection(ADirection));
end;

procedure TNavArea.Disconnect(AArea: TNavArea);
var
  I, J: Int32;
begin
  if not IsConnected(AArea) then
    Exit;

  for I := Low(FConnections) to High(FConnections) do
    for J := Low(FConnections[I]) to High(FConnections[I]) do
      if FConnections[I][J] = AArea.Index then
      begin
       // Alert([Length(FConnections[I])]);
        Delete(FConnections[I], J, 1);
       // Alert([Length(FConnections[I])]);
        Exit;
      end;
end;

procedure TNavArea.BiDisconnect(AArea: TNavArea);
begin
  Disconnect(AArea);
  AArea.Disconnect(Self);
end;

class operator TNavLadder.Equal(A, B: TNavLadder): Boolean;
begin
  Result := A.Index = B.Index;
end;

class operator TNavLadder.NotEqual(A, B: TNavLadder): Boolean;
begin
  Result := A.Index <> B.Index;
end;

constructor TNavMesh.Create;
begin
  inherited;
end;

destructor TNavMesh.Destroy;
begin
  inherited;
end;

function TNavMesh.LoadFromFile(AFileName: LStr; AGameDir: LStr = ''): TNavLoadResult;
var
  I, J, K: Int32;
  S: LStr;
begin
//  Finalize(Self);
  Finalize(Locations);
  Finalize(Areas);
  Finalize(HidingSpots);
  Finalize(Ladders);

  Name := TPath.GetFileNameWithoutExtension(ExtractFileName(AFileName));

  if FileExists(Name) then
    AFileName := Name
  else
    if FileExists('navigations\' + Name + '.nav') then
      AFileName := 'navigations\' + Name + '.nav'
    else
      if FileExists('maps\' + Name + '.nav') then
        AFileName := 'maps\' + Name + '.nav'
      else
        if FileExists('worlds\' + Name + '.nav') then
          AFileName := 'worlds\' + Name + '.nav'
        else
          if AGameDir <> '' then
            if FileExists(AGameDir + '\navigations\' + Name + '.nav') then
              AFileName := AGameDir + '\navigations\' + Name + '.nav'
            else
              if FileExists(AGameDir + '\maps\' + Name + '.nav') then
                AFileName := AGameDir + '\maps\' + Name + '.nav'
              else
                if FileExists(AGameDir + '\worlds\' + Name + '.nav') then
                  AFileName := AGameDir + '\worlds\' + Name + '.nav';

  Result := NAV_LOAD_OK;

  if not FileExists(AFileName) then
    Exit(NAV_LOAD_FILE_NOT_FOUND);

  with TBufferEx2.Create do
  begin
    LoadFromFile(AFileName);

    Start;

    if ReadUInt32 <> NAV_MAGIC then
      Exit(NAV_LOAD_BAD_MAGIC);

    Version := ReadUInt32;

    if Version > NAV_VERSION_LAST then
      Exit(NAV_LOAD_BAD_VERSION);

    if Version >= 10 then
      SubVersion := ReadUInt32;

    if Version >= 4 then
      WorldSize := ReadUInt32;

    if Version >= 14 then
      Analyzed := ReadBool8;

    if Version >= 5 then
    begin
      SetLength(Locations, ReadUInt16);

      for I := Low(Locations) to High(Locations) do
        Locations[I] := ParseBefore(ReadLStr(ReadUInt16), #0);

      if Version > 11 then
        HasUnnamedAreas := ReadBool8;
    end;

    SetLength(Areas, ReadUInt32);

    for I := Low(Areas) to High(Areas) do
      with Areas[I] do
      begin
        Index := ReadUInt32;

        if Version <= 8 then
          Flags := ReadUInt8
        else
          if Version < 13 then
            Flags := ReadUInt16
          else
            Flags := ReadUInt32;

        Read(Extent, SizeOf(Extent));

        for J := Low(FConnections) to High(FConnections) do
        begin
          SetLength(FConnections[J], ReadUInt32);

          for K := Low(FConnections[J]) to High(FConnections[J]) do
            FConnections[J][K] := ReadUInt32;
        end;

        K := ReadUInt8;
        SetLength(Self.HidingSpots, Length(Self.HidingSpots) + K);

        for J := Length(Self.HidingSpots) - K to Length(Self.HidingSpots) - 1 do
          with Self.HidingSpots[J] do
          begin
            if Version > 1 then
            begin
              Index := ReadUInt32;
              Position := ReadVec3F;
              Flags := ReadUInt8;
            end
            else
            begin
              Position := ReadVec3F;
              Flags := NAV_SPOT_IN_COVER;
            end;

            FParent := Areas[I].Index;
          end;

        if Version < 15 then
        begin
          SetLength(Approaches, ReadUInt8);

          for J := Low(Approaches) to High(Approaches) do
            with Approaches[J] do
            begin
              FHere := ReadUInt32;
              FPrev := ReadUInt32;
              PrevToHereHow := TNavTraverseType(ReadUInt8);
              FNext := ReadUInt32;
              HereToNextHow := TNavTraverseType(ReadUInt8);
              FParent := Areas[I].Index;
            end;
        end;

        SetLength(Encounters, ReadUInt32);

        for J := Low(Encounters) to High(Encounters) do
          with Encounters[J] do
            if Version >= 3 then
            begin
              FFrom := ReadUInt32;
              FromDir := TNavDirection(ReadUInt8);
              FDest := ReadUInt32;
              DestDir := TNavDirection(ReadUInt8);

              SetLength(Spots, ReadUInt8);

              for K := Low(Spots) to High(Spots) do
                with Spots[K] do
                begin
                  FSpot := ReadUInt32;
                  T := ReadUInt8;
                end;
            end
            else
            begin
              FFrom := ReadUInt32;
              FDest := ReadUInt32;
              Skip(24); // wat ?
              Skip(ReadUInt8 * 16); // ???
            end;

        if Version < 5 then
          Continue;

        J := ReadUInt16 - 1;

        if J in [Low(Locations)..High(Locations)] then
          Location := @Locations[J]
        else
          Location := nil;

        if Version < 7 then
          Continue;

        for J := Low(FLadders) to High(FLadders) do
        begin
          SetLength(FLadders[J], ReadUInt32);

          for K := Low(FLadders[J]) to High(FLadders[J]) do
            FLadders[J][K] := ReadUInt32;
        end;

        if Version < 8 then
          Continue;

        SetLength(OccupyTimes, MAX_NAV_TEAMS);

        for J := Low(OccupyTimes) to High(OccupyTimes) do
          OccupyTimes[J] := ReadFloat;

        if Version < 11 then
          Continue;

        SetLength(LightIntensity, MAX_NAV_CORNERS);

        for J := Low(LightIntensity) to High(LightIntensity) do
          LightIntensity[J] := ReadFloat;

        if Version < 16 then
          Continue;

        SetLength(Visibles, ReadUInt32);

        for J := Low(Visibles) to High(Visibles) do
          with Visibles[J] do
          begin
            FArea := ReadUInt32;
            Flags := ReadUInt8;
          end;

        FInheritVisibilityFrom := ReadUInt32;

        _unk1 := ReadUInt8;

        if _unk1 > 0 then
          Exit(NAV_LOAD_BAD_VERSION);
      end;

    if Version >= 6 then
    begin
      SetLength(Ladders, ReadUInt32);

      for I := Low(Ladders) to High(Ladders) do
        with Ladders[I] do
        begin
          Index := ReadUInt32;
          Width := ReadFloat;
          Top := ReadVec3F;
          Bottom := ReadVec3F;
          Length := ReadFloat;
          Direction := TNavDirection(ReadUInt32);

          if Version = 6 then
            IsDangling := ReadBool8;

          FTopForwardArea := ReadUInt32;
          FTopLeftArea := ReadUInt32;
          FTopRightArea := ReadUInt32;
          FTopBehindArea := ReadUInt32;
          FBottomArea := ReadUInt32;
        end;
    end;

    Free;
  end;

  Result := ReallocatePointers;
end;

function TNavMesh.SaveToFile(AFileName: LStr; OverwriteExisting: Boolean = True): TNavSaveResult;
var
  I, J, K: Int32;
begin
  Result := NAV_SAVE_OK;

  if FileExists(AFileName) and not OverwriteExisting then
    Exit(NAV_SAVE_FILE_ALREADY_EXISTS);

  with TBufferEx2.Create do
  begin
    WriteUInt32(NAV_MAGIC);
    WriteUInt32(Version);

    if Version >= 10 then
      WriteUInt32(SubVersion);

    if Version >= 4 then
      WriteUInt32(WorldSize);

    if Version >= 14 then
      WriteBool8(Analyzed);

    if Version >= 5 then
    begin
      WriteUInt16(Length(Locations));

      for I := Low(Locations) to High(Locations) do
      begin
        WriteUInt16(Length(Locations[I]) + 1);
        WriteLStr(Locations[I]);
      end;

      if Version > 11 then
        WriteBool8(HasUnnamedAreas);
    end;

    WriteUInt32(Length(Areas));

    for I := Low(Areas) to High(Areas) do
      with Areas[I] do
      begin
        WriteUInt32(Index);

        if Version <= 8 then
          WriteUInt8(Flags)
        else
          if Version < 13 then
            WriteUInt16(Flags)
          else
            WriteUInt32(Flags);

        Write(Extent, SizeOf(Extent));

        for J := Low(FConnections) to High(FConnections) do
        begin
          WriteUInt32(Length(FConnections[J]));

          for K := Low(FConnections[J]) to High(FConnections[J]) do
            WriteUInt32(FConnections[J][K]);
        end;

        WriteUInt8(Length(HidingSpots));

        for J := Low(HidingSpots) to High(HidingSpots) do
          with HidingSpots[J]^ do
            if Version > 1 then
            begin
              WriteUInt32(Index);
              WriteVec3F(Position);
              WriteUInt8(Flags);
            end
            else
              WriteVec3F(Position);

        if Version < 15 then
        begin
          WriteUInt8(Length(Approaches));

          for J := Low(Approaches) to High(Approaches) do
            with Approaches[J] do
            begin
              WriteUInt32(FHere);
              WriteUInt32(FPrev);
              WriteUInt8(UInt8(PrevToHereHow));
              WriteUInt32(FNext);
              WriteUInt8(UInt8(HereToNextHow));
            end;
        end;

        WriteUInt32(Length(Encounters));

        for J := Low(Encounters) to High(Encounters) do
          with Encounters[J] do
            if Version >= 3 then
            begin
              WriteUInt32(FFrom);
              WriteUInt8(UInt32(FromDir));

              WriteUInt32(FDest);
              WriteUInt8(UInt32(DestDir));

              WriteUInt8(Length(Spots));

              for K := Low(Spots) to High(Spots) do
                with Spots[K] do
                begin
                  WriteUInt32(FSpot);
                  WriteUInt8(T);
                end;
            end
            else
            begin
              WriteUInt32(FFrom);
              WriteUInt32(FDest);

              for K := 1 to 24 do // FIX, or fuck the fix >?
                WriteUInt8(0);

              //Skip(ReadUInt8 * 16); // FIX
            end;

        if Version < 5 then
          Continue;

        K := 0;

        for J := Low(Locations) to High(Locations) do
          if Location = @Locations[J] then
          begin
            K := J + 1;
            Break;
          end;

        WriteUInt16(K);

        if Version < 7 then
          Continue;

        for J := Low(FLadders) to High(FLadders) do
        begin
          WriteUInt32(Length(FLadders[J]));

          for K := Low(FLadders[J]) to High(FLadders[J]) do
            WriteUInt32(FLadders[J][K]);
        end;

        if Version < 8 then
          Continue;

        for J := Low(OccupyTimes) to High(OccupyTimes) do
          WriteFloat(OccupyTimes[J]);

        if Version < 11 then
          Continue;

        for J := Low(LightIntensity) to High(LightIntensity) do
          WriteFloat(LightIntensity[J]);

        if Version < 16 then
          Continue;

        WriteUInt32(Length(Visibles));

        for J := Low(Visibles) to High(Visibles) do
          with Visibles[J] do
          begin
            WriteUInt32(FArea);
            WriteUInt8(Flags);
          end;

        WriteUInt32(FInheritVisibilityFrom);
        WriteUInt8(_unk1);
      end;

    Position := 0;
    WriteFile(AFileName, ReadLStr(rmEnd));

    //SaveToFile(AFileName);

    Free;
  end;
end;

function TNavMesh.ReallocatePointers: TNavLoadResult;
var
  I, J, K: Int32;
begin
  Result := NAV_LOAD_OK;

  for I := Low(Areas) to High(Areas) do
    with Areas[I] do
    begin
      for J := Low(Connections) to High(Connections) do
      begin
        SetLength(Connections[J], Length(FConnections[J]));

        for K := Low(Connections[J]) to High(Connections[J]) do
        begin
          Connections[J][K] := GetArea(FConnections[J][K]);

          if Connections[J][K] = nil then
            Exit(NAV_LOAD_BAD_DATA);
        end;
      end;

      if Version < 15 then
        for J := Low(Approaches) to High(Approaches) do
          with Approaches[J] do
          begin
            Here := GetArea(FHere);

            if Here = nil then
              Exit(NAV_LOAD_BAD_DATA);

            Prev := GetArea(FPrev);
            Next := GetArea(FNext);
            Parent := GetArea(FParent);
          end;

      for J := Low(Encounters) to High(Encounters) do
        with Encounters[J] do
          if Version >= 3 then
          begin
            From := GetArea(FFrom);

            if From = nil then
              Exit(NAV_LOAD_BAD_DATA);

            Dest := GetArea(FDest);

            if Dest = nil then
              Exit(NAV_LOAD_BAD_DATA);

            for K := Low(Spots) to High(Spots) do
              with Spots[K] do
                Spot := GetHidingSpot(FSpot);
          end
          else
          begin
            From := GetArea(FFrom);

            if From = nil then
              Exit(NAV_LOAD_BAD_DATA);

            Dest := GetArea(FDest);

            if Dest = nil then
              Exit(NAV_LOAD_BAD_DATA);
          end;

      for J := Low(Ladders) to High(Ladders) do
      begin
        SetLength(Ladders[J], Length(FLadders[J]));

        for K := Low(Ladders[J]) to High(Ladders[J]) do
          Ladders[J][K] := GetLadder(FLadders[J][K]);
      end;

      for J := Low(Visibles) to High(Visibles) do
        with Visibles[J] do
        begin
          Area := GetArea(FArea);

          if Area = nil then
            Exit(NAV_LOAD_BAD_DATA);
        end;
    end;

  if Version >= 6 then
    for I := Low(Ladders) to High(Ladders) do
      with Ladders[I] do
      begin
        TopForwardArea := GetArea(FTopForwardArea);
        TopLeftArea := GetArea(FTopLeftArea);
        TopRightArea := GetArea(FTopRightArea);
        TopBehindArea := GetArea(FTopBehindArea);
        BottomArea := GetArea(FBottomArea);
      end;

  for I := Low(HidingSpots) to High(HidingSpots) do
    with HidingSpots[I] do
    begin
      Parent := GetArea(FParent);

      if Parent = nil then
        Exit(NAV_LOAD_BAD_DATA);

      SetLength(Parent.HidingSpots, Length(Parent.HidingSpots) + 1);
      Parent.HidingSpots[High(Parent.HidingSpots)] := @HidingSpots[I];
    end;
end;

procedure TNavMesh.LoadLaddersFromWorld(AWorld: PWorld);
const
  GenerationStepSize = 5;
var
  E: TArray<PWorldEntity>;
  M: PWorldModel;
  I: Int32;
  TopLine, BottomLine: TVec3FLine;
begin
  if Version >= 6 then
    Exit;

  if AWorld = nil then
    Exit;

  Finalize(Ladders);

  E := AWorld.GetEntitiesByClassName('func_ladder');

  for I := Low(E) to High(E) do
  begin
    M := AWorld.GetModelForEntity(E[I]^);

    if M = nil then
      Continue;

    TopLine := TVec3FLine.Create(M.MaxS.X, M.MaxS.Y, M.MaxS.Z, M.MinS.X, M.MinS.Y, M.MaxS.Z);
    BottomLine := TVec3FLine.Create(M.MinS.X, M.MinS.Y, M.MinS.Z, M.MaxS.X, M.MaxS.Y, M.MinS.Z);

    SetLength(Ladders, Length(Ladders) + 1);

    with Ladders[High(Ladders)] do
    begin
      Top := TopLine.Center;
      Bottom := BottomLine.Center;
      Width := (TopLine.Length + BottomLine.Length) / 2;
      Length := Top.Distance(Bottom);

      BottomArea := GetArea(Bottom);
      TopForwardArea := GetArea(Top);

      // custom stuff:

      TL := TopLine;
      BL := BottomLine;
    end;
  end;

  for I := Low(Ladders) to High(Ladders) do
    with Ladders[I] do
    begin
      SetLength(BottomArea.Ladders[UInt32(NAV_LADDER_UP)], System.Length(BottomArea.Ladders[UInt32(NAV_LADDER_UP)]) + 1);
      BottomArea.Ladders[UInt32(NAV_LADDER_UP)][High(BottomArea.Ladders[UInt32(NAV_LADDER_UP)])] := @Ladders[I];

      SetLength(TopForwardArea.Ladders[UInt32(NAV_LADDER_DOWN)], System.Length(TopForwardArea.Ladders[UInt32(NAV_LADDER_DOWN)]) + 1);
      TopForwardArea.Ladders[UInt32(NAV_LADDER_DOWN)][High(TopForwardArea.Ladders[UInt32(NAV_LADDER_DOWN)])] := @Ladders[I];
    end;
end;

function TNavMesh.HasLocations: Boolean;
begin
  Result := LocationsCount > 0;
end;

function TNavMesh.HasLocation(ALocation: LStr): Boolean;
var
  I: Int32;
begin
  Result := False;

  if not HasLocations then
    Exit;

  for I := Low(Locations) to High(Locations) do
    if Locations[I] = ALocation then
      Exit(True);
end;

function TNavMesh.HasAreas: Boolean;
begin
  Result := AreasCount > 0;
end;

function TNavMesh.HasAreas(ALocation: LStr): Boolean;
var
  I: Int32;
begin
  Result := False;

  if not HasAreas then
    Exit;

  if not HasLocation(ALocation) then
    Exit;

  for I := Low(Areas) to High(Areas) do
    if Areas[I].AtLocation(ALocation) then
      Exit(True);
end;

function TNavMesh.HasLadders: Boolean;
begin
  Result := LaddersCount > 0;
end;

function TNavMesh.HasHidingSpots: Boolean;
begin
  Result := HidingSpotsCount > 0;
end;

function TNavMesh.GetAreas(ALocation: LStr): TArray<PNavArea>;
var
  I: Int32;
begin
  Finalize(Result);

  if not HasAreas(ALocation) then
    Exit;

  with TList<PNavArea>.Create do
  begin
    for I := Low(Areas) to High(Areas) do
      if Areas[I].AtLocation(ALocation) then
        Add(@Areas[I]);

    Result := ToArray;
    Free;
  end;
end;

function TNavMesh.GetArea(AIndex: UInt32): PNavArea;
var
  I: Int32;
begin
  Result := nil;

  if not HasAreas then
    Exit;

  for I := Low(Areas) to High(Areas) do
    if Areas[I].Index = AIndex then
      Exit(@Areas[I]);
end;

function TNavMesh.GetArea(APosition: TVec3F; GetNearestOnFailure: Boolean = True): PNavArea;
var
  I: Int32;
  D: Float;
begin
  Result := nil;

  if not HasAreas then
    Exit;

  for I := Low(Areas) to High(Areas) do
    if Areas[I].IsContains(APosition) then
      Exit(@Areas[I]);

  if not GetNearestOnFailure then
    Exit;

  D := MAX_DISTANCE;

  for I := Low(Areas) to High(Areas) do
    if Areas[I].GetDistanceEx(APosition) < D then
    begin
      D := Areas[I].GetDistanceEx(APosition);
      Result := @Areas[I];
    end;

  if Result = nil then
    for I := Low(Areas) to High(Areas) do
      if Areas[I].GetDistance(APosition) < D then
      begin
        D := Areas[I].GetDistance(APosition);
        Result := @Areas[I];
      end;
end;

function TNavMesh.GetArea(APosition: TVec3F; ALocation: LStr): PNavArea;
var
  I: Int32;
  D: Float;
begin
  Result := nil;

  if not HasAreas(ALocation) then
    Exit;

  D := MAX_DISTANCE;

  for I := Low(Areas) to High(Areas) do
    if Areas[I].Location <> nil then
      if (Areas[I].GetDistanceEx(APosition) < D) and (Areas[I].Location^ = ALocation) then
      begin
        D := Areas[I].GetDistanceEx(APosition);
        Result := @Areas[I];
      end;

  if Result = nil then
    for I := Low(Areas) to High(Areas) do
      if Areas[I].Location <> nil then
        if (Areas[I].GetDistance(APosition) < D) and (Areas[I].Location^ = ALocation) then
        begin
          D := Areas[I].GetDistance(APosition);
          Result := @Areas[I];
        end;
end;

function TNavMesh.GetArea(APosition: TVec2F): PNavArea;
var
  I: Int32;
  D: Float;
begin
  Result := nil;

  if not HasAreas then
    Exit;

  for I := Low(Areas) to High(Areas) do
    if Areas[I].IsContains(APosition) then
      Exit(@Areas[I]);

  D := MAX_DISTANCE;

  for I := Low(Areas) to High(Areas) do
    if Areas[I].GetDistanceEx(APosition) < D then
    begin
      D := Areas[I].GetDistanceEx(APosition);
      Result := @Areas[I];
    end;

  if Result = nil then
    for I := Low(Areas) to High(Areas) do
      if Areas[I].GetDistance(APosition) < D then
      begin
        D := Areas[I].GetDistance(APosition);
        Result := @Areas[I];
      end;
end;

function TNavMesh.GetAbsoluteIndex(AArea: TNavArea): Int32;
var
  I: Int;
begin
  Result := -1;

  for I := Low(Areas) to High(Areas) do
    if Areas[I].Index = AArea.Index then
      Exit(I);
end;

function TNavMesh.GetAbsoluteIndex(AArea: PNavArea): Int32;
begin
  if AArea = nil then
    Exit(-1);

  Result := (UInt32(AArea) - UInt32(@Areas[0])) div SizeOf(TNavArea);
end;

function TNavMesh.GetAbsoluteIndex(AHidingSpot: TNavHidingSpot): Int32;
var
  I: Int;
begin
  Result := -1;

  for I := Low(HidingSpots) to High(HidingSpots) do
    if HidingSpots[I].Index = AHidingSpot.Index then
      Exit(I);
end;

function TNavMesh.GetAbsoluteIndex(AHidingSpot: PNavHidingSpot): Int32;
begin
  if AHidingSpot = nil then
    Exit(-1);

  Result := (UInt32(AHidingSpot) - UInt32(@HidingSpots[0])) div SizeOf(TNavHidingSpot);
end;

function TNavMesh.GetHidingSpots(APosition: TVec3F; ARadius: Float): TArray<PNavHidingSpot>;
var
  I: Int32;
begin
  Finalize(Result);

  if not HasHidingSpots then
    Exit;

  with TList<PNavHidingSpot>.Create do
  begin
    for I := Low(HidingSpots) to High(HidingSpots) do
      if HidingSpots[I].Position.Distance(APosition) <= ARadius then
        Add(@HidingSpots[I]);

    Result := ToArray;
    Free;
  end;
end;

function TNavMesh.GetHidingSpot(AIndex: UInt32): PNavHidingSpot;
var
  I: Int32;
begin
  Result := nil;

  if not HasHidingSpots then
    Exit;

  for I := Low(HidingSpots) to High(HidingSpots) do
    if HidingSpots[I].Index = AIndex then
      Exit(@HidingSpots[I]);
end;

function TNavMesh.GetHidingSpot(APosition: TVec3F): PNavHidingSpot;
var
  I: Int32;
  D: Float;
begin
  Result := nil;

  if not HasHidingSpots then
    Exit;

  D := MAX_DISTANCE;

  for I := Low(HidingSpots) to High(HidingSpots) do
    if HidingSpots[I].Position.Distance(APosition) < D then
    begin
      D := HidingSpots[I].Position.Distance(APosition);
      Result := @HidingSpots[I];
    end;
end;

function TNavMesh.GetHidingSpot(APosition: TVec3F; ARadius: Float): PNavHidingSpot;
begin
  Result := GetHidingSpot(APosition);

  if Result.Distance(APosition) > ARadius then
    Result := nil;
end;

function TNavMesh.GetHidingSpot(APosition: TVec2F): PNavHidingSpot;
var
  I: Int32;
  D: Float;
begin
  Result := nil;

  if not HasHidingSpots then
    Exit;

  D := MAX_DISTANCE;

  for I := Low(Areas) to High(Areas) do
    if HidingSpots[I].Position.Distance(APosition) < D then
    begin
      D := HidingSpots[I].Position.Distance(APosition);
      Result := @HidingSpots[I];
    end;
end;

function TNavMesh.GetHidingSpot(AArea: TNavArea): PNavHidingSpot;
begin
  Result := GetHidingSpot(AArea.GetCenter);
end;

function TNavMesh.GetLadder(AIndex: UInt32): PNavLadder;
var
  I: Int32;
begin
  Result := nil;

  for I := Low(Ladders) to High(Ladders) do
    if Ladders[I].Index = AIndex then
      Exit(@Ladders[I]);
end;

function TNavMesh.LocationsCount: UInt32;
begin
  Result := Length(Locations);
end;

function TNavMesh.AreasCount: UInt32;
begin
  Result := Length(Areas)
end;

function TNavMesh.LaddersCount: UInt32;
begin
  Result := Length(Ladders)
end;

function TNavMesh.HidingSpotsCount: UInt32;
begin
  Result := Length(HidingSpots);
end;

function TNavMesh.ApproachesCount: UInt32;
var
  I: Int32;
begin
  Clear(Result);

  for I := Low(Areas) to High(Areas) do
    Inc(Result, Areas[I].ApproachesCount);
end;

function TNavMesh.EncountersCount: UInt32;
var
  I: Int32;
begin
  Clear(Result);

  for I := Low(Areas) to High(Areas) do
    Inc(Result, Areas[I].EncountersCount);
end;

function TNavMesh.GetRandomArea: PNavArea;
begin
  Result := nil;

  if not HasAreas then
    Exit;

  Result := @Areas[Random(AreasCount)];
end;

function TNavMesh.GetRandomArea(ALocation: LStr): PNavArea;
var
  I: Int32;
begin
  Result := nil;

  if not HasAreas(ALocation) then
    Exit;

  with TList<PNavArea>.Create do
  begin
    for I := Low(Areas) to High(Areas) do
      if Areas[I].Location <> nil then
        if Areas[I].Location^ = ALocation then
          Add(@Areas[I]);

    if Count > 0 then
      Result := Items[Random(Count)]
    else
      Result := nil;

    Free;
  end;
end;

function TNavMesh.GetRandomHidingSpot: PNavHidingSpot;
begin
  Result := nil;

  if not HasHidingSpots then
    Exit;

  Result := @HidingSpots[Random(HidingSpotsCount)];
end;

function TNavMesh.GetRandomHidingSpot(APosition: TVec3F; ARadius: Float): PNavHidingSpot;
var
  I: Int32;
  H: TArray<PNavHidingSpot>;
begin
  Result := nil;

  H := GetHidingSpots(APosition, ARadius);

  if Length(H) > 0 then
    Result := H[Random(Length(H))];
end;

function TNavMesh.GetChain(AFrom, ATo: PNavArea; ACostMultiplier: TCostMultiplier = nil; ExceptAreaFlags: UInt32 = 0; Optimization: Boolean = True): TNavChain;
  procedure AddToList(var AList: TArray<PNavArea>; AArea: PNavArea); inline;
  begin
    SetLength(AList, Length(AList) + 1);
    AList[High(AList)] := AArea;
  end;

  procedure CalculateCost(AArea, AParent: PNavArea; G: Float = 0);
  begin
    with AArea^ do
    begin
      FParent := AParent;

      //if Algorhytm <> NAV_CHAIN_BESTFIRST then
        FCostToStart := G;

      //if Algorhytm <> NAV_CHAIN_DIJKSTRA then
        if FParent = nil then
          FCostToFinish := GetDistance(ATo^)
        else
          FCostToFinish := FParent.GetPortal(AArea^).Center.Distance(ATo.GetCenter);

      FCostTotal := FCostToStart + FCostToFinish;
    end;
  end;

  function BuildChain(AArea: PNavArea): TNavChain;
  var
    R: TArray<PNavArea>;
    I: Int32;
  begin
    while AArea <> nil do // build chain
    begin
      SetLength(R, Length(R) + 1);
      R[High(R)] := AArea;
      AArea := AArea.FParent;
    end;

    SetLength(Result, Length(R));

    for I := High(R) downto Low(R) do // reverse chain
      Result[Length(Result) - I - 1] := R[I];

    Finalize(R);
  end;
  
var
  I, J: Int32;
  D, G, M: Float;
  A, B: PNavArea;
  V: TVec3F;
  L: TList<PNavArea>;
  P: TVec3FLine;
begin
  if AFrom = nil then
    Exit;

  if ATo = nil then
    Exit;

  if ATo.Flags and ExceptAreaFlags <> 0 then
    Exit;

  if AFrom.Flags and ExceptAreaFlags <> 0 then
    Exit;

  if AFrom = ATo then
  begin
    SetLength(Result, 1);
    Result[0] := AFrom;
    Exit;
  end;

  Finalize(Result);

  for I := Low(Areas) to High(Areas) do
    with Areas[I] do
    begin
      Clear(FVisited);
      Clear(FParent);
      Clear(FCostToStart); // G
      Clear(FCostToFinish); // H
      Clear(FCostTotal); // F
    end;

  L := TList<PNavArea>.Create;
  L.Add(AFrom);
  CalculateCost(AFrom, nil);

  while True do
  begin
    A := nil;

    D := MAX_DISTANCE;

    for I := 0 to L.Count - 1 do
      if not L[I].FVisited and (L[I].FCostTotal < D) then
      begin
        A := L[I];
        D := L[I].FCostTotal;
      end;

    if (A = nil) or (A = ATo) then // 'nil' means no way to destination
      Break;

    A.FVisited := True;

    with TList<PNavArea>.Create do
    begin
      for I := Low(A.Ladders) to High(A.Ladders) do
        for J := Low(A.Ladders[I]) to High(A.Ladders[I]) do
          case I of
            UInt32(NAV_LADDER_UP): Add(A.Ladders[I][J].TopForwardArea);
            UInt32(NAV_LADDER_DOWN): Add(A.Ladders[I][J].BottomArea);
          end;

      for I := Low(A.Connections) to High(A.Connections) do
        for J := Low(A.Connections[I]) to High(A.Connections[I]) do
          Add(A.Connections[I][J]);

      for I := 0 to Count - 1 do
      begin
        B := List[I];

        if B.Flags and ExceptAreaFlags <> 0 then // 'B' is bad area, skip
          Continue;

        if B.FVisited then // 'B' was checked already, skip
          Continue;

        M := 1;

        if @ACostMultiplier <> nil then
          M := ACostMultiplier(B^);

        P := A.GetPortal(B^);

        if A.FParent <> nil then
          G := A.FCostToStart + (A.FParent.GetPortal(A^).Center.Distance(P.Hi) * M)
        else
          G := A.GetCenter.Distance(P.Hi) * M;

        G := G + P.Length; // add portal length

        if L.Contains(B) then
          if G < B.FCostToStart then
            CalculateCost(B, A, G)
          else
        else
        begin
          L.Add(B);
          CalculateCost(B, A, G);
        end;
      end;

      Free;
    end;

    {for I := Low(A.Connections) to High(A.Connections) do
      for J := Low(A.Connections[I]) to High(A.Connections[I]) do
      begin
        B := A.Connections[I][J];

        if B.Flags and ExceptAreaFlags <> 0 then // 'B' is bad area, skip
          Continue;

        if B.FVisited then // 'B' was checked already, skip
          Continue;

        M := 1;

        if @ACostMultiplier <> nil then
          M := ACostMultiplier(B^);

        P := A.GetPortal(B^);

        if A.FParent <> nil then
          G := A.FCostToStart + (A.FParent.GetPortal(A^).Center.Distance(P.Hi) * M)
        else
          G := A.GetCenter.Distance(P.Hi) * M;

        G := G + P.Length; // add portal length

        if L.Contains(B) then
          if G < B.FCostToStart then
            CalculateCost(B, A, G)
          else
        else
        begin
          L.Add(B);
          CalculateCost(B, A, G);
        end;
      end;     }
  end;

  Result := BuildChain(A);

  if Optimization then
    OptimizeNavChain(Result);

  L.Free;
end;

procedure TNavMesh.RemoveFlagFromAllAreas(AFlag: UInt32);
var
  I: Int32;
begin
  for I := Low(Areas) to High(Areas) do
    Areas[I].Flags := Areas[I].Flags and not AFlag;
end;

procedure TNavMesh.Connect(A1, A2: TNavArea; ADirection: TNavDirection);
begin
  A1.Connect(A2, ADirection);
  ReallocatePointers;
end;

procedure TNavMesh.BiConnect(A1, A2: TNavArea; ADirection: TNavDirection);
begin
  //A1.BiConnect(A2, ADirection);
  //ReallocatePointers;
  Connect(A1, A2, ADirection);
  Connect(A2, A1, ADirection);
end;

procedure TNavMesh.Disconnect(A1, A2: TNavArea);
begin
  A1.Disconnect(A2);
  ReallocatePointers;
end;

procedure TNavMesh.BiDisconnect(A1, A2: TNavArea);
begin
  A1.BiDisconnect(A2);
  ReallocatePointers;
 { Disconnect(A1, A2);
  Disconnect(A2, A1);}
end;

procedure TNavMesh.Merge(A1, A2: TNavArea);
var
  D: TNavDirection;
  I, J: Int32;
begin
  if not A1.IsBiLinked(A2) then
    Exit;

  D := A1.GetDirection(A2);

  // check for sizes here

  {case D of
    NAV_NORTH:
    begin
      A1.Extent.Hi := A2.Extent.Hi;
      A1.Extent.Heights.X := A2.Extent.Heights.X;
    end;

    NAV_EAST:
    begin
      A1.Extent.Lo := A2.Extent.Lo;
      A1.Extent.Heights.X := A2.Extent.Heights.X;
    end;

    NAV_SOUTH:
    begin
      A1.Extent.Lo := A2.Extent.Lo;
      A1.Extent.Heights.Y := A2.Extent.Heights.Y;
    end;

    NAV_WEST:
    begin
      A1.Extent.Hi := A2.Extent.Hi;
      A1.Extent.Heights.Y := A2.Extent.Heights.Y;
    end;
  end;}

  {A1.BiDisconnect(A2);

  for I := Int32(NAV_DIRECTION_MIN) to Int32(NAV_DIRECTION_MAX) do
    for J := High(A2.Connections[I]) downto Low(A2.Connections[I]) do
    begin
      A1.BiConnect(A2.Connections[I][J]^, TNavDirection(I));
      A2.BiDisconnect(A2.Connections[I][J]^);
    end;}

  Delete(A2);
end;

procedure TNavMesh.Delete(AArea: TNavArea);
var
  I, J: Int32;
begin
  for I := Low(AArea.Connections) to High(AArea.Connections) do
    for J := High(AArea.Connections[I]) downto Low(AArea.Connections[I]) do
     // AArea.BiDisconnect(AArea.Connections[I][J]^);
     AArea.Connections[I][J].Disconnect(AArea);

  J := GetAbsoluteIndex(AArea);

  for I := J to High(Areas) - 1 do
    Areas[I] := Areas[I + 1];

  SetLength(Areas, Length(Areas) - 1);

  ReallocatePointers;
end;

procedure TNavMesh.Generate(AWorld: TWorld);
begin
  Version := 5;
  WorldSize := AWorld.Size;
  Name := AWorld.Name;

  FindWalkableSpace(AWorld);
//  MergeAreas;
end;

procedure TNavMesh.MergeAreas;
var
  I, J, K: Int32;
begin
  for I := Low(Areas) to High(Areas) do
    for J := Low(Areas[I].Connections) to High(Areas[I].Connections) do
      for K := Low(Areas[I].Connections[J]) to High(Areas[I].Connections[J]) do
        if Areas[I].GetSide(TNavDirection(J)) = Areas[I].Connections[J][K].GetSide(OppositeNavDirection(TNavDirection(J))) then
        begin
          Merge(Areas[I], Areas[I].Connections[J][K]^);
          MergeAreas;
          Exit;
        end;
end;

procedure TNavMesh.FindWalkableSpace(AWorld: TWorld);
var
  Entities: TArray<PWorldEntity>;
  V: TVec3F;
  I, J, K: Int32;
  T: TTokenizer;
  S: PLStr;
  TL: TWorldTrace;
begin
  Entities := AWorld.GetEntitiesByClassName('info_player_start') +
              AWorld.GetEntitiesByClassName('info_player_deathmatch'); // wow!

  T := TTokenizer.Create;

  for I := Low(Entities) to High(Entities) do
  begin
    S := Entities[I].GetValue('origin');

    if S = nil then
      Continue;

    T.Tokenize(S^);

    for J := 0 to 2 do
      V.A[J] := StrToFloatDefDot(T.Tokens[J], 0);

    TL := AWorld.TraceLine(V, V - TVec3F.Create(0, 0, MAX_UNITS));

    if GetArea(TL.EndPos, False) <> nil then
      Continue;

    AddNodeArea(AWorld, TL.EndPos);

    FloodFill(AWorld);
  end;

  T.Free;

  ReallocatePointers;
end;

procedure TNavMesh.FloodFill(AWorld: TWorld);
var
  D: TNavDirection;
  I: Int32;
  V: TVec3F;
  B: Boolean;
  A: PNavArea;
begin
  while B do
  begin
    B := False;

    for I := High(Areas) downto Low(Areas) do
    begin
      if Areas[I].FVisited then
        Continue;

      for D := NAV_DIRECTION_MIN to NAV_DIRECTION_MAX do
      begin
        V := Areas[I].GetCenter + TVec3F.Create(0, 0, HUMAN_HEIGHT);

        case D of
          NAV_NORTH: V.Y := V.Y - NAV_STEP_SIZE;
          NAV_EAST: V.X := V.X + NAV_STEP_SIZE;
          NAV_SOUTH: V.Y := V.Y + NAV_STEP_SIZE;
          NAV_WEST: V.X := V.X - NAV_STEP_SIZE;
        end;

        if not AWorld.IsVisible(Areas[I].GetCenter + TVec3F.Create(0, 0, HUMAN_HEIGHT), V) then
          Continue;

        A := GetArea(V - TVec3F.Create(0, 0, HUMAN_HEIGHT), False);

        if A <> nil then
        begin
          Areas[I].BiConnect(A^, D);
          Continue;
        end;

        A := AddNodeArea(AWorld, V);

        if A = nil then
          Continue;

        Areas[I].BiConnect(A^, D);

        B := True;
      end;

      Areas[I].FVisited := True;
    end;
  end;
end;

function TNavMesh.AddNodeArea(AWorld: TWorld; AOrigin: TVec3F): PNavArea;
var
  LeftTop,
  RightTop,
  LeftDown,
  RightDown: TVec3F;

  MaxZ, MinZ: Float;
begin
  Result := nil;

  LeftTop := AOrigin + TVec3F.Create(NAV_STEP_SIZE / 2, NAV_STEP_SIZE / 2, 0);
  RightTop := AOrigin + TVec3F.Create(NAV_STEP_SIZE / 2, -(NAV_STEP_SIZE / 2), 0);
  LeftDown := AOrigin + TVec3F.Create(-(NAV_STEP_SIZE / 2), NAV_STEP_SIZE / 2, 0);
  RightDown := AOrigin + TVec3F.Create(-(NAV_STEP_SIZE / 2), -(NAV_STEP_SIZE / 2), 0);

  if not AWorld.IsVisible(AOrigin, LeftTop) then
    Exit
  else
    if not AWorld.IsVisible(AOrigin, RightTop) then
      Exit
    else
      if not AWorld.IsVisible(AOrigin, LeftDown) then
        Exit
      else
        if not AWorld.IsVisible(AOrigin, RightDown) then
          Exit;

  LeftTop.Z := AWorld.TraceLine(LeftTop, LeftTop - TVec3F.Create(0, 0, MAX_UNITS)).EndPos.Z;
  RightTop.Z := AWorld.TraceLine(RightTop, RightTop - TVec3F.Create(0, 0, MAX_UNITS)).EndPos.Z;
  LeftDown.Z := AWorld.TraceLine(LeftDown, LeftDown - TVec3F.Create(0, 0, MAX_UNITS)).EndPos.Z;
  RightDown.Z := AWorld.TraceLine(RightDown, RightDown - TVec3F.Create(0, 0, MAX_UNITS)).EndPos.Z;

  MaxZ := Max(Max(LeftTop.Z, RightTop.Z), Max(LeftDown.Z, RightDown.Z));
  MinZ := Min(Min(LeftTop.Z, RightTop.Z), Min(LeftDown.Z, RightDown.Z));

  if MaxZ - MinZ > HUMAN_HEIGHT + HUMAN_HEIGHT_HALF then
    Exit;

  Result := AddArea(TNavArea.Create(LeftTop, RightTop, LeftDown, RightDown));
end;

function TNavMesh.AddArea(AArea: TNavArea): PNavArea;
begin
  SetLength(Areas, Length(Areas) + 1);
  AArea.Index := Length(Areas);
  AArea.Flags := 0;
  Areas[High(Areas)] := AArea;

  Result := @Areas[High(Areas)];
end;

function TArrayPNavAreaHelper.IndexOf(AArea: TNavArea): Int32;
var
  I: Int32;
begin
  Result := -1;

  for I := Low(Self) to High(Self) do
    if Self[I]^ = AArea then
      Exit(I);
end;

function TArrayPNavAreaHelper.IsContains(AArea: TNavArea): Boolean;
begin
  Result := Self.IndexOf(AArea) >= 0;
end;

function OppositeNavDirection(ADirection: TNavDirection): TNavDirection;
begin
  case ADirection of
    NAV_NORTH: Result := NAV_SOUTH;
    NAV_SOUTH: Result := NAV_NORTH;
    NAV_EAST: Result := NAV_WEST;
    NAV_WEST: Result := NAV_EAST;
  else
    Result := NAV_NUM_DIRECTIONS;
  end;
end;

function NavDirectionLeft(ADirection: TNavDirection): TNavDirection;
begin
  case ADirection of
    NAV_NORTH: Result := NAV_WEST;
    NAV_EAST: Result := NAV_NORTH;
    NAV_SOUTH: Result := NAV_EAST;
    NAV_WEST: Result := NAV_SOUTH;
  else
    Result := NAV_NUM_DIRECTIONS;
  end;
end;

function NavDirectionRight(ADirection: TNavDirection): TNavDirection;
begin
  case ADirection of
    NAV_NORTH: Result := NAV_EAST;
    NAV_EAST: Result := NAV_SOUTH;
    NAV_SOUTH: Result := NAV_WEST;
    NAV_WEST: Result := NAV_NORTH;
  else
    Result := NAV_NUM_DIRECTIONS;
  end;
end;

function NavDirectionToAngle(ADirection: TNavDirection): Float;
begin
  case ADirection of
    NAV_NORTH: Result := 270;
    NAV_EAST: Result := 0;
    NAV_SOUTH: Result := 90;
    NAV_WEST: Result := 180;
  else
    Result := 0;
  end;
end;

function AngleToNavDirection(AAngle: Float): TNavDirection;
begin
  while AAngle < 0 do
    AAngle := AAngle + 360;

  while AAngle > 360 do
    AAngle := AAngle - 360;

  if (AAngle < 45) or (AAngle > 315) then
    Exit(NAV_EAST);

  if (AAngle >= 45) or (AAngle < 135) then
    Exit(NAV_SOUTH);

  if (AAngle >= 135) or (AAngle < 225) then
    Exit(NAV_WEST);

  Result := NAV_NUM_DIRECTIONS;
end;

function RandomNavDirection: TNavDirection;
begin
  Result := TNavDirection(Random(4));
end;

function GetNavChainLength(AChain: TNavChain): Float;
var
  I: Int32;
  V, V2: TVec3F;
begin
  Clear(Result);

  if Length(AChain) < 2 then
    Exit;

  V := AChain[0].GetCenter;

  for I := Low(AChain) + 1 to High(AChain) do
    with AChain[I - 1]^ do
    begin
      V2 := GetPortal(AChain[I]^).Center;
      Result := Result + V.Distance(V2);
      V := V2;
    end;
end;

procedure OptimizeNavChain(var AChain: TNavChain);
var
  I, J, K: Int32;
label
  L1;
begin
  while True do
  begin
    for I := Low(AChain) to High(AChain) - 2 do
      for J := High(AChain) downto I + 2 do
        if AChain[I].IsConnected(AChain[J]^) then
          goto L1;

    Exit;

    L1:
    for K := J to High(AChain) do
      AChain[I + K - J + 1] := AChain[K];

    SetLength(AChain, Length(AChain) - (J - I - 1));
  end;
end;

function GetNavFlagsStr(AFlags: UInt32): LStr;
var
  I: Int32;
begin
  Clear(Result);

  if AFlags = 0 then
    Exit('NONE');

  for I := 0 to 31 do
    if 1 shl I and AFlags > 0 then
      case 1 shl I of
        NAV_AREA_INVALID: ;
        NAV_AREA_CROUCH: Result := Result + 'CROUCH. ';
        NAV_AREA_JUMP: Result := Result + 'JUMP. ';
        NAV_AREA_PRECISE: Result := Result + 'PRECISE. ';
        NAV_AREA_NO_JUMP: Result := Result + 'NO_JUMP. ';

        NAV_AREA_STOP: Result := Result + 'STOP. ';
        NAV_AREA_RUN: Result := Result + 'RUN. ';
        NAV_AREA_WALK: Result := Result + 'WALK. ';
        NAV_AREA_AVOID: Result := Result + 'AVOID. ';
        NAV_AREA_TRANSIENT: Result := Result + 'TRANSIENT. ';
        NAV_AREA_DONT_HIDE: Result := Result + 'DONT_HIDE. ';
        NAV_AREA_STAND: Result := Result + 'STAND. ';
        NAV_AREA_NO_HOSTAGES: Result := Result + 'NO_HOSTAGES. ';
        NAV_AREA_STAIRS: Result := Result + 'STAIRS. ';
        NAV_AREA_NO_MERGE: Result := Result + 'NO_MERGE. ';
        NAV_AREA_OBSTACLE_TOP: Result := Result + 'OBSTACLE_TOP. ';
        NAV_AREA_CLIFF: Result := Result + 'CLIFF. ';

        //NAV_AREA_FIRST_CUSTOM = 1 shl 16;
        // custom area flags must be between this two
        //NAV_AREA_LAST_CUSTOM = 1 shl 26;

        NAV_AREA_FUNC_COST: Result := Result + 'FUNC_COST. ';
        NAV_AREA_HAS_ELEVATOR: Result := Result + 'ELEVATOR. ';
        //NAV_AREA_NAV_BLOCKER: Result := Result + 'BLOCKER. ';
      end;
end;

function GetNavFlagStr(AFlag: UInt32): LStr;
begin
  Clear(Result);

  case AFlag of
    NAV_AREA_INVALID: ;
    NAV_AREA_CROUCH: Result := 'CROUCH';
    NAV_AREA_JUMP: Result := 'JUMP';
    NAV_AREA_PRECISE: Result := 'PRECISE';
    NAV_AREA_NO_JUMP: Result := 'NO_JUMP';

    NAV_AREA_STOP: Result := 'STOP';
    NAV_AREA_RUN: Result := 'RUN';
    NAV_AREA_WALK: Result := 'WALK';
    NAV_AREA_AVOID: Result := 'AVOID';
    NAV_AREA_TRANSIENT: Result := 'TRANSIENT';
    NAV_AREA_DONT_HIDE: Result := 'DONT_HIDE';
    NAV_AREA_STAND: Result := 'STAND';
    NAV_AREA_NO_HOSTAGES: Result := 'NO_HOSTAGES';
    NAV_AREA_STAIRS: Result := 'STAIRS';
    NAV_AREA_NO_MERGE: Result := 'NO_MERGE';
    NAV_AREA_OBSTACLE_TOP: Result := 'OBSTACLE_TOP';
    NAV_AREA_CLIFF: Result := 'CLIFF';

    //NAV_AREA_FIRST_CUSTOM = 1 shl 16;
    // custom area flags must be between this two
    //NAV_AREA_LAST_CUSTOM = 1 shl 26;

    NAV_AREA_FUNC_COST: Result := 'FUNC_COST';
    NAV_AREA_HAS_ELEVATOR: Result := 'ELEVATOR';
    //NAV_AREA_NAV_BLOCKER: Result := 'BLOCKER';
  end;
end;

procedure Clear(var Data: TNavDirection);
begin
  Data := NAV_NUM_DIRECTIONS;
end;

procedure Clear(var Data: TNavTraverseType);
begin
  Data := NAV_NUM_TRAVERSE_TYPES;
end;

procedure Clear(var Data: TNavCorner);
begin
  Data := NAV_NUM_CORNERS;
end;

procedure Clear(var Data: TNavRelativeDirection);
begin
  Data := NAV_NUM_RELATIVE_DIRECTIONS;
end;

procedure Clear(var Data: TNavLadderDirection);
begin
  Data := NAV_NUM_LADDER_DIRECTIONS;
end;

procedure Clear(var Data: TNavHidingSpot);
begin
  with Data do
  begin
    Clear(Index);
    Clear(Position);
    Clear(Flags);
    Clear(Parent);
  end;
end;

procedure Clear(var Data: PNavHidingSpot);
begin
  Data := nil;
end;

procedure Clear(var Data: TNavApproach);
begin
  with Data do
  begin
    Clear(Here);
    Clear(Prev);
    Clear(PrevToHereHow);
    Clear(Next);
    Clear(HereToNextHow);
  end;
end;

procedure Clear(var Data: TNavEncounterSpot);
begin
  with Data do
  begin
//    Clear(Spot);
    Clear(T);
  end;
end;

procedure Clear(var Data: TNavEncounter);
begin
  with Data do
  begin
    Clear(From);
    Clear(FromDir);
    Clear(Dest);
    Clear(DestDir);
    Finalize(Spots);
  end;
end;

procedure Clear(var Data: PNavLadder);
begin
  Data := nil;
end;

procedure Clear(var Data: TNavVisibility);
var
  I: Int32;
begin
  with Data do
  begin
    Clear(Area);
    Clear(Flags);
  end;
end;

procedure Clear(var Data: TNavArea);
begin
  with Data do
  begin
    Clear(FVisited);
    Clear(FParent);
    Clear(FCostToStart);
    Clear(FCostToFinish);
    Clear(FCostTotal);

    Clear(Index);
    Clear(Extent);
    Clear(Flags);
   // Finalize(Connections);
    Finalize(HidingSpots);
    Finalize(Approaches);
    Finalize(Encounters);
    Finalize(Ladders);
    Finalize(OccupyTimes);
    Finalize(LightIntensity);
    Finalize(Visibles);
    Clear(InheritVisibilityFrom);
    Clear(Location);
    Clear(FVisited);
  end;
end;

procedure Clear(var Data: PNavArea);
begin
  Data := nil;
end;

procedure Clear(var Data: TNavLadder);
begin
  with Data do
  begin
    Clear(Index);
    Clear(Top);
    Clear(Bottom);
    Clear(Width);
    Clear(Length);
    Clear(Direction);
    Clear(IsDangling);
    Clear(TopForwardArea);
    Clear(TopLeftArea);
    Clear(TopRightArea);
    Clear(TopBehindArea);
    Clear(BottomArea);
  end;
end;

end.
