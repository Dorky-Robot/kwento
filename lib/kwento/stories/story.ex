defmodule Kwento.Stories.Story do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stories" do
    field :title, :string
    field :slug, :string
    field :synopsis, :string
    field :visibility, Ecto.Enum, values: [:public, :private], default: :public
    field :genre, :string
    field :repo_path, :string

    belongs_to :user, Kwento.Accounts.User
    belongs_to :forked_from, Kwento.Stories.Story
    has_many :storylines, Kwento.Stories.Storyline
    has_many :bookmarks, Kwento.Stories.Bookmark
    has_many :threads, Kwento.Collaboration.Thread
    has_many :merge_proposals, Kwento.Collaboration.MergeProposal

    timestamps(type: :utc_datetime)
  end

  def changeset(story, attrs) do
    story
    |> cast(attrs, [:title, :synopsis, :visibility, :genre])
    |> validate_required([:title])
    |> validate_length(:title, min: 1, max: 200)
    |> validate_length(:synopsis, max: 2000)
    |> generate_slug()
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :title) do
      nil ->
        changeset

      title ->
        slug =
          title
          |> String.downcase()
          |> String.replace(~r/[^a-z0-9\s-]/, "")
          |> String.replace(~r/\s+/, "-")
          |> String.trim("-")
          |> String.slice(0, 80)

        put_change(changeset, :slug, slug)
    end
  end
end
