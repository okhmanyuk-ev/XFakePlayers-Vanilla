unit XNativeEngine;

interface

uses
  Windows,
  SysUtils,
  Classes,

  System.Generics.Collections,
  System.Generics.Defaults,

  Framer,
  Tokenizer,
  Network,
  Shared,
  Common,
  CVar,
  Command,
  Alias,
  Default;

type
  TXNativeEngine = class(TFramer)
  strict private type
    TLaterRec = record
      Data: LStr;
      Time: Float;
    end;

    TCmdRec = record
      Data: LStr;
      IsOutside: Boolean;
    end;

  strict private
    FOnSlowFrame: TNotifyEvent;

    FOnError,
    FOnHint: TOnTitleData;
    FOnPrint: TOnEString;

    FLastSlowFameTime: UInt32;
    FCmdWait: Int32;
  strict protected
    Developer: Int32; // cvar

    CMD: TTokenizer;
    CurrentCommand: TCmdRec;
    CommandsQueue: TList<TCmdRec>;
    Laters: TList<TLaterRec>;

    procedure Error(Title: LStr; Data: array of const); overload;
    procedure Hint(Title: LStr; Data: array of const);
    procedure Print(Data: LStr); overload; virtual;
    procedure Print(Data: array of const); overload; virtual;

    procedure Error(Sender: TObject; Title, Data: LStr); overload;

    procedure ReleaseEvent(AEvent: TNotifyEvent); overload;
    procedure ReleaseEvent(AEvent: TOnEString; AData: LStr); overload;
    procedure ReleaseEvent(AEvent: TOnEInt; AData: Int); overload;
    procedure ReleaseEvent(AEvent: TOnEAdr; AAddress: TNETAdr); overload;

    procedure SlowFrame; virtual;
    procedure Frame; override;

    procedure CMD_RegisterCommands; virtual;
    procedure CMD_RegisterCVars; virtual;

    procedure CMD_ExecuteConsoleCommand(AData: LStr; AIsOutside: Boolean = True); virtual;
    function CMD_ExecuteTokenizedText: Boolean; virtual;

    function CMD_ExecuteCVar: Boolean; virtual;
    function CMD_ExecuteCommand: Boolean; virtual;
    function CMD_ExecuteAlias: Boolean; virtual;

    procedure PrintCMDUsage(const A: array of LStr);

    procedure CMD_CmdList;
    procedure CMD_CVarList;
    procedure CMD_Version; virtual;
    procedure CMD_Alias;
    procedure CMD_Echo;
    procedure CMD_Exec;
    procedure CMD_Condition;
    procedure CMD_Loop;
    procedure CMD_Later;
    procedure CMD_Alert;
    procedure CMD_Toggle;
    procedure CMD_Wait;
    procedure CMD_Help;

  public
    constructor Create;
    destructor Destroy; override;

    procedure ExecuteCommand(Data: LStr); overload; virtual;
    procedure ExecuteCommand(Data: array of const); overload; virtual;

  public
    CVars: TCVarList;
    Commands: TCommandList;
    Aliases: TAliasList;

    property OnSlowFrame: TNotifyEvent read FOnSlowFrame write FOnSlowFrame;

    property OnError: TOnTitleData read FOnError write FOnError;
    property OnHint: TOnTitleData read FOnHint write FOnHint;
    property OnPrint: TOnEString read FOnPrint write FOnPrint;
  end;

implementation

procedure TXNativeEngine.Error(Title: LStr; Data: array of const);
var
  S: LStr;
begin
  if not Assigned(OnError) then
    Exit;

  StringFromVarRec(Data, S);

  Lock;
  OnError(Self, ClassName + '.' + Title, S);
  UnLock;
end;

procedure TXNativeEngine.Hint(Title: LStr; Data: array of const);
var
  S: LStr;
begin
  if not Assigned(OnHint) then
    Exit;

  StringFromVarRec(Data, S);

  Lock;
  OnHint(Self, Title, S);
  UnLock;
end;

procedure TXNativeEngine.Print(Data: LStr);
begin
  ReleaseEvent(OnPrint, Data);
end;

