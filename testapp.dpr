(*
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

  (c) Copyright 2003-2023 - Niels Tjornhoj-Thomsen - All Rights Reserved
*)
program testapp;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.Classes,
  System.SysUtils,
  WinApi.Windows,
  service,
  app in 'app.pas';

var
  oMain: TExampleMain;

function CatchQuitSignal( ACtrlType: dword ): BOOL; stdcall;
begin
  result := false;
  try
    case ACtrlType of
    CTRL_C_EVENT:
      begin
        writeln('ctrl-c received, performing orderly shutdown');
        oMain.Stopped := true;
        // sleep up to 5 seconds waiting for things to die
        sleep( 5000 );
        // handled
        result := true
      end;
    CTRL_BREAK_EVENT:
      begin
        // handled
        result := true;
      end;
    CTRL_CLOSE_EVENT:
      begin
        writeln('window closed, performing orderly shutdown');
        oMain.Stopped := true;
        // sleep up to 5 seconds waiting for things to die
        sleep( 5000 );
        // handled
        result := true
      end;
    end;
  except
  end;
end;

begin
  try
    // Start the fake service application, passing it the main task
    oMain := TExampleMain.Create;
    try
      // set up a ctrl-c handler so we can stop the fake service
      SetConsoleCtrlHandler( @CatchQuitSignal, true );
      // run the main loop
      oMain.Run( nil );
    finally
      oMain.Free;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

