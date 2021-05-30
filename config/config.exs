# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :nerves_live_reload, NervesLiveReloadWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "a2UVboQg3IhWqAu/d3z9KrS/dw9aKSFKE1WOt9EvU2z8QVtAr3Yd8J7Ot5IeTIHl",
  render_errors: [view: NervesLiveReloadWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: NervesLiveReload.PubSub,
  live_view: [signing_salt: "HkLsnjBl"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
