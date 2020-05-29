defmodule Mpd.MixProject do
  use Mix.Project

  def project do
    [
      app: :mpd,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Elixir Music Player Daemon service",
      package: package(),
      homepage_url: "https://nboisvert.com",
      source_url: "https://github.com/nicklayb/elixir-mpd"
    ]
  end

  def package do
    [
      name: "mpd",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/nicklayb/elixir-mpd"}
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [{:ex_doc, "~> 0.21", only: :dev, runtime: false}]
  end
end
