defmodule Mpd.Player do
  use GenServer
  use Mpd.Idle
  require Logger
  require Mpd.Utils
  alias Mpd.Player.State

  Mpd.Utils.logger()

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def update do
    GenServer.cast(__MODULE__, :update)
  end

  def state do
    GenServer.call(__MODULE__, :state)
  end

  @impl true
  def init(args) do
    info("Player listening")
    on_update = Keyword.get(args, :on_update)
    state = update(%State{on_update: on_update})
    idle()
    {:ok, state}
  end

  def handle_change(idle, state) do
    debug("Changed: #{idle}")
    update()
    state
  end

  def handle_info(msg, state) do
    warn("Unhandled #{msg}")
    {:noreply, state}
  end

  @impl true
  def handle_cast(:update, state) do
    state = update(state)

    fire_player_update(state)
    debug("Player updated")

    {:noreply, state}
  end

  @impl true
  def handle_call(:state, _, state) do
    {:reply, state, state}
  end

  defp update(state) do
    state
    |> put_current_song()
    |> put_status()
  end

  defp fire_player_update(%State{on_update: on_update} = state)
       when is_function(on_update) do
    on_update.(state)
    :ok
  end

  defp fire_player_update(_), do: :noop

  defp put_current_song(state) do
    case Handler.call(:currentsong) do
      {:ok, %Mpd.Song{file: file} = current_song} when not is_nil(file) ->
        %State{state | current_song: current_song}

      _ ->
        state
    end
  end

  defp put_status(state) do
    case Handler.call(:status) do
      {:ok, status} -> %State{state | status: status}
      _ -> state
    end
  end
end
