unit About;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Winapi.ShellAPI,

  Default;

type
  TAboutBox = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    procedure Label2MouseEnter(Sender: TObject);
    procedure Label2MouseLeave(Sender: TObject);
    procedure Label2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutBox: TAboutBox;
  AboutBoxOfficialThreadURL: LStr;

implementation

{$R *.dfm}

procedure TAboutBox.Label2Click(Sender: TObject);
begin
  ShellExecuteA(Handle, 'open', PLChar(AboutBoxOfficialThreadURL), nil, nil, SW_NORMAL);
end;

procedure TAboutBox.Label2MouseEnter(Sender: TObject);
begin
  Label2.Font.Color := clRed;
end;

procedure TAboutBox.Label2MouseLeave(Sender: TObject);
begin
  Label2.Font.Color := clYellow;
end;

end.
