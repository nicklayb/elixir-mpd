defmodule Mpd.Config do
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
        resolve(unquote(config))
      end
  end)

  def resolve(key, default) do
    Application.fetch_env!(:mpd, key)
  rescue
    _ -> default
  end

  def resolve(key) do
    Application.fetch_env!(:mpd, key)
  end
end
