unit WebServer.DataControl;

interface

uses
  System.SysUtils,
  System.TypInfo,
  System.Hash,
  System.JSON,
  BlockChain.Core,
  WebServer.HTTPTypes,
  WebServer.SourceData,
  WebServer.Abstractions;

type

  TPairs = class abstract
  private
    FData: String;
    procedure Reset;
    function GetPosition(const Name: string): TPosition; virtual; abstract;
  public
    constructor Create;
    function GetKeyValue(const Key: String): String; virtual; abstract;
    property Text: String read FData write FData;
  end;

  THeaders = class(TPairs)
  private
    function GetPosition(const Name: string): TPosition; override;
  public
    constructor Create;
    function GetKeyValue(const Key: String): String; override;
    function GetKeyPos(const Name: String): Integer;
    procedure AddHeader(const Key, Value: String);
  end;

  TParams = class(TPairs)
  private
    function GetPosition(const Name: string; Pos: Integer): TPosition;
  public
    constructor Create;
    function GetKeyValue(const Key: String; Pos: Integer): String;
    function GetKeyPos(const Name: String; Pos: Integer): Integer;
    function GetArgsCount: Integer;
  end;

  ReqType = (stGet, stPost, stUnknown);

  TRequest = class
  strict private
    BlockChain: TBlockChainCore;
    StatusCode: Integer;
    ByteData: TBytes;
    StrData: String;
    Method: ReqType;
    URIPath: String;
    HTTPVer: String;
    FHeaders: THeaders;
    procedure Parse;
  public
    constructor Create(const AData: TBytes; ABlockChain: TBlockChainCore = nil);
    procedure Reset;
    property Status: Integer read StatusCode;
    property ByteRequest: TBytes read ByteData write ByteData;
    property StrRequest: String read StrData write StrData;
    property RequestType: ReqType read Method;
    property Path: String read URIPath;
    property HTTPVersion: String read HTTPVer;
    destructor Destroy; override;
  end;

  TResponse = class
  strict private
    FDataSource: IDataSource;
    BlockChain: TBlockChainCore;
    ByteData: TBytes;
    StrData: String;
    FHeaders: THeaders;
    FParams: TParams;
    procedure AddLine(Line: String);
    procedure AddWords(Words: String);
  public
    constructor Create(const Request: TRequest; ABlockChain: TBlockChainCore = nil; RealData: Boolean = True);
    procedure Reset;
    property ByteAnswer: TBytes read ByteData write ByteData;
    property StrAnswer: String read StrData write StrData;
    destructor Destroy; override;
  end;

implementation

{ TRequest }
//
constructor TRequest.Create(const AData: TBytes; ABlockChain: TBlockChainCore = nil);
begin
  BlockChain := ABlockChain;
  FHeaders := THeaders.Create();
  Reset;
  ByteData := AData;
  StrData := TEncoding.UTF8.GetString(AData);
  Parse;
end;

destructor TRequest.Destroy;
begin
  Reset;
  FHeaders.Free;
end;

procedure TRequest.Parse;
var
  RequestLine: String;
  SubStrPos: Integer;
begin
  SubStrPos := Pos(NL, StrRequest);
  if (SubStrPos = 0) then
  begin
    StatusCode := INCORRECT_REQUEST_CODE;
    exit;
  end;
  RequestLine := Copy(StrRequest, 0, SubStrPos - 1);
  StrRequest := Copy(StrRequest, SubStrPos + 2, Length(StrRequest) - SubStrPos);

  SubStrPos := Pos(NL + NL, StrRequest);
  if (SubStrPos = 0) then
  begin
    StatusCode := INCORRECT_REQUEST_CODE;
    exit;
  end;
  FHeaders.Text := Copy(StrRequest, 0, SubStrPos - 1);

  StrRequest := Copy(StrRequest, SubStrPos + 4, Length(StrRequest) - SubStrPos);

  if RequestLine.StartsWith('GET') then
    Method := stGet
  else if RequestLine.StartsWith('POST') then
    Method := stPost
  else
  begin
    StatusCode := UNKNOWN_METHOD_CODE;
    exit;
  end;


  SubStrPos := Pos('HTTP/', RequestLine);
  if (SubStrPos = 0) then
  begin
    StatusCode := INCORRECT_REQUEST_CODE;
    exit;
  end;
  HTTPVer := Copy(RequestLine, SubStrPos + 5, 3);
  if (HTTPVer <> '1.1') then
  begin
    StatusCode := UNSUPPORTED_HTTP_VERSION_CODE;
    exit;
  end;

  case Method of
    stGet:
      begin
        URIPath := Trim(Copy(RequestLine, 5, SubStrPos - 5));
      end;

    stPost:
      begin
        URIPath := Trim(Copy(RequestLine, 6, SubStrPos - 6));
      end;
  end;

  if not URIPath.StartsWith(BASE_URI) then
  begin
    StatusCode := INCORRECT_REQUEST_CODE;
    exit;
  end;


