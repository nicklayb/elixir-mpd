defmodule Mpd.Handler do
  @moduledoc """
  The Mpd.Handle is the module responsible for executing commands with the mpd server. It wraps protocol's TCP command to prevent unsupported calls to the server.

  ## Configuration

  By default, the Handler uses the following configuration:

  - `hostname: binary()`: `"localhost"`; refers to server hostname
  - `port: integer()`: `6600`; refers to server port

  You can override those by calling doing the following:
  ```
  iex> Application.put_env(:mpd, :hostname, "http://someserver.com")
  ```

  Or using Config

  ```
  config :mpd, :hostname, "http://someserver.com"
  ```

  ## Usage

  There are 3 main ways to call commands using the Handler.

  - `call/1`: Executes the command and return the outputs. It returns nil for side-effect calls such at `:play`
  - `cast/1`: Executes the command in an asynchronous Task.
  - `call_idle/1`: Executes the idle command and sends events to a given process.

  ### Idles

  While most commands mutates the player states or returns information, idles are use to listen on the mpd server.

  For instance, the `:player` idle will listen on player event. Running `cast_idle(:player, self())` would send any player event to the current process.
  """

  @type command() ::
          :currentsong
          | :listall
          | :next
          | :pause
          | :play
          | :previous
          | :stats
          | :status
          | :toggle
          | {:add
             | :consume
             | :crossfade
             | :listallinfo
             | :random
             | :repeat
             | :replay_gain_mode
             | :setvol, any}
  @type command_result() :: {:ok, any} | {:error, any}

  @doc """
  Calls a command inside an asynchronous task

  See `call/1` for more details

  ## Examples
  ```
  iex> Mpd.Handler.cast(:play)
  %Task{}
  ```
  """
  @spec cast(command()) :: Task.t()
  def cast(command) do
    Task.async(fn -> call(command) end)
  end

  @doc """
  Calls a command through TCP to the MPD server using gen_tcp. Most commands doesn't return anywthing and therefore will return `{:ok, nil}`.

  Commands that has output returns structs reprenting the output, like `:currentsong`.

  ## Available commands

  Here is a complete list of supported commands and there expected output.

  Commands name should represent protocol's commands, see [https://www.musicpd.org/doc/html/protocol.html](https://www.musicpd.org/doc/html/protocol.html)

  - `:next`: Returns `nil`, plays the next song in queue
  - `:pause`: Returns `nil`, put the player on pause
  - `:play`:  Returns `nil`, put the player on play
  - `:previous`:  Returns `nil`, plays the previous song in queue
  - `:toggle`:  Returns `nil`, plays the player if paused, otherwise pauses it.
  - `{:add, uri}`: Returns `nil`, adds song with `uri` to the queue. URI's refers to song's file attribute.
  - `{:consume, boolean()}`: Returns `nil`, sets consume to either true or false.
  - `{:crossfade, integer()}`: Returns `nil`, sets crossfade to given integer value as seconds.
  - `{:random, boolean()}`: Returns `nil`, sets random mode to either true or false.
  - `{:repeat, boolean()}`: Returns `nil`, sets repeat mode to either true or false.
  - `{:setvol, integer()}`: Returns `nil`, sets volume to give integer value.
  - `{:replay_gain_mode, replay_modes()}`: Returns `nil`, sets given replay mode.
  - `:currentsong`: Returns `Mpd.Song.t()` with the tags and filename of the current playing song.
  - `:listall`: Returns `map(binary() => Mpd.Song.t())`, key is the filename and value is a song struct with tags.
  - `:stats`: Returns `Mpd.Stats.t()` representing server stats
  - `:status`: Returns `Mpd.Status.t()` representing the actual player state
  - `{:listallinfo, uri}`: Returns `Mpd.Song.t()` with given song's uri information.
  ```
  """
  @spec call(command()) :: command_result()
  def call(:status) do
    with {:ok, out} <- sync("status\n") do
      {:ok, out |> normalize() |> Mpd.Status.parse()}
    else
      error -> error
    end
  end

  def call(:currentsong) do
    with {:ok, out} <- sync("currentsong\n") do
      {:ok, out |> normalize() |> Mpd.Song.parse()}
    else
      error -> error
    end
  end

  def call(:stats) do
    with {:ok, out} <- sync("stats\n") do
      {:ok, out |> normalize() |> Mpd.Stats.parse()}
    else
      error -> error
    end
  end

  def call(:listall) do
    with {:ok, out} <- sync("listall\n") do
      {:ok, out |> normalize() |> Mpd.Songs.parse()}
    end
  end

  def call({:listallinfo, file}) do
    with {:ok, out} <- sync("listallinfo \"#{file}\"\n") do
      {:ok, out |> normalize() |> Mpd.Song.parse()}
    end
  end

  def call({:consume, state}), do: noresponse("consume #{bool_to_param(state)}\n")

  def call({:crossfade, seconds}), do: noresponse("crossfade #{seconds}\n")

  def call({:random, state}), do: noresponse("random #{bool_to_param(state)}\n")

  def call({:repeat, state}), do: noresponse("repeat #{bool_to_param(state)}\n")

  def call({:setvol, vol}), do: noresponse("setvol #{vol}\n")

  def call(:next), do: noresponse("next\n")

  def call(:previous), do: noresponse("previous\n")

  def call(:toggle), do: noresponse("pause\n")

  def call(:play), do: noresponse("pause 0\n")

  def call(:pause), do: noresponse("pause 1\n")

  def call({:add, %Mpd.Song{file: file}}), do: call({:add, file})

  def call({:add, uri}), do: noresponse("add \"#{uri}\"\n")

  @type replay_modes :: :off | :track | :album | :auto
  def call({:replay_gain_mode, mode}), do: noresponse("replay_gain_mode #{mode}\n")

  defp noresponse(command) do
    execute(command, fn _ -> {:ok, nil} end)
  end

  defp sync(command) do
    execute(command, &tcp_receive(&1, ''))
  end

  @packet_size 0
  defp tcp_receive(socket, acc) do
    with {:ok, out} <- :gen_tcp.recv(socket, @packet_size, 500) do
      acc = acc ++ out

      if String.ends_with?(to_string(out), "OK\n") do
        {:ok, :binary.list_to_bin(acc)}
      else
        tcp_receive(socket, acc)
      end
    else
      err ->
        err
    end
  end

  defp execute(command, on_success) do
    assert_command!(command)

    with {:ok, socket} = connect(active: false) do
      if connected_response?(:gen_tcp.recv(socket, 0)) do
        :gen_tcp.send(socket, command)
        response = on_success.(socket)
        :gen_tcp.close(socket)
        response
      else
        {:error, :cant_connect}
      end
    end
  end

  @doc """
  Calls idle commmand and connect the socket port to a process where it'll sends incoming events.

  For more information about idle commands see [MPD's protocol definition](https://www.musicpd.org/doc/html/protocol.html#querying-mpd-s-status)

  ## Examples

  ```
  iex> Mpd.Handler.call_idle(self())
  #Port<0.563>

  iex> flush()
  {:tcp, #Port<0.563>, 'OK MPD 0.20.0\n'}
  {:tcp, #Port<0.563>, 'changed: player\nOK\n'} # when the player is paused, for instance
  :ok
  ```
  """
  def call_idle(pid) do
    execute_attached("idle\n", pid)
  end

  @doc """
  Calls idle like `call_idle/1` but only for given idles. See [MPD's protocol definition](https://www.musicpd.org/doc/html/protocol.html#querying-mpd-s-status) for idles list and detail.

  ## Examples

  ```
  iex> Mpd.Handler.call_idle(:options, self())
  #Port<0.563>

  iex> flush()
  {:tcp, #Port<0.563>, 'OK MPD 0.20.0\n'}
  :ok
  ```

  Previous call would not receive events when the player gets updated as it only listens for `options` idle.
  """
  @type idles ::
          :database
          | :message
          | :mixer
          | :options
          | :output
          | :partition
          | :player
          | :playlist
          | :sticker
          | :stored_playlist
          | :subscription
          | :update
  @spec call_idle(idles() | [idles()], pid) :: port

  def call_idle(idles, pid) when is_list(idles) do
    idles =
      idles
      |> Enum.map(&to_string/1)
      |> Enum.join(" ")

    execute_attached("idle #{idles}\n", pid)
  end

  def call_idle(idle, pid) do
    execute_attached("idle #{idle}\n", pid)
  end

  defp execute_attached(command, pid) do
    assert_command!(command)

    with {:ok, socket} = connect([]) do
      Port.connect(socket, pid)
      :gen_tcp.send(socket, command)
      socket
    end
  end

  defp connect(opts) do
    :gen_tcp.connect(String.to_charlist(Mpd.Config.hostname()), Mpd.Config.port(), opts)
  end

  defp connected_response?({:ok, resp}) do
    resp
    |> to_string()
    |> String.starts_with?("OK MPD")
  end

  defp connected_response?(_), do: false

  defp assert_command!(command) do
    if not String.ends_with?(command, "\n"), do: raise("Commands must end with a line feed")
  end

  defp normalize(string) when is_bitstring(string), do: string

  defp bool_to_param(true), do: "1"
  defp bool_to_param(false), do: "0"
end
