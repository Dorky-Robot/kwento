defmodule Kwento.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notifications" do
    field :type, :string
    field :message, :string
    field :read, :boolean, default: false
    field :path, :string

    belongs_to :user, Kwento.Accounts.User
    belongs_to :actor, Kwento.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:type, :message, :path, :user_id, :actor_id])
    |> validate_required([:type, :message, :user_id])
  end
end
