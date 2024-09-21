defmodule NervesLiveReload.RunSrcDirs do
  @moduledoc """
  Runs the code in NervesLiveReload.SrcDirs via the shell

  This is because we want to run it in a separate BEAM instance
  """

  def run(mixfile_path) do
    # Get src directories to watch
    get_src_beam_directories(mixfile_path)

    # tell ExsyncLib to watch the source directories
    # TODO: This should be started under a supervision tree
    # ExSyncLib.SrcMonitor.start_link(src_dirs: src_dirs, src_extensions: [".erl", ".hrl", ".ex"])
    # src_extensions = [".erl", ".hrl", ".ex"]
    # ExSyncLib.DynamicSupervisor.start_child(:exsync_lib_supervisor, src_dirs, src_extensions)
  end

  # TODO: rename
  defp get_src_beam_directories(mixfile_path) do
    src_dirs_script_path = Path.join(__DIR__, "src_dirs.exs")

    bin_path = BEAMNotify.bin_path()

    command =
      "Code.eval_file(\"#{src_dirs_script_path}\"); NervesLiveReload.SrcDirs.run(\"#{mixfile_path}\", \"#{bin_path}\")"

    case System.cmd("elixir", ["-e", command],
           cd: Path.dirname(mixfile_path),
           # TODO: Pass appropriate MIX_TARGET in to function
           env: build_env("rpi0")
         ) do
      {_output, 0} ->
        :ok

      err ->
        raise "Unable to get src dirs due to error: #{inspect(err)}"
    end
  end

  defp build_env(mix_target) do
    beam_notify_env = Enum.to_list(BEAMNotify.env("nerves_live_reload"))

    [{"MIX_TARGET", mix_target}] ++ beam_notify_env
  end
end
