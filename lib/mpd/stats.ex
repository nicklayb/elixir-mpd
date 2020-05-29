defmodule Mpd.Stats do
  defstruct artists: 0,
            albums: 0,
            songs: 0,
            uptime: 0,
            db_playtime: 0,
            db_update: 0,
            playtime: 0

  import Mpd.Utils

  def parse(string) do
    string
    |> String.split("\n")
    |> Enum.reduce(%Mpd.Stats{}, &assign_field/2)
  end

  defp assign_field("artists: " <> value, stats) do
    %Mpd.Stats{stats | artists: to_int(value)}
  end

  defp assign_field("albums: " <> value, stats) do
    %Mpd.Stats{stats | albums: to_int(value)}
  end

  defp assign_field("songs: " <> value, stats) do
    %Mpd.Stats{stats | songs: to_int(value)}
  end

  defp assign_field("uptime: " <> value, stats) do
    %Mpd.Stats{stats | uptime: to_int(value)}
  end

  defp assign_field("db_playtime: " <> value, stats) do
    %Mpd.Stats{stats | db_playtime: to_int(value)}
  end

  defp assign_field("db_update: " <> value, stats) do
    %Mpd.Stats{stats | db_update: to_int(value)}
  end

  defp assign_field("playtime: " <> value, stats) do
    %Mpd.Stats{stats | playtime: to_int(value)}
  end

  defp assign_field(_, stats), do: stats
end
