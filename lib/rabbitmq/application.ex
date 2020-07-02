defmodule Rabbitmq.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Rabbitmq.Producer
    ]

    opts = [strategy: :one_for_one, name: Rabbitmq.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
