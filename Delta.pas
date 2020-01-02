unit Delta;

interface

uses
  Default,
  Shared,
  Common,
  Protocol,
  Event,
  Buffer,
  Entity;

{ TODO:
-> DT_TIMEWINDOW_8: GetUpTime
}

type
  PDeltaField = ^TDeltaField;
  TDeltaField = record
    Name: LStr;
    FieldType: Int32;
    Size,
    Bits: UInt8;
    Scale,
    PScale: Float;
    Offset: UInt32;

    class operator Equal(A, B: TDeltaField): Boolean; overload;
    class operator NotEqual(A, B: TDeltaField): Boolean; overload;

    class operator Equal(A: TDeltaField; B: LStr): Boolean; overload;
    class operator NotEqual(A: TDeltaField; B: LStr): Boolean; overload;
  end;

  TDeltaFields = array of TDeltaField;

const
  DeltaFieldCleared: TDeltaField = ();

type

  PDelta = ^TDelta;
  TDelta = record
    Name: LStr;
    Fields: TDeltaFields;

    class operator Equal(A, B: TDelta): Boolean; overload;
    class operator NotEqual(A, B: TDelta): Boolean; overload;

    class operator Equal(A: TDelta; B: LStr): Boolean; overload;
    class operator NotEqual(A: TDelta; B: LStr): Boolean; overload;
  end;

  TDeltas = array of TDelta;

  TDeltaReadField = record
    Readed: Boolean;
    Name: LStr;
    FieldType: Int32;
    ValueInt: UInt32;
    ValueFloat: Float;
    ValueStr: LStr;
  end;

  TDeltaReadFields = array of TDeltaReadField;

  TDeltaWriteField = record
    Writed: Boolean;
    Ptr: Pointer;
    Field: PDeltaField;
  end;

  TDeltaWriteFields = array of TDeltaWriteField;

procedure Clear(var Data: TDeltaField); overload; inline;
procedure Clear(var Data: TDeltaFields); overload; inline;
procedure Clear(var Data: TDeltaReadField); overload; inline;
procedure Clear(var Data: TDeltaReadFields); overload; inline;
procedure Clear(var Data: TDeltaWriteField); overload; inline;
procedure Clear(var Data: TDeltaWriteFields); overload; inline;
procedure Clear(var Data: TDelta); overload; inline;
procedure Clear(var Data: TDeltas); overload; inline;

const
  DT_BYTE = 1 shl 0;
  DT_SHORT = 1 shl 1;
  DT_FLOAT = 1 shl 2;
  DT_INTEGER = 1 shl 3;
  DT_ANGLE = 1 shl 4;
  DT_TIMEWINDOW_8 = 1 shl 5;
  DT_TIMEWINDOW_BIG = 1 shl 6;
  DT_STRING = 1 shl 7;

  DT_SIGNED = $80000000; // 1 shl 31;

  S_DELTA_EVENT = 'event_t';
  S_DELTA_WEAPON_DATA = 'weapon_data_t';
  S_DELTA_ENTITY_STATE = 'entity_state_t';
  S_DELTA_ENTITY_STATE_PLAYER = 'entity_state_player_t';
  S_DELTA_CUSTOM_ENTITY_STATE = 'custom_entity_state_t';
  S_DELTA_USERCMD = 'usercmd_t';
  S_DELTA_CLIENTDATA = 'clientdata_t';
  S_DELTA_METADELTA = 'g_MetaDelta';

  Delta_G_MetaDelta: array[1..7] of TDeltaField = (
    (Name: 'fieldType'; FieldType: DT_INTEGER; Bits: 32),
    (Name: 'fieldName'; FieldType: DT_STRING),
    (Name: 'fieldOffset'; FieldType: DT_INTEGER; Bits: 16),
    (Name: 'fieldSize'; FieldType: DT_BYTE{DT_INTEGER}; Bits: 8), // was dt_integer
    (Name: 'significant_bits'; FieldType: DT_INTEGER; Bits: 8),
    (Name: 'premultiply'; FieldType: DT_FLOAT; Bits: 32; Scale: 4000),
    (Name: 'postmultiply'; FieldType: DT_FLOAT; Bits: 32; Scale: 4000));

type
  TDeltaSystem = class(TXSystem)
  private
    Deltas: TDeltas;

    function FindDeltaField(ADelta: TDelta; const AName: LStr): PDeltaField;
    function FindDelta(const AName: LStr): PDelta;

    procedure Add(AName: LStr; AField: TDeltaField); overload;
    procedure Add(AName: LStr; AFields: array of TDeltaField); overload;

    function ReadFieldToOffset(AReadField: TDeltaReadField; AName: LStr; Ptr: Pointer): Boolean;
    procedure SetFieldToWrite(var ADeltaFields: TDeltaWriteFields; ADeltaName, AFieldName: LStr; AOffset: Pointer);

  public
    destructor Destroy; override;

    procedure Add(var ABuffer: TBufferEx2; const AName: LStr; AFieldsCount: UInt16); overload;

    procedure Initialize;
    procedure Finalize;

    function Count: Int32;
    function Get(AIndexInArray: UInt32): PDelta;

    function Read(var ABuffer: TBufferEx2; const AName: LStr): TDeltaReadFields; overload;
    procedure Read(var ABuffer: TBufferEx2; var ADeltaField: TDeltaField); overload;
    procedure Read(var ABuffer: TBufferEx2; var AEvent: TEvent); overload;
    procedure Read(var ABuffer: TBufferEx2; var AWeaponData: TWeaponData); overload;
    procedure Read(var ABuffer: TBufferEx2; var AUserCmd: TUserCmd); overload;
    procedure Read(var ABuffer: TBufferEx2; var AEntity: TEntity; const AType: TEntityType); overload;
    procedure Read(var ABuffer: TBufferEx2; var AClientData: TClientData); overload;

    procedure Write(var ABuffer: TBufferEx2; Delta: TDeltaWriteFields); overload;
    procedure Write(var ABuffer: TBufferEx2; ANew, AOld: TDeltaField); overload;
    // tevent
    // tweapondata
    procedure Write(var ABuffer: TBufferEx2; ANew, AOld: TUserCmd); overload;
    procedure Write(var ABuffer: TBufferEx2; ANew, AOld: TEntity; AType: TEntityType); overload;
    // tclientdata

  end;

