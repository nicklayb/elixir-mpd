defmodule Mpd.Songs do
  @moduledoc """
  This module is used to manipulate multiple songs like filtering or find songs among a list.
  """
  alias Mpd.Song
  @type songs :: [Mpd.Song.t()]
  @type song_map :: %{binary() => songs()}
  @type song_tree :: %{binary() => song_map()}

  @doc """
  Filters a list of songs by a given tag insensitively
  """
  @spec find_by_tag(songs(), binary(), binary()) :: songs()
  def find_by_tag(songs, tag, value) do
    songs
    |> Enum.filter(&Song.tag_like?(&1, tag, value))
  end

  @doc """
  Filters a list of songs by a given Artist tag insensitively
  """
  @spec find_by_artist(songs(), binary) :: songs()
  def find_by_artist(songs, value), do: find_by_tag(songs, "Artist", value)

  @doc """
  Filters a list of songs by a given Artist tag insensitively
  """
  @spec find_by_album(songs(), binary) :: songs()
  def find_by_album(songs, value), do: find_by_tag(songs, "Album", value)

  @doc """
  Groups a list of songs by artist
  """
  @spec artists(songs()) :: song_map()
  def artists(songs), do: Enum.group_by(songs, &Song.artist(&1))

  @doc """
  Groups a list of songs by album
  """
  @spec albums(songs()) :: song_map()
  def albums(songs), do: Enum.group_by(songs, &Song.album(&1))

  @doc """
  Creates a tree from songs grouped by artist then album.

  ```
  %{
    "Rouge Pompier" => %{
      "Neve Campbell" => [
        %Mpd.Song{},
        %Mpd.Song{},
      ],
      "Kevin Bacon" => [
        %Mpd.Song{},
        %Mpd.Song{},
      ]
    }
  }
  ```
  """
  @spec as_tree(songs() | song_map()) :: song_tree()
  def as_tree(songs) when is_map(songs), do: songs |> Map.values() |> as_tree()

  def as_tree(songs) when is_list(songs) do
    songs
    |> artists()
    |> Enum.reduce(%{}, fn {artist, songs}, acc ->
      albums = albums(songs)

      Map.put(acc, artist, albums)
    end)
  end

  @doc """
  Parses a song list MPD output into structs
  """
  @spec parse(binary) :: songs()
  def parse(string) do
    string
    |> String.split("\n")
    |> Enum.reduce([], &parse_song/2)
  end

  defp parse_song("file: " <> file, acc) do
    [file | acc]
  end

  defp parse_song("directory: " <> _, acc), do: acc
  defp parse_song("OK" <> _, acc), do: acc
  defp parse_song("", acc), do: acc
end
