unit DGUI.ConfirmTransaction;

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
  UI.Animated,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.Ani,
  FMX.Objects,
  UI.GUI.Types;

type
  TConfirmTransForm = class(TForm)
    MyAddressLabel: TLabel;
    ToAddressLabel: TLabel;
    AddressValueLabel: TLabel;
    AmountLabel: TLabel;
    AmountValueLabel: TLabel;
    CommissionLabel: TLabel;
    GoConfirmRectangle: TRectangle;
    GoConfirmLabel: TLabel;
    CancelRectangle: TRectangle;
    CancelLabel: TLabel;
    Line: TLine;
    ConnectionStateLabel: TLabel;
    CautionLabel: TLabel;
    procedure GoConfirmRectangleClick(Sender: TObject);
    procedure CancelRectangleClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CancelRectangleMouseEnter(Sender: TObject);
    procedure CancelRectangleMouseLeave(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    typeCoin, address, value: string;
  public
    procedure SetData(AArgs: TArray<string>);
    procedure Return(AArgs: TArray<string>);
  end;

var
  ConfirmTransForm: TConfirmTransForm;

implementation

{$R *.fmx}

procedure TConfirmTransForm.CancelRectangleMouseEnter(Sender: TObject);
begin
  CancelRectangle.Fill.Color := CLR_GRAY_SELECTED_TEXT;
end;

procedure TConfirmTransForm.CancelRectangleMouseLeave(Sender: TObject);
begin
  CancelRectangle.Fill.Color := CLR_GRAY_FREE_TEXT;
end;

procedure TConfirmTransForm.FormCreate(Sender: TObject);
begin
  GoConfirmRectangle.OnMouseEnter := TRectAnimations.AnimRectPurpleMouseIn;
  GoConfirmRectangle.OnMouseLeave := TRectAnimations.AnimRectPurpleMouseOut;

end;

procedure TConfirmTransForm.FormShow(Sender: TObject);
begin
  AddressValueLabel.Text := address;
  AmountValueLabel.Text := value + ' ' + typeCoin;
end;

procedure TConfirmTransForm.GoConfirmRectangleClick(Sender: TObject);
begin
  AppCore.GetHandler.HandleGUICommand(CMD_GUI_CREATE_TRANSFER, [Trim(typeCoin), address, value.Replace('.', ',')], Return);
end;

procedure TConfirmTransForm.Return(AArgs: TArray<string>);
begin
  if AArgs[0] = 'OK' then
    AppCore.ShowForm(ord(fNewTransaction), [])
  else
  begin
    ShowMessage('Sorry, your transaction was not completed, please try again later');
    AppCore.ShowForm(ord(fNewTransaction), []);
  end;

end;

procedure TConfirmTransForm.SetData(AArgs: TArray<string>);
begin
  typeCoin := AArgs[0];
  address := AArgs[1];
  value := AArgs[2];
end;

procedure TConfirmTransForm.CancelRectangleClick(Sender: TObject);
begin
  AppCore.ShowForm(ord(fNewTransaction), []);
end;

end.
