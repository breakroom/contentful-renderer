defmodule ContentfulRenderer.MixProject do
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :contentful_renderer,
      version: @version,
      elixir: "~> 1.8",
      deps: deps(),
      name: "Contentful Renderer",
      source_url: "https://github.com/poplarhq/contentful_renderer",
      description: "Rich Text to HTML renderer for Contentful CMS",
      package: package(),
      docs: docs()
    ]
  end

  def package do
    [
      licenses: ["MIT"],
      maintainers: ["Tom Taylor"],
      links: %{"GitHub" => "https://github.com/poplarhq/contentful_renderer"}
    ]
  end

  def docs do
    [
      source_ref: "v#{@version}"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:poison, "~> 3.1", only: :test},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end
end
