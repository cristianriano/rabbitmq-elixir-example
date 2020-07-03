defmodule Rabbitmq.Connection do
  @moduledoc """
  This module handles the RabbitMQ connection and re-connection
  """

  use GenServer
  require Logger

  alias AMQP.Connection

  @reconnect_after 5_000

  def get_connection() do
    case GenServer.call(__MODULE__, :get) do
      nil -> {:error, :not_connected}
      conn -> {:ok, conn}
    end
  end

  def start_link(config) do
    GenServer.start_link(__MODULE__, %{config: config}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state, {:continue, :connect}}
  end

  def handle_call(:get, _from, %{conn: conn} = state) do
    {:reply, conn, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, reason}, _) do
    # Stop GenServer. Will be restarted by Supervisor.
    {:stop, {:connection_lost, reason}, nil}
  end

  def handle_info(:connect, state), do: {:noreply, connect(state)}

  def handle_continue(:connect, state), do: {:noreply, connect(state)}

  defp connect(%{config: config} = state) do
    with {:ok, conn} <- Connection.open(config) do
      Logger.info("#{__MODULE__}: Connected to RabbitMQ")
      Process.monitor(conn.pid)

      %{config: config, conn: conn}
    else
      {:error, _} ->
        host = Keyword.get(config, :host)
        Logger.error("#{__MODULE__}: Failed to connect #{host}")

        Process.send_after(self(), :connect, @reconnect_after)
        state
    end
  end
end
