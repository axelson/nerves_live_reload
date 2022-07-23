defmodule NervesLiveReload.TelemetryHandler do
  def handle_event([:exsync_lib, :compile, :start], _measurements, _metadata, _config) do
    JaxUtils.play_sound(:compilation_started)
  end

  def handle_event([:exsync_lib, :reload, :finish], _measurements, _metadata, _config) do
    JaxUtils.play_sound(:compilation_finished)
  end
end
