unit World;  // BSP30

interface

uses {$REGION 'Include}
  System.Generics.Collections,
  System.Generics.Defaults,

  IOUtils,

  SysUtils,
  Default,
  Buffer,
  Shared,
  Tokenizer,
  Protocol,
  Vector,
  Entity;
  {$ENDREGION}

  {$REGION 'Protocol'}
const
  BSP_VERSION = 30;

  BSP_LUMP_ENTITIES = 0;
  BSP_LUMP_PLANES = 1;
  BSP_LUMP_ENTITIES_BSHIFT = 1;
  BSP_LUMP_PLANES_BSHIFT = 0;
  BSP_LUMP_TEXTURES = 2;
  BSP_LUMP_VERTEXES = 3;
  BSP_LUMP_VISIBILITY = 4;
  BSP_LUMP_NODES = 5;
  BSP_LUMP_TEXINFO = 6;
  BSP_LUMP_FACES = 7;
  BSP_LUMP_LIGHTING = 8;
  BSP_LUMP_CLIPNODES = 9;
  BSP_LUMP_LEAFS = 10;
  BSP_LUMP_MARKSURFACES = 11;
  BSP_LUMP_EDGES = 12;
  BSP_LUMP_SURFEDGES = 13;
  BSP_LUMP_MODELS = 14;

  BSP_HEADER_LUMPS = 15;

const // upper design bounds
  MAX_MAP_HULLS = 4;
  MAX_LIGHTMAPS = 4;

  MIPLEVELS = 4;

  MAX_MAP_MODELS = 400;
  MAX_MAP_BRUSHES = 4096;
  MAX_MAP_ENTITIES = 1024;
  MAX_MAP_ENTSTRING = 128 * 1024;

  MAX_MAP_PLANES = 32767;
  MAX_MAP_NODES = 32767; // because negative shorts are contents
  MAX_MAP_CLIPNODES = 32767;
  MAX_MAP_LEAFS = 8192;
  MAX_MAP_VERTS = 65535;
  MAX_MAP_FACES = 65535;
  MAX_MAP_MARKSURFACES = 65535;
  MAX_MAP_TEXINFO = 8192;
  MAX_MAP_EDGES = 256000;
  MAX_MAP_SURFEDGES = 512000;
  MAX_MAP_TEXTURES = 512;
  MAX_MAP_MIPTEX = $200000;
  MAX_MAP_LIGHTING = 200000;
  MAX_MAP_VISIBILITY = $200000;

  MAX_MAP_PORTALS = 65536;

const  // key / value pair sizes
  MAX_KEY = 32;
  MAX_VALUE = 1024;

const
  CONTENTS_EMPTY = -1;
  CONTENTS_SOLID = -2;
  CONTENTS_WATER = -3;
  CONTENTS_SLIME = -4;
  CONTENTS_LAVA = -5;
  CONTENTS_SKY = -6;
  CONTENTS_ORIGIN = -7; // removed at csg time
  CONTENTS_CLIP = -8; // changed to contents_solid

  CONTENTS_CURRENT_0 = -9;
  CONTENTS_CURRENT_90 = -10;
  CONTENTS_CURRENT_180 = -11;
  CONTENTS_CURRENT_270 = -12;
  CONTENTS_CURRENT_UP = -13;
  CONTENTS_CURRENT_DOWN = -14;

  CONTENTS_TRANSLUCENT = -15;

const
  PLANE_X = 0; // Plane is perpendicular to given axis
  PLANE_Y = 1;
  PLANE_Z = 2;
  PLANE_ANYX = 3; // Non-axial plane is snapped to the nearest
  PLANE_ANYY = 4;
  PLANE_ANYZ = 5;

const
  PlayerMinS: array[0..MAX_MAP_HULLS - 1] of TVec3F =
             ((A: (-16, -16, -36)),
              (A: (-16, -16, -18)),
              (A: (0, 0, 0)),
              (A: (-32, -32, -32)));

  PlayerMaxS: array[0..MAX_MAP_HULLS - 1] of TVec3F =
             ((A: (16, 16, 36)),
              (A: (16, 16, 18)),
              (A: (0, 0, 0)),
              (A: (32, 32, 32)));
  {$ENDREGION}

  {$REGION 'TWorldHeader'}
type
  TWorldLump = record
    Offset,
    Size: UInt32;
  end;

  PWorldHeader = ^TWorldHeader;
  TWorldHeader = record
    Version: UInt32;
    Lumps: array[0..BSP_HEADER_LUMPS - 1] of TWorldLump;
  end;
  {$ENDREGION}

  {$REGION 'TWorldVertex'}
type
  // The vertex lump is a list of all of the vertices in the world.
  // Each vertex is 3 floats which makes 12 bytes per vertex.
  // You can compute the numbers of vertices by dividing the length of the vertex lump by 12.

  PWorldVertex = ^TWorldVertex;
  TWorldVertex = TVec3F; // confirmed, 12 bytes
  {$ENDREGION}

  {$REGION 'TWorldEdge'}
type
  // Not only are vertices shared between faces, but edges are as well.
  // Each edge is stored as a pair of indices into the vertex array.
  // The storage is two 16-bit integers, so the number of edges in the edge array
  //  is the size of the edge lump divided by 4.
  // There is a little complexity here because an edge could be shared by two faces
  //  with different windings, and therefore there is no particular "direction" for an edge.
  // This is further discussed in the section on face edges.

  // 2:
  // Each edge is simply a pair of vertex indices (which index into the vertex lump array).
  // The edge is defined as the straight line between the two vertices.
  // Usually, the edge array is referenced through the Surfedge array (see below).

  PWorldEdge = ^TWorldEdge; // confirmed, 4 bytes
  TWorldEdge = array[0..1] of UInt16;
  {$ENDREGION}

  {$REGION 'TWorldSurfEdge'}
type
  // The Surfedge lump (Lump 13), presumable short for surface edge, is an array of (signed) integers.
  // Surfedges are used to reference the edge array, in a somewhat complex way.
  // The value in the surfedge array can be positive or negative.
  // The absolute value of this number is an index into the edge array:
  //  - if positive, it means the edge is defined from the first to the second vertex;
  //  - if negative, from the second to the first vertex.
  // By this method, the Surfedge array allows edges to be referenced for a particular direction.
  //  (See the face lump entry below for more on why this is done).

  TWorldSurfEdge = Int32;
  TWorldTexture = UInt8;
  {$ENDREGION}

  {$REGION 'TWorldPlane'}
type
  // The plane lump stores and array of bsp_plane structures which are used as the splitting planes in the BSP.

  // 2:
  // The basis of the BSP geometry is defined by planes,
  //  which are used as splitting surfaces across the BSP tree structure.

  PWorldPlaneD = ^TWorldPlaneD; // confirmed, 20 bytes
  TWorldPlaneD = record
    Normal: TVec3F; // A, B, C components of the plane equation
    Distance: Float; // D component of the plane equation
    PlaneType: UInt32; // PLANE_X - PLANE_ANYZ ? remove? trivial to regenerate
  end;

  PWorldPlaneM = ^TWorldPlaneM;
  TWorldPlaneM = record
    Normal: TVec3F;
    Distance: Float;
    PlaneType, SignBits, Padding1, Padding2: UInt8;
  end;

  // The plane_side is used to determine whether the normal for the face points
  //  in the same direction or opposite the plane's normal.
  // This is necessary since coplanar faces which share the same node in the BSP
  //  tree also share the same normal, however the true normal for the faces could be different.
  // If plane_side is non-zero, then the face normal points in the opposite direction as the plane's normal.

  // The details of texture and lightmap coordinate generation are discussed in
  //  the section on texture information and lightmap sections.
  {$ENDREGION}

  {$REGION 'TWorldFace'}
type
  // 2:
  // The face lump (Lump 7) contains the major geometry of the map,
  //  used by the game engine to render the viewpoint of the player.
  // The face lump contains faces after they have undergone the BSP splitting process;
  //  they therefore do not directly correspond to the faces of brushes created in Hammer.
  // Faces are always flat, convex polygons, though they can contain edges that are co-linear.

  PWorldFaceD = ^TWorldFaceD; // confirmed, 20 bytes
  TWorldFaceD = record
    Plane: UInt16; // index of the plane the face is parallel to
    Side: UInt16; // set if the normal is parallel to the plane normal
    FirstEdge: UInt32; // index of the first edge (in the face edge array)
    NumEdges: UInt16; // number of consecutive edges (in the face edge array)
    TextureInfo: UInt16; // index of the texture info structure
    LightStyles: array[0..MAX_LIGHTMAPS - 1] of uint8; // styles (bit flags) for the lightmaps
    LightOffset: UInt32; // offset of the lightmap (in bytes) in the lightmap lump
  end;

  PWorldFaceM = ^TWorldFaceM; // 68 // TWorldSurfaceM ?
  TWorldFaceM = record
    VisFrame, DLightFrame, DLightBits: Int32; // 0, 4, 8
    Plane: TWorldPlaneM; // 12
    Flags: Int32; // 16
    FirstEdge, NumEdges: Int32; // 20, 24
    CacheSpots: array[0..MIPLEVELS - 1] of Pointer; // 28

    TextureMinS: array[0..1] of Int16; // 44
    Extents: array[0..1] of Int16; // 48

    TexInfo: {TWorldTexInfo}Pointer; // 52 // FIX

    Styles: array[0..MAX_LIGHTMAPS - 1] of Byte; // 56

    Samples: Pointer; // 60
    Decals: Pointer; // 64
  end;
  {$ENDREGION}

  {$REGION 'TWorldNode'}
type
  // The nodes are stored as an array in the node lump, where the first element is the root of the BSP tree.

  // Each bsp_node is 28 bytes, so the number of nodes is the size of the node lump divided by 28.
  // Since a child of a node may be a leaf and not a node, negative values for the index
  //  are used to incate a leaf. The exact position in the leaf array for a negative
  //  index is computed as -(index + 1) so that the first negative number maps to 0.
  // Since the bounding boxes are axis aligned, the eight coordinates of the box can be
  //  found from the minimum and maximum coordinates stored in the bbox_min and bbox_max fields.
  // As mentioned earlier, the faces listed in the node are not used for rendering but rather for collision detection.


  TWorldNodeChild = record
  case Int32 of
    1: (A: array [0..1] of Int16);
    2: (Front, Back: Int16);
  end;

  PWorldNodeD = ^TWorldNodeD; // confirmed, 24 bytes
  TWorldNodeD = record
    Plane: UInt32; // index of the splitting plane (in the plane array)
    Child: TWorldNodeChild; // index of the front (& back) child node or leaf
    MinS, MaxS: TVec3S; // minimum (& maximum) x, y and z of the bounding box
    FirstFace: UInt16; // index of the first face (in the face array)
    NumFaces: UInt16; // number of consecutive edges (in the face array)
  end;

  PWorldNodeM = ^TWorldNodeM; // 40
  TWorldNodeM = record
    Contents, VisFrame: Int32; // 0, 4
    MinMaxS: array[0..5] of Int16; // 8
    Parent: PWorldNodeM; // 20
    Plane: PWorldPlaneM; // 24
    Children: array[0..1] of PWorldNodeM; // +28
    FirstSurface, NumSurfaces: UInt16; // +36, +38
  end;

  PWorldClipNode = ^TWorldClipNode; // confirmed, 8 bytes
  TWorldClipNode = record
    Plane: UInt32;
    Child: TWorldNodeChild;
  end;
  {$ENDREGION}

  {$REGION 'TWorldLeaf'}
type
  // The leaf lump stores an array of bsp_leaf structures which are the leaves of the BSP tree.

  // Leaves are grouped into clusters for the purpose of storing the PVS,
  // and the cluster field gives the index into the array stored in the visibility lump.
  // See the Visibility section for more information on this.
  // If the cluster is -1, then the leaf has no visibility information (in this case the
  //  leaf is not a place that is reachable by the player).

  PWorldLeafD = ^TWorldLeafD; // confirmed, 28 bytes
  TWorldLeafD = record
    Contents: Int32;
    VisOfs: Int32;
    MinS, MaxS: TVec3S;
    FirstMarkSurface: UInt16;
    NumMarkSurfaces: UInt16;
    AmbientLevel: array[0..{NUM_AMBIENTS - 1}3] of UInt8;
  end;

  PWorldLeafM = ^TWorldLeafM;
  TWorldLeafM = record
    Contents, VisFrame: Int32; // 0, 4
    MinMaxS: array[0..5] of Int16; // 8
    Parent: PWorldNodeM; // 20

    CompressedVis: PUInt8; // +24
    EFrags: Pointer;
    FirstMarkSurface: ^PWorldFaceM;
    NumMarkSurfaces, Key: Int32;
    AmbientSoundLevel: array[0..{NUM_AMBIENTS - 1}3] of UInt8;
  end;
  {$ENDREGION}

  {$REGION 'TWorldHull'}
type
  PWorldHull = ^TWorldHull; // 40
  TWorldHull = record
    ClipNodes: ^TArray<TWorldClipNode>;
    Planes: ^TArray<TWorldPlaneM>;
    FirstClipNode, LastClipNode: Int32;
    ClipMinS, ClipMaxS: TVec3F;
  end;
  {$ENDREGION}

  {$REGION 'TWorldModel'}
type
  PWorldModel = ^TWorldModel; // confirmed, 64 bytes
  TWorldModel = record
    MinS: TVec3F;
    MaxS: TVec3F;
    Origin: TVec3F;
    HeadNode: array[0..MAX_MAP_HULLS - 1] of Int32;
    VisLeafs: Int32;
    FirstFace: Int32;
    NumFaces: Int32;
  end;
  {$ENDREGION}

  {$REGION 'TWorldEntity'}
type
  PWorldEntity = ^TWorldEntity;
  TWorldEntity = record
    AbsoluteIndex: UInt;

    Args: TArray<TPair<LStr, LStr>>;

    function GetValue(AField: LStr): PLStr;
  end;
  {$ENDREGION}

type
  TBSPLoadResult = (
    BSP_LOAD_OK = 0,
    BSP_LOAD_FILE_NOT_FOUND,
    BSP_LOAD_CORRUPT_DATA);

  TPMPlane = record
    Normal: TVec3F;
    Distance: Float;
  end;

  PTrace = ^TWorldTrace;
  TWorldTrace = record // 68
    AllSolid, StartSolid, InOpen, InWater: Int32;
    Fraction: Single; // +16
    EndPos: TVec3F; // +20
    Plane: TPMPlane; // +32
    Ent: Int32; // 48
    DeltaVelocity: TVec3F; // 52
    HitGroup: Int32; // 64
  end;

  PWorld = ^TWorld;
  TWorld = class
  public
    Name: LStr;
    Size: Int; // in bytes
    Header: TWorldHeader;
    Entities: TArray<TWorldEntity>;
    Lightning: TArray<UInt8>;
    Vertexes: TArray<TWorldVertex>;
    Edges: TArray<TWorldEdge>;
    SurfEdges: TArray<TWorldSurfEdge>;
    Textures: TArray<TWorldTexture>;
    Planes: TArray<TWorldPlaneM>;
    Faces: TArray<TWorldFaceD>;
    MarkSurfaces: TArray<PWorldFaceM>;
    Visibility: TArray<UInt8>;
    Leafs: TArray<TWorldLeafM>;
    Nodes: TArray<TWorldNodeM>;
    ClipNodes: TArray<TWorldClipNode>;
    Models: TArray<TWorldModel>;

    ClipNodesHull0: TArray<TWorldClipNode>;
    Hulls: array[0..3] of TWorldHull;

    BoxHull: TWorldHull;
    BoxPlanes: array of TWorldPlaneM; // length must be 6
    BoxClipNodes: array of TWorldClipNode; // length must be 6

    constructor Create;
    destructor Destroy; override;

    function LoadFromFile(AFileName: LStr; AGameDir: LStr = ''): TBSPLoadResult;

    function EntitiesCount: UInt32;
    function VertexesCount: UInt32;
    function EdgesCount: UInt32;
    function SurfEdgesCount: UInt32;
    function TexturesCount: UInt32;
    function PlanesCount: UInt32;
    function FacesCount: UInt32;
    function LeafsCount: UInt32;
    function NodesCount: UInt32;
    function ClipNodesCount: UInt32;
    function ModelsCount: UInt32;

    function HasEntities: Boolean;
    function HasVertexes: Boolean;
    function HasEdges: Boolean;
    function HasSurfEdges: Boolean;
    function HasTextures: Boolean;
    function HasPlanes: Boolean;
    function HasFaces: Boolean;
    function HasLeafs: Boolean;
    function HasNodes: Boolean;
    function HasClipNodes: Boolean;
    function HasModels: Boolean;

    function GetEntity(AField, AValue: LStr): PWorldEntity;
    function GetEntities(AField, AValue: LStr): TArray<PWorldEntity>;
    function GetRandomEntity(AField, AValue: LStr): PWorldEntity;

    function GetEntityByClassName(AClassName: LStr): PWorldEntity;
    function GetEntitiesByClassName(AClassName: LStr): TArray<PWorldEntity>;
    function GetRandomEntityByClassName(AClassName: LStr): PWorldEntity;

    function GetModelForEntity(AEntity: TWorldEntity): PWorldModel;

    function GetModelAbsoluteIndex(AModel: PWorldModel): Int32;

    function HullForBox(const MinS, MaxS: TVec3F): PWorldHull;
    function HullPointContents(const Hull: TWorldHull; Num: Int32; const P: TVec3F): Int32;
    function RecursiveHullCheck(const Hull: TWorldHull; Num: Int32; P1F, P2F: Single; const P1, P2: TVec3F; out Trace: TWorldTrace): Boolean;

    function TraceLine(AStart, AFinish: TVec3F): TWorldTrace; overload;
    function TraceLine(AStart, AFinish: TVec3F; AEntities: TArray<TEntity>; Ignore: array of Int32): TWorldTrace; overload;

    function IsVisible(AStart, AFinish: TVec3F): Boolean; overload;
    function IsVisible(AStart, AFinish: TVec3F; AEntities: TArray<TEntity>; Ignore: array of Int32): Boolean; overload;
  end;

procedure Mod_SetParent(Node, Parent: PWorldNodeM);

implementation

{$REGION 'Shared'}
procedure Mod_SetParent(Node, Parent: PWorldNodeM);
begin
  Node.Parent := Parent;

  if Node.Contents < 0 then
    Exit;

  Mod_SetParent(Node.Children[0], Node);
  Mod_SetParent(Node.Children[1], Node);
end;
{$ENDREGION}

{$REGION 'TWorld'}
  {$REGION 'Create & Destroy'}
constructor TWorld.Create;
begin
  inherited;

  //
end;

destructor TWorld.Destroy;
begin
  //

  inherited;
end;
  {$ENDREGION}

  {$REGION 'LoadFromFile'}
function TWorld.LoadFromFile(AFileName: LStr; AGameDir: LStr = ''): TBSPLoadResult;
var
  I, J, K: Int32;
  P: Pointer;
  S: LStr;
  E: PWorldEntity;
  N: TWorldNodeD;
  Child: PWorldNodeM;
  L: TWorldLeafD;
begin
  Finalize(Entities);
  Finalize(Lightning);
  Finalize(Vertexes);
  Finalize(Edges);
  Finalize(SurfEdges);
  Finalize(Textures);
  Finalize(Planes);
  Finalize(Faces);
  Finalize(MarkSurfaces);
  Finalize(Visibility);
  Finalize(Leafs);
  Finalize(Nodes);
  Finalize(ClipNodes);
  Finalize(Models);

  Name := TPath.GetFileNameWithoutExtension(ExtractFileName(AFileName));

  if FileExists(Name) then
    AFileName := Name
  else
    if FileExists('worlds\' + Name + '.bsp') then
      AFileName := 'worlds\' + Name + '.bsp'
    else
      if FileExists('maps\' + Name + '.bsp') then
        AFileName := 'maps\' + Name + '.bsp'
      else
        if AGameDir <> '' then
          if FileExists(AGameDir + '\worlds\' + Name + '.bsp') then
            AFileName := AGameDir + '\worlds\' + Name + '.bsp'
          else
            if FileExists(AGameDir + '\maps\' + Name + '.bsp') then
              AFileName := AGameDir + '\maps\' + Name + '.bsp';

  Result := BSP_LOAD_OK;

  if not FileExists(AFileName) then
    Exit(BSP_LOAD_FILE_NOT_FOUND);

  with TBufferEx2.Create do
  begin
    LoadFromFile(AFileName);

    Self.Size := Size;

    Start;

    Read(Header, SizeOf(Header));

    {$REGION 'Vertexes'}
    SetLength(Vertexes, Header.Lumps[BSP_LUMP_VERTEXES].Size div SizeOf(TWorldVertex));
    Position := Header.Lumps[BSP_LUMP_VERTEXES].Offset;
    Read(Pointer(Vertexes)^, Header.Lumps[BSP_LUMP_VERTEXES].Size);
    {$ENDREGION}

    {$REGION 'Edges'}
    SetLength(Edges, Header.Lumps[BSP_LUMP_EDGES].Size div SizeOf(TWorldEdge));
    Position := Header.Lumps[BSP_LUMP_EDGES].Offset;
    Read(Pointer(Edges)^, Header.Lumps[BSP_LUMP_EDGES].Size);

    {for I := Low(Edges) to High(Edges) do
    begin
      Edges[I][0] := @Vertexes[ReadInt16];
      Edges[I][1] := @Vertexes[ReadInt16];
    end;}
    {$ENDREGION}

    {$REGION 'SurfEdges'}
    SetLength(SurfEdges, Header.Lumps[BSP_LUMP_SURFEDGES].Size div SizeOf(TWorldSurfEdge));
    Position := Header.Lumps[BSP_LUMP_SURFEDGES].Offset;
    Read(Pointer(SurfEdges)^, Header.Lumps[BSP_LUMP_SURFEDGES].Size);
    {$ENDREGION}

    {$REGION 'Entities'}
    Position := Header.Lumps[BSP_LUMP_ENTITIES].Offset;
    S := ReadLStr(Header.Lumps[BSP_LUMP_ENTITIES].Size);

    P := @S[1];

    with TTokenizer.Create do
    begin
      Parse(P);

      while P <> nil do
      begin
        if Token <> '{' then
          Exit(BSP_LOAD_CORRUPT_DATA);

        SetLength(Entities, Length(Entities) + 1);
        E := @Entities[High(Entities)];
        E.AbsoluteIndex := High(Entities);

        Parse(P);

        while Token <> '}' do
        begin
          SetLength(E.Args, Length(E.Args) + 1);

          with E.Args[High(E.Args)] do
          begin
            Key := Token;
            Parse(P);
            Value := Token;
            Parse(P);
          end;
        end;
        Parse(P);
      end;

      Free;
    end;
    {$ENDREGION}

    {$REGION 'Textures'}

    {$ENDREGION}

    {$REGION 'Lightning'}
    SetLength(Lightning, Header.Lumps[BSP_LUMP_LIGHTING].Size);
    Position := Header.Lumps[BSP_LUMP_LIGHTING].Offset;
    Read(Pointer(Lightning)^, Header.Lumps[BSP_LUMP_LIGHTING].Size);
    {$ENDREGION}

    {$REGION 'Planes'}
    SetLength(Planes, Header.Lumps[BSP_LUMP_PLANES].Size div SizeOf(TWorldPlaneD));
    Position := Header.Lumps[BSP_LUMP_PLANES].Offset;

    for I := Low(Planes) to High(Planes) do
      with Planes[I] do
      begin
        Normal := ReadVec3F;

        SignBits := 0;

        for J := 0 to 2 do
          if Normal.A[J] < 0 then
           K := K or (1 shl J);

        Distance := ReadFloat;
        PlaneType := ReadInt32;
      end;
    {$ENDREGION}

    {$REGION 'TexInfo'}
    // ...
    {$ENDREGION}

    {$REGION 'Faces'}
    SetLength(Faces, Header.Lumps[BSP_LUMP_FACES].Size div SizeOf(TWorldFaceD));
    Position := Header.Lumps[BSP_LUMP_FACES].Offset;
    Read(Pointer(Faces)^, Header.Lumps[BSP_LUMP_FACES].Size);
    {$ENDREGION}

    {$REGION 'Mark Surfaces'}
    SetLength(MarkSurfaces, Header.Lumps[BSP_LUMP_MARKSURFACES].Size div 2);
    Position := Header.Lumps[BSP_LUMP_MARKSURFACES].Offset;

    for I := Low(MarkSurfaces) to High(MarkSurfaces) do
      MarkSurfaces[I] := @Faces[ReadUInt16]; // or int16 ?
    {$ENDREGION}

    {$REGION 'Visibility'}
    SetLength(Visibility, Header.Lumps[BSP_LUMP_VISIBILITY].Size);
    Position := Header.Lumps[BSP_LUMP_VISIBILITY].Offset;
    Read(Visibility, Header.Lumps[BSP_LUMP_VISIBILITY].Size);
    {$ENDREGION}

    {$REGION 'Leafs'}
    SetLength(Leafs, Header.Lumps[BSP_LUMP_LEAFS].Size div SizeOf(TWorldLeafD));
    Position := Header.Lumps[BSP_LUMP_LEAFS].Offset;

    for I := Low(Leafs) to High(Leafs) do
    begin
      Read(L, SizeOf(L));

      for J := 0 to 2 do
      begin
        Leafs[I].MinMaxS[J] := L.MinS.A[J];
        Leafs[I].MinMaxS[J + 3] := L.MaxS.A[J];
      end;

      Leafs[I].Contents := L.Contents;
      Leafs[I].FirstMarkSurface := @MarkSurfaces[L.FirstMarkSurface];
      Leafs[I].NumMarkSurfaces := L.NumMarkSurfaces;

      K := L.VisOfs;

      if K = -1 then
        Leafs[I].CompressedVis := nil
      else
        Leafs[I].CompressedVis := @Visibility[K];

      Leafs[I].EFrags := nil;

      for J := 0 to 3 do
       Leafs[I].AmbientSoundLevel[J] := L.AmbientLevel[J];
    end;
    {$ENDREGION}

    {$REGION 'Nodes'}
    SetLength(Nodes, Header.Lumps[BSP_LUMP_NODES].Size div SizeOf(TWorldNodeD));
    Position := Header.Lumps[BSP_LUMP_NODES].Offset;

    for I := Low(Nodes) to High(Nodes) do
    begin
      Read(N, Sizeof(N));

      for J := 0 to 2 do
      begin
        Nodes[I].MinMaxS[J] := N.MinS.A[J];
        Nodes[I].MinMaxS[J + 3] := N.MaxS.A[J];
      end;

      Nodes[I].Plane := @Planes[N.Plane];
      Nodes[I].FirstSurface := N.FirstFace;
      Nodes[I].NumSurfaces := N.NumFaces;

      for J := 0 to 1 do
      begin
        K := N.Child.A[J];

        if K >= 0 then
          Nodes[I].Children[J] := @Nodes[K]
        else
          Nodes[I].Children[J] := @Leafs[UInt32(-1 - K)];
       end;
    end;

    if Length(Nodes) > 0 then
      Mod_SetParent(@Nodes[0], nil);
    {$ENDREGION}

    {$REGION 'ClipNodes'}
    SetLength(ClipNodes, Header.Lumps[BSP_LUMP_CLIPNODES].Size div SizeOf(TWorldClipNode));
    Position := Header.Lumps[BSP_LUMP_CLIPNODES].Offset;
    Read(Pointer(ClipNodes)^, SizeOf(TWorldClipNode) * Length(ClipNodes));
    {$ENDREGION}

    {$REGION 'Models'}
    SetLength(Models, Header.Lumps[BSP_LUMP_MODELS].Size div SizeOf(TWorldModel));
    Position := Header.Lumps[BSP_LUMP_MODELS].Offset;
    Read(Pointer(Models)^, SizeOf(TWorldModel) * Length(Models));
    {$ENDREGION}

    Free;
  end;

  {$REGION 'Hulls'}
  for I := 1 to 3 do
  begin
    Hulls[I].ClipNodes := @ClipNodes;
    Hulls[I].Planes := @Planes;
    Hulls[I].FirstClipNode := 0;
    Hulls[I].LastClipNode := High(ClipNodes);
  end;

  with Hulls[1] do
  begin
    ClipMinS.A[0] := -16;
    ClipMinS.A[1] := -16;
    ClipMinS.A[2] := -36;
    ClipMaxS.A[0] := 16;
    ClipMaxS.A[1] := 16;
    ClipMaxS.A[2] := 36;
  end;

  with Hulls[2] do
  begin
    ClipMinS.A[0] := -32;
    ClipMinS.A[1] := -32;
    ClipMinS.A[2] := -32;
    ClipMaxS.A[0] := 32;
    ClipMaxS.A[1] := 32;
    ClipMaxS.A[2] := 32;
  end;

  with Hulls[3] do
  begin
    ClipMinS.A[0] := -16;
    ClipMinS.A[1] := -16;
    ClipMinS.A[2] := -18;
    ClipMaxS.A[0] := 16;
    ClipMaxS.A[1] := 16;
    ClipMaxS.A[2] := 18;
  end;

  SetLength(ClipNodesHull0, Length(Nodes));
  Hulls[0].ClipNodes := @ClipNodesHull0;
  Hulls[0].Planes := @Planes;
  Hulls[0].FirstClipNode := 0;
  Hulls[0].LastClipNode := Length(ClipNodesHull0) - 1;

  for I := Hulls[0].FirstClipNode to Hulls[0].LastClipNode do
  begin
    ClipNodesHull0[I].Plane := (UInt32(Nodes[I].Plane) - UInt32(@Planes[0])) div SizeOf(Nodes[I].Plane^);

    for J := 0 to 1 do
      if Nodes[I].Children[J].Contents < 0 then
        ClipNodesHull0[I].Child.A[J] := Nodes[I].Children[J].Contents
      else
        ClipNodesHull0[I].Child.A[J] := (UInt32(Nodes[I].Children[J]) - UInt32(@Nodes[0])) div SizeOf(Nodes[I].Children[J]^);
  end;

  SetLength(BoxClipNodes, 6);
  SetLength(BoxPlanes, 6);

  BoxHull.ClipNodes := @BoxClipNodes;
  BoxHull.Planes := @BoxPlanes;
  BoxHull.FirstClipNode := 0;
  BoxHull.LastClipNode := High(BoxClipNodes);

  for I := Low(BoxClipNodes) to High(BoxClipNodes) do
  begin
    BoxClipNodes[I].Plane := I;
    BoxClipNodes[I].Child.A[I and 1] := CONTENTS_EMPTY;

    if I = High(BoxClipNodes) then
      BoxClipNodes[I].Child.A[(I and 1) xor 1] := CONTENTS_SOLID
    else
      BoxClipNodes[I].Child.A[(I and 1) xor 1] := I + 1;

    BoxPlanes[I].PlaneType := I shr 1;
    BoxPlanes[I].Normal.A[I shr 1] := 1;
  end;

  {$ENDREGION}
end;
  {$ENDREGION}

  {$REGION 'CountOf'}
function TWorld.EntitiesCount: UInt32;
begin
  Result := Length(Entities);
end;

function TWorld.VertexesCount: UInt32;
begin
  Result := Length(Vertexes);
end;

function TWorld.EdgesCount: UInt32;
begin
  Result := Length(Edges);
end;

function TWorld.SurfEdgesCount: UInt32;
begin
  Result := Length(SurfEdges);
end;

function TWorld.TexturesCount: UInt32;
begin
  Result := Length(Textures);
end;

function TWorld.PlanesCount: UInt32;
begin
  Result := Length(Planes);
end;

function TWorld.FacesCount: UInt32;
begin
  Result := Length(Faces);
end;

function TWorld.LeafsCount: UInt32;
begin
  Result := Length(Leafs);
end;

function TWorld.NodesCount: UInt32;
begin
  Result := Length(Nodes);
end;

function TWorld.ClipNodesCount: UInt32;
begin
  Result := Length(ClipNodes);
end;

function TWorld.ModelsCount: UInt32;
begin
  Result := Length(Models);
end;
  {$ENDREGION}

  {$REGION 'IsHas'}
function TWorld.HasEntities: Boolean;
begin
  Result := EntitiesCount > 0
end;

function TWorld.HasVertexes: Boolean;
begin
  Result := VertexesCount > 0;
end;

function TWorld.HasEdges: Boolean;
begin
  Result := EdgesCount > 0;
end;

function TWorld.HasSurfEdges: Boolean;
begin
  Result := SurfEdgesCount > 0;
end;

function TWorld.HasTextures: Boolean;
begin
  Result := TexturesCount > 0;
end;

function TWorld.HasPlanes: Boolean;
begin
  Result := PlanesCount > 0;
end;

function TWorld.HasFaces: Boolean;
begin
  Result := FacesCount > 0;
end;

function TWorld.HasLeafs: Boolean;
begin
  Result := LeafsCount > 0;
end;

function TWorld.HasNodes: Boolean;
begin
  Result := NodesCount > 0;
end;

function TWorld.HasClipNodes: Boolean;
begin
  Result := ClipNodesCount > 0;
end;

function TWorld.HasModels: Boolean;
begin
  Result := ModelsCount > 0;
end;
  {$ENDREGION}

  {$REGION 'GetEntity'}
function TWorld.GetEntity(AField, AValue: LStr): PWorldEntity;
var
  I: Int32;
  S: PLStr;
begin
  Result := nil;

  for I := Low(Entities) to High(Entities) do
  begin
    S := Entities[I].GetValue(AField);

    if S = nil then
      Continue;

    if S^ = AValue then
      Exit(@Entities[I]);
  end;
end;

function TWorld.GetEntities(AField, AValue: LStr): TArray<PWorldEntity>;
var
  I: Int32;
  S: PLStr;
begin
  Finalize(Result);

  with TList<PWorldEntity>.Create do
  begin
    for I := Low(Entities) to High(Entities) do
    begin
      S := Entities[I].GetValue(AField);

      if S = nil then
        Continue;

      if S^ = AValue then
        Add(@Entities[I]);
    end;

    Result := ToArray;
    Free;
  end;
end;

function TWorld.GetRandomEntity(AField, AValue: LStr): PWorldEntity;
var
  A: TArray<PWorldEntity>;
begin
  Result := nil;

  A := GetEntities(AField, AValue);

  if Length(A) > 0 then
    Result := A[Random(Length(A))];
end;

function TWorld.GetEntityByClassName(AClassName: LStr): PWorldEntity;
begin
  Result := GetEntity('classname', AClassName);
end;

function TWorld.GetEntitiesByClassName(AClassName: LStr): TArray<PWorldEntity>;
begin
  Result := GetEntities('classname', AClassName);
end;

function TWorld.GetRandomEntityByClassName(AClassName: LStr): PWorldEntity;
begin
  Result := GetRandomEntity('classname', AClassName);
end;
  {$ENDREGION}

  {$REGION 'GetModelForEntity'}
function TWorld.GetModelForEntity(AEntity: TWorldEntity): PWorldModel;
var
  V: PLStr;
  I: Int32;
begin
  Result := nil;

  V := AEntity.GetValue('model');

  if V = nil then
    Exit;

  if V^[1] <> '*' then
    Exit;

  I := StrToIntDef(ParseAfter(V^, '*'), -1);

  if not (I in [Low(Models)..High(Models)]) then
    Exit;

  Result := @Models[I];
end;

  {$ENDREGION}

  {$REGION 'GetModelAbsoluteIndex'}
function TWorld.GetModelAbsoluteIndex(AModel: PWorldModel): Int32;
begin
  if AModel = nil then
    Exit(-1);

  Result := (UInt32(AModel) - UInt32(@Models[0])) div SizeOf(TWorldModel);
end;
  {$ENDREGION}

  {$REGION 'Extended'}
function TWorld.HullForBox(const MinS, MaxS: TVec3F): PWorldHull;
begin
  BoxPlanes[0].Distance := MaxS.A[0];
  BoxPlanes[1].Distance := MinS.A[0];
  BoxPlanes[2].Distance := MaxS.A[1];
  BoxPlanes[3].Distance := MinS.A[1];
  BoxPlanes[4].Distance := MaxS.A[2];
  BoxPlanes[5].Distance := MinS.A[2];

  Result := @BoxHull;
end;

function TWorld.HullPointContents(const Hull: TWorldHull; Num: Int32; const P: TVec3F): Int32;
var
  Node: PWorldClipNode;
  Plane: PWorldPlaneM;
  D: Single;
begin
  if Hull.FirstClipNode < Hull.LastClipNode then
  begin
    while Num >= 0 do
    begin
      Node := @Hull.ClipNodes^[Num];
      Plane := @Hull.Planes^[Node.Plane];

      if Plane.PlaneType >= 3 then
        D := Plane.Normal.DotProduct(P) - Plane.Distance
      else
        D := P.A[Plane.PlaneType] - Plane.Distance;

      if D >= 0 then
        Num := Node.Child.A[0]
      else
        Num := Node.Child.A[1];
    end;

    Result := Num;
  end
  else
    Result := CONTENTS_EMPTY;
end;

function TWorld.RecursiveHullCheck(const Hull: TWorldHull; Num: Int32; P1F, P2F: Single; const P1, P2: TVec3F; out Trace: TWorldTrace): Boolean;
const
  DIST_EPSILON = 0.03125;
var
  Node: PWorldClipNode;
  Plane: PWorldPlaneM;
  T1, T2, Frac, MidF: Single;
  I, Side: UInt;
  Mid: TVec3F;
begin
  if Num < 0 then
  begin
    if Num = CONTENTS_SOLID then
      Trace.StartSolid := 1
    else
    begin
      Trace.AllSolid := 0;

      if Num = CONTENTS_EMPTY then
        Trace.InOpen := 1
      else
        Trace.InWater := 1;
    end;

    Result := True;
  end
  else
    if Hull.FirstClipNode >= Hull.LastClipNode then
    begin
      Trace.AllSolid := 0;
      Trace.InOpen := 1;
      Result := True;
    end
    else
    begin
      Node := @Hull.ClipNodes^[Num];
      Plane := @Hull.Planes^[Node.Plane];

      if Plane.PlaneType >= 3 then
      begin
        T1 := Plane.Normal.DotProduct(P1) - Plane.Distance;
        T2 := Plane.Normal.DotProduct(P2) - Plane.Distance;
      end
      else
      begin
        T1 := P1.A[Plane.PlaneType] - Plane.Distance;
        T2 := P2.A[Plane.PlaneType] - Plane.Distance;
      end;

      if (T1 >= 0) and (T2 >= 0) then
      begin
        Result := RecursiveHullCheck(Hull, Node.Child.A[0], P1F, P2F, P1, P2, Trace);
        Exit;
      end
      else
        if (T1 < 0) and (T2 < 0) then
        begin
          Result := RecursiveHullCheck(Hull, Node.Child.A[1], P1F, P2F, P1, P2, Trace);
          Exit;
        end;

      if T1 >= 0 then
        Frac := (T1 - DIST_EPSILON) / (T1 - T2)
      else
        Frac := (T1 + DIST_EPSILON) / (T1 - T2);

      if Frac > 1 then
        Frac := 1
      else
        if Frac < 0 then
          Frac := 0;

      MidF := (P2F - P1F) * Frac + P1F;
      Mid := (P2 - P1) * Frac + P1;

      Side := UInt(T1 < 0);

      if not RecursiveHullCheck(Hull, Node.Child.A[Side], P1F, MidF, P1, Mid, Trace) then
        Result := False
      else
        if HullPointContents(Hull, Node.Child.A[Side xor 1], Mid) <> CONTENTS_SOLID then
          Result := RecursiveHullCheck(Hull, Node.Child.A[Side xor 1], MidF, P2F, Mid, P2, Trace)
        else
          if Trace.AllSolid <> 0 then
            Result := False
          else
          begin
            if Side > 0 then
            begin
              Trace.Plane.Normal := -Plane.Normal;
              Trace.Plane.Distance := -Plane.Distance;
            end
            else
            begin
              Trace.Plane.Normal := Plane.Normal;
              Trace.Plane.Distance := Plane.Distance;
            end;

            while HullPointContents(Hull, Hull.FirstClipNode, Mid) = CONTENTS_SOLID do
            begin
              Frac := Frac - 0.05;

              if Frac < 0 then
              begin
                Trace.Fraction := MidF;
                Trace.EndPos := Mid;
                Result := False;
                Exit;
              end;

              MidF := (P2F - P1F) * Frac + P1F;
              Mid := (P2 - P1) * Frac + P1;
            end;

            Trace.Fraction := MidF;
            Trace.EndPos := Mid;
            Result := False;
          end;
    end;
end;

function TWorld.TraceLine(AStart, AFinish: TVec3F): TWorldTrace;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Fraction := 1;
  Result.EndPos := AFinish;
  Result.Ent := -1;
  Result.AllSolid := 1;
  RecursiveHullCheck(Hulls[0], Hulls[0].FirstClipNode, 0, 1, AStart, AFinish, Result);

  if Result.AllSolid > 0 then
    Result.StartSolid := 1;

  if Result.StartSolid > 0 then
    Result.Fraction := 0;

  if Result.Fraction <> 1 then
    Result.EndPos := (AFinish - AStart) * Result.Fraction + AStart;
end;

function TWorld.TraceLine(AStart, AFinish: TVec3F; AEntities: TArray<TEntity>; Ignore: array of Int32): TWorldTrace;
var
  J, LastHull: UInt;
  Orig, V1, V2, V3, V4, Fwd, Right, Up: TVec3F;
  Hull: PWorldHull;
  HullNum: Int32;
  B, B2, B3: Boolean;
  TL, TL2: TWorldTrace;
  I, K: Int;
begin
  Hull := nil;
  FillChar(Result, SizeOf(Result), 0);
  Result.Fraction := 1;
  Result.EndPos := AFinish;
  Result.Ent := -1;

  for I := Low(AEntities) to High(AEntities) do
    with AEntities[I] do
    begin
      if {(PE.Model <> nil) and} (Solid = 0) and (Skin <> 0) then
        Continue;

    //  if {((TraceFlags and PM_GLASS_IGNORE) > 0) and }(RenderMode <> 0) then
    //    Continue;

      B3 := False;

      for K := Low(Ignore) to High(Ignore) do
        if Ignore[K] = I then
        begin
          B3 := True;
          Break;
        end;

      if B3 then
        Continue;

      Orig := Origin;
      HullNum := 1;

      if I = 0 then
        Hull := @Hulls[UseHull]
      else
      {  if (I > 0) and (I < 32) then
        begin
          V1 := MinS - PlayerMaxS[UseHull];
          V2 := MaxS - PlayerMinS[UseHull];
          Hull := HullForBox(V1, V2);
        end
        else
          {if (MinS <> 0) or (MaxS <> 0) then // world entities has gabarites already in entities array from net_chan, thanks valve
            Hull := HullForBox(MinS, MaxS)
          else  }
            Continue; // we do not have hull for this model

      V1 := AStart - Orig;
      V2 := AFinish - Orig;

      if (Solid <> SOLID_BSP) or (Angles = 0) then
        B := False
      else
      begin
        B := True;
        AngleVectors(Angles, @Fwd, @Right, @Up);
        V3.A[0] := V1.DotProduct(Fwd);
        V3.A[1] := -V1.DotProduct(Right);
        V3.A[2] := V1.DotProduct(Up);
        V4.A[0] := V2.DotProduct(Fwd);
        V4.A[1] := -V2.DotProduct(Right);
        V4.A[2] := V2.DotProduct(Up);
        V1 := V3;
        V2 := V4;
      end;

      LastHull := 0;
      FillChar(TL, SizeOf(TL), 0); //MemSet(TL, SizeOf(TL), 0);
      TL.Fraction := 1;
      TL.AllSolid := 1;
      TL.EndPos := AFinish;

      if HullNum <= 0 then
        TL.AllSolid := 0
      else
        if HullNum = 1 then
          RecursiveHullCheck(Hull^, Hull.FirstClipNode, 0, 1, V1, V2, TL)
        else
          for J := 0 to HullNum - 1 do
          begin
            FillChar(TL2, SizeOf(TL2), 0); //MemSet(TL2, SizeOf(TL2), 0);
            TL2.Fraction := 1;
            TL2.AllSolid := 1;
            TL2.EndPos := AFinish;

            RecursiveHullCheck(Hull^, Hull.FirstClipNode, 0, 1, V1, V2, TL2);

            if (J = 0) or (TL2.AllSolid > 0) or (TL2.StartSolid > 0) or (TL2.Fraction < TL.Fraction) then
            begin
              B2 := TL.StartSolid <> 0;
              Move(TL2, TL, SizeOf(TL));

              if B2 then
                TL.StartSolid := 1;

              LastHull := J;
            end;

            // TL.HitGroup := SV_HitgroupForStudioHull(LastHull); // wtf ???

            Inc(UInt(Hull), SizeOf(Hull^));
          end;

      if TL.AllSolid > 0 then
        TL.StartSolid := 1;

      if TL.StartSolid > 0 then
        TL.Fraction := 0;

      if TL.Fraction <> 1 then
      begin
        if B then
        begin
          AngleVectorsTranspose(Angles, @Fwd, @Right, @Up);
          V3.A[0] := TL.Plane.Normal.DotProduct(Fwd);
          V3.A[1] := TL.Plane.Normal.DotProduct(Right);
          V3.A[2] := TL.Plane.Normal.DotProduct(Up);
          TL.Plane.Normal := V3;
        end;

        TL.EndPos := (AFinish - AStart) * TL.Fraction + AStart;
      end;

      if TL.Fraction < Result.Fraction then
      begin
        Result := TL;
        Result.Ent := I;
      end;
    end;
end;

function TWorld.IsVisible(AStart, AFinish: TVec3F): Boolean;
begin
  Result := TraceLine(AStart, AFinish).Fraction = 1;
end;

function TWorld.IsVisible(AStart, AFinish: TVec3F; AEntities: TArray<TEntity>; Ignore: array of Int32): Boolean;
begin
  Result := TraceLine(AStart, AFinish, AEntities, Ignore).Fraction = 1;
end;
  {$ENDREGION}
{$ENDREGION}

{$REGION 'TWorldEntity'}
function TWorldEntity.GetValue(AField: LStr): PLStr;
var
  I: Int32;
begin
  Result := nil;

  for I := Low(Args) to High(Args) do
    if Args[I].Key = AField then
      Exit(@Args[I].Value);
end;
{$ENDREGION}

end.