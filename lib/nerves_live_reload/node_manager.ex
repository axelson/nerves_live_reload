defmodule NervesLiveReload.NodeManager do
  @moduledoc """
  https://medium.com/elixir-bytes/how-to-test-elixir-cluster-of-nodes-using-slaves-69e59a77ec3f

  Receives a file system path and compiles the project into a separate build directory

  Starts a peer node to compile the other project
  """

  use GenServer
  require Logger

  defmodule State do
    defstruct [:peer_node]
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def user_picked_path(pid, path) do
    GenServer.cast(pid, {:user_picked_path, path})
  end

  def run_code(pid, mod, fun, args) do
    GenServer.call(pid, {:run_code, mod, fun, args})
  end

  @impl GenServer
  def init(_) do
    start_node()
    {:ok, peer_node} = start_peer_node()
    {:ok, %State{peer_node: peer_node}}
  end

  @impl GenServer
  def handle_cast({:user_picked_path, path}, state) do
    IO.inspect(path, label: "analyze project path")
    # analyze_project(path, state)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:stdout, _os_pid, msg}, state) do
    IO.inspect(msg, label: "msg")
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.debug("Ignoring msg: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:run_code, mod, fun, args}, _from, state) do
    peer_modules()
    |> IO.inspect(label: "modules")
    |> Enum.each(fn module ->
      IEx.Helpers.nl([state.peer_node], module)
      |> IO.inspect(label: "nl")
    end)

    result = :rpc.call(state.peer_node, mod, fun, args)
    {:reply, result, state}
  end

  def analyze_project(_path, state) do
    # Compile on peer node and get output here
    # dir = Path.dirname(path)
    # IO.inspect(dir, label: "dir")

    # TODO: need to start a new peer node for each project

    peer_modules()
    |> Enum.each(fn module ->
      IEx.Helpers.nl([state.peer_node], module)
    end)

    # rpc:call(N, peer, pseudo, [node(), [pxw_server]]).
    # :rpc.call(state.peer_node, :peer, :pseudo, [node(), [GViz.RemoteCompiler]])

    # :rpc.call(state.peer_node, GViz.RemoteCompiler, :start_link, [[]])
    # :rpc.call(state.peer_node, GViz.RemoteCompiler, :test, [])

    # TODO: What actual code to call here?
    # :rpc.call(state.peer_node, GViz.Peer.Compiler, :compile_code, [])
    # |> IO.inspect(label: "called")

    # Mix.Task.clear()
    # Mix.Task.run("compile", ["--return-errors", "--ignore-module-conflict"])
    # MIX_BUILD_ROOT = "/tmp/gviz_build"

    # :exec.run_link("ls /tmp", [
    #       {:cd, dir},
    #   :stdout,
    #   :stderr,
    #   :stdin,
    #   :monitor
    # ])
    # |> IO.inspect(label: "run_link")
  end

  defp peer_modules() do
    {:ok, modules} = :application.get_key(:nerves_live_reload, :modules)

    modules
    |> Enum.filter(fn module ->
      case Module.split(module) do
        ["NervesLiveReload", "Peer" | _] -> true
        _ -> false
      end
    end)
  end

  defp start_node do
    :ok = :net_kernel.monitor_nodes(true)
    {"", 0} = System.cmd("epmd", ["-daemon"])

    # Allow spawned nodes to fetch all code from this node
    :erl_boot_server.start([])
    allow_boot(to_charlist("127.0.0.1"))

    _ = Node.start(:master@localhost, :shortnames)
  end

  defp allow_boot(host) do
    {:ok, ipv4} = :inet.parse_ipv4_address(host)
    :erl_boot_server.add_slave(ipv4)
  end

  defp start_peer_node do
    IO.puts("Starting peer node!")
    # Host, Name, Args
    {:ok, node} =
      :peer.start_link(%{
        host: :localhost,
        name: 'peer_node',
        args: peer_args()
      })

    IO.puts("DONE Starting peer node!")
    add_code_paths(node)
    transfer_configuration(node)
    ensure_applications_started(node)
    {:ok, node}
  end

  defp add_code_paths(node) do
    rpc(node, :code, :add_paths, [:code.get_path()])
  end

  defp transfer_configuration(node) do
    for {app_name, _, _} <- Application.loaded_applications() do
      for {key, val} <- Application.get_all_env(app_name) do
        rpc(node, Application, :put_env, [app_name, key, val])
      end
    end
  end

  @apps_to_start [
    # :iex,
    :logger,
    # :file_system,
    # :jason,
    :erlexec,
    :runtime_tools,
    # :inets,
    :stdlib,
    :crypto,
    # :hex,
    :elixir,
    # :public_key,
    # :gviz,
    # :mix,
    # :gettext,
    :kernel,
    :ssl,
    :compiler
    # :asn1,
  ]

  defp ensure_applications_started(node) do
    rpc(node, Application, :ensure_all_started, [:mix])
    rpc(node, Mix, :env, [Mix.env()])

    # for {app_name, _, _} <- Application.loaded_applications() do
    #   rpc(node, Application, :ensure_all_started, [app_name])
    # end
    for app_name <- @apps_to_start do
      IO.inspect(app_name, label: "starting app_name")

      rpc(node, Application, :ensure_all_started, [app_name])
      |> IO.inspect(label: "started #{inspect(app_name)}")
    end
  end

  defp rpc(node, module, function, args) do
    :rpc.block_call(node, module, function, args)
  end

  defp peer_args do
    Enum.join(
      [
        "-loader inet -hosts 127.0.0.1",
        "-setcookie #{:erlang.get_cookie()}",
        # TODO: Make this dynamic!
        "-env MIX_TARGET rpi0"
        # "-env MIX_BUILD_ROOT /tmp/gviz_build"
      ],
      " "
    )
    |> to_charlist()
  end
end
