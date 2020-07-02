defmodule Rabbitmq.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Rabbitmq.Producer, rabbitmq_config()},
      {Rabbitmq.Consumer, rabbitmq_config()}
    ]

    opts = [strategy: :one_for_one, name: Rabbitmq.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp rabbitmq_config() do
    [
      host:         Application.fetch_env!(:rabbitmq, :host),
      username:     Application.fetch_env!(:rabbitmq, :user),
      password:     Application.fetch_env!(:rabbitmq, :password),
      port:         Application.fetch_env!(:rabbitmq, :port),
      virtual_host: Application.fetch_env!(:rabbitmq, :vhost),
    ]
  end
end
