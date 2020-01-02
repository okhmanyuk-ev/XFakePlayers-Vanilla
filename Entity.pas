unit Entity;

interface

uses
  Default,
  Vector,
  Shared;

type
  PEntity = ^TEntity; // 340  cf2
  TEntity = record
    EntityType: Int32;
    Number: UInt32; // revalidate
    MsgTime: Float;

    MessageNum: Int32;

    Origin, Angles: TVec3F;

    ModelIndex, Sequence: Int32;
    Frame: Float;

    ColorMap: Int32;
    Skin: UInt16;
    Solid: UInt16;
    Effects: Int32;
    Scale: Float;

    EFlags: Byte;

    RenderMode, RenderAmt: Int32;
    RenderColor: TRGB;
    RenderFX: Int32;

    MoveType: Int32;
    AnimTime, FrameRate: Float;
    Body: Int32;
    Controller: array[0..3] of Byte; // int32 ?
    Blending: array[0..3] of Byte;

    Velocity: TVec3F;

    MinS, MaxS: TVec3F;

    AimEnt, Owner: Int32;

    Friction, Gravity: Float;

    Team, // tfc
    PlayerClass, // tfc
    Health, Spectator, WeaponModel, GaitSequence: Int32;

    BaseVelocity: TVec3F;
    UseHull: Int32;
    OldButtons, OnGround, StepLeft: Int32;

    FallVelocity: Float;

    FOV: Float;
    WeaponAnim: Int32;

    StartPos, EndPos: TVec3F;
    ImpactTime, StartTime: Float;

    IUser1, IUser2, IUser3, IUser4: Int32;
    FUser1, FUser2, FUser3, FUser4: Float;
    VUser1, VUser2, VUser3, VUser4: TVec3F;

    IsActive: Boolean;
  end;

  PEntities = ^TEntities;
  TEntities = TArray<TEntity>;

  TEntityType = (ENT_STANDART, ENT_PLAYER, ENT_CUSTOM); // it is not TEntity.EntityType

const
  EntityCleared: TEntity = ();

implementation

end.