defmodule Mpd.Player.State do
  defstruct status: nil, current_song: nil, on_update: nil

  def put_status(%__MODULE__{} = state, status) do
    %__MODULE__{state | status: status}
  end

  def put_current_song(%__MODULE__{} = state, current_song) do
    %__MODULE__{state | current_song: current_song}
  end
end
