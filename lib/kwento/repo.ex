defmodule Kwento.Repo do
  use Ecto.Repo,
    otp_app: :kwento,
    adapter: Ecto.Adapters.Postgres
end
