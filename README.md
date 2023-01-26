# delphi-service
Delphi Service example

# overview

This shows how to build a windows service in Delphi, with a few extras.

Debugging windows services is hard.  So instead, teh method I use is to debug in a normal application, then simply compile the service to make
use of the exact same code in a real service.

# how to

Implement the service function in the app.pas example file.  Then compile the testapp.dpr project and do your debugging there.

Once you've eradicated all your bugs, compile the serviceapp.drp project instead.  Then install using the normal `serviceapp /install` method and
enjoy the fruits of your labour.

The service unit also supports multiple installations of the same service, in which case you install them with `serviceapp /install instance_name`

There's a group project included to make it easy to open all projects involved.

# customization

At the top of service.pas are a set of constant strings that are used to describe the service in the service manager.  Tailor them for your service, for that professional look and feel.
