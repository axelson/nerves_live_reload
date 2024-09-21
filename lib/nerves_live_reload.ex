defmodule NervesLiveReload do
  @moduledoc """
  NervesLiveReload keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  use Boundary, deps: [JaxUtils], exports: [Server, TelemetryHandler]

  @doc """
  Watch an application

  ## Options

  * scenic_live_reload - Pass in the application env key where the Scenic
    viewport configuration can be looked up. Expects values with format
    `{app_name, viewport_config_key}` (e.g. `{:my_app, :viewport}`). These
    values will be passed to `Application.get_key/2` to fetch the viewport
    configuration. Defaults to `false` which will not add the special code to
    reload scenic applications.
  """
  def watch_application(mixfile_path, mix_target, opts \\ []) do
    node = Keyword.fetch!(opts, :node)
    scenic_live_reload_config_key = Keyword.get(opts, :scenic_live_reload, false)

    ensure_connected_to_node(node)

    mixfile_dir = Path.dirname(mixfile_path)

    build_path = Path.join(mixfile_dir, ".nerves-live-reload/build")
    File.mkdir_p(build_path)

    other_children =
      if scenic_live_reload_config_key do
        [{NervesLiveReload.ScenicLiveReload.Server, config_key: scenic_live_reload_config_key, node: node}]
      else
        []
      end

    ExSyncLib.DynamicSupervisor.start_child(
      :exsync_lib_supervisor,
      mixfile_path,
      node,
      build_path,
      mix_target,
      other_children
    )
  end

  def reload_complete do
    require Logger
    Logger.warn("Starting to reload!")

    for {pid, _} <- scenic_live_reload_registered() do
      NervesLiveReload.ScenicLiveReload.Server.reload_current_scene(pid)
    end

    # Temp
    # for node <- Node.list() do
    #   :erpc.call(node, Inky, :set_pixels, [Inky.Foo, %{}])
    # end
  end

  def scenic_live_reload_registered do
    Registry.lookup(:nerves_live_reload_registry, "scenic_live_reload")
  end

  defp ensure_connected_to_node(node) do
    case Node.connect(node) do
      true -> :ok
      _ -> raise """
      Unable to connect/cluster to node #{node}, usually this means that the
      hostname or the cookie is incorrect.
      """
    end
  end
end
