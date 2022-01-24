unit Wallet.FileHandler;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.IOUtils,
  Crypto.Data,
  App.Types,
  Wallet.Types;

type
  TWalletsFileHandler = class
  private
    StringList: TStringList;
    FFileListWallets: TextFile;
    FFileWallet: file;
    Path: string;
    procedure SaveWalletToFile(AWallet: TWallet; Password: string);
    function OpenWalletFromFile(AWalletName, Password: string): TWallet;
  public
    function TrySaveNewWallet(AWallet: TWallet; APassword: string): boolean;
    function TryOpenWallet(AWallet, Password: string): TWallet;
    function TryRecover(APathFile: string; APassword: string): boolean;
    procedure RemoveWallet(AWalletHash: string);
    constructor Create(AWallets: TStringList);
    destructor Destroy; override;
  end;

implementation

{ TWalletsFileHandler }

function TWalletsFileHandler.TrySaveNewWallet(AWallet: TWallet; APassword: string): boolean;
begin
  Result := True;
  try
    Assign(FFileListWallets, Path);
    Append(FFileListWallets);
    WriteLn(FFileListWallets, string(AWallet.GetAddress));
    Close(FFileListWallets);

    if StringList.IndexOf(string(AWallet.GetAddress)) = -1 then
    begin
      StringList.Add(AWallet.GetAddress);
      SaveWalletToFile(AWallet, APassword);
    end;
  except
    Result := False;
  end;
end;

constructor TWalletsFileHandler.Create(AWallets: TStringList);
var
  Wallet: string;
begin
  StringList := AWallets;
  Path := Paths.GetPathCryptoContainer;
  Path := TPath.Combine(Path, 'Wallets');

  Assign(FFileListWallets, Path);
  if not TFile.Exists(Path) then
    Rewrite(FFileListWallets)
  else
  begin
    Reset(FFileListWallets);
    while not eof(FFileListWallets) do
    begin
      Readln(FFileListWallets, Wallet);
      StringList.Add(Wallet);
    end;
  end;
  Close(FFileListWallets);
end;

destructor TWalletsFileHandler.Destroy;
begin
  StringList := nil;
  inherited;
end;

function TWalletsFileHandler.OpenWalletFromFile(AWalletName, Password: string): TWallet;
var
  Buf: TBytes;
  Wallet: TWallet;
begin
  try
    var
    Path := TPath.Combine(Paths.GetPathCryptoContainer, AWalletName);
    AssignFile(FFileWallet, Path);
    Reset(FFileWallet, 1);
    Seek(FFileWallet, 0);
    SetLength(Buf, FileSize(FFileWallet));
    BlockRead(FFileWallet, Buf[0], FileSize(FFileWallet) - 1);
    Close(FFileWallet);
    Buf := DecryptData(Buf, Password);
    Wallet := Buf;
    if Wallet.GetAddress = AWalletName then
      Result := Wallet
    else
      Result := Default (TWallet);
  except
    Result := Default (TWallet);
  end;
end;

procedure TWalletsFileHandler.RemoveWallet(AWalletHash: string);
begin
  if TFile.Exists(TPath.Combine(Paths.GetPathCryptoContainer, AWalletHash)) then
    TFile.Delete(TPath.Combine(Paths.GetPathCryptoContainer, AWalletHash));
end;

procedure TWalletsFileHandler.SaveWalletToFile(AWallet: TWallet; Password: string);
var
  Buf: TBytes;
  addr: string;
  fileName: string;
begin
  addr := AWallet.GetAddress;
  Buf := EncryptData(AWallet, Password);
  fileName := TPath.Combine(Paths.GetPathCryptoContainer, addr);
  AssignFile(FFileWallet, fileName);
  Rewrite(FFileWallet, 1);
  Seek(FFileWallet, 0);
  BlockWrite(FFileWallet, Buf[0], Length(Buf));
  Close(FFileWallet);
end;

function TWalletsFileHandler.TryOpenWallet(AWallet, Password: string): TWallet;
begin
  try
    Result := OpenWalletFromFile(AWallet, Password);
  except
    Result := Default (TWallet);
  end;
end;

function TWalletsFileHandler.TryRecover(APathFile, APassword: string): boolean;
var
  Buf: TBytes;
  Wallet: TWallet;
begin
  try
    var
    Path := APathFile;
    AssignFile(FFileWallet, Path);
    Reset(FFileWallet, 1);
    Seek(FFileWallet, 0);
    SetLength(Buf, FileSize(FFileWallet));
    BlockRead(FFileWallet, Buf[0], FileSize(FFileWallet) - 1);
    Close(FFileWallet);
    Buf := DecryptData(Buf, APassword);
    Wallet := Buf;

    Result := TrySaveNewWallet(Wallet, APassword);
  except
    Result := False;
  end;
end;

end.
