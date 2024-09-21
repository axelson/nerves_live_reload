defmodule NervesLiveReload.ScenicReload do
  require Logger

  @view_port_supervisor_name :scenic_viewports

  def reload do
    view_port_pids()
    |> Enum.each(fn pid ->
      {:ok, view_port} = Scenic.ViewPort.info(pid)
      # WARNING: Private API
      %{scene: {scene, param}} = :sys.get_state(view_port.pid)
      Scenic.ViewPort.set_root(view_port, scene, param)
    end)
  end

  def view_port_pids do
    children = DynamicSupervisor.which_children(@view_port_supervisor_name)

    Enum.map(children, fn child ->
      {_, root_scene_pid, _, _} = child
      root_scene_pid
    end)
  end
end
