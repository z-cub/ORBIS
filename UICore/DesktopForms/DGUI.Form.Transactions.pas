unit DGUI.Form.Transactions;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  App.Types,
  App.Notifyer,
  App.Globals,
  App.Meta,
  App.IHandlerCore,
  UI.Types,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.Objects,
  FMX.Layouts,
  FMX.ListBox,
  DGUI.Form.Resources;

const
  OUTGOING_TRANS_SVG = 'M41.4306983947754,2.00003004074097 L30.1243991851807,2.00003004074097 L30.1243991851807,11' +
  'L41.4306983947754,11 L41.4306983947754,2.00003004074097 Z M32.6369018554688,4.00003004074097' +
  'L38.9182014465332,4.00003004074097 L38.9182014465332,9.00002956390381 L32.6369018554688,9.00002956390381' +
  'L32.6369018554688,4.00003004074097 Z M16.305700302124,13 L16.305700302124,22 L27.6119003295898,22' +
  'L27.6119003295898,13 L16.305700302124,13 Z M25.0993995666504,20 L18.8181991577148,20 L18.8181991577148,15' +
  'L25.0993995666504,15 L25.0993995666504,20 Z M23.8432006835938,8.00002956390381 L23.8432006835938,11' +
  'L27.6119003295898,11 L27.6119003295898,8.00002956390381 L23.8432006835938,8.00002956390381 Z' +
  'M30.1243991851807,16 L33.8931999206543,16 L33.8931999206543,13 L30.1243991851807,13 L30.1243991851807,16 Z' +
  'M0.256493002176285,6.1224799156189 L11.7934999465942,3.05175999528728E-5 L11.7934999465942,3.29850006103516' +
  'L19.9463005065918,3.29850006103516 L19.9463005065918,8.94645977020264 L11.7934999465942,8.94645977020264' +
  'L11.7934999465942,12.2448997497559 L0.256493002176285,6.1224799156189 Z';

type
  TTransHistory = record
    Date, Address, Address2, Token, Volume, Hash: string;
  end;

  TTransactionsForm = class(TForm)
    TransactionsLabel: TLabel;
    Line: TLine;
    TransactionsListBox: TListBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure OnApplyStyleTransItem(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    History: TArray<TTransHistory>;
    procedure SetTransfers(args: TArray<string>);
    procedure AcceptCC;
    procedure ItemOnCLick(Sender: TObject);
  public
    Address: string;
    Token: string;
    Handler: IBaseHandler;
    procedure AddTransaction(ADate, AAddress, Address2, AToken, AVolume, AHash: string);
  end;

var
  TransactionsForm: TTransactionsForm;

implementation

{$R *.fmx}

procedure TTransactionsForm.AcceptCC;
begin
  if Self.Visible then
  begin
    Handler.HandleGUICommand(CMD_GUI_TRANSACTION_HISTORY, [Token], SetTransfers);
  end;
end;

procedure TTransactionsForm.AddTransaction(ADate, AAddress, Address2, AToken, AVolume, AHash: string);
var
  Item: TListBoxItem;
  TH: TTransHistory;
  Txt: TText;
  FS: TFormatSettings;
begin
  FS.DateSeparator := '.';
  FS.TimeSeparator := ':';
  FS.ShortDateFormat := 'dd.mm.yy/hh:mm:ss';

  TH.Date := ADate;
  TH.Address := AAddress;
  TH.Address2 := Address2;
  TH.Token := AToken;
  TH.Volume := AVolume;
  TH.Hash := AHash;
  History := History + [TH];

  Item := TListBoxItem.Create(TransactionsListBox);
  with Item do
  begin
    Name := 'ListItem' + TransactionsListBox.Items.Count.ToString;
    StyleLookup := 'TransInfoListBoxItemStyle';
    Item.Tag := TransactionsListBox.Items.Count;
    Item.Height := TransactionsListBox.ItemHeight;

    OnApplyStyleLookup := OnApplyStyleTransItem;
    StyledSettings := [TStyledSetting.Family, TStyledSetting.Size, TStyledSetting.Style, TStyledSetting.FontColor,
    TStyledSetting.Other];
    TextSettings.FontColor := $FF525A64;

    TransactionsListBox.AddObject(Item);
    Item.NeedStyleLookup;
    Item.ApplyStyleLookup;
    OnClick := ItemOnCLick;
  end;
end;

procedure TTransactionsForm.OnApplyStyleTransItem(Sender: TObject);
var
  Item: TListBoxItem;
  TH: TTransHistory;
  Txt: TText;
begin
  Item := Sender as TListBoxItem;
  TH := History[Item.Tag];

  TLabel(Item.FindStyleResource('DateTimeLabel')).Text := TH.Date;
  Item.Text := TH.Address;
  Txt := TText(Item.FindStyleResource('VolumeText'));
  if (TH.Volume.ToExtended > 0) then
    Txt.Text := '+' + TH.Volume.Replace(',', '.') + ' ' + TH.Token
  else
    Txt.Text := TH.Volume.Replace(',', '.') + ' ' + TH.Token;
  if (TH.Volume.ToExtended < 0) then
  begin

    TPath(Item.FindStyleResource('ImagePath')).Data.Data := OUTGOING_TRANS_SVG;
    TPath(Item.FindStyleResource('ImagePath')).Fill.Color := $FFEB5E6C;
    TText(Item.FindStyleResource('VolumeText')).TextSettings.FontColor := $FFEB5E6C;
  end;
end;

procedure TTransactionsForm.SetTransfers(args: TArray<string>);
var
  Counter: integer;
begin
  History := [];
  TransactionsListBox.Clear;
  if Length(args) = 0 then
    exit;

  Counter := Length(args) - 1;
  while Counter >= 0 do
  begin
    var
    Hash := args[Counter];
    dec(Counter);
    var
    UnixTime := args[Counter];
    dec(Counter);
    var
    Token := args[Counter];
    dec(Counter);
    var
    Amount := args[Counter];
    dec(Counter);
    var
    DirectTo := args[Counter];
    dec(Counter);
    var
    DirectFrom := args[Counter];
    dec(Counter);
    if StrToFloat(Amount) > 0 then
      AddTransaction(UnixTime, DirectFrom, DirectTo, Token, Amount, Hash)
    else
      AddTransaction(UnixTime, DirectTo, DirectFrom, Token, Amount, Hash);

  end;
end;

procedure TTransactionsForm.FormCreate(Sender: TObject);
begin
  Notifyer.Subscribe(AcceptCC, nOnAcceptTransfers);
  SetLength(History, 0);
end;

procedure TTransactionsForm.FormDestroy(Sender: TObject);
begin
  SetLength(History, 0);
end;

procedure TTransactionsForm.FormShow(Sender: TObject);
begin
  Handler.HandleGUICommand(CMD_GUI_TRANSACTION_HISTORY, [Token], SetTransfers);
end;

procedure TTransactionsForm.ItemOnCLick(Sender: TObject);
begin
  var
  Item := Sender as TListBoxItem;
  var
  TH := History[Item.Tag];
  AppCore.ShowForm(ord(fTransaction), [TH.Date, TH.Address, TH.Address2, TH.Token, TH.Volume, TH.Hash])
end;

end.
