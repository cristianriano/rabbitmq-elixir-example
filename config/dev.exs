import Config

config :rabbitmq,
  host: "localhost",
  port: 5672,
  user: "guest",
  password: "guest",
  vhost: "pmp_development"

# AMQP supervisors are too verbose
config :logger, handle_otp_reports: false
