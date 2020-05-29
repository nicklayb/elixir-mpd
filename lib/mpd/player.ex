defmodule Mpd.Player do
  @moduledoc """
  The `Mpd.Player` genserver can be used to monitor the player's states. It contains the current playing song and the player status and listens to idles to update itself when it changes.

  You can add the Player to you Application's supervisor or start manually like

  ```
  Mpd.Player.start_link([])
  ```

  Then you can play around with your mpd server and check it's current state with `Mpd.Player.state/0`

  ### Events

  When starting the process, you can give an `on_update` argument as a function. This function will be called on every player changes.

  You could then use it with Phoenix's broadcast/subscribe:

  ```
  Mpd.Player.start_link([on_update: fn state ->
    MyAppWeb.Endpoint.broadcast("mpd:update", state)
  end)])
  ```
  """
  use GenServer
  use Mpd.Idle
  require Logger
  require Mpd.Utils
  alias Mpd.Player.State

  Mpd.Utils.logger()

  @doc """
  Starts the genserver linked
  """
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Force the player to update it's state with the mpd server
  """
  @spec update :: :ok
  def update do
    GenServer.cast(__MODULE__, :update)
  end

  @doc """
  Gets the player's state
  """
  @spec state :: Mpd.Player.State.t()
  def state do
    GenServer.call(__MODULE__, :state)
  end

  @impl true
  @spec init(keyword) :: {:ok, any}
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
