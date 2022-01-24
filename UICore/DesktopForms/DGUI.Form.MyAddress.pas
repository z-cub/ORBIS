unit DGUI.Form.MyAddress;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.Platform,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.Layouts,
  FMX.Objects,
  DGUI.Toast.Windows,
  DGUI.Form.Resources,
  UI.Animated,
  QR.Core,
  UI.GUI.Types;

type
  TMyAddressForm = class(TForm)
    MyAddressLabel: TLabel;
    AddressValueLabel: TLabel;
    CopyAddressLabel: TLabel;
    Line: TLine;
    CopyAddressLayout: TLayout;
    DownloadQRLayout: TLayout;
    DownloadQRLabel: TLabel;
    DownloadQRPath: TPath;
    DownloadQRCircle: TCircle;
    QRImage: TImage;
    SaveDialog: TSaveDialog;
    CopyAddressRectangle: TRectangle;
    procedure DownloadQRLayoutClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CopyAddressRectangleClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure DownloadQRLayoutMouseEnter(Sender: TObject);
    procedure DownloadQRLayoutMouseLeave(Sender: TObject);
  private
    QRCodeBitmap: TBitmap;
    function GetQRCodeBitMap(s: string): TBitmap;
  public
    procedure SetData(args: TArray<string>);
    procedure SetAddressValue(AAddress: String);
  end;

var
  MyAddressForm: TMyAddressForm;

implementation

{$R *.fmx}

procedure TMyAddressForm.CopyAddressRectangleClick(Sender: TObject);
var
  Service: IFMXClipBoardService;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXClipBoardService, Service) then
  begin
    Service.SetClipboard(AddressValueLabel.Text);
    ShowWinToast('����� ����������');
  end;
end;

procedure TMyAddressForm.DownloadQRLayoutClick(Sender: TObject);
begin
  SaveDialog.FileName := AddressValueLabel.Text;
  if SaveDialog.Execute then
    QRImage.Bitmap.SaveToFile(SaveDialog.FileName);
end;

procedure TMyAddressForm.DownloadQRLayoutMouseEnter(Sender: TObject);
begin
  DownloadQRCircle.Fill.Color := CLR_GRAY_SELECTED_TEXT;
  DownloadQRLabel.TextSettings.FontColor := CLR_GRAY_SELECTED_TEXT;
end;

procedure TMyAddressForm.DownloadQRLayoutMouseLeave(Sender: TObject);
begin
  DownloadQRCircle.Fill.Color := CLR_GRAY_FREE_TEXT;
  DownloadQRLabel.TextSettings.FontColor := CLR_GRAY_FREE_TEXT;
end;

procedure TMyAddressForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  QRCodeBitmap.Free;
end;

procedure TMyAddressForm.FormCreate(Sender: TObject);
begin
  CopyAddressRectangle.OnMouseEnter := TRectAnimations.AnimRectGrayMouseIn;
  CopyAddressRectangle.OnMouseLeave := TRectAnimations.AnimRectGrayMouseOut;
end;

procedure TMyAddressForm.FormShow(Sender: TObject);
begin
  QRImage.Bitmap.Assign(GetQRCodeBitMap(AddressValueLabel.Text));
end;

function TMyAddressForm.GetQRCodeBitMap(s: string): TBitmap;
var
  QRCode: TDelphiZXingQRCode;
  Row, Column: Integer;
  BitmapData: TBitmapData;
  k, h, w: Integer;
begin
  QRCodeBitmap := TBitmap.Create;
  QRCode := TDelphiZXingQRCode.Create;
  BitmapData := TBitmapData.Create(h, w, TPixelFormat.None);
  try
    QRCode.Data := s;
    QRCode.Encoding := TQRCodeEncoding(0);
    QRCode.QuietZone := StrToIntDef('4', 4);
    k := 8;
    h := QRCode.Rows * k;
    w := QRCode.Columns * k;

    QRCodeBitmap.SetSize(h, w);
    QRCodeBitmap.Map(TMapAccess.ReadWrite, BitmapData);
    for Row := 0 to h - 1 do
    begin
      for Column := 0 to w - 1 do
      begin
        if (QRCode.IsBlack[Row div k, Column div k]) then
        begin
          BitmapData.SetPixel(Column, Row, TAlphaColorRec.Black);
        end
        else
        begin
          BitmapData.SetPixel(Column, Row, TAlphaColorRec.White);
        end;
      end;
    end;
  finally
    QRCodeBitmap.UnMap(BitmapData);
    QRCode.Free;
  end;
  Result := QRCodeBitmap;
end;

procedure TMyAddressForm.SetAddressValue(AAddress: String);
begin
  AddressValueLabel.Text := AAddress;
  QRImage.Bitmap.Assign(GetQRCodeBitMap(AddressValueLabel.Text));
end;

procedure TMyAddressForm.SetData(args: TArray<string>);
begin
  AddressValueLabel.Text := args[0];
end;

end.
