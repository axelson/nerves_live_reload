defmodule NervesLiveReload.Server do
  @moduledoc """
  Server global GenServer that is responsible for receiving the BEAMNotify output
  """
  use GenServer
  require Logger
  alias NervesLiveReload.RunSrcDirs

  defstruct [:respond_to, :timeout_ref]
  alias __MODULE__, as: State

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def run(mixfile_path) do
    GenServer.call(__MODULE__, {:run, mixfile_path}, :infinity)
  end

  def handle_beam_notify(encoded, _) do
    GenServer.call(__MODULE__, {:handle_beam_notify, encoded})
  end

  @impl GenServer
  def init(_opts) do
    {:ok, %State{}}
  end

  @impl GenServer
  def handle_call({:run, _mixfile_path}, _from, %State{respond_to: respond_to} = state)
      when not is_nil(respond_to) do
    {:reply, {:error, :request_already_pending}, state}
  end

  def handle_call({:run, mixfile_path}, from, state) do
    :ok = RunSrcDirs.run(mixfile_path)

    # Send ourselves a message to timeout this request
    timeout_ref = Process.send_after(self(), :timeout_notify, 10_000)

    state = %State{state | respond_to: from, timeout_ref: timeout_ref}
    {:noreply, state}
  end

  # NOTE: This won't be processed before :run finishes because at the earliest
  # it will be queued while run is running
  def handle_call({:handle_beam_notify, encoded}, _from, state) do
    %State{respond_to: respond_to, timeout_ref: timeout_ref} = state

    Process.cancel_timer(timeout_ref)
    {src_dirs, beam_dirs} = parse_src_beam_dirs(encoded)

    if respond_to do
      # This is the common case since the notification is usually
      # received while running the script
      GenServer.reply(respond_to, {:ok, src_dirs, beam_dirs})
    end

    state = %State{state | respond_to: nil, timeout_ref: nil}

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_cast(msg, state) do
    Logger.warn("Unexpected handle_cast: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:timeout_ref, state) do
    %State{respond_to: respond_to} = state

    if respond_to do
      GenServer.reply(respond_to, {:error, :timeout_while_fetching_dirs})
    end

    state = %State{state | respond_to: nil, timeout_ref: nil}
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.warn("Unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  defp parse_src_beam_dirs(encoded) do
    list = Jason.decode!(encoded)
    [src_dirs_length | rest] = list
    {src_dirs, [beam_dirs_length | rest]} = Enum.split(rest, src_dirs_length)
    {beam_dirs, []} = Enum.split(rest, beam_dirs_length)

    {src_dirs, beam_dirs}
  end
end
