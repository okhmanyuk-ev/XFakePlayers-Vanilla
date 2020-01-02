unit Console;

interface

uses
  Windows,
  SysUtils,
  Shared,
  Default;

const
  CON_COLOR_RED = FOREGROUND_RED;
  CON_COLOR_GREEN = FOREGROUND_GREEN;
  CON_COLOR_BLUE = FOREGROUND_BLUE;

  CON_COLOR_EX = FOREGROUND_INTENSITY;

  CON_COLOR_RED_EX = CON_COLOR_RED or CON_COLOR_EX;
  CON_COLOR_GREEN_EX = CON_COLOR_GREEN or CON_COLOR_EX;
  CON_COLOR_BLUE_EX = CON_COLOR_BLUE or CON_COLOR_EX;

  CON_COLOR_YELLOW = CON_COLOR_GREEN or CON_COLOR_RED;
  CON_COLOR_YELLOW_EX = CON_COLOR_YELLOW or CON_COLOR_EX;

  CON_COLOR_AQUA = CON_COLOR_GREEN or CON_COLOR_BLUE or CON_COLOR_EX; 

  CON_COLOR_GRAY = CON_COLOR_RED or CON_COLOR_GREEN or CON_COLOR_BLUE;
  CON_COLOR_GRAY_EX = CON_COLOR_GRAY or CON_COLOR_EX;

  CON_COLOR_STANDART = CON_COLOR_GRAY;

function StrAnsiToOem(AData: LStr): LStr;
function GetConsoleWindow: HWND; stdcall; external kernel32;

type
  TConsole = class(TObject)
  strict protected
    InputHandle,
    OutputHandle: THandle;

    LargestConsoleWindowSize: TCoord;
    ConsoleScreenBufferInfo: TConsoleScreenBufferInfo;
    ConsoleCursorInfo: TConsoleCursorInfo;

    Finished: Boolean;
    PrintEnabled: Boolean;

    CharsWritten: UInt16;

    procedure Frame; dynamic; abstract;

    procedure Color(AColor: UInt16);

    procedure Print(AData: LStr = ''; AColor: UInt16 = CON_COLOR_STANDART); overload;
    procedure Print(AData: array of const; AColor: UInt16 = CON_COLOR_STANDART); overload;
    procedure PrintLn(AData: LStr = ''; AColor: UInt16 = CON_COLOR_STANDART); overload;
    procedure PrintLn(AData: array of const; AColor: UInt16 = CON_COLOR_STANDART); overload;

    procedure SetCursorPosition(AX, AY: UInt16);
    procedure SetCursorVisibility(IsVisible: Boolean);

    procedure Clear;
    procedure Quit;
  public
    procedure Main;

    constructor Create;
    destructor Destroy; override;
  end;

implementation

function StrAnsiToOem(AData: LStr): LStr;
begin
  if Length(AData) > 0 then
  begin
    SetLength(Result, Length(AData));
    CharToOemA(PLChar(AData), PLChar(Result));
  end
  else
    Result := '';
end;

procedure TConsole.Main;
begin
  while not Finished do
    Frame;

  Free;
end;

procedure TConsole.Color(AColor: UInt16);
begin
  SetConsoleTextAttribute(OutputHandle, AColor);
end;

procedure TConsole.Print(AData: LStr = ''; AColor: UInt16 = CON_COLOR_STANDART);
begin
  if not PrintEnabled then
    Exit;

  Color(AColor);
  Write(StrAnsiToOem(AData));
  Inc(CharsWritten, Length(AData));
end;

procedure TConsole.Print(AData: array of const; AColor: UInt16 = CON_COLOR_STANDART);
begin
  Print(StringFromVarRec(AData), AColor);
end;

procedure TConsole.PrintLn(AData: LStr = ''; AColor: UInt16 = CON_COLOR_STANDART);
begin
  if not PrintEnabled then
    Exit;

  Color(AColor);
  WriteLn(StrAnsiToOem(AData));
  CharsWritten := 0;
end;

procedure TConsole.PrintLn(AData: array of const; AColor: UInt16 = CON_COLOR_STANDART);
begin
  PrintLn(StringFromVarRec(AData), AColor);
end;

procedure TConsole.SetCursorPosition(AX, AY: UInt16);
var
  C: TCoord;
begin
  C.X := AX; C.Y := AY;
  SetConsoleCursorPosition(OutputHandle, C);
end;

procedure TConsole.SetCursorVisibility(IsVisible: Boolean);
begin
  ConsoleCursorInfo.bVisible := IsVisible;
  SetConsoleCursorInfo(OutputHandle, ConsoleCursorInfo);
end;

procedure TConsole.Clear;
var
  Coord: TCoord;
  WrittenChars: DWORD;
begin
  FillChar(Coord, SizeOf(TCoord), 0);
  FillConsoleOutputCharacter(OutputHandle,' ', ConsoleScreenBufferInfo.dwSize.X * ConsoleScreenBufferInfo.dwSize.Y, Coord, WrittenChars);
  SetConsoleCursorPosition(OutputHandle, Coord);
end;

procedure TConsole.Quit;
begin
  Finished := True;
  PrintLn('Press ''Enter'' to continue..');
end;

constructor TConsole.Create;
begin
  inherited;

  AllocConsole;

  OutputHandle := GetStdHandle(STD_OUTPUT_HANDLE);
  InputHandle := GetStdHandle(STD_INPUT_HANDLE);

  LargestConsoleWindowSize := GetLargestConsoleWindowSize(OutputHandle);
  GetConsoleScreenBufferInfo(OutputHandle, ConsoleScreenBufferInfo);
  GetConsoleCursorInfo(OutputHandle, ConsoleCursorInfo);

  Finished := False;
  SetConsoleTitle('');

  SetConsoleOutputCP(1251);
  SetConsoleCP(1251);

  PrintEnabled := True;

  if HasParam('hide') then
    ShowWindow(GetConsoleWindow, SW_HIDE);
end;

destructor TConsole.Destroy;
begin
  //

  inherited;
end;

end.