implementation

class operator TDeltaField.Equal(A, B: TDeltaField): Boolean;
begin
  Result := A.Name = B.Name;
end;

class operator TDeltaField.NotEqual(A, B: TDeltaField): Boolean;
begin
  Result := A.Name <> B.Name;
end;

class operator TDeltaField.Equal(A: TDeltaField; B: LStr): Boolean;
begin
  Result := A.Name = B;
end;

class operator TDeltaField.NotEqual(A: TDeltaField; B: LStr): Boolean;
begin
  Result := A.Name <> B;
end;

class operator TDelta.Equal(A, B: TDelta): Boolean;
begin
  Result := A.Name = B.Name;
end;

class operator TDelta.NotEqual(A, B: TDelta): Boolean;
begin
  Result := A.Name <> B.Name;
end;

class operator TDelta.Equal(A: TDelta; B: LStr): Boolean;
begin
  Result := A.Name = B;
end;

class operator TDelta.NotEqual(A: TDelta; B: LStr): Boolean;
begin
  Result := A.Name <> B;
end;

function TDeltaSystem.FindDeltaField(ADelta: TDelta; const AName: LStr): PDeltaField;
var
  I: Int32;
begin
  Result := nil;

  with ADelta do
    for I := Low(Fields) to High(Fields) do
      if Fields[I] = AName then
        Exit(@Fields[I]);
end;

function TDeltaSystem.FindDelta(const AName: LStr): PDelta;
var
  I: Int32;
begin
  Result := nil;

  for I := Low(Deltas) to High(Deltas) do
    if Deltas[I] = AName then
      Exit(@Deltas[I]);
end;

procedure TDeltaSystem.Add(AName: LStr; AField: TDeltaField);
var
  D: PDelta;
  F: PDeltaField;
begin
  D := FindDelta(AName);

  // add new
  if D = nil then
  begin
    SetLength(Deltas, Length(Deltas) + 1);
    D := @Deltas[High(Deltas)];
    D.Name := AName;
  end;

  F := FindDeltaField(D^, AField.Name);

  if F = nil then
  begin
    SetLength(D.Fields, Length(D.Fields) + 1);

    // need checking for existing field
    D.Fields[High(D.Fields)] := AField;

    with D.Fields[High(D.Fields)] do
    begin
      if Size = 0 then
        Size := 1;

      if Bits = 0 then
        Bits := 1;

      if Scale = 0 then
        Scale := 1;

      if PScale = 0 then
        PScale := 1;
    end;
  end;
end;

procedure TDeltaSystem.Add(AName: LStr; AFields: array of TDeltaField);
var
  I: Int32;
begin
  for I := Low(AFields) to High(AFields) do
    Add(AName, AFields[I])
end;

function TDeltaSystem.ReadFieldToOffset(AReadField: TDeltaReadField; AName: LStr; Ptr: Pointer): Boolean;
begin
  Result := False;

  with AReadField do
    if Name = AName then
    begin
      case FieldType and not DT_SIGNED of
        DT_BYTE: PUInt8(Ptr)^ := ValueInt;
        DT_SHORT: PUInt16(Ptr)^ := ValueInt;
        DT_INTEGER: PUInt32(Ptr)^ := ValueInt;

        DT_FLOAT,
        DT_TIMEWINDOW_8,
        DT_TIMEWINDOW_BIG,
        DT_ANGLE: PFloat(Ptr)^ := ValueFloat;

        DT_STRING: PLStr(Ptr)^ := ValueStr;
      end;

      Result := True;
    end;
end;

procedure TDeltaSystem.SetFieldToWrite(var ADeltaFields: TDeltaWriteFields; ADeltaName, AFieldName: LStr; AOffset: Pointer);
const Title = 'SetFieldToWrite';
var
  I: Int32;
  D: PDelta;
  F: PDeltaField;
begin
  D := FindDelta(ADeltaName);

  if D = nil then
  begin
    Error(Title, ['Unknown delta: "', ADeltaName, '"']);
    Exit;
  end;

  F := FindDeltaField(D^, AFieldName);

  // no error, its ok
  if F = nil then
    Exit;

  if Length(ADeltaFields) <> Length(D.Fields) then
    SetLength(ADeltaFields, Length(D.Fields));

  for I := Low(D.Fields) to High(D.Fields) do
    if D.Fields[I] = AFieldName then
      with ADeltaFields[I] do
      begin
        Writed := True;
        Ptr := AOffset;
        Field := F;

        Break;
      end;
end;

destructor TDeltaSystem.Destroy;
begin
  Finalize;

  inherited;
end;

procedure TDeltaSystem.Add(var ABuffer: TBufferEx2; const AName: LStr; AFieldsCount: UInt16);
const Title = 'Add';
var
  I: Int32;
  F: TDeltaField;
