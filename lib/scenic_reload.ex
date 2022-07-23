defmodule NervesLiveReload.ScenicReload do
  require Logger

  def reload(config_key) do
    {app_name, key} = config_key
    viewport = Application.get_env(app_name, key)

    scene_pids([viewport])
    |> Enum.each(fn
      {:ok, pid} ->
        Process.exit(pid, :kill)

      _ ->
        Logger.warn("Unable to find any scene PID's to reload")
        nil
    end)

    :ok
  end

  defp scene_pids(viewports) do
    Enum.map(viewports, fn config ->
      viewport_name = config.name
      {:ok, %{root_scene_pid: root_scene_pid}} = apply(Scenic.ViewPort, :info, [viewport_name])
      {:ok, root_scene_pid}
    end)
  end
end
