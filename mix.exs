defmodule Rabbitmq.MixProject do
  use Mix.Project

  def project do
    [
      app: :rabbitmq,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Rabbitmq.Application, []}
    ]
  end

  defp deps do
    [
      {:amqp, "~> 1.5"},
      {:broadway_rabbitmq, "~> 0.6"},
      {:msgpax, "~> 2.2"}
    ]
  end
end
