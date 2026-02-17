defmodule Kwento.Notifications do
  @moduledoc """
  Context for user notifications with PubSub for real-time delivery.
  """

  import Ecto.Query, warn: false
  alias Kwento.Repo
  alias Kwento.Notifications.Notification

  def list_notifications(user, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    Notification
    |> where(user_id: ^user.id)
    |> order_by(desc: :inserted_at)
    |> limit(^limit)
    |> preload(:actor)
    |> Repo.all()
  end

  def unread_count(user) do
    Notification
    |> where(user_id: ^user.id, read: false)
    |> Repo.aggregate(:count)
  end

  def mark_as_read(notification) do
    notification
    |> Ecto.Changeset.change(read: true)
    |> Repo.update()
  end

  def mark_all_as_read(user) do
    Notification
    |> where(user_id: ^user.id, read: false)
    |> Repo.update_all(set: [read: true])
  end

  def create_notification(attrs) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
    |> tap(fn
      {:ok, notification} -> broadcast_notification(notification)
      _ -> :ok
    end)
  end

  def notify(user_id, actor_id, type, message, path \\ nil) do
    create_notification(%{
      user_id: user_id,
      actor_id: actor_id,
      type: type,
      message: message,
      path: path
    })
  end

  def subscribe(user_id) do
    Phoenix.PubSub.subscribe(Kwento.PubSub, "notifications:#{user_id}")
  end

  defp broadcast_notification(notification) do
    Phoenix.PubSub.broadcast(
      Kwento.PubSub,
      "notifications:#{notification.user_id}",
      {:new_notification, notification}
    )
  end
end
