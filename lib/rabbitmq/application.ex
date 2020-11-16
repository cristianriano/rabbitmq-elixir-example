defmodule Rabbitmq.Application do
  @moduledoc false

  use Application

  @exchange "events"
  @queue "test"
  @error_queue "error_test"

  def start(_type, _args) do
    children = [
      {Rabbitmq.Connection, rabbitmq_config()},
      {Rabbitmq.Producer,
       %{
         conn_module: Rabbitmq.Connection,
         exchange: @exchange,
         error_queue: @error_queue
       }},
      {Rabbitmq.Consumer,
       %{
         config: rabbitmq_config(),
         routing_keys: ~w[user.game_session.started],
         error_queue: @error_queue,
         exchange: @exchange,
         queue: @queue
       }}
    ]

    opts = [strategy: :one_for_one, name: Rabbitmq.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp rabbitmq_config() do
    [
      host: Application.fetch_env!(:rabbitmq, :host),
      username: Application.fetch_env!(:rabbitmq, :user),
      password: Application.fetch_env!(:rabbitmq, :password),
      port: Application.fetch_env!(:rabbitmq, :port),
      virtual_host: Application.fetch_env!(:rabbitmq, :vhost),
      heartbeat: Application.get_env(:rabbitmq, :heartbeat, 15)
    ]
  end
end
