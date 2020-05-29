defmodule Mpd.Utils do
  def boolean_int("1"), do: true
  def boolean_int(_), do: false

  def to_int(string) when is_bitstring(string) do
    case Integer.parse(string) do
      {int, _} -> int
      _ -> 0
    end
  end

  def to_float(string) when is_bitstring(string) do
    case Float.parse(string) do
      {float, _} -> float
      _ -> 0.0
    end
  end

  def format_time(seconds) do
    minutes = trunc(Float.floor(seconds / 60))

    seconds =
      (seconds - minutes * 60)
      |> trunc()
      |> to_string()
      |> String.pad_leading(2, "0")

    Enum.join([minutes, seconds], ":")
  end

  def string_like?(first, second) when is_list(second) do
    Enum.any?(second, &string_like?(first, &1))
  end

  def string_like?(first, second) do
    first = normalize_string(first)
    second = normalize_string(second)
    String.contains?(first, second)
  end

  defp normalize_string(string) do
    string
    |> to_string()
    |> String.downcase()
  end

  defmacro logger do
    quote do
      require Logger

      def info(msg), do: msg |> prefix() |> Logger.info()
      def debug(msg), do: msg |> prefix() |> Logger.debug()
      def warn(msg), do: msg |> prefix() |> Logger.warn()
      def error(msg), do: msg |> prefix() |> Logger.error()
      defp prefix(msg), do: "[#{module_name()}] #{msg}"
      defp module_name, do: __MODULE__ |> to_string() |> String.replace("Elixir.", "")
    end
  end
end
