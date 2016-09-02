use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
config :mfa_mockup, MfaMockup.Endpoint,
  secret_key_base: "dGMKe2JoPZbTJ4Fymq+slr48t2i4BRfjJ5xCaYYt/M6JiqJp+xGBLy4ubZAPLNI0"

# Configure your database
config :mfa_mockup, MfaMockup.Repo,
  adapter: Ecto.Adapters.MySQL,
  username: "root",
  password: "",
  database: "mfa_mockup_prod",
  pool_size: 20
