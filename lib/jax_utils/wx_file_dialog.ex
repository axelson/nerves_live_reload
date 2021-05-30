defmodule JaxUtils.WxFileDialog do
  @moduledoc """
  Code based on these resources:
  * https://github.com/ijcd/wx_widgets/blob/62a7bd4e2e63095cc7e0ca6ab8cbe9d80a0dc859/lib/examples/elixir/simple.ex
  * https://gist.github.com/rlipscombe/5f400451706efde62acbbd80700a6b7c
  * https://erlang.org/doc/apps/wx/wx.pdf
  """
  require Logger

  defmodule State do
    defstruct [:file_picker, :handler]
  end

  @behaviour :wx_object
  def start_link(opts \\ []) do
    opts = Keyword.merge([handler: self()], opts)
    wx_opts = []
    :wx_object.start_link(__MODULE__, opts, wx_opts)
  end

  # http://www.idiom.com/~turner/wxtut/wxwidgets.html
  @impl :wx_object
  def init(opts \\ []) do
    handler = Keyword.get(opts, :handler)
    wx = :wx.new()

    frame = :wxFrame.new(wx, -1, 'Select mix.exs')
    :wxFrame.show(frame)
    :wxFrame.createStatusBar(frame)
    :wxFrame.setStatusText(frame, 'Quiet here.')

    menu_bar = :wxMenuBar.new()
    :wxFrame.setMenuBar(frame, menu_bar)

    file_menu = :wxMenu.new()
    :wxMenuBar.append(menu_bar, file_menu, '&File')

    file_picker = :wxFilePickerCtrl.new(frame, 1)

    :ok = :wxEvtHandler.connect(frame, :close_window)

    # Looked through
    # https://erlang.org/doc/man/wxEvtHandler.html#connect-3
    # To find an even that was related to the filepicker
    :ok = :wxEvtHandler.connect(frame, :command_filepicker_changed)

    state = %State{file_picker: file_picker, handler: handler}
    {frame, state}
  end

  @impl :wx_object
  def handle_info(info_event, state) do
    Logger.info("Ignoring info event: #{inspect(info_event)}")
    {:noreply, state}
  end

  @impl :wx_object
  def handle_event({:wx, _, _, _, {:wxClose, :close_window}}, state) do
    {:stop, :normal, state}
  end

  def handle_event({:wx, _, _, _, {:wxFileDirPicker, :command_filepicker_changed, path}}, state) do
    %State{handler: handler} = state
    GenServer.cast(handler, {:file_picked, to_string(path)})

    {:stop, :normal, state}
  end

  def handle_event(event, state) do
    Logger.info("Ignoring event: #{inspect(event)}")
    {:noreply, state}
  end
end
