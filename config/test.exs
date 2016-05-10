use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :thumber, Thumber.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :thumber, Thumber.Repo,
  adapter: Sqlite.Ecto,
  database: "db/thumber_test.sqlite",
  pool: Ecto.Adapters.SQL.Sandbox
