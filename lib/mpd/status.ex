defmodule Mpd.Status do
  @moduledoc """
  Represents a server status

  ## Status keys

  - partition: the name of the current partition (see Partition commands)
  - volume: 0-100 (deprecated: -1 if the volume cannot be determined)
  - repeat: 0 or 1
  - random: 0 or 1
  - single [2]: 0, 1, or oneshot [6]
  - consume [2]: 0 or 1
  - playlist: 31-bit unsigned integer, the playlist version number
  - playlistlength: integer, the length of the playlist
  - state: play, stop, or pause
  - song: playlist song number of the current song stopped on or playing
  - songid: playlist songid of the current song stopped on or playing
  - nextsong [2]: playlist song number of the next song to be played
  - nextsongid [2]: playlist songid of the next song to be played
  - time: total time elapsed (of current playing/paused song) in seconds (deprecated, use elapsed instead)
  - elapsed [3]: Total time elapsed within the current song in seconds, but with higher resolution.
  - duration [5]: Duration of the current song in seconds.
  - bitrate: instantaneous bitrate in kbps
  - xfade: crossfade in seconds
  - mixrampdb: mixramp threshold in dB
  - mixrampdelay: mixrampdelay in seconds
  - audio: The format emitted by the decoder plugin during playback, format: samplerate:bits:channels. See Global Audio Format for a detailed explanation.
  - updating_db: job id
  """
  defstruct partition: nil,
            volume: nil,
            repeat: nil,
            random: nil,
            single: nil,
            consume: nil,
            playlist: nil,
            playlist_length: nil,
            state: nil,
            song: nil,
            songid: nil,
            next_song: nil,
            next_song_id: nil,
            time: nil,
            elapsed: nil,
            duration: nil,
            bitrate: nil,
            xfade: nil,
            mix_ramp_db: nil,
            mix_ramp_delay: nil,
            audio: nil,
            updating_db: nil,
            error: nil

  @type t() :: %Mpd.Status{}
  import Mpd.Utils

  @atom_states ~w(play pause stop)a
  @states Enum.map(@atom_states, &to_string/1)

  @doc """
  Parse MPD output as a status struct
  """
  @spec parse(binary) :: Mpd.Status.t()
  def parse(string) do
    string
    |> String.split("\n")
    |> Enum.reduce(%Mpd.Status{}, &assign_field/2)
  end

  defp assign_field("partition: " <> value, status) do
    %__MODULE__{status | partition: value}
  end

  defp assign_field("volume: " <> value, status) do
    %__MODULE__{status | volume: to_int(value)}
  end

  defp assign_field("repeat: " <> value, status) do
    %__MODULE__{status | repeat: boolean_int(value)}
  end

  defp assign_field("random: " <> value, status) do
    %__MODULE__{status | random: boolean_int(value)}
  end

  defp assign_field("single: " <> value, status) do
    %__MODULE__{status | single: to_int(value)}
  end

  defp assign_field("consume: " <> value, status) do
    %__MODULE__{status | consume: boolean_int(value)}
  end

  defp assign_field("playlist: " <> value, status) do
    %__MODULE__{status | playlist: to_int(value)}
  end

  defp assign_field("playlistlength: " <> value, status) do
    %__MODULE__{status | playlist_length: to_int(value)}
  end

  defp assign_field("state: " <> value, status) when value in @states do
    %__MODULE__{status | state: String.to_existing_atom(value)}
  end

  defp assign_field("state: " <> _value, status), do: status

  defp assign_field("song: " <> value, status) do
    %__MODULE__{status | song: to_int(value)}
  end

  defp assign_field("songid: " <> value, status) do
    %__MODULE__{status | songid: to_int(value)}
  end

  defp assign_field("nextsong: " <> value, status) do
    %__MODULE__{status | next_song: to_int(value)}
  end

  defp assign_field("nextsongid: " <> value, status) do
    %__MODULE__{status | next_song_id: to_int(value)}
  end

  defp assign_field("time: " <> value, status) do
    %__MODULE__{status | time: to_float(value)}
  end

  defp assign_field("elapsed: " <> value, status) do
    %__MODULE__{status | elapsed: to_float(value)}
  end

  defp assign_field("duration: " <> value, status) do
    %__MODULE__{status | duration: to_float(value)}
  end

  defp assign_field("bitrate: " <> value, status) do
    %__MODULE__{status | bitrate: to_int(value)}
  end

  defp assign_field("xfade: " <> value, status) do
    %__MODULE__{status | xfade: value}
  end

  defp assign_field("mixrampdb: " <> value, status) do
    %__MODULE__{status | mix_ramp_db: to_float(value)}
  end

  defp assign_field("mixrampdelay: " <> value, status) do
    %__MODULE__{status | mix_ramp_delay: value}
  end

  defp assign_field("audio: " <> value, status) do
    %__MODULE__{status | audio: value}
  end

  defp assign_field("updating_db: " <> value, status) do
    %__MODULE__{status | updating_db: value}
  end

  defp assign_field("error: " <> value, status) do
    %__MODULE__{status | error: value}
  end

  defp assign_field(_value, status), do: status
end
