(*
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

  (c) Copyright 2003-2023 - Niels Tjornhoj-Thomsen - All Rights Reserved
*)
program serviceapp;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.Classes,
  System.SysUtils,
  Vcl.SvcMgr,
  service,
  app;

begin
  if not Application.DelayInitialize or Application.Installing then begin
    Application.Initialize;
  end;
  Application.CreateForm(TGenericService, GenericService);
  Application.Run;
end.

