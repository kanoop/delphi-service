(*
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

  (c) Copyright 2003-2023 - Niels Tjornhoj-Thomsen - All Rights Reserved
*)
unit service;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  Vcl.SvcMgr;

const
  DEFAULT_SERVICE_NAME    = 'ExampleService';
  SERVICE_DESCRIPTION     = 'Example service. Stopping or disabling this service will prevent stuff from working.';

type
  // Main task should expose this API
  IMainTask = class
  protected
    function GetRunning: boolean; virtual; abstract;
    function GetStopped: boolean; virtual; abstract;
    procedure SetStopped(const Value: boolean); virtual; abstract;
  public
    procedure Run( const AYieldCallback: TNotifyEvent ); virtual; abstract;
    property Running: boolean read GetRunning;
    property Stopped: boolean read GetStopped write SetStopped;
  end;

  TGenericService = class( TService )
    procedure ServiceCreate( Sender: TObject );
    procedure ServiceDestroy( Sender: TObject );
    procedure ServiceStart(
      Sender: TService;
      var Started: Boolean );
    procedure ServiceStop(
      Sender: TService;
      var Stopped: Boolean );
    procedure ServiceContinue(
      Sender: TService;
      var Continued: Boolean );
    procedure ServiceAfterInstall( Sender: TService );
    procedure ServiceAfterUninstall(Sender: TService);
    procedure ServiceShutdown(Sender: TService);
  private
    { Private declarations }
    oMain: IMainTask;
    oThread: TThread;
    procedure StopService;
  public
    { Public declarations }
    constructor Create( AOwner: TComponent; const AMain: IMainTask ); reintroduce;
    function GetServiceController: TServiceController; override;
  end;

var
  GenericService: TGenericService;

implementation

{$R *.DFM}

uses
  registry;

const
  // These match numbers used in servicemsgs.rc
  RS_ENTER_RUNNING_STATE  = 1;
  RS_LEAVE_RUNNING_STATE  = 2;
  RS_EXCEPTION_THROWN     = 3;

var
  sServiceName: string;

procedure ServiceController( CtrlCode: DWord ); stdcall;
begin
  GenericService.Controller( CtrlCode );
end;

constructor TGenericService.Create(AOwner: TComponent; const AMain: IMainTask);
begin
  inherited Create( AOwner );;
  oMain := AMain;
  Name := sServiceName;
end;

function TGenericService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TGenericService.ServiceAfterInstall( Sender: TService );
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create( KEY_READ or KEY_WRITE );
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKey( '\SYSTEM\CurrentControlSet\Services\' + sServiceName, false ) then begin
      Reg.WriteString( 'Description', SERVICE_DESCRIPTION );
      // remember the instance name
      Reg.WriteString( 'ImagePath', format( '%s /n %s', [ ParamStr( 0 ), sServiceName ] ) );
      Reg.CloseKey;
    end;
    // set message resource for eventlog, from a dll called serviceres.dll
    if Reg.OpenKey( '\SYSTEM\CurrentControlSet\Services\EventLog\Application\' + sServiceName, true ) then begin
      Reg.WriteString( 'EventMessageFile', format( '%s\serviceres.dll', [ ExtractFilePath( ParamStr( 0 ) ) ] ) );
      Reg.WriteInteger( 'TypesSupported', 7 );
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

procedure TGenericService.ServiceAfterUninstall(Sender: TService);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create( KEY_READ or KEY_WRITE );
  try
    // Clean up on uninstall
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    Reg.DeleteKey( '\SYSTEM\CurrentControlSet\Services\' + sServiceName );
    Reg.DeleteKey( '\SYSTEM\CurrentControlSet\Services\EventLog\Application\' + sServiceName );
  finally
    Reg.Free;
  end;
end;

procedure TGenericService.ServiceContinue(
  Sender: TService;
  var Continued: Boolean );
begin
  // @todo: resume the main thread if you support pause/resume
  Continued := true;
end;

procedure TGenericService.ServiceCreate( Sender: TObject );
begin
  DisplayName := format( 'Example Service (%s)', [ sServiceName ] );
  AllowPause := false;
end;

procedure TGenericService.ServiceDestroy( Sender: TObject );
begin
  if ( assigned( oMain ) ) then begin
    oMain.Stopped := true;
  end;
end;

procedure TGenericService.ServiceShutdown(Sender: TService);
begin
  StopService;
end;

procedure TGenericService.ServiceStart(
  Sender: TService;
  var Started: Boolean );
begin
  // start the main thread running
  oThread := TThread.CreateAnonymousThread(
    procedure( )
    begin
      LogMessage( 'Service entering the running state', EVENTLOG_INFORMATION_TYPE, 0, RS_ENTER_RUNNING_STATE );
      try
        // The Run method returns when oMain.Stopped is set to true
        oMain.Run( nil );
      except
        on E: Exception do begin
          LogMessage( format( 'Service exception thrown: %s', [ E.Message ] ), EVENTLOG_ERROR_TYPE, 0, RS_EXCEPTION_THROWN );
        end;
      end;
      LogMessage( 'Service leaving the running state', EVENTLOG_INFORMATION_TYPE, 0, RS_LEAVE_RUNNING_STATE );
    end );
  oMain.Stopped := false;
  oThread.FreeOnTerminate := false;
  oThread.Start;
  Started := true;
end;

procedure TGenericService.ServiceStop(
  Sender: TService;
  var Stopped: Boolean );
begin
  Stopped := true;
  StopService;
end;

procedure TGenericService.StopService;
var
  iTimeout: integer;
begin
  // ask the main thread to stop
  oMain.Stopped := true;
  // and wait up to 30 seconds for it to do so
  iTimeout := 30;
  while ( ( oMain.Running ) and ( iTimeout > 0 ) ) do begin
    dec( iTimeout );
    sleep( 1000 );
    ServiceThread.ProcessRequests( false );
  end;
  FreeAndNil( oThread );
end;

initialization
  // check if a second command line parameter was given, in which case we use
  // it as the service name.  This allows multiple services to be installed using
  // non-conflicting names
  if ( ParamCount >= 2 ) then begin
    sServiceName := ParamStr( 2 );
  end else begin
    sServiceName := DEFAULT_SERVICE_NAME;
  end;
end.

