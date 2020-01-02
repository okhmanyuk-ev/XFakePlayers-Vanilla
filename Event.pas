unit Event;

interface

uses Default, Vector;

type
  PEvent = ^TEvent;
  TEvent = record   // TEventArgs
    Flags: Int32;
    EntIndex: Int32;

    Origin, Angles, Velocity: TVec3F;
    Ducking: Int32;

    FParam1, FParam2: Float;
    IParam1, IParam2: Int32;
    BParam1, BParam2: Int32;

    function ToString: LStr;
  end;

 TEventInfo = record
   Index: UInt16;
   Packet, Entity: Int16;
   FireTime: Float;
   Args: TEvent;
   Flags: UInt32;

   function ToString: LStr;
 end;
 
const
  MAX_EVENTS = 256;
  MAX_EVENT_QUEUE = 64;
 
  FEVENT_ORIGIN = 1 shl 0;
  FEVENT_ANGLES = 1 shl 1;
 
  FEV_NOTHOST = 1 shl 0; // 1
  FEV_RELIABLE = 1 shl 1; // 2
  FEV_GLOBAL = 1 shl 2; // 4
  FEV_UPDATE = 1 shl 3; // 8
  FEV_HOSTONLY = 1 shl 4; // 16
  FEV_SERVER = 1 shl 5; // 32
  FEV_CLIENT = 1 shl 6; // 64
 
procedure Clear(var Data: TEvent); overload; inline;
procedure Clear(var Data: TEventInfo); overload; inline;

implementation

function TEvent.ToString: LStr;
begin
  Result := StringFromVarRec([
    'Flags: ', Flags, ', ',
    'EntIndex: ', EntIndex, ', ',
    'Origin: [', Origin.ToString, '], ',
    'Angles: [', Angles.ToString, '], ',
    'Velocity: [', Velocity.ToString, '], ',
    'Ducking: ', Ducking, ', ',
    'F1: ', FParam1, ', ',
    'F2: ', FParam2, ', ',
    'I1: ', IParam1, ', ',
    'I2: ', IParam2, ', ',
    'B1: ', BParam1, ', ',
    'B2: ', BParam2]);
end;

function TEventInfo.ToString: LStr;
begin
  Result := StringFromVarRec([
    'Index: ', Index, ', ',
    'Packet: ', Packet, ', ',
    'Entity: ', Entity, ', ',
    'FireTime: ', FireTime, ', ',
    Args.ToString, ', ',
    'Flags: ', Flags]);
end;

procedure Clear(var Data: TEvent);
begin
  with Data do
  begin
    Clear(Flags);
    Clear(EntIndex);

    Clear(Origin);
    Clear(Angles);
    Clear(Velocity);
    Clear(Ducking);

    Clear(FParam1);
    Clear(FParam2);
    Clear(IParam1);
    Clear(IParam2);
    Clear(BParam1);
    Clear(BParam2);
  end;
end;

procedure Clear(var Data: TEventInfo);
begin
  with Data do
  begin
    Clear(Index);
    Clear(Packet);
    Clear(Entity);
    Clear(FireTime);
    Clear(Args);
    Clear(Flags);
  end;
end;


end.