procedure TXNativeEngine.Print(Data: array of const);
begin
  Print(StringFromVarRec(Data));
end;

procedure TXNativeEngine.Error(Sender: TObject; Title, Data: LStr);
begin
  Error(Title, [Data]);
end;

procedure TXNativeEngine.ReleaseEvent(AEvent: TNotifyEvent);
begin
  if not Assigned(AEvent) then
    Exit;

  Lock;
  AEvent(Self);
  UnLock;
end;

procedure TXNativeEngine.ReleaseEvent(AEvent: TOnEString; AData: LStr);
begin
  if not Assigned(AEvent) then
    Exit;

  Lock;
  AEvent(Self, AData);
  UnLock;
end;

procedure TXNativeEngine.ReleaseEvent(AEvent: TOnEInt; AData: Int);
begin
  if not Assigned(AEvent) then
    Exit;

  Lock;
  AEvent(Self, AData);
  UnLock;
end;

procedure TXNativeEngine.ReleaseEvent(AEvent: TOnEAdr; AAddress: TNETAdr);
begin
  if not Assigned(AEvent) then
    Exit;

  Lock;
  AEvent(Self, AAddress);
  UnLock;
end;

procedure TXNativeEngine.SlowFrame;
begin
  ReleaseEvent(OnSlowFrame);

  //
end;

procedure TXNativeEngine.Frame;
var
  I: Int32;
label
  L1;
begin
  inherited;

  if GetTickCount - FLastSlowFameTime >= 1000 then // slow frame
  begin
    SlowFrame;
    FLastSlowFameTime := GetTickCount;
  end;

  L1:
  for I := 0 to Laters.Count - 1 do
    if Laters[I].Time <= GetTickCount then
    begin
      ExecuteCommand(Laters[I].Data);
      Laters.Delete(I);
      goto L1;
    end;

  while (CommandsQueue.Count > 0) and (FCmdWait = 0) do
  begin
    CurrentCommand := CommandsQueue.Items[0];
    CommandsQueue.Delete(0);
    CMD.Tokenize(CurrentCommand.Data);
    CMD_ExecuteTokenizedText;
    CurrentCommand.Data := '';
  end;

  if FCmdWait > 0 then
    Dec(FCmdWait);
end;

procedure TXNativeEngine.CMD_RegisterCommands;
begin
  with Commands do
  begin
    Add('cmdlist', CMD_CmdList, 'show list of commands');
    Add('cvarlist', CMD_CVarList, 'show list of cvars');
    Add('version', CMD_Version, 'show build info');
    Add('alias', CMD_Alias, 'alias a command');
    Add('echo', CMD_Echo, 'echo text to console');
    Add('exec', CMD_Exec, 'execute script file');
    Add('if', CMD_Condition, 'condition', CMD_PROTECTED);
    Add('loop', CMD_Loop, 'cycle', CMD_PROTECTED);
    Add('later', CMD_Later, 'delayed execution', CMD_PROTECTED);
    Add('alert', CMD_Alert, 'show alert message', CMD_PROTECTED);
    Add('toggle', CMD_Toggle, 'toggles a convar on or off, or cycles through a set of values', CMD_PROTECTED);
    Add('wait', CMD_Wait, 'waiting');
    Add('help', CMD_Help, 'find help about a convar/command');
  end;
end;

procedure TXNativeEngine.CMD_RegisterCVars;
begin
  with CVars do
  begin
    Add('developer', @Developer, 0, 'Developer Level', CVAR_PRIVATE);
//    Add('sys_frame_delta', @FrameDelta, 0, 'Frame Delta', CVAR_PRIVATE)
  end;
end;

procedure TXNativeEngine.CMD_ExecuteConsoleCommand(AData: LStr; AIsOutside: Boolean = True);
var
  C: TCmdRec;
begin
  while AData <> '' do
  begin
    AData := CMD.TokenizeEx(AData);

    C.Data := RemoveTBytes(CMD.UnTokenized);

    if CurrentCommand.Data <> '' then
      C.IsOutside := CurrentCommand.IsOutside
    else
      C.IsOutside := AIsOutside;

    CommandsQueue.Add(C);
  end;
