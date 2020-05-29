defmodule MpdTest do
  use ExUnit.Case
  doctest Mpd

  test "greets the world" do
    assert Mpd.hello() == :world
  end
end
