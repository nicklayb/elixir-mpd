defmodule Mpd.Config do
  @moduledoc """
  Config modules defines zero arity function with fallback on compilation to prevent boilerplate code.
  """
  @configs [
    {:hostname, "localhost"},
    {:port, 6600}
  ]

  Enum.map(@configs, fn
    {config, default} ->
      def unquote(config)() do
        resolve(unquote(config), unquote(default))
      end

    config ->
      def unquote(config)() do
        resolve!(unquote(config))
      end
  end)

  @doc """
  Resolves a configuration value with a fallback
  """
  @spec resolve(atom, any) :: any
  def resolve(key, default) do
    Application.fetch_env!(:mpd, key)
  rescue
    _ -> default
  end

  @doc """
  Resolves a required configuration value
  """
  @spec resolve!(atom) :: any
  def resolve!(key) do
    Application.fetch_env!(:mpd, key)
  end
end