end;

function TXNativeEngine.CMD_ExecuteTokenizedText: Boolean; // xbasegameclient overrides
var
  I: Int32;
begin
  Result := True;

  if CMD.Count = 0 then
  begin
    Print([S_CMD_EMPTY_COMMAND]);
    Exit;
  end;

  if CMD_ExecuteCVar then
    Exit;

  if CMD_ExecuteCommand then
    Exit;

  if CMD_ExecuteAlias then
    Exit;

  Print([Format('Unknown command "%s"', [AnsiLowerCase(CMD.Tokens[0])])]);  // <- client not need to do this, but server need. fix it in xproxy. NAOW!
  Result := False;
end;

function TXNativeEngine.CMD_ExecuteCVar: Boolean;  // xbasegameclient overrides
var
  I: Int32;
begin
  Result := True;

  I := CVars.IndexOf(AnsiLowerCase(CMD.Tokens[0]));

  if I = -1 then
    Exit(False);

  with CVars.List[I] do
  begin
    if Flags and CVAR_HIDE > 0 then
      Exit(False); // false

    if (Flags and CVAR_PROTECTED > 0) and CurrentCommand.IsOutside then
      Exit(False); // false

    if CMD.Count < 2 then
    begin
      Print([Format(S_CMD_SENDVALUE, [Name, ToString + ' (' + Data + ')'])]);
      Exit;
    end;

    Data := CMD.Tokens[1];

    case VType of
      V_BOOL:
      begin
        if (CMD.Tokens[1] <> '0') and (CMD.Tokens[1] <> '1') then
        begin
          Print([Format(S_CMD_MUST_BE_BOOLEAN, [CMD.Tokens[1]])]);
          Exit;
        end;

        Write(Boolean(StrToInt(CMD.Tokens[1])));
      end;

      V_INT:
      begin
        if not IsNumbers(CMD.Tokens[1]) then
        begin
          Print([Format(S_CMD_MUST_BE_INTEGER, [CMD.Tokens[1]])]);
          Exit;
        end;

        Write(StrToInt(CMD.Tokens[1]));
      end;

      V_FLOAT: Write(StrToFloatDefDot(CMD.Tokens[1], 0));
      V_STR: Write(CMD.Tokens[1]);
    end;

    Print([Format(S_CMD_ACCEPTED, [Name, CMD.Tokens[1]])]);
  end;
end;

function TXNativeEngine.CMD_ExecuteCommand: Boolean;
var
  I: Int32;
begin
  Result := True;

  I := Commands.IndexOf(AnsiLowerCase(CMD.Tokens[0]));

  if I = -1 then
    Exit(False);

  if (Commands[I].Flags and CMD_PROTECTED > 0) and CurrentCommand.IsOutside then
    Exit; // true

  if Assigned(Commands[I].Callback) then
    Commands[I].Callback;
end;

function  TXNativeEngine.CMD_ExecuteAlias: Boolean;
var
  I: Int32;
begin
  Result := True;

  I := Aliases.IndexOf(AnsiLowerCase(CMD.Tokens[0]));

  if I = -1 then
    Exit(False);

  if Length(Aliases[I].Value) > 0 then
    ExecuteCommand(Aliases[I].Value);
end;

procedure TXNativeEngine.PrintCMDUsage(const A: array of LStr);
var
  S: LStr;
  I: Int;
begin
  S := 'Syntax: ' + CMD.Tokens[0];

  for I := Low(A) to High(A) do
    S := S + ' <' + A[I] + '>';

  Print([S]);
end;

procedure TXNativeEngine.CMD_CmdList;
var
  I, J: Int32;
  S, S2: LStr;