begin
  for I := 0 to AFieldsCount - 1 do
  begin
    Clear(F);
    Read(ABuffer, F);
    Add(AName, F);
  end;
end;

procedure TDeltaSystem.Initialize;
begin
  Add(S_DELTA_METADELTA, Delta_G_MetaDelta);
end;

procedure TDeltaSystem.Finalize;
begin
  Clear(Deltas);
end;

function TDeltaSystem.Count: Int32;
begin
  Result := Length(Deltas);
end;

function TDeltaSystem.Get(AIndexInArray: UInt32): PDelta;
begin
  Result := @Deltas[AIndexInArray];
end;

function TDeltaSystem.Read(var ABuffer: TBufferEx2; const AName: LStr): TDeltaReadFields;
const Title = 'Read';
var
  I: Int32;
  D: PDelta;
  C: array[1..8] of UInt8;
  Signed: Boolean;
begin
  SetTitle(Title);

  D := FindDelta(AName);

  if D = nil then
  begin
    Error(Title, ['Unknown delta: "', AName, '"']);
    Exit;
  end;

  FillChar(C, SizeOf(C), 0);

  for I := 1 to ABuffer.ReadUBits(3) do
    C[I] := ABuffer.ReadUBits(8);

  Clear(Result);
  SetLength(Result, Length(D.Fields));

  with ABuffer do
    for I := Low(D.Fields) to High(D.Fields) do
      if PUInt32(UInt32(@C) + 4 * UInt32(I > 31))^ and (1 shl (I and 31)) > 0 then
        with Result[I] do
        begin
          Readed := True;
          Name := D.Fields[I].Name;
          FieldType := D.Fields[I].FieldType;

          Signed := (FieldType and DT_SIGNED) > 0;

          with D.Fields[I] do
            case FieldType and not DT_SIGNED of
              DT_TIMEWINDOW_8, 
              DT_TIMEWINDOW_BIG, 
              DT_FLOAT:
                if Signed then
                  ValueFloat := ReadSBits(Bits) / Scale * PScale
                else
                  ValueFloat := ReadUBits(Bits) / Scale * PScale;

              DT_ANGLE: ValueFloat := ReadBitAngle(Bits);

              DT_BYTE,
              DT_SHORT,
              DT_INTEGER:
                if Signed then
                  ValueInt := Trunc(ReadSBits(Bits) / Scale * PScale)
                else
                  ValueInt := Trunc(ReadUBits(Bits) / Scale * PScale);

              DT_STRING: ValueStr := ReadBitLStr;
            else
              Error(Title, ['Unparseable field type "', FieldType and not DT_SIGNED, '".']);
            end;
        end;
end;

procedure TDeltaSystem.Read(var ABuffer: TBufferEx2; var ADeltaField: TDeltaField);
  procedure V(AData: TDeltaReadField);
    function A(AName: LStr; Ptr: Pointer): Boolean; begin Result := ReadFieldToOffset(AData, AName, Ptr); end;
  begin
    with ADeltaField do
      if not A('fieldType', @FieldType) then
      if not A('fieldName', @Name) then
      if not A('fieldOffset', @Offset) then
      if not A('fieldSize', @Size) then
      if not A('significant_bits', @Bits) then
      if not A('premultiply', @Scale) then
      A('postmultiply', @PScale);
  end;
var
  I: Int32;
  Data: TDeltaReadFields;
begin
  Data := Read(ABuffer, S_DELTA_METADELTA);

  for I := Low(Data) to High(Data) do
    if Data[I].Readed then
      V(Data[I]);
end;

procedure TDeltaSystem.Read(var ABuffer: TBufferEx2; var AEvent: TEvent);
  procedure V(AData: TDeltaReadField);
    function A(AName: LStr; Ptr: Pointer): Boolean; begin Result := ReadFieldToOffset(AData, AName, Ptr); end;
  begin
    with AEvent do
      if not A('entindex', @EntIndex) then
      if not A('origin[0]', @Origin.X) then
      if not A('origin[1]', @Origin.Y) then
      if not A('origin[2]', @Origin.Z) then
      if not A('angles[0]', @Angles.X) then
      if not A('angles[1]', @Angles.Y) then
      if not A('angles[2]', @Angles.Z) then
      if not A('ducking', @Ducking) then
      if not A('fparam1', @FParam1) then
      if not A('fparam2', @FParam2) then
      if not A('iparam1', @IParam1) then
      if not A('iparam2', @IParam2) then
      if not A('bparam1', @BParam1) then
      A('bparam2', @BParam2);
  end;
var
  I: Int32;
  Data: TDeltaReadFields;
begin
  Data := Read(ABuffer, S_DELTA_EVENT);

  for I := Low(Data) to High(Data) do
    if Data[I].Readed then
      V(Data[I]);
end;

procedure TDeltaSystem.Read(var ABuffer: TBufferEx2; var AWeaponData: TWeaponData);
  procedure V(AData: TDeltaReadField);
    function A(AName: LStr; Ptr: Pointer): Boolean; begin Result := ReadFieldToOffset(AData, AName, Ptr); end;
  begin
    with AWeaponData do
      if not A('m_iId', @ID) then
      if not A('m_iClip', @Clip) then
      if not A('m_flNextPrimaryAttack', @NextPrimaryAttack) then
      if not A('m_flNextSecondaryAttack', @NextSecondaryAttack) then
      if not A('m_flTimeWeaponIdle', @TimeWeaponIdle) then
      if not A('m_fInReload', @InReload) then
      if not A('m_fInSpecialReload', @InSpecialReload) then
      if not A('m_flNextReload', @NextReload) then
      if not A('m_flPumpTime', @PumpTime) then
      if not A('m_fReloadTime', @ReloadTime) then
      if not A('m_fAimedDamage', @AimedDamage) then
      if not A('m_fNextAimBonus', @NextAimBonus) then
      if not A('m_fInZoom', @InZoom) then
      if not A('m_iWeaponState', @WeaponState) then
      if not A('iuser1', @IUser1) then
      if not A('iuser2', @IUser2) then
      if not A('iuser3', @IUser3) then
      if not A('iuser4', @IUser4) then
      if not A('fuser1', @FUser1) then
      if not A('fuser2', @FUser2) then
      if not A('fuser3', @FUser3) then
      A('fuser4', @FUser4);
  end;
