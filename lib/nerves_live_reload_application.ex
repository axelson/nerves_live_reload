defmodule NervesLiveReloadApplication do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Boundary, deps: [NervesLiveReloadWeb]

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      NervesLiveReloadWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: NervesLiveReload.PubSub},
      # Start the Endpoint (http/https)
      NervesLiveReloadWeb.Endpoint
      # Start a worker by calling: NervesLiveReload.Worker.start_link(arg)
      # {NervesLiveReload.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NervesLiveReload.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    NervesLiveReloadWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
