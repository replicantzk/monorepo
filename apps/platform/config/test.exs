import Config

get_env = fn name, default, type ->
  case System.get_env(name) do
    nil ->
      default

    var ->
      case type do
        :int -> String.to_integer(var)
        :float -> String.to_float(var)
        :bool -> var == "true"
        :string -> var
      end
  end
end

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :platform, Platform.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "platform_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  port: get_env.("PLATFORM_DB_PORT", 5432, :int)

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :platform, PlatformWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "KWEAOLSlgeQcBbAL2yklokPk+YBLKNjlGdmGfVBDefwW+dxgWSKVbsAl1gaSubsc",
  server: false

# In test we don't send emails.
config :platform, Platform.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
