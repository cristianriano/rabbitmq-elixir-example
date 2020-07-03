import Config

config :rabbitmq,
  host: "localhost",
  port: 5672,
  user: "admin",
  password: "pass",
  vhost: "test"

# AMQP supervisors are too verbose
config :logger, handle_otp_reports: false
