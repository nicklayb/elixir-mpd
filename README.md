# Mpd

MPD (Music Player Daemon) is commonly used on UNIX.

  It's a TCP server that plays music in the background which allows a lot of possibility.

  [See here](https://www.musicpd.org/doc/html/index.html)

  The ultimate goal is to have full abilities on MPD server through GenServers.

## Installation

The package can be installed by adding `mpd` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mpd, "~> 0.1.0"}
  ]
end
```

## Usage

### Mpd.Player

The package now includes a Player GenServer that you can use to have the player's current state and playing song. It also listens on change and gets updated on change

See documentation for more info

### Mpd.Database (WIP)

The goal is to have cached or quickly accessible database copy and have it accessible as a gen server.

See documentation for it's progress