begin
  WriteLine(S, 'Commands:');

  for I := 0 to Commands.Count - 1 do
    with Commands, Commands[I] do
    begin
      if Flags and CMD_HIDE > 0 then
        Continue;

      Default.Clear(S2);

      if Flags and CMD_PROTECTED > 0 then
        if S2 = '' then
          S2 := 'protected'
        else
          S2 := S2 + ', protected';

      if Flags and CMD_ONLY_IN_GAME > 0 then
        if S2 = '' then
          S2 := 'ingame'
        else
          S2 := S2 + ', ingame';

      Inc(J);

      if Flags = 0 then
        if Description <> '' then
          WriteLine(S, '  ' + IntToStr(J) + ') ' + Name + ' - ' + Description)
        else
          WriteLine(S, '  ' + IntToStr(J) + ') ' + Name)
      else
        if Description <> '' then
          WriteLine(S, '  ' + IntToStr(J) + ') ' + Name + ' - ' + Description + ' (' +S2 + ')')
        else
          WriteLine(S, '  ' + IntToStr(J) + ') ' + Name + ' (' +S2 + ')')
    end;

  Print([S]);
end;

procedure TXNativeEngine.CMD_CVarList;
var
  I, J: Int32;
  S, S2: LStr;
begin
  Clear(J);

  WriteLine(S, 'CVars:');

  for I := 0 to CVars.Count - 1 do
    with CVars, CVars[I] do
    begin
      if Flags and CVAR_HIDE > 0 then
        Continue;

      Default.Clear(S2);

      if Flags and CVAR_PROTECTED > 0 then
        if S2 = '' then
          S2 := 'protected'
        else
          S2 := S2 + ', protected';

      if Flags and CVAR_PRIVATE > 0 then
        if S2 = '' then
          S2 := 'private'
        else
          S2 := S2 + ', private';

      if Flags and CVAR_USERINFO > 0 then
        if S2 = '' then
          S2 := 'userinfo'
        else
          S2 := S2 + ', userinfo';

      Inc(J);

      if Flags = 0 then
        if VType = V_STR then
          WriteLine(S, '  ' + IntToStr(J) + ') ' + Name + ' = "' + ToString + '"')
        else
          WriteLine(S, '  ' + IntToStr(J) + ') ' + Name + ' = ' + ToString)
      else
        if VType = V_STR then
          WriteLine(S, '  ' + IntToStr(J) + ') ' + Name + ' = "' + ToString + '" (' + S2 + ')')
        else
          WriteLine(S, '  ' + IntToStr(J) + ') ' + Name + ' = ' + ToString + ' (' + S2 + ')');
    end;

  Print([S]);
end;

procedure TXNativeEngine.CMD_Version;
var
  S: LStr;
begin
  WriteLine(S, 'Name: ' + ClassName);
  //WriteLine(S, 'Desctipion: ' + GetDescription);
  WriteLine(S, 'Version: 1');
  WriteLine(S, 'Author: ZeaL');

  Print([S]);
end;

procedure TXNativeEngine.CMD_Alias;
var
  I: Int32;
  S: LStr;
begin
  with Aliases do
    if CMD.Count > 1 then
      if CVars.IndexOf(AnsiLowerCase(CMD.Tokens[1])) <> -1 then
      begin
      //  Print([CMD.Word(2), ' already exists as cvar']);
        Exit;
      end
      else
        if Commands.IndexOf(AnsiLowerCase(CMD.Tokens[1])) <> -1 then
        begin
        //  Print([CMD.Word(2), ' already exists as command']);
          Exit;
        end
        else
          if CMD.Count > 2 then
            Add(CMD.Tokens[1], CMD.Tokens[2])
          else
            Add(CMD.Tokens[1])
    else
      if Count > 0 then
      begin
        WriteLine(S, 'Aliases: ');

        for I := 0 to Count - 1 do
          with Aliases[I] do
            WriteLine(S, '  ' + IntToStr(I + 1) + ') ' + Key + ' - ' + Value);

        Print([S]);
      end
      else
      begin
        Print(['no aliases registered.']);
        PrintCMDUsage(['name', '(cmd)']);
      end;
end;

procedure TXNativeEngine.CMD_Echo;
begin
  if CMD.Count <= 1 then
    Exit;

  ReleaseEvent(OnPrint, CMD.Tokens[1]);
end;

procedure TXNativeEngine.CMD_Exec;
var
  S: LStr;
  F: TextFile;
  I: Int32;