end;

procedure TRequest.Reset;
begin
  StatusCode := 0;
  SetLength(ByteData, 0);
  StrData := '';
  Method := stUnknown;
  URIPath := '';
  HTTPVer := '';
  FHeaders.Reset;
end;

{ THeaders }

procedure THeaders.AddHeader(const Key, Value: String);
begin
  FData := FData + Key + ': ' + Value + NL;
end;

function THeaders.GetKeyPos(const Name: String): Integer;
begin
  Result := (NL + FData.ToLower).IndexOf(NL + Name.ToLower + ':');
end;

constructor THeaders.Create;
begin
  inherited;
end;

function THeaders.GetPosition(const Name: string): TPosition;
var
  Pos, Len: Integer;
begin
  Pos := GetKeyPos(Name);

  Len := Pos;
  Pos := Pos + Length(Name) + 1;

  if Len <> -1 then
    Len := (FData.ToLower + NL).IndexOf(NL, Pos)
  else
    Pos := -1;

  Result.Pos := Pos;
  Result.Len := Len - Pos;
end;

function THeaders.GetKeyValue(const Key: String): String;
var
  P: TPosition;
begin
  P := GetPosition(Key);

  if P.Pos <> -1 then
    Result := Trim(Copy(FData, P.Pos + 1, P.Len))
  else
    Result := '';
end;

{ TPairs }

constructor TPairs.Create;
begin
  Reset;
end;

procedure TPairs.Reset;
begin
  Text := '';
end;

{ TResponse }

procedure TResponse.AddLine(Line: String);
begin
  Self.StrAnswer := Self.StrAnswer + NL + Line;
end;

procedure TResponse.AddWords(Words: String);
begin
  Self.StrAnswer := Self.StrAnswer + ' ' + Words;
end;

constructor TResponse.Create(const Request: TRequest; ABlockChain: TBlockChainCore = nil; RealData: Boolean = True);
var
  JSObj: TJSONObject;
  frstarg, scndarg, thrdarg, frtharg, fiftharg, sixtharg, seventharg, eightharg, nintharg: String;
  pagenum, pagesize, step: Integer;
  fee: Double;
  t1, t2: TDateTime;
  FS: TFormatSettings;
  DblValue: Double;
  Tokens: TStrings;
