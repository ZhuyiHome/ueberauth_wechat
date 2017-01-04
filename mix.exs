defmodule UeberauthWechat.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [app: :ueberauth_wechat,
     version: @version,
     name: "Ueberauth wechat",
     package: package(),
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://github.com/ZhuyiHome/ueberauth_wechat",
     homepage_url: "https://github.com/ZhuyiHome/ueberauth_wechat",
     description: description(),
     deps: deps(),
     docs: docs()]
  end

  def application do
    [applications: [:logger, :ueberauth, :oauth2]]
  end

  defp deps do
    [{:ueberauth, "~> 0.4"},
     {:oauth2, "~> 0.8"},

     # docs dependencies
     {:earmark, "~> 0.2", only: :dev},
     {:ex_doc, ">= 0.0.0", only: :dev}]
  end

  defp docs do
    [extras: ["README.md"]]
  end

  defp description do
    "An Ueberauth strategy for using Wechat to authenticate your users."
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["TianJun Zhao"],
      licenses: ["MIT"],
      links: %{"GitHub": "https://github.com/ZhuyiHome/ueberauth_wechat"}]
  end
end