begin
  if CMD.Count < 2 then
  begin
    PrintCMDUsage(['filename (cfg/rc)']);
    Exit;
  end;

  if (Pos('\\', CMD.Tokens[1]) <> 0) or (Pos(':', CMD.Tokens[1]) <> 0) or (Pos('~', CMD.Tokens[1]) <> 0) or (Pos('..', CMD.Tokens[1]) <> 0) or (CMD.Tokens[1][1] = '/') or (Pos('.', CMD.Tokens[1]) = 0) then
  begin
    Print(['Invalid path (', CMD.Tokens[1], ')']);
    Exit;
  end;

  if Pos('.', ParseAfter(CMD.Tokens[1], '.', False)) > 0 then
  begin
    Print(['Invalid file name (', CMD.Tokens[1],')']);
    Exit;
  end;

  if (ExtractFileExt(CMD.Tokens[1]) <> '.cfg') and (ExtractFileExt(CMD.Tokens[1]) <> '.rc') then
  begin
    Print(['Invalid file extension (', ExtractFileExt(CMD.Tokens[1]), '), not *cfg or *rc file']);
    Exit;
  end;

  if not FileExists(CMD.Tokens[1]) then
  begin
    Print(['File not found (', CMD.Tokens[1], ')']);
    Exit;
  end;

  with TList<TCmdRec>.Create do
  begin
    for I := 0 to CommandsQueue.Count - 1 do
      Add(CommandsQueue.Items[I]);

    CommandsQueue.Clear;

    with TStringList.Create do
    begin
      LoadFromFile(CMD.Tokens[1]);

      for I := 0 to Count - 1 do
      begin
        S := Trim(Strings[I]);

        if Length(S) = 0 then
          Continue;

        if S[1] = '/' then
          Continue;

        CMD_ExecuteConsoleCommand(S);
      end;

      Free;
    end;

     for I := 0 to Count - 1 do
      CommandsQueue.Add(Items[I]);

    Free;
  end;
end;

procedure TXNativeEngine.CMD_Condition;
var
  I: Int32;
begin
  if CMD.Count < 4 then
  begin
    Print(['Syntax: ', CMD.Tokens[0], ' <cvar> <value> <then> <(else)>']);
    Exit;
  end;

  // 1 - our command, 2 - cvar, 3 - value, 4 - command, 5 - else command

  I := CVars.IndexOf(CMD.Tokens[1]);

  if I = -1 then
  begin
    Print([Format(S_CVAR_UNKNOWN_CVAR, [CMD.Tokens[1]])]);
    Exit;
  end;

  if CVars[I].ToString = CMD.Tokens[2] then
    CMD_ExecuteConsoleCommand(CMD.Tokens[3])
  else
    if CMD.Count >= 5 then // else
      CMD_ExecuteConsoleCommand(CMD.Tokens[4])

end;

procedure TXNativeEngine.CMD_Loop;
var
  Command: LStr;
  Count, I: Int32;
begin
  if CMD.Count <= 2 then
  begin
    PrintCMDUsage(['amount', 'command']);
    Exit;
  end;

  if not IsNumbers(CMD.Tokens[1]) then
  begin
    Print([Format(S_CMD_MUST_BE_INTEGER, [CMD.Tokens[1]])]);
    Exit;
  end;

  Count := StrToInt(CMD.Tokens[1]);
  Command := CMD.Tokens[2];

  for I := 0 to Count - 1 do
    CMD_ExecuteConsoleCommand(Command);
end;

procedure TXNativeEngine.CMD_Later; // 15 Aug 2014, modified 10 Aug 2015
var
  L: TLaterRec;
begin
  if CMD.Count < 3 then
  begin
    PrintCMDUsage(['second(s)', 'command']);
    Exit;
  end;

  L.Time := (StrToFloatDefDot(CMD.Tokens[1], 0) * 1000) + GetTickCount;
  L.Data := CMD.Tokens[2];

  Laters.Add(L);
end;

procedure TXNativeEngine.CMD_Alert;
begin
  if CMD.Count < 2 then
    Exit;

  TThread.CreateAnonymousThread(procedure begin Alert([CMD.Tokens[1]]) end).Start;
