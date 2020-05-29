defmodule Mpd.Database.Importer do
  alias Mpd.Handler
  require Mpd.Utils
  Mpd.Utils.logger()

  @doc """
  Loads all the mpd database songs and their tags
  """
  @spec import :: Mpd.Songs.song_map()
  def import do
    debug("Loading songs")

    with {:ok, songs} <- load_songs() do
      debug("Songs loaded")

      Enum.reduce(songs, %{}, fn file, acc ->
        with {:ok, song} <- load_song_info(file) do
          debug("Song #{file} loaded")
          Map.put(acc, song.file, song)
        else
          error ->
            error(inspect(error))
            acc
        end
      end)
    end
  end

  defp load_songs do
    Handler.call(:listall)
  end

  defp load_song_info(file) do
    Handler.call({:listallinfo, file})
  end
end
