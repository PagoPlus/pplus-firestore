defmodule PPlusFireStore.MixProject do
  use Mix.Project

  @source_url "https://github.com/PagoPlus/pplus-firestore"
  @version "0.1.0"

  def project do
    [
      app: :pplus_firestore,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test,
        ci: :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def docs do
    [
      name: "PPlusFireStore",
      source_ref: "v#{@version}",
      source_url: @source_url,
      main: "readme",
      extras: ["README.md", "LICENSE"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  def deps do
    [
      {:google_api_firestore, "~> 0.32"},
      {:goth, "~> 1.4"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:styler, "~> 1.4.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18.3", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      ci: [
        "format --check-formatted",
        "deps.unlock --check-unused",
        "credo suggest --strict --all",
        "coveralls"
      ],
      docs: ["docs", &copy_images/1]
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      maintaners: ["JVMartyns", "Fernando Mumbach"]
    }
  end

  defp copy_images(_) do
    File.mkdir_p("doc/priv/images")
    File.cp_r("priv/images", "doc/priv/images")
  end
end
