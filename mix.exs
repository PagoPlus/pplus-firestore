defmodule PPlusFireStore.MixProject do
  use Mix.Project

  def project do
    [
      app: :pplus_firestore,
      version: "0.1.0",
      elixir: "~> 1.18",
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
  def deps do
    [
      {:google_api_firestore, "~> 0.32"},
      {:goth, "~> 1.4"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:styler, "~> 1.0.0-rc.1", only: [:dev, :test], runtime: false}
    ]
  end
end
