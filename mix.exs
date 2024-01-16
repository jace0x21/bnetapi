defmodule Bnetapi.MixProject do
  use Mix.Project

  def project do
    [
      app: :bnetapi,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :dev,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Bnetapi.Application, [env: Mix.env]},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.14"},
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 5.0"}
    ]
  end
end
