unit Common;

interface

uses {$REGION 'Include'}
  Windows,
  Classes,
  SysUtils,
  SyncObjs,
  Math, 

  Vector,
  Shared,
  Other,
  Default;
  {$ENDREGION}

const
  VERSION = 1;

  {$REGION 'TXSystem'}
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
  {$ENDREGION}

  {$REGION 'TLogSystem'}
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
  {$ENDREGION}

{$REGION 'Strings'}
const
  SS = ' ';
  S_STRING = '%s';
  S_INTEGER = '%d';
  S_PREFIX = '[' + S_STRING + '] ';

  S_INITIALIZING_CONNECTION = 'Initializing connection to ' + S_STRING;
  S_INITIALIZING_CONNECTION_VIA = S_INITIALIZING_CONNECTION + ' via ' + S_STRING;

  S_RETRYING_CONNECTION = 'Retrying connection to ' + S_STRING + ' (' + S_INTEGER + ')';
  S_RETRYING_CONNECTION_VIA = S_RETRYING_CONNECTION + ' via ' + S_STRING;

  S_CANNOT_CONNECT = 'Cannot connect to ' + S_STRING;
  S_CANNOT_CONNECT_VIA = S_CANNOT_CONNECT + ' via ' + S_STRING;

  S_BADADDR = 'Bad server addres "' + S_STRING + '"';

  S_ENGINE_MESSAGE_ILLEGAL = 'Illegal Engine Message ' + S_INTEGER;
  S_GAME_EVENT_ILLEGAL = 'Illegal Game Event ' + S_INTEGER;
  S_DIRECTOR_CMD_ILLEGAL = 'Illegal Director Command ' + S_INTEGER;
  S_GAME_EVENT_TOO_BIG = 'Game Event ' + S_STRING + ' sent too much data (%i bytes), %i bytes max.';
  S_LAST_MESSAGES = 'Last Parsed Messages';

  S_BAD_CHALLENGE = 'Bad challenge.';
  S_BAD_RCON_NO_RCON = 'Bad rcon_password.' + #$0A + 'No password set for this server.';
  S_BAD_RCON = 'Bad rcon_password.';

  S_SLOTS_ARE_FULL = S_PREFIX + 'Slots are full.';

  S_CANT_READ_PROTOCOL = 'Can''t read protocol version.';
  S_BAD_PASSWORD_RESPONSE = 'Invalid server password.';

  S_INVALID_PROTINFO = 'Invalid ProtInfo in connect command.';
  S_INVALID_USERINFO = 'Invalid UserInfo in connect command.';

  S_CLIENT_SENT_DROP = 'Client sent ''drop''';
  S_CLIENT_SENT_RECONNECT = 'Client sent ''reconnect''';

  S_NO_ACTIVE_TUNNELS = 'No active tunnels opened';

  S_FULL_STACK = 'Full Stack';
  S_OVERFLOW = 'Overflow';

  S_INFO_COLOR_NORMAL = #1;
  S_INFO_COLOR_GREEN = #4;
  S_INFO_COLOR_TEAM = #3;
  S_INFO_GREEN_STRING = S_INFO_COLOR_GREEN + S_STRING + S_INFO_COLOR_NORMAL;

  S_HTML_COLOR_GREEN = '<FONT Color=Lime>';
  S_HTML_COLOR_END = '</FONT>';
  S_HTML_GREEN_STRING = S_HTML_COLOR_GREEN + S_STRING + S_HTML_COLOR_END;
  S_HTML_LINEBREAK = '<BR>';

{$ENDREGION}

implementation

{$REGION 'TXSystem'}
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
{$ENDREGION}

{$REGION 'TLogSystem'}
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
{$ENDREGION}

end.
