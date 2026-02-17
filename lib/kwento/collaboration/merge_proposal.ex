defmodule Kwento.Collaboration.MergeProposal do
  use Ecto.Schema
  import Ecto.Changeset

  schema "merge_proposals" do
    field :title, :string
    field :description, :string
    field :status, Ecto.Enum, values: [:open, :merged, :closed], default: :open
    field :source_storyline, :string
    field :target_storyline, :string

    belongs_to :story, Kwento.Stories.Story
    belongs_to :author, Kwento.Accounts.User
    has_many :comments, Kwento.Collaboration.Comment

    timestamps(type: :utc_datetime)
  end

  def changeset(proposal, attrs) do
    proposal
    |> cast(attrs, [:title, :description, :source_storyline, :target_storyline])
    |> validate_required([:title, :source_storyline, :target_storyline])
    |> validate_length(:title, min: 1, max: 200)
  end

  def status_changeset(proposal, status) do
    proposal
    |> change(status: status)
  end
end
