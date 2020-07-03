defmodule Rabbitmq.Consumer do
  use Broadway
  require Logger

  alias Broadway.Message

  @queue "test"

  def start_link(%{config: config, routing_keys: keys, error_queue: error_queue, exchange: exchange}) do
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
           declare: [
             durable: true,
             arguments: [
              {"x-dead-letter-exchange", :longstr, ""},
              {"x-dead-letter-routing-key", :longstr, error_queue}
             ]
           ],
           bindings: Enum.map(keys, &{exchange, routing_key: &1}),
           connection: config},
        concurrency: 1
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