end;

procedure TXNativeEngine.CMD_Toggle;
var
  I, J: Int;
begin
  if CMD.Count < 2 then
  begin
    Print(['Syntax: ', CMD.Tokens[0], ' <cvar> (<value1> <value2>...<value999>)']);
    Exit;
  end;

  // 1 - our command, 2 - cvar

  I := CVars.IndexOf(CMD.Tokens[1]);

  if I = -1 then
  begin
    Print([Format(S_CVAR_UNKNOWN_CVAR, [CMD.Tokens[1]])]);
    Exit;
  end;

  if CMD.Count < 3 then // simple mode
  begin
    case CVars[I].VType of
      V_BOOL:
        if PBoolean(CVars[I].Ptr)^ then
          CMD_ExecuteConsoleCommand(CMD.Tokens[1] + ' 0')
        else
          CMD_ExecuteConsoleCommand(CMD.Tokens[1] + ' 1');
    else
      Print(['bad cvar for simple toggling']);
    end;

    Exit;
  end;

  for J := 3 to CMD.Count - 1 do
    if CVars[I].ToString = CMD.Tokens[J - 1] then
    begin
      CMD_ExecuteConsoleCommand(CMD.Tokens[1] + ' "' + CMD.Tokens[J] + '"');
      Exit;
    end;

  CMD_ExecuteConsoleCommand(CMD.Tokens[1] + ' "' + CMD.Tokens[2] + '"');
end;

procedure TXNativeEngine.CMD_Wait;
begin
  if CMD.Count > 1 then
    FCmdWait := StrToIntDef(CMD.Tokens[1], 1)
  else
    FCmdWait := 1;
end;

procedure TXNativeEngine.CMD_Help;
var
  I: Int;
begin
  if CMD.Count < 2 then
  begin
    PrintCMDUsage(['cvar/cmd']);
    Exit;
  end;

  I := CVars.IndexOf(CMD.Tokens[1]);

  if I <> -1 then
  begin
    Print('"' + CVars[I].Name + '" = "' + CVars[I].ToString + '"');

    if CVars[I].Description <> '' then
      Print(' - ' + CVars[I].Description)
    else
      Print('no description for this cvar');

    Exit;
  end;

  I := Commands.IndexOf(CMD.Tokens[1]);

  if I <> - 1 then
  begin
    Print('"' + Commands[I].Name + '"');

    if Commands[I].Description <> '' then
      Print(' - ' + Commands[I].Description)
    else
      Print('no description for this command');

    Exit;
  end;

  Print('help: no cvar or command named "' + CMD.Tokens[1] + '"');
end;

constructor TXNativeEngine.Create;
var
  I: Int32;
  S, S2: LStr;
begin
  inherited Create;

  CVars := TCVarList.Create;
  Commands := TCommandList.Create;
  Aliases := TAliasList.Create;
  CMD := TTokenizer.Create;

  CMD_RegisterCommands;
  CMD_RegisterCVars;

  Laters := TList<TLaterRec>.Create;
  CommandsQueue := TList<TCmdRec>.Create;

  FLastSlowFameTime := GetTickCount;

  //

  // read params
  for I := 1 to ParamCount do
    S := S + ParamStr(I) + ' ';

  while Pos('+', S) <> 0 do
  begin
    S2 := ParseBefore(ParseAfter(S, '+'), '+');

    if Pos('+', S) <> 0 then
      Delete(S, Pos('+', S), Length(S2) + 1);

    ExecuteCommand(S2);
  end;

  ExecuteCommand('exec autoexec.cfg');
end;

destructor TXNativeEngine.Destroy;
begin
  CVars.Free;
  Commands.Free;
  Aliases.Free;
  Laters.Free;
  CommandsQueue.Free;
  CMD.Free;

  inherited;
end;

procedure TXNativeEngine.ExecuteCommand(Data: LStr);
begin
  CMD_ExecuteConsoleCommand(Data, False);
end;

procedure TXNativeEngine.ExecuteCommand(Data: array of const);
begin
  ExecuteCommand(StringFromVarRec(Data));
end;

end.
