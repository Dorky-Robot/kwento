defmodule Kwento.Repo.Migrations.CreateStorylines do
  use Ecto.Migration

  def change do
    create table(:storylines) do
      add :name, :string, null: false
      add :display_name, :string
      add :description, :text
      add :is_default, :boolean, default: false, null: false
      add :story_id, references(:stories, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:storylines, [:story_id])
    create unique_index(:storylines, [:story_id, :name])
  end
end
