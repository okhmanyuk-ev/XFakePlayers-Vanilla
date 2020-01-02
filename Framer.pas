unit Framer;

interface

uses
  Windows,
  Classes,
  Thread,
  Default;

const
  DEFAULT_FRAME_DELTA = 0;

type
  TFramer = class(TThreadEx)
  strict private
    FOnFrame: TNotifyEvent;

    FActive: Boolean;

    FFrameDelta,
    FRealDelta, // reading only
    FLastFrameTime,

    FFramesCount,
    FFramesPerSecondInternal,
    FFramesPerSecond,

    FLastFramesPerSecondCheckTime: UInt;
  strict protected
    procedure Execute; override; final;

    procedure Frame; virtual;
  public
    constructor Create;

    property IsActive: Boolean read FActive;

    procedure Activate;
    procedure Deactivate;

    property FrameDelta: UInt read FFrameDelta write FFrameDelta;

    property GetRealDelta: UInt read FRealDelta;
    property GetFramesCount: UInt read FFramesCount;
    property GetFramesPerSecond: UInt read FFramesPerSecond;

    property OnFrame: TNotifyEvent read FOnFrame write FOnFrame;
  end;

implementation

procedure TFramer.Frame;
begin
  if Assigned(OnFrame) then
  begin
    Lock;
    OnFrame(Self);
    UnLock;
  end;

  FRealDelta := GetTickCount - FLastFrameTime;

  Inc(FFramesCount);
  Inc(FFramesPerSecondInternal);

  if GetTickCount - FLastFramesPerSecondCheckTime >= 1000 then
  begin
    FFramesPerSecond := FFramesPerSecondInternal;
    FFramesPerSecondInternal := 0;
    FLastFramesPerSecondCheckTime := GetTickCount;
  end;
end;

procedure TFramer.Execute;
begin
  while not Terminated do
  begin
    Sleep(1);

    if not FActive then
      Continue;

    if GetTickCount - FLastFrameTime < FFrameDelta then
      Continue;

    Frame;

    FLastFrameTime := GetTickCount;
  end;
end;

constructor TFramer.Create;
begin
  inherited Create(False);

  FFrameDelta := DEFAULT_FRAME_DELTA;

  FLastFrameTime := GetTickCount;
  FLastFramesPerSecondCheckTime := GetTickCount;
end;

procedure TFramer.Activate;
begin
  FActive := True;
end;

procedure TFramer.Deactivate;
begin
  FActive := False;
end;

end.