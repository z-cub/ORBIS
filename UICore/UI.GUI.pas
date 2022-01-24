unit UI.GUI;

interface

{$IFDEF GUII}

uses
  System.Threading,
  FMX.Forms,
  App.Meta,
  UI.Types,
  UI.Abstractions,
  UI.GUI.FormsConrol;

type

  TGUI = class(TBaseUI)
  private

    Controller: TFormsControl;
  public
    procedure ShutDown(const Msg: string = ''); override;
    procedure DoRun;
    procedure DoTerminate;
    procedure RunCommand(Data: TCommandData);
    constructor Create;
    destructor Destroy; override;
  end;
{$ENDIF}

implementation

{$IFDEF GUII}
{$REGION 'TGUI'}

constructor TGUI.Create;
begin
  Controller := TFormsControl.Create;
  FShowForm := Controller.ShowForm;
end;

destructor TGUI.Destroy;
begin
  Controller.Free;
  inherited;
end;

procedure TGUI.DoRun;
begin
  Controller.Initialize;
  Application.Run;
end;

procedure TGUI.DoTerminate;
begin

end;

procedure TGUI.RunCommand(Data: TCommandData);
begin

end;

procedure TGUI.ShutDown(const Msg: string);
begin
  inherited;

end;

{$ENDREGION}
{$ENDIF}

end.