var
  I: Int32;
  Data: TDeltaReadFields;
begin
  Data := Read(ABuffer, S_DELTA_WEAPON_DATA);

  for I := Low(Data) to High(Data) do
    if Data[I].Readed then
      V(Data[I]);
end;

procedure TDeltaSystem.Read(var ABuffer: TBufferEx2; var AUserCmd: TUserCmd);
  procedure V(AData: TDeltaReadField);
    function A(AName: LStr; Ptr: Pointer): Boolean; begin Result := ReadFieldToOffset(AData, AName, Ptr); end;
  begin
    with AUserCmd do
      if not A('lerp_msec', @LerpMSec) then
      if not A('msec', @MSec) then
      if not A('viewangles[1]', @ViewAngles.Y) then
      if not A('viewangles[0]', @ViewAngles.X) then
      if not A('viewangles[2]', @ViewAngles.Z) then
      if not A('forwardmove', @ForwardMove) then
      if not A('sidemove', @SideMove) then
      if not A('upmove', @UpMove) then
      if not A('lightlevel', @LightLevel) then
      if not A('buttons', @Buttons) then
      if not A('impulse', @Impulse) then
      if not A('weaponselect', @WeaponSelect) then
      if not A('impact_index', @ImpactIndex) then
      if not A('impact_position[0]', @ImpactPosition.X) then
      if not A('impact_position[1]', @ImpactPosition.Y) then
      A('impact_position[2]', @ImpactPosition.Z);
  end;
var
  I: Int32;
  Data: TDeltaReadFields;
begin
  Data := Read(ABuffer, S_DELTA_USERCMD);

  for I := Low(Data) to High(Data) do
    if Data[I].Readed then
      V(Data[I]);
end;

procedure TDeltaSystem.Read(var ABuffer: TBufferEx2; var AEntity: TEntity; const AType: TEntityType);
  procedure V(AData: TDeltaReadField);
    function A(AName: LStr; Ptr: Pointer): Boolean; begin Result := ReadFieldToOffset(AData, AName, Ptr); end;
  begin
    with AEntity do
      if not A('origin[0]', @Origin.X) then
      if not A('origin[1]', @Origin.Y) then
      if not A('origin[2]', @Origin.Z) then
      if not A('angles[0]', @Angles.X) then
      if not A('angles[1]', @Angles.Y) then
      if not A('angles[2]', @Angles.Z) then
      if not A('modelindex', @ModelIndex) then
      if not A('sequence', @Sequence) then
      if not A('frame', @Frame) then
      if not A('colormap', @ColorMap) then
      if not A('skin', @Skin) then
      if not A('solid', @Solid) then
      if not A('effects', @Effects) then
      if not A('scale', @Scale) then
      if not A('eflags', @EFlags) then
      if not A('rendermode', @RenderMode) then
      if not A('renderamt', @RenderAmt) then
      if not A('rendercolor.r', @RenderColor.R) then
      if not A('rendercolor.g', @RenderColor.G) then
      if not A('rendercolor.b', @RenderColor.B) then
      if not A('renderfx', @RenderFX) then
      if not A('movetype', @MoveType) then
      if not A('animtime', @AnimTime) then
      if not A('framerate', @FrameRate) then
      if not A('body', @Body) then
      if not A('controller[0]', @Controller[0]) then
      if not A('controller[1]', @Controller[1]) then
      if not A('controller[2]', @Controller[2]) then
      if not A('controller[3]', @Controller[3]) then
      if not A('blending[0]', @Blending[0]) then
      if not A('blending[1]', @Blending[1]) then
      if not A('velocity[0]', @Velocity.X) then
      if not A('velocity[1]', @Velocity.Y) then
      if not A('velocity[2]', @Velocity.Z) then
      if not A('mins[0]', @MinS.X) then
      if not A('mins[1]', @MinS.Y) then
      if not A('mins[2]', @MinS.Z) then
      if not A('maxs[0]', @MaxS.X) then
      if not A('maxs[1]', @MaxS.Y) then
      if not A('maxs[2]', @MaxS.Z) then
      if not A('aiment', @Aiment) then
      if not A('owner', @Owner) then
      if not A('friction', @Friction) then
      if not A('gravity', @Gravity) then
      if not A('team', @Team) then
      if not A('playerclass', @PlayerClass) then
      if not A('health', @Health) then
      if not A('spectator', @Spectator) then
      if not A('weaponmodel', @WeaponModel) then
      if not A('gaitsequence', @GaitSequence) then
      if not A('basevelocity[0]', @BaseVelocity.X) then
      if not A('basevelocity[1]', @BaseVelocity.Y) then
      if not A('basevelocity[2]', @BaseVelocity.Z) then
      if not A('usehull', @UseHull) then
      if not A('oldbuttons', @OldButtons) then
      if not A('onground', @OnGround) then
      if not A('iStepLeft', @StepLeft) then
      if not A('flFallVelocity', @FallVelocity) then

      if not A('weaponanim', @WeaponAnim) then
      if not A('startpos[0]', @StartPos.X) then
      if not A('startpos[1]', @StartPos.Y) then
      if not A('startpos[2]', @StartPos.Z) then
      if not A('endpos[0]', @EndPos.X) then
      if not A('endpos[1]', @EndPos.Y) then
      if not A('endpos[2]', @EndPos.Z) then
      if not A('impacttime', @ImpactTime) then
      if not A('starttime', @StartTime) then
      if not A('iuser1', @IUser1) then
      if not A('iuser2', @IUser2) then
      if not A('iuser3', @IUser3) then
      if not A('iuser4', @IUser4) then
      if not A('fuser1', @FUser1) then
      if not A('fuser2', @FUser2) then
      if not A('fuser3', @FUser3) then
      if not A('fuser4', @FUser4) then
      if not A('vuser1[0]', @VUser1.X) then
      if not A('vuser1[1]', @VUser1.Y) then
      if not A('vuser1[2]', @VUser1.Z) then
      if not A('vuser2[0]', @VUser2.X) then
      if not A('vuser2[1]', @VUser2.Y) then
      if not A('vuser2[2]', @VUser2.Z) then
      if not A('vuser3[0]', @VUser3.X) then
      if not A('vuser3[1]', @VUser3.Y) then
      if not A('vuser3[2]', @VUser3.Z) then
      if not A('vuser4[0]', @VUser4.X) then
      if not A('vuser4[1]', @VUser4.Y) then
      A('vuser4[2]', @VUser4.Z);
  end;
