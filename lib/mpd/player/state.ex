defmodule Mpd.Player.State do
  defstruct status: nil, current_song: nil, on_update: nil
  @type t :: %Mpd.Player.State{}

  @doc """
  Puts the given status struct in the state
  """
  @spec put_status(Mpd.Player.State.t(), any) :: Mpd.Player.State.t()
  def put_status(%__MODULE__{} = state, status) do
    %__MODULE__{state | status: status}
  end

  @doc """
  Puts the given song struct in the current song state
  """
  @spec put_current_song(Mpd.Player.State.t(), any) :: Mpd.Player.State.t()
  def put_current_song(%__MODULE__{} = state, current_song) do
    %__MODULE__{state | current_song: current_song}
  end
end
