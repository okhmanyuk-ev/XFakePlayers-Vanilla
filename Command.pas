unit Command;

interface

uses
  SysUtils,
  Default,
  Common,
  System.Generics.Defaults,
  System.Generics.Collections;

const
  CMD_HIDE = 1 shl 0; // hides from user
  CMD_PROTECTED = 1 shl 1; // protected from svc_stufftext
  CMD_XPROXY_NOREMOVE = 1 shl 2;
  CMD_ONLY_IN_GAME = 1 shl 3; // cmd must be executed only in game

const
  S_CMD_UNKNOWN_COMMAND = 'Unknown command "' + S_STRING + '".';
  S_CMD_EMPTY_COMMAND = 'Empty command.';

  S_CMD_USAGE = 'Syntax: ' + S_STRING + ' <' + S_STRING + '>';
  S_CMD_USAGE2 = S_CMD_USAGE + ' <' + S_STRING + '>';
  S_CMD_USAGE3 = S_CMD_USAGE2 + ' <' + S_STRING + '>';

  S_CMD_CANNOT_CONNECTED = 'Can''t ' + S_STRING + ', not connected';

  S_CMD_SENDVALUE = S_STRING + SS + '=' + SS + '"' + S_STRING + '".' + sLineBreak;
  S_CMD_ACCEPTED = 'Accepted : ' + S_STRING + ' = "' + S_STRING + '".' + sLineBreak;
  S_CMD_MUST_BE_BOOLEAN = 'Incorrect Parameter: "' + S_STRING + '". ' + #$0A + 'Parameter must be in <0..1>.' + sLineBreak;
  S_CMD_MUST_BE_INTEGER = 'Incorrect Parameter: "' + S_STRING + '". ' + #$0A + 'Parameter must be numerical.' + sLineBreak;

type
  PCommand = ^TCommand;
  TCommand = record
    Name: LStr;
    Callback: TProcedureObj;
    Description: LStr;
    Flags: UInt32;

    class function Create(AName: LStr; ACallback: TProcedureObj; ADescription: LStr; AFlags: Int32 = 0): TCommand; static;
  end;

  TCommandComparer = class(TComparer<TCommand>)
    function Compare(const Left, Right: TCommand): Int32; override;
  end;

  TCommandList = class(TList<TCommand>)
  public
    constructor Create;

    function Add(AName: LStr; ACallback: TProcedureObj; ADescription: LStr; AFlags: Int32 = 0): Int32; overload;
    function Add(AName: LStr; ACallback: TProcedureObj; AFlags: Int32 = 0): Int32; overload;
    function Add(AName: LStr; AFlags: Int32 = 0): Int32; overload;

    function IndexOf(const AName: LStr): Int32; overload;
  end;

implementation

{$REGION 'TCVar'}
class function TCommand.Create(AName: LStr; ACallback: TProcedureObj; ADescription: LStr; AFlags: Int32 = 0): TCommand;
begin
  Result.Name := AName;
  Result.Callback := ACallback;
  Result.Description := ADescription;
  Result.Flags := AFlags;
end;
{$ENDREGION}

{$REGION 'TCommandComparer'}
function TCommandComparer.Compare(const Left, Right: TCommand): Int32;
begin
  Result := CompareStr(Left.Name, Right.Name);
end;
{$ENDREGION}

{$REGION 'TCommandList'}
constructor TCommandList.Create;
begin
  inherited Create(TCommandComparer.Create);
end;

function TCommandList.Add(AName: LStr; ACallback: TProcedureObj; ADescription: LStr; AFlags: Int32 = 0): Int32;
begin
  Result := Add(TCommand.Create(AName, ACallback, ADescription, AFlags));
end;

function TCommandList.Add(AName: LStr; ACallback: TProcedureObj; AFlags: Int32 = 0): Int32;
begin
  Result := Add(AName, ACallback, '', AFlags);
end;

function TCommandList.Add(AName: LStr; AFlags: Int32 = 0): Int32;
begin
  Result :=Add(TCommand.Create(AName, nil, '', AFlags));
  //Add(AName, nil, AFlags);
end;

function TCommandList.IndexOf(const AName: LStr): Int32;
var
  I: Int32;
begin
  for I := 0 to Count - 1 do
    if Items[I].Name = AName then
      Exit(I);

  Result := -1;
end;
{$ENDREGION}

end.