var
  I: Int32;
  Data: TDeltaReadFields;
begin
  case AType of
    ENT_STANDART: Data := Read(ABuffer, S_DELTA_ENTITY_STATE);
    ENT_PLAYER: Data := Read(ABuffer, S_DELTA_ENTITY_STATE_PLAYER);
    ENT_CUSTOM: Data := Read(ABuffer, S_DELTA_CUSTOM_ENTITY_STATE);
  end;

  for I := Low(Data) to High(Data) do
    if Data[I].Readed then
      V(Data[I]);
end;

procedure TDeltaSystem.Read(var ABuffer: TBufferEx2; var AClientData: TClientData);
  procedure V(AData: TDeltaReadField);
    function A(AName: LStr; Ptr: Pointer): Boolean; begin Result := ReadFieldToOffset(AData, AName, Ptr); end;
  begin
    with AClientData do
      if not A('origin[0]', @Origin.X) then
      if not A('origin[1]', @Origin.Y) then
      if not A('origin[2]', @Origin.Z) then
      if not A('velocity[0]', @Velocity.X) then
      if not A('velocity[1]', @Velocity.Y) then
      if not A('velocity[2]', @Velocity.Z) then
      if not A('viewmodel', @ViewModel) then
      if not A('punchangle[0]', @PunchAngle.X) then
      if not A('punchangle[1]', @PunchAngle.Y) then
      if not A('punchangle[2]', @PunchAngle.Z) then
      if not A('flags', @Flags) then
      if not A('waterlevel', @WaterLevel) then
      if not A('watertype', @WaterType) then
      if not A('view_ofs[0]', @ViewOffset.X) then
      if not A('view_ofs[1]', @ViewOffset.Y) then
      if not A('view_ofs[2]', @ViewOffset.Z) then
      if not A('health', @Health) then
      if not A('bInDuck', @InDuck) then
      if not A('weapons', @Weapons) then
      if not A('flTimeStepSound', @TimeStepSound) then
      if not A('flDuckTime', @DuckTime) then
      if not A('flSwimTime', @SwimTime) then
      if not A('waterjumptime', @WaterJumpTime) then
      if not A('maxspeed', @MaxSpeed) then
      if not A('fov', @FOV) then
      if not A('weaponanim', @WeaponAnim) then
      if not A('m_iId', @ID) then
      if not A('ammo_shells', @AmmoShells) then
      if not A('ammo_nails', @AmmoNails) then
      if not A('ammo_cells', @AmmoCells) then
      if not A('ammo_rockets', @AmmoRockets) then
      if not A('m_flNextAttack', @NextAttack) then
      if not A('tfstate', @TFState) then
      if not A('pushmsec', @PushMSec) then
      if not A('deadflag', @DeadFlag) then
      if not A('physinfo', @PhysInfo) then
      if not A('iuser1', @IUser1) then
      if not A('iuser2', @IUser2) then
      if not A('iuser3', @IUser3) then
      if not A('iuser4', @IUser4) then
      if not A('fuser1', @FUser1) then
      if not A('fuser2', @FUser2) then
      if not A('fuser3', @FUser3) then
      if not A('fuser4', @FUser4) then
      if not A('vuser1[0]', @VUser1.X) then
      if not A('vuser1[1]', @VUser1.Y) then
      if not A('vuser1[2]', @VUser1.Z) then
      if not A('vuser2[0]', @VUser2.X) then
      if not A('vuser2[1]', @VUser2.Y) then
      if not A('vuser2[2]', @VUser2.Z) then
      if not A('vuser3[0]', @VUser3.X) then
      if not A('vuser3[1]', @VUser3.Y) then
      if not A('vuser3[2]', @VUser3.Z) then
      if not A('vuser4[0]', @VUser4.X) then
      if not A('vuser4[1]', @VUser4.Y) then
      A('vuser4[2]', @VUser4.Z)
  end;
var
  I: Int32;
  Data: TDeltaReadFields;
