defmodule NervesLiveReloadApplication do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Boundary, deps: [NervesLiveReloadWeb, NervesLiveReload]

  use Application

  def start(_type, _args) do
    # beam_notify_options = [name: "nerves_live_reload", dispatcher: &NervesLiveReload.Server.handle_beam_notify/2]

    children = [
      {Task.Supervisor, name: :nerves_live_reload_task_supervisor},
      {Registry, keys: :duplicate, name: :nerves_live_reload_registry},
      NervesLiveReload.Server,
      # Beamnotify has moved into ex_sync_lib
      # {BEAMNotify, beam_notify_options},
      {ExSyncLib.DynamicSupervisor, name: :exsync_lib_supervisor},
      NervesLiveReloadWeb.Telemetry,
      {Phoenix.PubSub, name: NervesLiveReload.PubSub},
      NervesLiveReloadWeb.Endpoint
    ]

    attach_telemetry()

    opts = [strategy: :one_for_one, name: NervesLiveReload.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp attach_telemetry do
    :ok =
      :telemetry.attach_many(
        "nerves-live-reload-telemetry-handler",
        # TODO: Change this
        [
          [:exsync_lib, :compile, :start],
          [:exsync_lib, :reload, :finish]
        ],
        &NervesLiveReload.TelemetryHandler.handle_event/4,
        nil
      )
  end

  def config_change(changed, _new, removed) do
    NervesLiveReloadWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
