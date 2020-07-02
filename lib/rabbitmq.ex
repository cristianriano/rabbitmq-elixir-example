defmodule Rabbitmq do
  @moduledoc """
  Test app to connect to RabbitMQ in Elixir
  """

  alias Rabbitmq.Producer

  def publish(key, msg) do
    Producer.publish(key, msg)
  end

  def publish_multiple(n) when is_integer(n) and n > 0 do
    for x <- 0..n do
      publish("order.created", "Message #{x}")
    end
  end

  def publish_multiple(_), do: :error
end
