defmodule Fuelex.Repo do
  use Ecto.Repo,
    otp_app: :fuelex,
    adapter: Ecto.Adapters.Postgres
end
