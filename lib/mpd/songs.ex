defmodule Mpd.Songs do
  alias Mpd.Song

  def find_by_tag(songs, tag, value) do
    songs
    |> Enum.filter(&Song.tag_like?(&1, tag, value))
  end

  def find_by_artist(songs, value), do: find_by_tag(songs, "Artist", value)

  def find_by_album(songs, value), do: find_by_tag(songs, "Album", value)

  def artists(songs), do: Enum.group_by(songs, &Song.artist(&1))

  def albums(songs), do: Enum.group_by(songs, &Song.album(&1))

  def as_tree(songs) when is_map(songs), do: songs |> Map.values() |> as_tree()

  def as_tree(songs) when is_list(songs) do
    songs
    |> artists()
    |> Enum.reduce(%{}, fn {artist, songs}, acc ->
      albums = albums(songs)

      Map.put(acc, artist, albums)
    end)
  end

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