begin
  Data := Read(ABuffer, S_DELTA_CLIENTDATA);

  for I := Low(Data) to High(Data) do
    if Data[I].Readed then
      V(Data[I]);
end;

procedure TDeltaSystem.Write(var ABuffer: TBufferEx2; Delta: TDeltaWriteFields);
const Title = 'Write';
var
  I, Fields: Int32;
  C: array[1..8] of UInt8;
  Signed: Boolean;

  function CountSendFields: Int32;
  var
    I: Int32;
  begin
    Clear(Result);

    for I := Low(Delta) to High(Delta) do
      if Delta[I].Writed then
        Inc(Result);
  end;

  procedure SetFlags(Dest: Pointer; out BytesWritten: Int32);
  var
    ID, I: Int32;
    P: PUInt32;
  begin
    FillChar(Dest^, 8, 0);
    ID := -1;

    for I := High(Delta) downto Low(Delta) do
      if Delta[I].Writed then
      begin
        if ID = -1 then
          ID := I;

        P := PUInt32(UInt32(Dest) + 4 * UInt32(I > 31));
        P^ := P^ or UInt32(1 shl (I and 31));
      end;

    if ID = -1 then
      BytesWritten := 0
    else
      BytesWritten := (UInt32(ID) shr 3) + 1;
  end;
begin
  SetTitle(Title);

  SetFlags(@C, Fields);

  ABuffer.WriteUBits(Fields, 3);

  for I := 1 to Fields do
    ABuffer.WriteUBits(C[I], 8);

  with ABuffer do
    for I := Low(Delta) to High(Delta) do
      with Delta[I] do
        if Writed then
          with Field^ do
          begin
            Signed := FieldType and DT_SIGNED > 0;

            case FieldType and not DT_SIGNED of             
              DT_FLOAT:
                if Signed then
                  WriteSBits(Trunc(PFloat(Ptr)^ * Scale / PScale), Bits)
                else
                  WriteUBits(Trunc(PFloat(Ptr)^ * Scale / PScale), Bits);

              DT_ANGLE: WriteBitAngle(PFloat(Ptr)^, Bits);
              DT_TIMEWINDOW_8: WriteSBits({Trunc(GetUpTime * 100) -} Trunc(PFloat(Ptr)^ * 100), 8);
              DT_TIMEWINDOW_BIG: WriteSBits({Trunc(GetUpTime * Scale) -} Trunc(PFloat(Ptr)^ * Scale), Bits);

              DT_BYTE:
                if Signed then
                  WriteSBits(Trunc(PInt8(Ptr)^ * Scale / PScale) and $FF, Bits)
                else
                  WriteUBits(Trunc(PUInt8(Ptr)^ * Scale / PScale) and $FF, Bits);

              DT_SHORT:
                if Signed then
                  WriteSBits(Trunc(PInt16(Ptr)^ * Scale / PScale) and $FFFF, Bits)
                else
                  WriteUBits(Trunc(PUInt16(Ptr)^ * Scale / PScale) and $FFFF, Bits);

              DT_INTEGER:
                  if Signed then
                    WriteSBits(Trunc(PInt32(Ptr)^ * Scale / PScale), Bits)
                  else
                    WriteUBits(Trunc(PUInt32(Ptr)^ * Scale / PScale), Bits);

              DT_STRING: WriteBitLStr(PLStr(Ptr)^);
            else
              Error(Title, ['Unknown send field type']);
            end;
          end;
end;

procedure TDeltaSystem.Write(var ABuffer: TBufferEx2; ANew, AOld: TDeltaField);
var
  Data: TDeltaWriteFields;
  procedure A(AFieldName: LStr; Offset: Pointer); begin SetFieldToWrite(Data, S_DELTA_METADELTA, AFieldName, Offset); end;
begin
  with ANew do
  begin
    if FieldType <> AOld.FieldType then A('fieldType', @FieldType);
    if Name <> AOld.Name then A('fieldName', @Name);
    if Offset <> AOld.Offset then A('fieldOffset', @Offset);
    if Size <> AOld.Size then A('fieldSize', @Size);
    if Bits <> AOld.Bits then A('significant_bits', @Bits);
    if Scale <> AOld.Scale then A('premultiply', @Scale);
    if PScale <> AOld.PScale then A('postmultiply', @PScale);
  end;

  Write(ABuffer, Data);
end;

procedure TDeltaSystem.Write(var ABuffer: TBufferEx2; ANew, AOld: TUserCmd);
var
  Data: TDeltaWriteFields;
  procedure A(AFieldName: LStr; Offset: Pointer); begin SetFieldToWrite(Data, S_DELTA_USERCMD, AFieldName, Offset); end;
begin
  with ANew do
  begin
    if LerpMSec <> AOld.LerpMSec then A('lerp_msec', @LerpMSec);
    if MSec <> AOld.MSec then A('msec', @MSec);
    if ViewAngles.X <> AOld.ViewAngles.X then A('viewangles[0]', @ViewAngles.X);
    if ViewAngles.Y <> AOld.ViewAngles.Y then A('viewangles[1]', @ViewAngles.Y);
    if ViewAngles.Z <> AOld.ViewAngles.Z then A('viewangles[2]', @ViewAngles.Z);
    if ForwardMove <> AOld.ForwardMove then A('forwardmove', @ForwardMove);
    if SideMove <> AOld.SideMove then A('sidemove', @SideMove);
    if UpMove <> AOld.UpMove then A('upmove', @UpMove);
    if LightLevel <> AOld.LightLevel then A('lightlevel', @LightLevel);
    if Buttons <> AOld.Buttons then A('buttons', @Buttons);
    if Impulse <> AOld.Impulse then A('impulse', @Impulse);
    if WeaponSelect <> AOld.WeaponSelect then A('weaponselect', @WeaponSelect);
    if ImpactIndex <> AOld.ImpactIndex then A('impact_index', @ImpactIndex);
    if ImpactPosition.X <> AOld.ImpactPosition.X then A('impact_position[0]', @ImpactPosition.X);
    if ImpactPosition.Y <> AOld.ImpactPosition.Y then A('impact_position[1]', @ImpactPosition.Y);
    if ImpactPosition.Z <> AOld.ImpactPosition.Z then A('impact_position[2]', @ImpactPosition.Z);
  end;

  Write(ABuffer, Data);
