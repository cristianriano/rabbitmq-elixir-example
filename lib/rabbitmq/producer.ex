defmodule Rabbitmq.Producer do
  @moduledoc """
  This module sends messages to RabbitMQ
  """

  use GenServer
  require Logger

  alias AMQP.{Basic, Channel, Connection, Exchange, Queue}

  @queue "test"
  @exchange "test"
  @queue_error "#{@queue}_error"
  @routing_key "order.*"

  def publish(key, msg) do
    GenServer.cast(__MODULE__, {:publish, key, msg})
  end

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, conn} = Connection.open("amqp://admin:pass@localhost:5672/test")
    {:ok, chan} = Channel.open(conn)
    setup_queue(chan)

    # Limit unacknowledged messages to 10
    # :ok = Basic.qos(chan, prefetch_count: 10)
    # Register the GenServer process as a consumer
    # {:ok, _consumer_tag} = Basic.consume(chan, @queue)

    {:ok, %{chan: chan}}
  end

  def handle_cast({:publish, key, msg}, %{chan: chan} = state) do
    Logger.debug("Publishing msg: `#{inspect(msg)}`")
    Basic.publish(chan, @exchange, key, msg, [])
    {:noreply, state}
  end

  defp setup_queue(chan) do
    {:ok, _} = Queue.declare(chan, @queue_error, durable: true)
    # Messages that cannot be delivered to any consumer in the main queue will be routed to the error queue
    {:ok, _} = Queue.declare(chan, @queue,
                             durable: true,
                             arguments: [
                               {"x-dead-letter-exchange", :longstr, ""},
                               {"x-dead-letter-routing-key", :longstr, @queue_error}
                             ]
                            )
    :ok = Exchange.topic(chan, @exchange, durable: true)
    :ok = Queue.bind(chan, @queue, @exchange, routing_key: @routing_key)
  end
end
