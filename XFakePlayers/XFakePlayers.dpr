program XFakePlayers;

uses
  Vcl.Forms,
  System.SysUtils,
  Main in 'Main.pas' {Engine},
  Proxy in 'Proxy.pas' {ProxyForm},
  Names in 'Names.pas' {NamesForm},
  About in '..\About.pas' {AboutBox},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TEngine, Engine);
  Application.CreateForm(TProxyForm, ProxyForm);
  Application.CreateForm(TNamesForm, NamesForm);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.Run;
end.
