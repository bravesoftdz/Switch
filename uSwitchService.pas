unit uSwitchService;

interface

uses
  Windows, Messages, SysUtils, Classes, SvcMgr, uPipeServer, Call_TLB;

type
  TSwitchService = class(TService)
    procedure ServiceAfterInstall(Sender: TService);
    procedure ServiceContinue(Sender: TService; var Continued: Boolean);
    procedure ServiceExecute(Sender: TService);
    procedure ServicePause(Sender: TService; var Paused: Boolean);
    procedure ServiceShutdown(Sender: TService);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
  private
    FPipeServer: TNamedPipeServer;
  public
    function GetServiceController: TServiceController; override;
  end;

var
  SwitchService: TSwitchService;

implementation

uses
  Registry, uSwitchPipeServer;

const
  // ����������Ϣ
  SVC_DESC = '���õ绰��������������񱻽��ã�����ܵ������رգ�ͬʱ�绰�����������ٱ�������';

{$R *.DFM}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  SwitchService.Controller(CtrlCode);
end;

{
******************************** TSwitchService ********************************
}
function TSwitchService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TSwitchService.ServiceAfterInstall(Sender: TService);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    with Reg do
    begin
      RootKey := HKEY_LOCAL_MACHINE;
      if OpenKey('SYSTEM\CurrentControlSet\Services\'+Self.Name, false) then
      begin
        WriteString('Description',SVC_DESC);
      end;
      CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

procedure TSwitchService.ServiceContinue(Sender: TService; var Continued:
    Boolean);
begin
  Continued := True;
end;

procedure TSwitchService.ServiceExecute(Sender: TService);
begin
  while not Terminated do
  begin
    {ÿ��ѭ���󣬱���Ҫ��������, Ȼ��������״��}
    Sleep(100);
    ServiceThread.ProcessRequests(False);
  end;
end;

procedure TSwitchService.ServicePause(Sender: TService; var Paused: Boolean);
begin
  Paused := True;
end;

procedure TSwitchService.ServiceShutdown(Sender: TService);
begin
  Status := csStopped;
end;

procedure TSwitchService.ServiceStart(Sender: TService; var Started: Boolean);
begin
  try
    FPipeServer := TSwitchPipeServer.Create('interop.switch');
    FPipeServer.Start;
    Started := True;
  except
    on E: Exception do
    begin
      Started := False;
      raise E;
    end;
  end;
end;

procedure TSwitchService.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  try
    if Assigned(FPipeServer) then
    begin
      FreeAndNil(FPipeServer);
    end;
    Stopped := True;
  except
    on E: Exception do
    begin
      Stopped := False;
      raise E;
    end;
  end;
end;

end.
