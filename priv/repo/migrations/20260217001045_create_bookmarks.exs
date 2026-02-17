defmodule Kwento.Repo.Migrations.CreateBookmarks do
  use Ecto.Migration

  def change do
    create table(:bookmarks) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :story_id, references(:stories, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:bookmarks, [:user_id, :story_id])
    create index(:bookmarks, [:story_id])
  end
end
