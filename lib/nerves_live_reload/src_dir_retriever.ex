defmodule NervesLiveReload.Slave.SrcDirRetriever do
  def hi do
    IO.inspect(System.build_info()[:build], label: "Elixir version")
    IO.inspect(System.otp_release(), label: "Erlang version")

    self()
    |> IO.inspect(label: "self()")
    IO.inspect(Node.self(), label: "Node.self()")

    System.get_env("MIX_ARCHIVES")
    |> IO.inspect(label: "mix_archives")

    mixfile = "/home/jason/dev/scenic-side-screen/fw/mix.exs"
    # mixfile = "/home/jason/dev/forks/nerves_examples/blinky/mix.exs"
    File.cd(Path.dirname(mixfile))

    # FIXME: Private API
    Mix.start()
    # FIXME: Private API
    Mix.Local.append_archives()
    # FIXME: Private API
    Mix.Local.append_paths()

    case Mix.ProjectStack.peek() do
      %{file: ^mixfile, name: module} ->
        # FIXME: Private API
        Mix.Project.pop()
        purge_module(module)

      _ ->
        :ok
    end

    Mix.Task.clear()

    File.mkdir_p(".nerves-live-reload/build")
    Mix.ProjectStack.post_config(build_path: ".nerves-live-reload/build")

    IO.puts("Going to compile!")

    # Mix.Tasks.Deps.Compile.run(["nerves", "--include-children"])
    Code.eval_file(mixfile)

    # Do we actually need this?
    Mix.Tasks.Deps.Compile.run(["nerves", "--include-children"])

    Mix.Task.run("loadconfig")
    src_dirs()
    |> IO.inspect(label: "src_dirs")


    # case Kernel.ParallelCompiler.compile([mixfile]) do
    #   {:ok, _, warnings} ->
    #     IO.inspect(warnings, label: "warnings")
    #     Mix.Task.run("loadconfig")
    #     src_dirs()
    #     |> IO.inspect(label: "src_dirs")

    #   {:error, errors, warnings} ->
    #     IO.inspect(errors, label: "errors")
    #     IO.inspect(warnings, label: "warnings")
    #     {:error, {errors, warnings}}
    # end
  end

  def src_dirs do
    src_default_dirs()
  end

  defp src_default_dirs do
    if Mix.Project.umbrella?() do
      for %Mix.Dep{app: app, opts: opts} <- Mix.Dep.Umbrella.loaded() do
        Mix.Project.in_project(app, opts[:path], fn _ -> src_default_dirs() end)
      end
    else
      dep_paths =
        Mix.Dep.cached()
        |> Enum.filter(fn dep -> dep.opts[:path] != nil end)
        |> Enum.map(fn %Mix.Dep{app: app} = dep ->
          path = resolve_dep_path(dep)

          Mix.Project.in_project(app, path, fn _ ->
            src_default_dirs()
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