begin
  if RealData then
    FDataSource := TBlockChainSource.Create(ABlockChain)
  else
    FDataSource := FTestSource;
  FHeaders := THeaders.Create;
  FParams := TParams.Create;
  Reset;
  Self.StrAnswer := 'HTTP/1.1';
  case Request.Status of

    - 1, -2:
      AddWords(ERR_BAD_REQUEST);

    -3:
      AddWords(ERR_IM_A_TEAPOT);

    -4:
      AddWords(ERR_NOT_FOUND);

    0:
      AddWords(REQUEST_OK);

  end;

  Self.FHeaders.AddHeader('Content-Type', 'application/json');
  Self.AddLine(FHeaders.FData);

  if (Request.Status <> 0) then
    exit;

  try
    JSObj := TJSONObject.Create;
    try
      if (Request.Path.StartsWith('/api/address_info/')) then
      begin
        FParams.FData := Copy(Request.Path, 19, Length(Request.Path));
        if (FParams.GetArgsCount <> 3) then
          raise Exception.Create('bad arguments count');

        frstarg := FParams.GetKeyValue('id', 1);
        if (frstarg = NL) then
          raise Exception.Create('argument ''id'' is not found');

        scndarg := FParams.GetKeyValue('net', 2);
        if (scndarg = NL) then
          raise Exception.Create('argument ''net'' is not found');
        if (Ord(GetNetByStr(scndarg)) = -1) then
          raise Exception.Create('incorrect net argument value');

        thrdarg := FParams.GetKeyValue('tokens', 3);
        if (thrdarg = NL) then
          raise Exception.Create('argument ''tokens'' is not found');
        Tokens := Parse(thrdarg);
        if (Request.RequestType = stPost) and ((Length(Tokens) <> 1) or (Tokens[0] = 'all')) then
          raise Exception.Create('incorrect ''tokens'' argument value');

        JSObj.Free;
        JSObj := FDataSource.GetAccData(frstarg,scndarg,Tokens);

        if JSObj.Count = 0 then
          raise Exception.Create('wallet is not exists');
      end
      else

      if (Request.Path.StartsWith('/api/address_info_details/')) then
      begin
        FParams.FData := Copy(Request.Path, 27, Length(Request.Path));
        if (FParams.GetArgsCount <> 6) and (FParams.GetArgsCount <> 7) and
          (FParams.GetArgsCount <> 9) then
          raise Exception.Create('bad arguments count');

        frstarg := FParams.GetKeyValue('tab', 1);
        if (frstarg = NL) then
          raise Exception.Create('argument ''tab'' is not found');
        if (frstarg <> 'transactions') and (frstarg <> 'tokens') then
          raise Exception.Create('incorrect tab argument value');

        scndarg := FParams.GetKeyValue('id', 2);
        if (scndarg = NL) then
          raise Exception.Create('argument ''id'' is not found');

        thrdarg := FParams.GetKeyValue('tokens', 3);
        if (thrdarg = NL) then
          raise Exception.Create('argument ''tokens'' is not found');
        Tokens := Parse(thrdarg);

        frtharg := FParams.GetKeyValue('page', 4);
        if (frtharg = NL) then
          raise Exception.Create('argument ''page'' is not found');
        if not(TryStrToInt(frtharg, pagenum) and (pagenum > 0)) then
          raise Exception.Create('incorrect page number');

        fiftharg := FParams.GetKeyValue('pagesize', 5);
        if (fiftharg = NL) then
          raise Exception.Create('argument ''pagesize'' is not found');
        if not(TryStrToInt(fiftharg, pagesize) and (pagesize > 0)) then
          raise Exception.Create('incorrect page size number');

        sixtharg := FParams.GetKeyValue('net', 6);
        if (sixtharg = NL) then
          raise Exception.Create('argument ''net'' is not found');
        if (Ord(GetNetByStr(sixtharg)) = -1) then
          raise Exception.Create('incorrect net argument value');

        case FParams.GetArgsCount of
          6:
            begin
              JSObj.Free;
              JSObj := FDataSource.GetAccDataDetails(frstarg,scndarg,sixtharg,Tokens,pagenum,pagesize);
            end;
          7:
            begin
              seventharg := FParams.GetKeyValue('type', 7);
              if (seventharg = NL) then
                raise Exception.Create('argument ''type'' is not found');
              if not((seventharg = 'incoming') or (seventharg = 'outgoing') or (seventharg = 'all'))
              then
                raise Exception.Create('incorrect ''type'' value');

              JSObj.Free;
              JSObj := FDataSource.GetAccDataDetails(frstarg,scndarg,sixtharg,Tokens,pagenum,pagesize,
                                                   TTransType(GetEnumValue(TypeInfo(TTransType),seventharg)));
            end;
          9:
            begin
              FS.DateSeparator := '.';
              FS.TimeSeparator := ':';
              FS.ShortDateFormat := 'dd.mm.yyyy_hh:mm:ss';

              seventharg := FParams.GetKeyValue('date_from', 7);
              if (seventharg = NL) then
                raise Exception.Create('argument ''date_from'' is not found');
              if not(TryStrToDateTime(seventharg, t1, FS) and (t1 > 0)) then
                raise Exception.Create('incorrect ''date_from'' value');

              eightharg := FParams.GetKeyValue('date_to', 8);
              if (eightharg = NL) then
                raise Exception.Create('argument ''date_to'' is not found');
              if not(TryStrToDateTime(eightharg, t2, FS) and (t2 > 0) and (t1 <= t2)) then
                raise Exception.Create('incorrect ''date_to'' value');

              nintharg := FParams.GetKeyValue('type', 9);
              if (nintharg = NL) then
                raise Exception.Create('argument ''type'' is not found');
              if not((nintharg = 'incoming') or (nintharg = 'outgoing') or (nintharg = 'all')) then
                raise Exception.Create('incorrect ''type'' value');

              JSObj.Free;
              JSObj := FDataSource.GetAccDataDetails(frstarg,scndarg,sixtharg,Tokens,pagenum,pagesize,
                          TTransType(GetEnumValue(TypeInfo(TTransType),nintharg)),seventharg,eightharg);
            end
        else
          raise Exception.Create('bad arguments count');
        end;

        if JSObj.Count = 0 then
          raise Exception.Create('wallet is not exists');
      end
      else

      if (Request.Path.StartsWith('/api/address_tokens/')) then
      begin
        FParams.FData := Copy(Request.Path, 21, Length(Request.Path));
        if (FParams.GetArgsCount <> 2) then
          raise Exception.Create('bad arguments count');

        frstarg := FParams.GetKeyValue('id', 1);
        if (frstarg = NL) then
          raise Exception.Create('argument ''id'' is not found');

        scndarg := FParams.GetKeyValue('net', 2);
        if (scndarg = NL) then
          raise Exception.Create('argument ''net'' is not found');
        if (Ord(GetNetByStr(scndarg)) = -1) then
          raise Exception.Create('incorrect net argument value');

        JSObj.Free;
        JSObj := FDataSource.GetTokenListData(frstarg,scndarg);
        if JSObj.Count = 0 then
          raise Exception.Create('wallet is not exists');
      end
      else

      if (Request.Path.StartsWith('/api/general_info/')) then
      begin
        FParams.FData := Copy(Request.Path, 19, Length(Request.Path)).ToLower;
        if (FParams.GetArgsCount <> 4) and (FParams.GetArgsCount <> 5) then
          raise Exception.Create('bad arguments count');

        case FParams.GetArgsCount of
          4:
            begin
              frstarg := FParams.GetKeyValue('name', 1);
              if (frstarg = NL) then
                raise Exception.Create('argument ''name'' is not found');
              if not((frstarg = 'accounts') or (frstarg = 'transactions') or (frstarg = 'tokens'))
              then
                raise Exception.Create('incorrect name argument value');

              scndarg := FParams.GetKeyValue('pagesize', 2);
              if (scndarg = NL) then
                raise Exception.Create('argument ''pagesize'' is not found');
              if not(TryStrToInt(scndarg, pagesize) and (pagesize > 0)) then
                raise Exception.Create('incorrect page size number');

              thrdarg := FParams.GetKeyValue('page', 3);
              if (thrdarg = NL) then
                raise Exception.Create('argument ''page'' is not found');
              if not(TryStrToInt(thrdarg, pagenum) and (pagenum > 0)) then
                raise Exception.Create('incorrect page number');

              frtharg := FParams.GetKeyValue('net', 4);
              if (frtharg = NL) then
                raise Exception.Create('argument ''net'' is not found');
              if (Ord(GetNetByStr(frtharg)) = -1) then
                raise Exception.Create('incorrect net argument value');

              JSObj.Free;
              JSObj := FDataSource.GetData(frstarg,pagenum,pagesize,frtharg);
            end;
          5:
            begin
              frstarg := FParams.GetKeyValue('parent', 1);
              if (frstarg = NL) then
                raise Exception.Create('argument ''parent'' is not found');
              if not(frstarg = 'tokens') then
                raise Exception.Create('incorrect parent argument value');

              scndarg := FParams.GetKeyValue('name', 2);
              if (scndarg = NL) then
                raise Exception.Create('argument ''name'' is not found');
              if not(scndarg = 'fee') then
                raise Exception.Create('incorrect name argument value');

              thrdarg := FParams.GetKeyValue('pagesize', 3);
              if (thrdarg = NL) then
                raise Exception.Create('argument ''pagesize'' is not found');
              if not(TryStrToInt(thrdarg, pagesize) and (pagesize > 0)) then
                raise Exception.Create('incorrect page size number');

              frtharg := FParams.GetKeyValue('page', 4);
              if (frtharg = NL) then
                raise Exception.Create('argument ''page'' is not found');
              if not(TryStrToInt(frtharg, pagenum) and (pagenum > 0)) then
                raise Exception.Create('incorrect page number');

              fiftharg := FParams.GetKeyValue('net', 5);
              if (fiftharg = NL) then
                raise Exception.Create('argument ''net'' is not found');
              if (Ord(GetNetByStr(fiftharg)) = -1) then
                raise Exception.Create('incorrect net argument value');

              JSObj.Free;
              JSObj := FDataSource.GetData(scndarg,pagenum,pagesize,fiftharg);
            end;
        else
          raise Exception.Create('bad arguments count');
        end;
      end
      else

        if (Request.Path.StartsWith('/api/transaction_info/')) then
      begin
        FParams.FData := Copy(Request.Path, 23, Length(Request.Path)).ToLower;
        if (FParams.GetArgsCount <> 2) then
          raise Exception.Create('bad arguments count');

        frstarg := FParams.GetKeyValue('id', 1);
        if (frstarg = NL) then
          raise Exception.Create('argument ''id'' is not found');

        scndarg := FParams.GetKeyValue('net', 2);
        if (scndarg = NL) then
          raise Exception.Create('argument ''net'' is not found');
        if (Ord(GetNetByStr(scndarg)) = -1) then
          raise Exception.Create('incorrect net argument value');

        JSObj.Free;
        if JSObj.Count = 0 then
          raise Exception.Create('transaction is not exists');
      end
      else

        case Request.RequestType of
          stGet:
            begin
{$REGION 'Other requests'}
              if (Request.Path.StartsWith('/api/create/wallet/')) then
              begin
                FParams.FData := Copy(Request.Path, 20, Length(Request.Path)).ToLower;
                if (FParams.FData <> '') then
                  raise Exception.Create('no arguments expected');

                Randomize;
                JSObj.AddPair('pub_key', THashSHA1.GetHashString(FloatToStr(Now)));
                JSObj.AddPair('private_key',
                  THashSHA1.GetHashString(FloatToStr(Now + Random(100))));
                JSObj.AddPair('address', THashSHA1.GetHashString(FloatToStr(Now - Random(100))));
              end
              else

                if (Request.Path.StartsWith('/api/balance/')) then
              begin
                FParams.FData := Copy(Request.Path, 14, Length(Request.Path)).ToLower;
                if (FParams.GetArgsCount <> 1) then
                  raise Exception.Create('bad arguments count');

                frstarg := FParams.GetKeyValue('wallet', 1);
                if (frstarg = NL) then
                  raise Exception.Create('argument ''wallet'' is not found');

                if (Length(frstarg) <> WALLET_ADDRESS_LENGTH) then
                  raise Exception.Create('incorrect wallet address');

                Randomize;
                DblValue := (Random(999999999) + 1) * 0.00000001;
                JSObj.AddPair('wallet', frstarg);
                JSObj.AddPair('balance', FormatFloat('0.00000000', DblValue));
                JSObj.AddPair('success', TJSONBool.Create(True))
              end
              else
{$ENDREGION}
{$REGION 'Transactions requests'}
                if (Request.Path.StartsWith('/api/token_info_details/')) then
                begin
                  FParams.FData := Copy(Request.Path, 25, Length(Request.Path)).ToLower;
                  if (FParams.GetArgsCount <> 5) then
                    raise Exception.Create('bad arguments count');

                  frstarg := FParams.GetKeyValue('tab', 1);
                  if (frstarg = NL) then
                    raise Exception.Create('argument ''tab'' is not found');
                  if (frstarg <> 'transactions') and (frstarg <> 'owners') then
                    raise Exception.Create('incorrect tab argument value');

                  scndarg := FParams.GetKeyValue('name', 2);
                  if (scndarg = NL) then
                    raise Exception.Create('argument ''name'' is not found');

                  thrdarg := FParams.GetKeyValue('page', 3);
                  if (thrdarg = NL) then
                    raise Exception.Create('argument ''page'' is not found');
                  if not(TryStrToInt(thrdarg, pagenum) and (pagenum > 0)) then
                    raise Exception.Create('incorrect page number');

                  frtharg := FParams.GetKeyValue('pagesize', 4);
                  if (frtharg = NL) then
                    raise Exception.Create('argument ''pagesize'' is not found');
                  if not(TryStrToInt(frtharg, pagesize) and (pagesize > 0)) then
                    raise Exception.Create('incorrect page size number');

                  fiftharg := FParams.GetKeyValue('net', 5);
                  if (fiftharg = NL) then
                    raise Exception.Create('argument ''net'' is not found');
                  if (Ord(GetNetByStr(fiftharg)) = -1) then
                    raise Exception.Create('incorrect net argument value');

                  JSObj.Free;                                                S
                  if JSObj.Count = 0 then
                    raise Exception.Create('token is not exists');
                end

                else
{$ENDREGION}
{$REGION 'Tokens requests'}
                  if (Request.Path.StartsWith('/api/token_info/')) then
                  begin
                    FParams.FData := Copy(Request.Path, 17, Length(Request.Path)).ToLower;
                    if (FParams.GetArgsCount <> 2) then
                      raise Exception.Create('bad arguments count');

                    frstarg := FParams.GetKeyValue('name', 1);
                    if (frstarg = NL) then
                      raise Exception.Create('argument ''name'' is not found');

                    scndarg := FParams.GetKeyValue('net', 2);
                    if (scndarg = NL) then
                      raise Exception.Create('argument ''net'' is not found');
                    if (Ord(GetNetByStr(scndarg)) = -1) then
                      raise Exception.Create('incorrect net argument value');

                    JSObj.Free;
                    if JSObj.Count = 0 then
                      raise Exception.Create('token is not exists');
                  end
                  else
{$ENDREGION}
{$REGION 'Statistics requests'}
                    if (Request.Path.StartsWith('/api/statistics/')) then
                    begin
                      FParams.FData := Copy(Request.Path, 17, Length(Request.Path)).ToLower;
                      if (FParams.GetArgsCount <> 2) and (FParams.GetArgsCount <> 5) then
                        raise Exception.Create('bad arguments count');

                      frstarg := FParams.GetKeyValue('tab', 1);
                      if (frstarg = NL) then
                        raise Exception.Create('argument ''tab'' is not found');
                      if (frstarg <> 'validators') then
                        raise Exception.Create('incorrect tab argument value');

                      scndarg := FParams.GetKeyValue('net', 2);
                      if (scndarg = NL) then
                        raise Exception.Create('argument ''net'' is not found');
                      if (Ord(GetNetByStr(scndarg)) = -1) then
                        raise Exception.Create('incorrect net argument value');

                      case FParams.GetArgsCount of
                        2:
                          begin
                            JSObj.Free;
                          end;
                        5:
                          begin
                            FS.DateSeparator := '.';
                            FS.TimeSeparator := ':';
                            FS.ShortDateFormat := 'dd.mm.yyyy_hh:mm:ss';

                            thrdarg := FParams.GetKeyValue('date_from', 3);
                            if (thrdarg = NL) then
                              raise Exception.Create('argument ''date_from'' is not found');
                            if not(TryStrToDateTime(thrdarg, t1, FS) and (t1 > 0)) then
                              raise Exception.Create('incorrect ''date_from'' value');

                            frtharg := FParams.GetKeyValue('date_to', 4);
                            if (frtharg = NL) then
                              raise Exception.Create('argument ''date_to'' is not found');
                            if not(TryStrToDateTime(frtharg, t2, FS) and (t2 > 0) and (t1 <= t2))
                            then
                              raise Exception.Create('incorrect ''date_to'' value');

                            fiftharg := FParams.GetKeyValue('step', 5);
                            if (fiftharg = NL) then
                              raise Exception.Create('argument ''date_to'' is not found');
                            if not(TryStrToInt(fiftharg, step) and (step > 0)) then
                              raise Exception.Create('incorrect page size number');

                            JSObj.Free;
                          end;
                      end;
                    end
{$ENDREGION}
                    else
                      raise Exception.Create('bad request');
            end;

          stPost:
            begin
              if (Request.Path.StartsWith('/api/create/transaction/')) then
              begin
                FParams.FData := Copy(Request.Path, 25, Length(Request.Path)).ToLower;
                if (FParams.GetArgsCount <> 3) then
                  raise Exception.Create('bad arguments count');

                frstarg := FParams.GetKeyValue('from', 1);
                if (frstarg = NL) then
                  raise Exception.Create('argument ''from'' is not found');

                scndarg := FParams.GetKeyValue('to', 2);
                if (scndarg = NL) then
                  raise Exception.Create('argument ''to'' is not found');

                if (frstarg = scndarg) then
                  raise Exception.Create('identical wallets');

                thrdarg := FParams.GetKeyValue('token', 3);
                if (thrdarg = NL) then
                  raise Exception.Create('argument ''token'' is not found');

                frtharg := FParams.GetKeyValue('amount', 4);
                if (frtharg = NL) then
                  raise Exception.Create('argument ''amount'' is not found');
                if not(TryStrToFloat(frtharg, DblValue) and (DblValue > 0)) then
                  raise Exception.Create('incorrect amount');

                fiftharg := FParams.GetKeyValue('fee', 5);
                if (fiftharg = NL) then
                  raise Exception.Create('argument ''fee'' is not found');
                if not(TryStrToFloat(fiftharg, fee) and (fee > 0)) then
                  raise Exception.Create('incorrect fee value');

                JSObj.AddPair('datetime', DateTimeToStr(DblValue));
                JSObj.AddPair('block_number', TJSONNumber.Create(DblValue));
                JSObj.AddPair('to', scndarg);
                JSObj.AddPair('from', frstarg);
                JSObj.AddPair('to', scndarg);
                JSObj.AddPair('hash', frstarg);
                JSObj.AddPair('token', scndarg);
                JSObj.AddPair('sent', TJSONNumber.Create(DblValue));
                JSObj.AddPair('received', TJSONNumber.Create(DblValue));
                JSObj.AddPair('fee', TJSONNumber.Create(fee));
              end

              else
                raise Exception.Create('bad request');
            end;
        end;
    except
      on E: Exception do
      begin
        JSObj.AddPair('success', TJSONBool.Create(False));
        JSObj.AddPair('error', E.Message);
      end;
    end;
  finally
    Self.AddLine(JSObj.ToString);
    JSObj.Free;
  end;

  Self.ByteData := TEncoding.UTF8.GetBytes(Trim(Self.StrData));
