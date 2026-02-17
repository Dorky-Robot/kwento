defmodule Kwento.Repo.Migrations.CreateThreads do
  use Ecto.Migration

  def change do
    create table(:threads) do
      add :title, :string, null: false
      add :body, :text, null: false
      add :status, :string, default: "open", null: false
      add :labels, {:array, :string}, default: []
      add :story_id, references(:stories, on_delete: :delete_all), null: false
      add :author_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:threads, [:story_id])
    create index(:threads, [:author_id])
    create index(:threads, [:status])
  end
end
