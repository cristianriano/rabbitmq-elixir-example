defmodule Rabbitmq.Application do
  @moduledoc false

  use Application

  @exchange "test"
  @error_queue "test_error"

  def start(_type, _args) do
    children = [
      {Rabbitmq.Connection, rabbitmq_config()},
      {Rabbitmq.Producer, %{
        conn_module: Rabbitmq.Connection,
        exchange: @exchange,
        error_queue: @error_queue
        }
      },
      {Rabbitmq.Consumer, %{
        config: rabbitmq_config(),
        routing_keys: ~w[order.* user.*],
        error_queue: @error_queue,
        exchange: @exchange
        }
      }
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
      virtual_host: Application.fetch_env!(:rabbitmq, :vhost)
    ]
  end
end
