defmodule VersionChecker.MixProject do
  use Mix.Project

  def project do
    [
      app: :version_checker,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:git_cli, "~> 0.3.0"},
      {:tentacat, "~> 1.6.1"}
    ]
  end
end
