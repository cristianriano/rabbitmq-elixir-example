defmodule Rabbitmq do
  @moduledoc """
  Test app to connect to RabbitMQ in Elixir
  """

  alias Rabbitmq.Producer

  def publish(key, msg) do
    Producer.publish(key, msg)
  end

  def publish_multiple(n) when is_integer(n) and n > 0 do
    for x <- 1..n do
      publish("order.created", %{data: "Message #{x}"})
    end
  end

  def publish_multiple(_), do: {:error, "Requires an integer > 0"}

  def publish_multiple(), do: publish_multiple(5)
end