end;

destructor TResponse.Destroy;
begin
  Reset;
  FHeaders.Free;
  FParams.Free;
end;

procedure TResponse.Reset;
begin
  SetLength(ByteData, 0);
  StrData := '';
  FHeaders.Reset;
  FParams.Reset;
end;

{ TParams }

constructor TParams.Create;
begin
  inherited;
end;

function TParams.GetKeyPos(const Name: String; Pos: Integer): Integer;
var
  i: Integer;
begin
  if (Pos = 1) then
  begin
    if (FData.ToLower.IndexOf('?' + Name.ToLower) = 0) then
      Result := 0
    else
      Result := -1;
  end
  else
  begin
    Result := 0;
    for i := 2 to Pos do
      Result := FData.ToLower.IndexOf('&', Result + 1);
    if (Copy(FData, Result + 2, Length(Name)) <> Name) then
      Result := -1;
  end;
end;

function TParams.GetPosition(const Name: string; Pos: Integer): TPosition;
var
  ind, Len: Integer;
begin
  ind := GetKeyPos(Name, Pos);

  Len := ind;
  ind := ind + Length(Name) + 1;

  if Len <> -1 then
  begin
    Len := FData.ToLower.IndexOf('=', ind);
    if Len <> ind then
    begin
      ind := -1;
      Len := -1;
    end
    else
    begin
      Len := FData.ToLower.IndexOf('&', Len);
      if (Len = -1) then
        Len := Length(FData.ToLower);
    end;
  end
  else
    ind := -1;

  Result.Pos := ind;
  Result.Len := Len - ind;
end;

function TParams.GetArgsCount: Integer;
var
  Pos: Integer;
begin
  Result := 0;
  if Length(FData) = 0 then
    exit;

  Pos := 1;
  if not(FData[Pos] = '?') then
    exit
  else
    Inc(Result);

  while Pos < Length(FData) do
  begin
    if (FData[Pos] = '&') then
      Inc(Result);
    Inc(Pos);
  end;
end;

function TParams.GetKeyValue(const Key: String; Pos: Integer): String;
var
  P: TPosition;
begin
  P := GetPosition(Key, Pos);

  if P.Pos <> -1 then
    Result := Trim(Copy(FData, P.Pos + 2, P.Len - 1))
  else
    Result := NL;
end;

end.
