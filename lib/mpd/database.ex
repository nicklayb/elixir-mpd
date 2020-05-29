defmodule Mpd.Database do
  defstruct songs: %{}, tree: %{}
  use GenServer
  import Mpd.Utils
  alias Mpd.{Database, Song, Songs}

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_) do
    sync()
    {:ok, %Database{}}
  end

  @impl true
  def handle_cast(:sync, state) do
    songs = Database.Importer.import()
    {:noreply, %Database{state | songs: songs, tree: Songs.as_tree(songs)}}
  end

  @impl true
  def handle_call({:get, file}, _from, %Database{songs: songs} = state) do
    {:reply, Map.get(songs, file), state}
  end

  def handle_call(:all, _from, %Database{songs: songs} = state) do
    {:reply, Map.values(songs), state}
  end

  def handle_call({:search, query}, _from, %Database{songs: songs} = state) do
    songs = Enum.filter(songs, fn {_, song} -> Song.like?(song, query) end)

    {:reply, Keyword.values(songs), state}
  end

  def handle_call({:albums, artists}, _from, %Database{tree: tree} = state) do
    filtered_tree = if artists == [], do: tree, else: Map.take(tree, artists)

    albums =
      filtered_tree
      |> Map.values()
      |> Enum.reduce([], fn albums, acc -> acc ++ Map.keys(albums) end)

    {:reply, albums, state}
  end

  def handle_call({:artists, []}, _from, %Database{tree: tree} = state) do
    {:reply, Map.keys(tree), state}
  end

  def handle_call({:artists, filters}, _from, %Database{tree: tree} = state) do
    artists =
      tree
      |> Enum.filter(fn {artist, _} -> string_like?(artist, filters) end)

    {:reply, artists, state}
  end

  def sync do
    GenServer.cast(__MODULE__, :sync)
  end

  def get(file) do
    GenServer.call(__MODULE__, {:get, file})
  end

  def search(query) do
    GenServer.call(__MODULE__, {:search, query})
  end

  def all do
    GenServer.call(__MODULE__, :all)
  end

  def artists(filters \\ []) do
    GenServer.call(__MODULE__, {:artists, filters})
  end

  def albums(artists \\ []) do
    GenServer.call(__MODULE__, {:albums, artists})
  end
end
