defmodule JaxUtils.SoundPlayer do
  require Logger

  defp sound_name(:default), do: "eventually-590.mp3"
  defp sound_name(:compilation_started), do: "i-did-it-message-tone.mp3"
  defp sound_name(:compilation_finished), do: "eventually-590.mp3"

  def play(name) do
    sound_path = get_sound(name) || get_sound(:default)

    Task.Supervisor.start_child(:nerves_live_reload_task_supervisor, fn ->
      cond do
        System.find_executable("mpv") -> mpv_play(sound_path)
        true -> Logger.warning("mpv not found, skipping sound playback")
      end
    end)
  end

  # Default sound is in the priv directory
  def get_sound(:default),
    do: Path.join([:code.priv_dir(:nerves_live_reload), "sounds", sound_name(:default)])

  def get_sound(name) do
    filename = sound_name(name)
    path = Path.join([sound_directory(), filename])

    if File.exists?(path) do
      path
    end
  end

  defp sound_directory do
    Application.get_env(:nerves_live_reload, :sound_directory, "priv/sounds")
  end

  defp mpv_play(sound_path) do
    MuonTrap.cmd("mpv", ["--volume=60", "--really-quiet", sound_path])
  end
end
