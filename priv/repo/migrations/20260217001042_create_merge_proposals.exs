defmodule Kwento.Repo.Migrations.CreateMergeProposals do
  use Ecto.Migration

  def change do
    create table(:merge_proposals) do
      add :title, :string, null: false
      add :description, :text
      add :status, :string, default: "open", null: false
      add :source_storyline, :string, null: false
      add :target_storyline, :string, null: false
      add :story_id, references(:stories, on_delete: :delete_all), null: false
      add :author_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:merge_proposals, [:story_id])
    create index(:merge_proposals, [:author_id])
    create index(:merge_proposals, [:status])
  end
end
