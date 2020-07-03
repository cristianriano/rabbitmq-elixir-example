defmodule Rabbitmq.Producer do
  @moduledoc """
  This module sends messages to RabbitMQ
  """

  use GenServer
  require Logger

  alias AMQP.{Basic, Channel, Exchange, Queue}

  @queue "test"
  @exchange "test"
  @queue_error "#{@queue}_error"
  @routing_key "order.*"

  def publish(key, msg) do
    GenServer.cast(__MODULE__, {:publish, key, msg})
  end

  def start_link(%{conn_module: _mod} = args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(%{conn_module: conn_module}) do
    {:ok, conn} = conn_module.get_connection()
    {:ok, chan} = Channel.open(conn)
    setup_queue(chan)

    conn_module
    |> Process.whereis()
    |> Process.monitor()

    {:ok, %{chan: chan}}
  end

  @impl true
  def handle_cast({:publish, key, msg}, %{chan: chan} = state) do
    Logger.debug("Publishing...")

    payload = encode(msg)
    :ok = Basic.publish(chan, @exchange, key, payload,
      content_type: "application/x-msgpack"
    )
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, reason}, state) do
    {:stop, {:connection_lost, reason}, state}
  end

  @impl true
  def terminate(reason, %{chan: chan} = _state) do
    Logger.info("#{__MODULE__}: Closing RabbitMQ channel. #{inspect(reason)}")
    Channel.close(chan)
  end

  defp encode(msg) do
    msg |> Msgpax.pack!(iodata: false)
  end

  defp setup_queue(chan) do
    {:ok, _} = Queue.declare(chan, @queue_error, durable: true)

    # Messages that cannot be delivered to any consumer in the main queue will be routed to the error queue
    {:ok, _} =
      Queue.declare(chan, @queue,
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
