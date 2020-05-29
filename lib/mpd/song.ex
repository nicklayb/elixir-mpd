defmodule Mpd.Song do
  defstruct file: nil, tags: %{}
  import Mpd.Utils

  @type t() :: %Mpd.Song{}
  @common_tags %{
    artist: "Artist",
    album: "Album"
  }

  Enum.map(@common_tags, fn {func, tag} ->
    def unquote(func)(%Mpd.Song{} = song) do
      tag(song, unquote(tag))
    end
  end)

  @doc """
  Gets song summary
  """
  @spec summary(Mpd.Song.t()) :: binary
  def summary(%Mpd.Song{} = song) do
    "#{tag(song, "Artist", "Unkown artist")} - #{tag(song, "Title", "Unkown track")}"
  end

  @doc """
  Gets song tag by name
  """
  @spec tag(Mpd.Song.t(), binary, any) :: any
  def tag(%Mpd.Song{tags: tags}, tag, fallback \\ "") do
    Map.get(tags, tag, fallback)
  end

  @doc """
  Checks if song filanem insensitively compares to a given query
  """
  @spec file_like?(Mpd.Song.t(), any) :: boolean
  def file_like?(%Mpd.Song{file: file}, query) do
    string_like?(file, query)
  end

  @doc """
  Checks if song tags insensitively compares to a given query
  """
  @spec tag_like?(Mpd.Song.t(), any) :: boolean
  def tag_like?(%Mpd.Song{tags: tags}, query) do
    Enum.any?(tags, fn {_key, value} ->
      string_like?(value, query)
    end)
  end

  @doc """
  Checks if a given song tag insensitively compares to a given query
  """
  @spec tag_like?(Mpd.Song.t(), binary, any) :: boolean
  def tag_like?(%Mpd.Song{tags: tags}, tag, query) do
    tags
    |> Map.get(tag)
    |> string_like?(query)
  end

  @doc """
  Checks if song tags or filename insensitively compares to a given query
  """
  @spec like?(Mpd.Song.t(), binary) :: boolean
  def like?(song, query) do
    tag_like?(song, query) or file_like?(song, query)
  end

  @doc """
  Puts a tag in a given song
  """
  @spec put_tag(Mpd.Song.t(), binary, binary) :: Mpd.Song.t()
  def put_tag(%Mpd.Song{tags: tags} = song, key, value) do
    %Mpd.Song{song | tags: Map.put(tags, String.trim(key), String.trim(value))}
  end

  @doc """
  Parses a MPD song output to the appropriate stucture.

  A common song output (using `:currentsong`, for instance) has the following body
  ```
  file: Rouge Pompier/Neve Campbell/10 Gaetan Mouillé.m4a
  Last-Modified: 2020-05-21T04:19:18Z
  Artist: Rouge Pompier
  Album: Neve Campbell
  Title: Gaetan Mouillé
  Track: 10
  Genre: French Pop
  Date: 2020-03-20T07:00:00Z
  Composer: Jessy Fuchs & Alexandre Portelance
  Disc: 1
  AlbumArtist: Rouge Pompier
  Time: 141
  duration: 140.829
  Pos: 34
  Id: 45
  OK
  ```

  he `file: ...` entry is refered as the song URI's, the rests are song tags. Since these may vary depending files, it'a map.

  ## Examples

  ```
  iex> Mpd.Status.parse(str)
  %Mpd.Status{
    file: "Rouge Pompier/Neve Campbell/10 Gaetan Mouillé.m4a",
    tags: %{
      "Artist" => "Rouge Pompier",
      "Album" => "Neve Campbell",
      "Title" => "Gaetan Mouillé",
      "Track" => "10",
      "Genre" => "French Pop",
      ...
    }
  }
  ```
  """
  @spec parse(binary()) :: Mpt.Song.t()
  def parse(string) do
    string
    |> String.split("\n")
    |> Enum.reduce(%Mpd.Song{}, &assign_field/2)
  end

  defp assign_field("file: " <> file, song) do
    %Mpd.Song{song | file: file}
  end

  defp assign_field("OK" <> _, song), do: song

  defp assign_field(tag, %Mpd.Song{} = song) do
    if is_tag?(tag) do
      [key, value] = String.split(tag, ":", parts: 2)

      put_tag(song, key, value)
    else
      song
    end
  end

  defp is_tag?(tag), do: String.contains?(tag, ":")
end
