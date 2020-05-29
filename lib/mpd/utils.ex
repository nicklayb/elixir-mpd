defmodule Mpd.Utils do
  @doc """
  Convert an integer value to boolean. MPD uses 1 as true and it gets read as a string from the output.
  """
  @spec boolean_int(binary()) :: boolean
  def boolean_int("1"), do: true
  def boolean_int(_), do: false

  @doc """
  Parses an int from a string in safe way returning a 0 in the case of a failure
  """
  @spec to_int(binary) :: integer
  def to_int(string) when is_bitstring(string) do
    case Integer.parse(string) do
      {int, _} -> int
      _ -> 0
    end
  end

  @doc """
  Parses a float from a string in safe way returning a 0.0 in the case of a failure
  """
  @spec to_float(binary) :: float
  def to_float(string) when is_bitstring(string) do
    case Float.parse(string) do
      {float, _} -> float
      _ -> 0.0
    end
  end

  @doc """
  Formats a time in second to "MM:SS" format.
  """
  @spec format_time(number) :: binary
  def format_time(seconds) do
    minutes = trunc(Float.floor(seconds / 60))

    seconds =
      (seconds - minutes * 60)
      |> trunc()
      |> to_string()
      |> String.pad_leading(2, "0")

    Enum.join([minutes, seconds], ":")
  end

  @doc """
  Checks if two strings are insensitively like. Since it does a `to_string/1` it can handles almost any stringable format.

  It also support list to compare against as a second parameter

  ## Examples

  ```
  iex> str = "Primus - Too many puppies"
  "Primus - Too many puppies"
  iex> Mpd.Utils.string_like?(str, "pri")
  true
  iex> Mpd.Utils.string_like?(str, "pup")
  true
  iex> Mpd.Utils.string_like?("Primus - Too many puppies", ["IAM", "Primus"])
  true
  iex> Mpd.Utils.string_like?("Primus - Too many puppies", ["Pink Floyd"])
  false
  ```
  """
  @spec string_like?(any, any) :: boolean
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

  @doc """
  Includes logging helpers to do logging using module name as namespace.
  """
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
