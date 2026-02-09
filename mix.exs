defmodule ExAIS.MixProject do
  use Mix.Project

  @source_url "https://github.com/admarrs/ais"
  @version "0.2.3"

  def project do
    [
      app: :exais,
      version: @version,
      elixir: "~> 1.17",
      name: "ExAis",
      source_url: @source_url,
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      package: package(),
      deps: deps(),
      docs: docs(),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def cli do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test,
      "coveralls.cobertura": :test
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # dev & test deps
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false, warn_if_outdated: true},

      # test deps
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  defp aliases do
    [
      precommit: ["compile --warning-as-errors", "deps.unlock --unused", "format", "test"]
    ]
  end

  defp package do
    [
      description: description(),
      files: ["lib", "mix.exs", "README*", "LICENSE", "CHANGELOG.md"],
      exclude_patterns: ["_build", "deps", "test", "*~"],
      maintainers: ["Alan Marrs"],
      licenses: ["MIT"],
      links: %{
        Changelog: "#{@source_url}/blob/master/CHANGELOG.md",
        GitHub: @source_url
      },
      exclude_patterns: [~r/.*~/]
    ]
  end

  defp description do
    """
    Elixir library for decoding AIS data.
    """
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]
end