end;

procedure TDeltaSystem.Write(var ABuffer: TBufferEx2; ANew, AOld: TEntity; AType: TEntityType);
var
  Data: TDeltaWriteFields;
  procedure A(AFieldName: LStr; Offset: Pointer);
  begin
    case AType of
      ENT_STANDART: SetFieldToWrite(Data, S_DELTA_ENTITY_STATE, AFieldName, Offset);
      ENT_PLAYER: SetFieldToWrite(Data, S_DELTA_ENTITY_STATE_PLAYER, AFieldName, Offset);
      ENT_CUSTOM: SetFieldToWrite(Data, S_DELTA_CUSTOM_ENTITY_STATE, AFieldName, Offset);
    end;
  end;
begin
  with ANew do
  begin
    if Origin.X <> AOld.Origin.X then A('origin[0]', @Origin.X);
    if Origin.Y <> AOld.Origin.Y then A('origin[1]', @Origin.Y);
    if Origin.Z <> AOld.Origin.Z then A('origin[2]', @Origin.Z);
    if Angles.X <> AOld.Angles.X then A('angles[0]', @Angles.X);
    if Angles.Y <> AOld.Angles.Y then A('angles[1]', @Angles.Y);
    if Angles.Z <> AOld.Angles.Z then A('angles[2]', @Angles.Z);
    if ModelIndex <> AOld.ModelIndex then A('modelindex', @ModelIndex);
    if Sequence <> AOld.Sequence then A('sequence', @Sequence);
    if Frame <> AOld.Frame then A('frame', @Frame);
    if Colormap <> AOld.ColorMap then A('colormap', @ColorMap);
    if Skin <> AOld.Skin then A('skin', @Skin);
    if Solid <> AOld.Solid then A('solid', @Solid);
    if Effects <> AOld.Effects then A('effects', @Effects);
    if Scale <> AOld.Scale then A('scale', @Scale);
    if EFlags <> AOld.EFlags then A('eflags', @EFlags);
    if RenderMode <> AOld.RenderMode then A('rendermode', @RenderMode);
    if RenderAmt <> AOld.RenderAmt then A('renderamt', @RenderAmt);
    if RenderColor.R <> AOld.RenderColor.R then A('rendercolor.r', @RenderColor.R);
    if RenderColor.G <> AOld.RenderColor.G then A('rendercolor.g', @RenderColor.G);
    if RenderColor.B <> AOld.RenderColor.B then A('rendercolor.b', @RenderColor.B);
    if RenderFX <> AOld.RenderFX then A('renderfx', @RenderFX);
    if MoveType <> AOld.MoveType then A('movetype', @MoveType);
    if AnimTime <> AOld.AnimTime then A('animtime', @AnimTime);
    if FrameRate <> AOld.FrameRate then A('framerate', @FrameRate);
    if Body <> AOld.Body then A('body', @Body);
    if Controller[0] <> AOld.Controller[0] then A('controller[0]', @Controller[0]);
    if Controller[1] <> AOld.Controller[1] then A('controller[1]', @Controller[1]);
    if Controller[2] <> AOld.Controller[2] then A('controller[2]', @Controller[2]);
    if Controller[3] <> AOld.Controller[3] then A('controller[3]', @Controller[3]);
    if Blending[0] <> AOld.Blending[0] then A('blending[0]', @Blending[0]);
    if Blending[1] <> AOld.Blending[1] then A('blending[1]', @Blending[1]);
    if Velocity.X <> AOld.Velocity.X then A('velocity[0]', @Velocity.X);
    if Velocity.Y <> AOld.Velocity.Y then A('velocity[1]', @Velocity.Y);
    if Velocity.Z <> AOld.Velocity.Z then A('velocity[2]', @Velocity.Z);
    if MinS.X <> AOld.MinS.X then A('mins[0]', @MinS.X);
    if MinS.Y <> AOld.MinS.Y then A('mins[1]', @MinS.Y);
    if MinS.Z <> AOld.MinS.Z then A('mins[2]', @MinS.Z);
    if MaxS.X <> AOld.MaxS.X then A('maxs[0]', @MaxS.X);
    if MaxS.Y <> AOld.MaxS.Y then A('maxs[1]', @MaxS.Y);
    if MaxS.Z <> AOld.MaxS.Z then A('maxs[2]', @MaxS.Z);
    if Aiment <> AOld.Aiment then A('aiment', @Aiment);
    if Owner <> AOld.Owner then A('owner', @Owner);
    if Friction <> AOld.Friction then A('friction', @Friction);
    if Gravity <> AOld.Gravity then A('gravity', @Gravity);
    if Team <> AOld.Team then A('team', @Team);
    if PlayerClass <> AOld.PlayerClass then A('playerclass', @PlayerClass);
    if Health <> AOld.Health then A('health', @Health);
    if Spectator <> AOld.Spectator then A('spectator', @Spectator);
    if WeaponModel <> AOld.WeaponModel then A('weaponmodel', @WeaponModel);
    if GaitSequence <> AOld.GaitSequence then A('gaitsequence', @GaitSequence);
    if BaseVelocity.X <> AOld.BaseVelocity.X then A('basevelocity[0]', @BaseVelocity.X);
    if BaseVelocity.Y <> AOld.BaseVelocity.Y then A('basevelocity[1]', @BaseVelocity.Y);
    if BaseVelocity.Z <> AOld.BaseVelocity.Z then A('basevelocity[2]', @BaseVelocity.Z);
    if UseHull <> AOld.UseHull then A('usehull', @UseHull);
    if OldButtons <> AOld.OldButtons then A('oldbuttons', @OldButtons);
    if OnGround <> AOld.OnGround then A('onground', @OnGround);
    if StepLeft <> AOld.StepLeft then A('iStepLeft', @StepLeft);
    if FallVelocity <> AOld.FallVelocity then A('flFallVelocity', @FallVelocity);

    if WeaponAnim <> AOld.WeaponAnim then A('weaponanim', @WeaponAnim);
    if StartPos.X <> AOld.StartPos.X then A('startpos[0]', @StartPos.X);
    if StartPos.Y <> AOld.StartPos.Y then A('startpos[1]', @StartPos.Y);
    if StartPos.Z <> AOld.StartPos.Z then A('startpos[2]', @StartPos.Z);
    if EndPos.X <> AOld.EndPos.X then A('endpos[0]', @EndPos.X);
    if EndPos.Y <> AOld.EndPos.Y then A('endpos[1]', @EndPos.Y);
    if EndPos.Z <> AOld.EndPos.Z then A('endpos[2]', @EndPos.Z);
    if ImpactTime <> AOld.ImpactTime then A('impacttime', @ImpactTime);
    if StartTime <> AOld.StartTime then A('starttime', @StartTime);
    if IUser1 <> AOld.IUser1 then A('iuser1', @IUser1);
    if IUser2 <> AOld.IUser2 then A('iuser2', @IUser2);
    if IUser3 <> AOld.IUser3 then A('iuser3', @IUser3);
    if IUser4 <> AOld.IUser4 then A('iuser4', @IUser4);
    if FUser1 <> AOld.FUser1 then A('fuser1', @FUser1);
    if FUser2 <> AOld.FUser2 then A('fuser2', @FUser2);
    if FUser3 <> AOld.FUser3 then A('fuser3', @FUser3);
    if FUser4 <> AOld.FUser4 then A('fuser4', @FUser4);
    if VUser1.X <> AOld.VUser1.X then A('vuser1[0]', @VUser1.X);
    if VUser1.Y <> AOld.VUser1.Y then A('vuser1[1]', @VUser1.Y);
    if VUser1.Z <> AOld.VUser1.Z then A('vuser1[2]', @VUser1.Z);
    if VUser2.X <> AOld.VUser2.X then A('vuser2[0]', @VUser2.X);
    if VUser2.Y <> AOld.VUser2.Y then A('vuser2[1]', @VUser2.Y);
    if VUser2.Z <> AOld.VUser2.Z then A('vuser2[2]', @VUser2.Z);
    if VUser3.X <> AOld.VUser3.X then A('vuser3[0]', @VUser3.X);
    if VUser3.Y <> AOld.VUser3.Y then A('vuser3[1]', @VUser3.Y);
    if VUser3.Z <> AOld.VUser3.Z then A('vuser3[2]', @VUser3.Z);
    if VUser4.X <> AOld.VUser4.X then A('vuser4[0]', @VUser4.X);
    if VUser4.Y <> AOld.VUser4.Y then A('vuser4[1]', @VUser4.Y);
    if VUser4.Z <> AOld.VUser4.Z then A('vuser4[2]', @VUser4.X);
  end;

  Write(ABuffer, Data);
