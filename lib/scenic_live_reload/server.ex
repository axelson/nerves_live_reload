# TODO: Does this actually need to be a GenServer?
# Maybe it does because of the registry
defmodule NervesLiveReload.ScenicLiveReload.Server do
  @moduledoc """
  A simple, generic code reloader for Scenic Scenes
  """
  use GenServer
  require Logger

  defmodule State do
    @moduledoc false
    defstruct [:config_key, :node]
  end

  def start_link(opts \\ [], name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl GenServer
  def init(opts) do
    Logger.debug("SceneReloader running #{inspect(self())}")
    config_key = Keyword.fetch!(opts, :config_key)
    node = Keyword.fetch!(opts, :node)

    # NervesLiveReload specific!
    {:ok, _} = Registry.register(:nerves_live_reload_registry, "scenic_live_reload", [])

    state = %State{config_key: config_key, node: node}

    {:ok, state}
  end

  def reload_current_scene(server \\ __MODULE__) do
    GenServer.call(server, :reload_current_scene)
  end

  @impl GenServer
  def handle_call(:reload_current_scene, _, state) do
    %State{config_key: config_key, node: node} = state
    Logger.info("Reloading current scene!")
    reload_current_scenes(node, config_key)

    {:reply, nil, state}
  end

  defp reload_current_scenes(node, config_key) do
    # TODO: Remove the code after?
    ExSyncLib.Utils.nl([node], NervesLiveReload.ScenicReload)
    case :rpc.call(node, NervesLiveReload.ScenicReload, :reload, [config_key]) do
      :ok -> Logger.info("Reloaded scene!")
      error -> Logger.error("Unable to reload scene due to error: #{inspect error}")
    end
  end
end
