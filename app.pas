(*
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

  (c) Copyright 2003-2023 - Niels Tjornhoj-Thomsen - All Rights Reserved
*)
unit app;

// This is where the actual service implementation exists

interface

uses
  System.Classes,
  System.SysUtils,
  service;

type
  TExampleMain = class( IMainTask )
  private
    FRunning: boolean;
    FStopped: boolean;
  protected
    function GetRunning: boolean; override;
    function GetStopped: boolean; override;
    procedure SetStopped(const Value: boolean); override;
  public
    procedure Run( const AYieldCallback: TNotifyEvent ); override;
  end;

implementation

{ TExampleMain }

function TExampleMain.GetRunning: boolean;
begin
  result := FRunning;
end;

function TExampleMain.GetStopped: boolean;
begin
  result := FStopped;
end;

procedure TExampleMain.Run(const AYieldCallback: TNotifyEvent);
begin
  while ( not Stopped ) do begin
    // do some work
    // [...]
    sleep( 100 );
    // Yield every so often
    if ( assigned( AYieldCallback ) ) then begin
      AYieldCallback( self );
    end;
  end;
end;

procedure TExampleMain.SetStopped(const Value: boolean);
begin
  FStopped := Value;
end;

end.
