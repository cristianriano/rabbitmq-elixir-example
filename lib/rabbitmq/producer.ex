defmodule Rabbitmq.Producer do
  @moduledoc """
  This module sends messages to RabbitMQ
  """

  use GenServer
  require Logger

  alias AMQP.{Basic, Channel, Exchange, Queue}

  def publish(topic, msg) do
    GenServer.cast(__MODULE__, {:publish, topic, msg})
  end

  def start_link(%{conn_module: _, exchange: _, error_queue: _} = args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(%{conn_module: conn_module, exchange: exchange, error_queue: error_queue}) do
    {:ok, conn} = conn_module.get_connection()
    {:ok, chan} = Channel.open(conn)
    setup_error_queue(chan, error_queue)
    setup_exchange(chan, exchange)

    conn_module
    |> Process.whereis()
    |> Process.monitor()

    {:ok, %{chan: chan, exchange: exchange}}
  end

  @impl true
  def handle_cast({:publish, topic, msg}, %{chan: chan, exchange: ex} = state) do
    Logger.debug("Publishing...")

    payload = encode(msg)
    :ok = Basic.publish(chan, ex, topic, payload,
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

  defp setup_error_queue(chan, error_queue) do
    {:ok, _} = Queue.declare(chan, error_queue, durable: true)
  end

  defp setup_exchange(chan, exchange) do
    :ok = Exchange.topic(chan, exchange, durable: true)
  end
end
