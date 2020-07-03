defmodule Rabbitmq.Consumer do
  use Broadway
  require Logger

  alias Broadway.Message

  @queue "test"

  def start_link(config) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {BroadwayRabbitMQ.Producer,
           queue: @queue,
           qos: [
             prefetch_count: 10
           ],
           metadata: [:content_type],
           connection: config},
        concurrency: 2
      ],
      processors: [
        default: [
          concurrency: 10
        ]
      ]
    )
  end

  @impl true
  def handle_message(_processor, %Message{metadata: %{content_type: "application/x-msgpack"}} = message, _) do
    data = Msgpax.unpack!(message.data)
    Logger.debug("Message received: «#{inspect(data)}»")
    message
  end

  def handle_message(_processor, %Message{data: data} = message, _conext) do
    Logger.debug("Message received «#{inspect(data)}»")
    message
  end
end
