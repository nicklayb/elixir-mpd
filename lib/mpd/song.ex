defmodule Mpd.Song do
  defstruct file: nil, tags: %{}
  import Mpd.Utils

  @common_tags %{
    artist: "Artist",
    album: "Album"
  }

  Enum.map(@common_tags, fn {func, tag} ->
    def unquote(func)(%Mpd.Song{} = song) do
      tag(song, unquote(tag))
    end
  end)

  def summary(%__MODULE__{} = song) do
    "#{tag(song, "Artist", "Unkown artist")} - #{tag(song, "Title", "Unkown track")}"
  end

  def tag(%__MODULE__{tags: tags}, tag, fallback \\ "") do
    Map.get(tags, tag, fallback)
  end

  def file_like?(%__MODULE__{file: file}, query) do
    string_like?(file, query)
  end

  def tag_like?(%__MODULE__{tags: tags}, query) do
    Enum.any?(tags, fn {_key, value} ->
      string_like?(value, query)
    end)
  end

  def tag_like?(%__MODULE__{tags: tags}, tag, query) do
    tags
    |> Map.get(tag)
    |> string_like?(query)
  end

  def like?(song, query) do
    tag_like?(song, query)
  end

  def put_tag(%__MODULE__{tags: tags} = song, key, value) do
    %__MODULE__{song | tags: Map.put(tags, String.trim(key), String.trim(value))}
  end

  def parse(string) do
    string
    |> String.split("\n")
    |> Enum.reduce(%__MODULE__{}, &assign_field/2)
  end

  defp assign_field("file: " <> file, song) do
    %__MODULE__{song | file: file}
  end

  defp assign_field("OK" <> _, song), do: song

  defp assign_field(tag, %__MODULE__{} = song) do
    if is_tag?(tag) do
      [key, value] = String.split(tag, ":", parts: 2)

      put_tag(song, key, value)
    else
      song
    end
  end

  defp is_tag?(tag), do: String.contains?(tag, ":")
end
