defmodule Kwento.Collaboration.Thread do
  use Ecto.Schema
  import Ecto.Changeset

  schema "threads" do
    field :title, :string
    field :body, :string
    field :status, Ecto.Enum, values: [:open, :closed], default: :open
    field :labels, {:array, :string}, default: []

    belongs_to :story, Kwento.Stories.Story
    belongs_to :author, Kwento.Accounts.User
    has_many :comments, Kwento.Collaboration.Comment

    timestamps(type: :utc_datetime)
  end

  def changeset(thread, attrs) do
    thread
    |> cast(attrs, [:title, :body, :labels])
    |> validate_required([:title, :body])
    |> validate_length(:title, min: 1, max: 200)
  end

  def status_changeset(thread, status) do
    thread
    |> change(status: status)
  end
end
