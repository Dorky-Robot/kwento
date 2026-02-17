defmodule Kwento.Repo.Migrations.CreateStories do
  use Ecto.Migration

  def change do
    create table(:stories) do
      add :title, :string, null: false
      add :slug, :string, null: false
      add :synopsis, :text
      add :visibility, :string, default: "public", null: false
      add :genre, :string
      add :repo_path, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :forked_from_id, references(:stories, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:stories, [:user_id])
    create unique_index(:stories, [:user_id, :slug])
    create index(:stories, [:visibility])
    create index(:stories, [:forked_from_id])
  end
end
