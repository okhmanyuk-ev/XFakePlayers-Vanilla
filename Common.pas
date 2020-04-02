unit Common;

interface

uses
  Windows,
  Classes,
  SysUtils,
  SyncObjs,
  Math,

  Vector,
  Shared,
  Other,
  Default;

const
  VERSION = 1;

type
  TOnEString = procedure(Sender: TObject; Data: LStr) of object;
  TOnEInt = procedure(Sender: TObject; Data: Int) of object;

type
  TXSystem = class(TObject)
  private
    FTitle: LStr;
    FOnError: TOnTitleData;
  protected
    procedure SetTitle(Title: LStr);
    procedure Error(Title: LStr; Data: array of const);
  public
    property OnError: TOnTitleData read FOnError write FOnError;
  end;

type
  TLogSystem = class
  private
    FOnLog: TOnEString;

    FLogFile: Boolean;
    FFileName: LStr;
    FFolderName: LStr;

    FFile: TextFile;
  public
    procedure Add(const Data: LStr; ATime: Boolean = True; AFile: Boolean = True; Releasing: Boolean = True); overload;
    procedure Add(Data: array of const; ATime: Boolean = True; AFile: Boolean = True; Releasing: Boolean = True); overload;
    procedure Add; overload;

    destructor Destroy; override;
    procedure SetFileName(AFolderName, AFileName: LStr);

    property OnLog: TOnEString read FOnLog write FOnLog;
  end;

implementation

procedure TXSystem.Error(Title: LStr; Data: array of const);
var
  S: LStr;
begin
  StringFromVarRec(Data, S);

  if Assigned(OnError) then
    if (Length(FTitle) > 0) and not (FTitle = Title) then
      OnError(Self, ClassName + '.' + FTitle + '.' + Title, S)
    else
      OnError(Self, ClassName + '.' + Title, S);
end;

procedure TXSystem.SetTitle(Title: LStr);
begin
  FTitle := Title;
end;

destructor TLogSystem.Destroy;
begin
  if FLogFile then
    CloseFile(FFile);

  inherited;
end;

procedure TLogSystem.Add(const Data: LStr; ATime: Boolean = True; AFile: Boolean = True; Releasing: Boolean = True);
var
  S, S2: LStr;
label L1;
  procedure Release(SData: LStr);
  begin
    SData := RemoveTBytes(SData);

    if Length(SData) = 0 then
      Exit;

    if ATime then
      SData := Other.GetTime + SS + '-' + SS + SData;

    if Assigned(OnLog) and Releasing then
      OnLog(Self, Trim(SData));

    if AFile then
      if FLogFile then
        try
          Writeln(FFile, SData);
        except

        end;
  end;
begin
  Clear(S);
  S := Utf8ToAnsi(Data);

  L1:
  if (Length(S) = 0) and ATime then
    Exit;

  Clear(S2);

  if Pos(LChar(10), S) > 0 then
  begin
    S2 := ReadLine(S);
    Release(S2);
    Delete(S, 1, Pos(LChar(10), S));

    goto L1;
  end
  else
  begin
    S2 := S;
    Release(S2);
  end;
end;

procedure TLogSystem.Add(Data: array of const; ATime: Boolean = True; AFile: Boolean = True; Releasing: Boolean = True);
begin
  Add(StringFromVarRec(Data), ATime, AFile);
end;

procedure TLogSystem.Add;
begin
  Add(SS, False);
end;

procedure TLogSystem.SetFileName(AFolderName, AFileName: LStr);
begin
  FLogFile := True;
  FFileName := AFileName;
  FFolderName := AFolderName;

  if not DirectoryExists(FFolderName) then
    CreateDir(FFolderName);

  if not FileExists(FFolderName + '/' + FFileName) then
    WriteFile(FFolderName + '/' + FFileName);

  AssignFile(FFile, FFolderName + '/' + FFileName);
  Append(FFile);
end;

end.
