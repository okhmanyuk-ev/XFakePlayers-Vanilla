unit Thread;

interface

uses
  Classes,
  Windows,
  Default;

type
  TThreadEx = class(TThread)
  strict protected
    procedure Lock;
    procedure UnLock;
  end;

var
  Critical: TRTLCriticalSection;

implementation

procedure TThreadEx.Lock;
begin
  EnterCriticalSection(Critical);
end;

procedure TThreadEx.UnLock;
begin
  LeaveCriticalSection(Critical);
end;

initialization
  InitializeCriticalSection(Critical);

finalization
  DeleteCriticalSection(Critical);
end.