end;

procedure Clear(var Data: TDeltaField);
begin
  with Data do
  begin
    Clear(Name);
    Clear(FieldType);
    Clear(Offset);
    Clear(Size);
    Clear(Bits);
    Clear(Scale);
    Clear(PScale);
  end;
end;

procedure Clear(var Data: TDeltaFields);
var
  I: Int32;
begin
  for I := Low(Data) to High(Data) do
    Clear(Data[I]);

  SetLength(Data, 0);
end;

procedure Clear(var Data: TDeltaReadField);
begin
  with Data do
  begin
    Clear(Readed);
    Clear(Name);
    Clear(FieldType);
    Clear(ValueInt);
    Clear(ValueFloat);
    Clear(ValueStr);
  end;
end;

procedure Clear(var Data: TDeltaReadFields);
var
  I: Int32;
begin
  for I := Low(Data) to High(Data) do
    Clear(Data[I]);

  SetLength(Data, 0);
end;

procedure Clear(var Data: TDeltaWriteField);
begin
  with Data do
  begin
    Clear(Writed);
    Clear(Ptr);
    Field := nil;
  end;
end;

procedure Clear(var Data: TDeltaWriteFields);
var
  I: Int32;
begin
  for I := Low(Data) to High(Data) do
    Clear(Data[I]);

  SetLength(Data, 0);
end;

procedure Clear(var Data: TDelta);
begin
  with Data do
  begin
    Clear(Name);
    Clear(Fields);
  end;
end;

procedure Clear(var Data: TDeltas);
var
  I: Int32;
begin
  for I := Low(Data) to High(Data) do
    Clear(Data[I]);

  SetLength(Data, 0);
end;

end.
