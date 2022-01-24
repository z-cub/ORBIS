unit UI.GUI.FormsConrol;

interface

{$IFDEF GUII}

uses
  App.Globals,
  DGUI.Form.LogIn,
  DGUI.Form.Registration,
  DGUI.Form.NewTransaction,
  DGUI.Form.Verification,
  DGUI.Form.Transactions,
  DGUI.Form.TransactionInfo,
  DGUI.Form.MyAddress,
  DGUI.ConfirmTransaction,
  DGUI.Form.Waiting,
  DGUI.Form.Resources,
  DGUI.Form.ResCryptocontainer,
  DGUI.Form.EnterCryptoKeys,
  DGUI.Form.FileCryptocontainer,
  DGUI.Form.GenCryptoKeys,

  UI.Types,
  App.IHandlerCore,
  App.Meta,
  FMX.Forms,
  System.SysUtils,
  System.Generics.Collections;

type
  TFormsControl = class
  private
    Forms: TDictionary<TDesktopForms, TForm>;
    procedure CreateForms(Args: TArray<string>);
  public
    procedure Initialize;
    procedure ShowForm(AType: byte; atgs: TArray<string>);
    constructor Create;
    destructor Destroy; override;
  end;
{$ENDIF}

implementation

{ TFormsControl }
{$IFDEF GUII}

constructor TFormsControl.Create;
begin
  Forms := TDictionary<TDesktopForms, TForm>.Create;
end;

procedure TFormsControl.CreateForms(Args: TArray<string>);
begin
  Application.CreateForm(TWaitingForm, WaitingForm);
  Application.CreateForm(TRegistrationForm, RegistrationForm);
  Application.CreateForm(TLogInForm, LogInForm);
  Application.CreateForm(TVerificationForm, VerificationForm);
  Application.CreateForm(TNewTransactionForm, NewTransactionForm);
  Application.CreateForm(TTransactionsForm, TransactionsForm);
  Application.CreateForm(TTransactionInfoForm, TransactionInfoForm);
  Application.CreateForm(TMyAddressForm, MyAddressForm);
  Application.CreateForm(TResCryptocontainerForm, ResCryptocontainerForm);
  Application.CreateForm(TFileCryptocontainerForm, FileCryptocontainerForm);
  Application.CreateForm(TEnterWords, EnterWords);
  Application.CreateForm(TConfirmTransForm, ConfirmTransForm);
  Application.CreateForm(TGenCryptoKeysForm, GenCryptoKeysForm);
  Application.CreateForm(TResourcesForm, ResourcesForm);
end;

destructor TFormsControl.Destroy;
begin
  Forms.Free;
  inherited;
end;

procedure TFormsControl.Initialize;
begin
  Application.Initialize;
  CreateForms([]);
end;

procedure TFormsControl.ShowForm(AType: byte; atgs: TArray<string>);
var
  TypeForm: TDesktopForms;
begin
  var X, Y: integer;
  X := Application.MainForm.Left;
  Y := Application.MainForm.Top;
  TypeForm := TDesktopForms(AType);
  case TypeForm of
    fRegestrattion:
      begin
        Application.MainForm.Hide;
        Application.MainForm := RegistrationForm;
        Application.MainForm.Show;
      end;
    fVerification:
      begin
        Application.MainForm.Hide;
        Application.MainForm := VerificationForm;
        VerificationForm.Password := atgs[0];
        Application.MainForm.Show;
      end;
    fLogin:
      begin
        Application.MainForm.Hide;
        Application.MainForm := LogInForm;
        Application.MainForm.Show;
      end;
    fNewTransaction:
      begin
        Application.MainForm.Hide;
        NewTransactionForm.ClearFields;
        Application.MainForm := NewTransactionForm;
        Application.MainForm.Show;
      end;
    fTransactionHistory:
      begin
        TransactionsForm.Handler := Handler;
        TransactionsForm.token := atgs[0];
        TransactionsForm.Show;
      end;
    fTransaction:
      begin
        TransactionInfoForm.SetData(atgs);
        TransactionInfoForm.Show;
      end;
    fMyAddress:
      begin
        MyAddressForm.SetData([LogInForm.WalletEdit.Text]);
        MyAddressForm.Show;
      end;
    fRestoreSelection:
      begin
        Application.MainForm.Hide;
        Application.MainForm := ResCryptocontainerForm;
        Application.MainForm.Show;
      end;
    fEnterWods:
      begin
        Application.MainForm.Hide;
        Application.MainForm := EnterWords;
        Application.MainForm.Show;
      end;
    fChooseCC:
      begin
        Application.MainForm.Hide;
        Application.MainForm := FileCryptocontainerForm;
        Application.MainForm.Show;
      end;
    fApproveTrx:
      begin
        Application.MainForm.Hide;
        ConfirmTransForm.SetData(atgs);
        Application.MainForm := ConfirmTransForm;
        Application.MainForm.Show;
      end;
    fWords:
      begin
        Application.MainForm.Hide;
        Application.MainForm := GenCryptoKeysForm;
        Application.MainForm.Show;
      end;
  end;
  Application.MainForm.Top := Y;
  Application.MainForm.Left := X;
end;
{$ENDIF}

end.
