defmodule Kwento.Stories.Storyline do
  use Ecto.Schema
  import Ecto.Changeset

  schema "storylines" do
    field :name, :string
    field :display_name, :string
    field :description, :string
    field :is_default, :boolean, default: false

    belongs_to :story, Kwento.Stories.Story

    timestamps(type: :utc_datetime)
  end

  def changeset(storyline, attrs) do
    storyline
    |> cast(attrs, [:name, :display_name, :description, :is_default])
    |> validate_required([:name])
    |> validate_format(:name, ~r/^[a-zA-Z0-9][a-zA-Z0-9._\/-]*$/,
      message: "must be a valid branch name"
    )
    |> validate_length(:name, max: 100)
    |> validate_length(:display_name, max: 200)
  end
end
