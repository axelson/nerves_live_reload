*Warning*: This is currently more of a proof-of-concept and I'm not sure if or when I'll have the time and inclination to take it further.

The idea behind NervesLiveReload is that as you edit files in your editor on your development machine, after being compiled those files are then sent to your nerves device and "hot reloaded" there.

This works by using `:peer` to start a node on the remote machine and transfer configuration over to it.

## Current status

NervesLiveReload is isn't finished or documented. I don't currently have any plans to take it further.

## Raw WIP notes

Nerves Livebook (inky):

    iex --name "reload@192.168.1.4" --cookie nerves_livebook_cookie -S mix phx.server
    NervesLiveReload.watch_application("/home/jason/dev/inky_impression_livebook/mix.exs", "rpi0", node: :"livebook@nerves-517f.local")

Impression Dash:

    iex --name "reload@192.168.1.4" --cookie nerves_livebook_cookie -S mix phx.server
    NervesLiveReload.watch_application("/home/jason/dev/inky_impression_livebook/mix.exs", "rpi0", node: :"livebook@nerves-517f.local")

Scenic Side Screen:

``` elixir
iex --name "reload@192.168.1.4" --cookie fw_cookie -S mix phx.server
Node.connect(:"fw@192.168.1.6")
NervesLiveReload.watch_application("/home/jason/dev/scenic-side-screen/fw/mix.exs", "rpi3", node: :"fw@192.168.1.6")
NervesLiveReload.watch_application("/home/jason/dev/scenic-side-screen/fw/mix.exs", "rpi3", node: :"fw@192.168.1.6", scenic_live_reload: true)
```

Other

    recompile; NervesLiveReload.Server.run("/home/jason/dev/forks/nerves_examples/blinky/mix.exs")


TODO:
- [x] Look at LiveBook's evaluator node (via a Port) https://github.com/elixir-nx/livebook/pull/20
  - I think this approach could work quite well. Should start up one instance to fetch all the paths that need to be watched by ExSync.
  - NOTE: Ended up running an elixir script with eval instead (and beam_notify)
- [ ] Write up notes about the NervesLiveReload architecture
- [ ] When the device restarts we have to push all the modules again
- [ ] Create a GenServer to be linked to the watching of a project
- [ ] The GenServer should be the one calling:
  - [ ]`ExSyncLib.DynamicSupervisor.start_child(:exsync_lib_supervisor, src_dirs, src_extensions)`
  - [ ] Also needs to pass the beam_dirs (might need changes in ExSyncLib)
- [ ] Create a LiveView that interfaces with the watching GenServer
- [ ] Clean way to stop watching the project
- [ ] Don't hardcode method of getting mix config
- [ ] Check if phoenix views are reloaded
- [ ] Try to get PhoenixLiveReload to work?
- [ ] auto-set/detect cookie when possible
  - Read from a file like `./_build/rpi3_dev/rel/fw/releases/COOKIE` or from `mix.exs -> releases -> cookie`
  - https://hexdocs.pm/mix/Mix.Tasks.Release.html#module-options
- [ ] Fix this error on startup
  - > iex(reload@192.168.1.4)10> Couldn't watch /home/jason/dev/inky_impression_livebook/.nerves-live-reload/build/rpi0_dev/lib/scenic_widget_contrib/ebin: No such file or directory
  - Related to not using a path dep?

Error checking:
- [ ] Ensure that `nerves_bootstrap` archive is installed
- [ ] Verify that every source directory is using the same version of elixir and erlang
  - This will prevent errors like:
  ``` sh
  13:54:38.683 [error] beam/beam_load.c(1879): Error loading module telemetry:
    This BEAM file was compiled for a later version of the run-time system than 23.
    To fix this, please recompile this module with an 23 compiler.
    (Use of opcode 172; this emulator supports only up to 170.)
  ```
- [ ] Return an error when the scenic scene has a name of `:nil`

# How it Works

Built on ExSyncLib

ExSyncLib.DynamicSupervisor is used to watch the project

Uses ExSyncLib to watch the target project, when changes are detected, the files are recompiled and then Beam clustering is used to push the changed BEAM files.

# NervesLiveReload

NOTE: Umbrella projects are not supported, they may or may not work.

Contains a vendored version of [ScenicLiveReload](https://github.com/axelson/scenic_live_reload/)

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Attributions

Sounds:
- i-did-it-message-tone.mp3
  - https://notificationsounds.com/notification-sounds/i-did-it-message-tone
- eventually-590.mp3
  - https://notificationsounds.com/notification-sounds/eventually-590
