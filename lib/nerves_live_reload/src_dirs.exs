defmodule NervesLiveReload.SrcDirs do
  def run(mixfile_path, _beam_notify_path) do
    File.cd(Path.dirname(mixfile_path))

    # FIXME: Private API
    Mix.start()
    # FIXME: Private API
    Mix.Local.append_archives()
    # FIXME: Private API
    Mix.Local.append_paths()

    case Mix.ProjectStack.peek() do
      %{file: ^mixfile_path, name: module} ->
        # FIXME: Private API
        Mix.Project.pop()
        purge_module(module)

      _ ->
        :ok
    end

    Mix.Task.clear()

    File.mkdir_p(".nerves-live-reload/build")
    Mix.ProjectStack.post_config(build_path: ".nerves-live-reload/build")

    Code.eval_file(mixfile_path)

    src_dirs = src_dirs()
    beam_dirs = beam_dirs()

    encoded =
      [
        length(src_dirs),
        src_dirs,
        length(beam_dirs),
        beam_dirs
      ]
      |> List.flatten()
      |> inspect(limit: :infinity)

    notify(encoded)

    :ok
  end

  defp notify(data) do
    System.cmd(System.get_env("BEAM_NOTIFY"), [data])
  end

  defp src_dirs do
    if Mix.Project.umbrella?() do
      for %Mix.Dep{app: app, opts: opts} <- Mix.Dep.Umbrella.loaded() do
        Mix.Project.in_project(app, opts[:path], fn _ -> src_dirs() end)
      end
    else
      dep_paths =
        Mix.Dep.cached()
        |> Enum.filter(fn dep -> dep.opts[:path] != nil end)
        |> Enum.map(fn %Mix.Dep{app: app} = dep ->
          path = resolve_dep_path(dep)

          Mix.Project.in_project(app, path, fn _ ->
            src_dirs()
          end)
        end)

      self_paths =
        Mix.Project.config()
        |> Keyword.take([:elixirc_paths, :erlc_paths, :erlc_include_path])
        |> Keyword.values()
        |> List.flatten()
        |> Enum.map(&Path.join(app_source_dir(), &1))
        |> Enum.filter(&File.exists?/1)

      [self_paths | dep_paths]
    end
    |> List.flatten()
    |> Enum.uniq()
  end

  def beam_dirs do
    if Mix.Project.umbrella?() do
      for %Mix.Dep{app: app, opts: opts} <- Mix.Dep.Umbrella.loaded() do
        config = [
          umbrella?: true,
          app_path: opts[:build]
        ]

        Mix.Project.in_project(app, opts[:path], config, fn _ -> beam_dirs() end)
      end
    else
      dep_paths =
        Mix.Dep.cached()
        |> Enum.filter(fn dep -> dep.opts[:path] != nil end)
        |> Enum.map(fn %Mix.Dep{app: app, opts: opts} = dep ->
          config = [
            umbrella?: opts[:in_umbrella],
            app_path: opts[:build]
          ]

          path = resolve_dep_path(dep)

          Mix.Project.in_project(app, path, config, fn _ -> beam_dirs() end)
        end)

      [Mix.Project.compile_path() | dep_paths]
    end
    |> List.flatten()
    |> Enum.uniq()
  end

  # Resolve dep path (which may be a relative path)
  defp resolve_dep_path(%Mix.Dep{} = dep) do
    %Mix.Dep{from: from, opts: opts} = dep
    dep_path = opts[:path]
    dep_dir = Path.dirname(from)
    Path.expand(dep_path, dep_dir)
  end

  def app_source_dir do
    Path.dirname(Mix.ProjectStack.peek().file)
  end

  defp purge_module(module) do
    :code.purge(module)
    :code.delete(module)
  end
end
