defmodule Kwento.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :body, :text, null: false
      add :author_id, references(:users, on_delete: :delete_all), null: false
      add :thread_id, references(:threads, on_delete: :delete_all)
      add :merge_proposal_id, references(:merge_proposals, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:comments, [:author_id])
    create index(:comments, [:thread_id])
    create index(:comments, [:merge_proposal_id])
  end
end
