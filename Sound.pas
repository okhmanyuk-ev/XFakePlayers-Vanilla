unit Sound;

interface

uses Default, Vector;

const
  SND_VOLUME = 1 shl 0;
  SND_ATTN = 1 shl 1;
  SND_LONG_INDEX = 1 shl 2;
  SND_PITCH = 1 shl 3;
  SND_SENTENCE = 1 shl 4;

  SND_STOP = 1 shl 5;
  SND_CHANGE_VOL = 1 shl 6;
  SND_CHANGE_PITCH = 1 shl 7;
  SND_SPAWNING = 1 shl 8; // 9 bits

  CHAN_AUTO = 0;
  CHAN_WEAPON = 1;
  CHAN_VOICE = 2;
  CHAN_ITEM = 3;
  CHAN_BODY = 4;
  CHAN_STREAM = 5;
  CHAN_STATIC = 6;
  CHAN_NETWORKVOICE_BASE = 7;
  CHAN_NETWORKVOICE_END = 500;

  ATTN_NONE = 0;
  ATTN_NORM = 0.8;
  ATTN_IDLE = 2;
  ATTN_STATIC = 1.25;

  PITCH_NORM = 100;
  PITCH_LOW = 95;
  PITCH_HIGH = 120;

  VOL_NORM = 255;

type
  TSound = record
    Index,
    Entity,
    Channel,
    Volume,
    Pitch: Int16;
    Attenuation: Float;
    Flags: Int16;
    Origin: TVec3F;

    class operator Equal(A, B: TSound): Boolean;
    class operator NotEqual(A, B: TSound): Boolean;

    function ToString: LStr;
  end;

implementation

class operator TSound.Equal(A, B: TSound): Boolean;
begin
  Result :=
    (A.Index = B.Index) and
    (A.Entity = B.Entity) and
    (A.Channel = B.Channel) and
    (A.Volume = B.Volume) and
    (A.Pitch = B.Pitch) and
    (A.Attenuation = B.Attenuation) and
    (A.Flags = B.Flags) and
    (A.Origin = B.Origin);
end;

class operator TSound.NotEqual(A, B: TSound): Boolean;
begin
  Result :=
    (A.Index <> B.Index) or
    (A.Entity <> B.Entity) or
    (A.Channel <> B.Channel) or
    (A.Volume <> B.Volume) or
    (A.Pitch <> B.Pitch) or
    (A.Attenuation <> B.Attenuation) or
    (A.Flags <> B.Flags) or
    (A.Origin <> B.Origin);
end;

function TSound.ToString: LStr;
begin
  StringFromVarRec([
      'Index: ', Index, ', ',
      'Entity: ', Entity, ', ',
      'Channel: ', Channel, ', ',
      'Origin: [', Origin.ToString, '], ',
      'Volume: ', Volume, ', ',
      'Pitch: ', Pitch, ', ',
      'Attenuation: ', Attenuation, ', ',
      'Flags: ', Flags],
      Result);
end;

end.