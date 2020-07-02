defmodule Rabbitmq do
  @moduledoc """
  Test app to connect to RabbitMQ in Elixir
  """

  alias Rabbitmq.Producer

  def publish(key, msg) do
    Producer.publish(key, msg)
  end
end
