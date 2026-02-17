defmodule Kwento.Collaboration.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :body, :string

    belongs_to :author, Kwento.Accounts.User
    belongs_to :thread, Kwento.Collaboration.Thread
    belongs_to :merge_proposal, Kwento.Collaboration.MergeProposal

    timestamps(type: :utc_datetime)
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body])
    |> validate_required([:body])
    |> validate_length(:body, min: 1, max: 10_000)
  end
end
