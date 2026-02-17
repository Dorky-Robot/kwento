defmodule Kwento.Stories.Bookmark do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bookmarks" do
    belongs_to :user, Kwento.Accounts.User
    belongs_to :story, Kwento.Stories.Story

    timestamps(type: :utc_datetime)
  end

  def changeset(bookmark, attrs) do
    bookmark
    |> cast(attrs, [:user_id, :story_id])
    |> validate_required([:user_id, :story_id])
    |> unique_constraint([:user_id, :story_id])
  end
end
