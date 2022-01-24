unit DGUI.Form.GenCryptoKeys;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  App.Globals,
  App.Meta,
  UI.Types,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  DGUI.Form.Resources,
  UI.Animated,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.Objects,
  FMX.Layouts,
  FMX.Memo.Types,
  FMX.ScrollBox,
  FMX.Memo,
  FMX.Ani;

type
  TGenCryptoKeysForm = class(TForm)
    LogoLayout: TLayout;
    OrbisLogoPath2: TPath;
    OrbisLogoPath1: TPath;
    OrbisLogoPath3: TPath;
    HeadLabel: TLabel;
    KeysMemo: TMemo;
    EnterPassLabel: TLabel;
    LogInRectangle: TRectangle;
    LogInLabel: TLabel;
    Line: TLine;
    procedure FormCreate(Sender: TObject);
    procedure LogInRectangleClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure SetWords(AAray: TArray<string>);
  public
    procedure SetData(AAray: TArray<string>);
  end;

var
  GenCryptoKeysForm: TGenCryptoKeysForm;

implementation

{$R *.fmx}

procedure TGenCryptoKeysForm.FormCreate(Sender: TObject);
begin
  LogInRectangle.OnMouseEnter := TRectAnimations.AnimRectPurpleMouseIn;
  LogInRectangle.OnMouseLeave := TRectAnimations.AnimRectPurpleMouseOut;
end;

procedure TGenCryptoKeysForm.FormShow(Sender: TObject);
begin
  Handler.HandleGUICommand(CMD_GUI_GET_WORDS, [], SetWords);
end;

procedure TGenCryptoKeysForm.LogInRectangleClick(Sender: TObject);
begin
  AppCore.ShowForm(ord(fLogin), []);
end;

procedure TGenCryptoKeysForm.SetData(AAray: TArray<string>);
begin
end;

procedure TGenCryptoKeysForm.SetWords(AAray: TArray<string>);
begin
  KeysMemo.Lines.Clear;
  KeysMemo.Text := AAray[0];
end;

end.
