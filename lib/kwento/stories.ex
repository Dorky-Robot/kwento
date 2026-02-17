defmodule Kwento.Stories do
  @moduledoc """
  The Stories context - manages stories, storylines, and their git-backed content.
  """

  import Ecto.Query, warn: false
  alias Kwento.Repo
  alias Kwento.Git
  alias Kwento.Stories.{Story, Storyline, Bookmark}

  ## Stories

  def list_public_stories(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)
    sort = Keyword.get(opts, :sort, :recent)

    Story
    |> where(visibility: :public)
    |> sort_stories(sort)
    |> limit(^limit)
    |> offset(^offset)
    |> preload(:user)
    |> Repo.all()
  end

  def list_user_stories(user) do
    Story
    |> where(user_id: ^user.id)
    |> order_by(desc: :updated_at)
    |> preload(:user)
    |> Repo.all()
  end

  def list_user_public_stories(user) do
    Story
    |> where(user_id: ^user.id, visibility: :public)
    |> order_by(desc: :updated_at)
    |> preload(:user)
    |> Repo.all()
  end

  def get_story!(id), do: Repo.get!(Story, id) |> Repo.preload(:user)

  def get_story(username, slug) do
    query =
      from s in Story,
        join: u in assoc(s, :user),
        where: u.username == ^String.downcase(username) and s.slug == ^slug,
        preload: [user: u, storylines: ^from(sl in Storyline, order_by: [desc: sl.is_default])]

    Repo.one(query)
  end

  def create_story(user, attrs) do
    changeset =
      %Story{user_id: user.id}
      |> Story.changeset(attrs)

    Repo.transact(fn ->
      with {:ok, story} <- Repo.insert(changeset) do
        repo_path = build_repo_path(user.id, story.slug)

        story = Repo.update!(Ecto.Changeset.change(story, repo_path: repo_path))

        with {:ok, _} <- Git.init_repo(repo_path) do
          # Create initial content file
          author = "#{user.display_name || user.username} <#{user.email}>"
          synopsis = story.synopsis || "A new story."

          Git.commit(repo_path, "Begin story: #{story.title}", author, %{
            "story.md" => "# #{story.title}\n\n#{synopsis}\n"
          })

          # Create the default storyline
          {:ok, _storyline} =
            %Storyline{story_id: story.id}
            |> Storyline.changeset(%{
              name: "main",
              display_name: "Main Storyline",
              is_default: true
            })
            |> Repo.insert()

          {:ok, Repo.preload(story, [:user, :storylines])}
        end
      end
    end)
  end

  def update_story(story, attrs) do
    story
    |> Story.changeset(attrs)
    |> Repo.update()
  end

  def delete_story(story) do
    # Remove the git repo from disk
    if story.repo_path && File.exists?(story.repo_path) do
      File.rm_rf!(story.repo_path)
    end

    Repo.delete(story)
  end

  def change_story(story, attrs \\ %{}) do
    Story.changeset(story, attrs)
  end

  ## Content (git-backed)

  def read_content(story, storyline_name \\ "main") do
    Git.read_file(story.repo_path, storyline_name, "story.md")
  end

  def save_content(story, storyline_name, user, content, message) do
    author = "#{user.display_name || user.username} <#{user.email}>"

    # Checkout the branch first
    with :ok <- Git.checkout(story.repo_path, storyline_name) do
      Git.commit(story.repo_path, message, author, %{"story.md" => content})
    end
  end

  def list_revisions(story, storyline_name \\ "main", opts \\ []) do
    Git.log(story.repo_path, storyline_name, opts)
  end

  ## Storylines

  def list_storylines(story) do
    Storyline
    |> where(story_id: ^story.id)
    |> order_by(desc: :is_default, asc: :name)
    |> Repo.all()
  end

  def get_storyline!(id), do: Repo.get!(Storyline, id)

  def get_default_storyline(story) do
    Storyline
    |> where(story_id: ^story.id, is_default: true)
    |> Repo.one()
  end

  def create_storyline(story, attrs) do
    name = Map.get(attrs, "name") || Map.get(attrs, :name)
    from_branch = Map.get(attrs, "from", "main") || Map.get(attrs, :from, "main")

    Repo.transact(fn ->
      with :ok <- Git.create_branch(story.repo_path, name, from_branch) do
        %Storyline{story_id: story.id}
        |> Storyline.changeset(attrs)
        |> Repo.insert()
      end
    end)
  end

  ## Forks

  def fork_story(story, user) do
    story = Repo.preload(story, [:user, :storylines])
    new_slug = story.slug
    new_repo_path = build_repo_path(user.id, new_slug)

    Repo.transact(fn ->
      with {:ok, _} <- Git.clone(story.repo_path, new_repo_path) do
        {:ok, forked_story} =
          %Story{
            title: story.title,
            slug: new_slug,
            synopsis: story.synopsis,
            visibility: story.visibility,
            genre: story.genre,
            repo_path: new_repo_path,
            user_id: user.id,
            forked_from_id: story.id
          }
          |> Repo.insert()

        # Copy storylines
        for sl <- story.storylines do
          %Storyline{story_id: forked_story.id}
          |> Storyline.changeset(%{
            name: sl.name,
            display_name: sl.display_name,
            description: sl.description,
            is_default: sl.is_default
          })
          |> Repo.insert!()
        end

        {:ok, Repo.preload(forked_story, [:user, :storylines])}
      end
    end)
  end

  ## Bookmarks

  def bookmark_story(user, story) do
    %Bookmark{}
    |> Bookmark.changeset(%{user_id: user.id, story_id: story.id})
    |> Repo.insert()
  end

  def unbookmark_story(user, story) do
    Bookmark
    |> where(user_id: ^user.id, story_id: ^story.id)
    |> Repo.delete_all()

    :ok
  end

  def bookmarked?(user, story) do
    Bookmark
    |> where(user_id: ^user.id, story_id: ^story.id)
    |> Repo.exists?()
  end

  def bookmark_count(story) do
    Bookmark
    |> where(story_id: ^story.id)
    |> Repo.aggregate(:count)
  end

  def fork_count(story) do
    Story
    |> where(forked_from_id: ^story.id)
    |> Repo.aggregate(:count)
  end

  ## Search

  def search_stories(query_string, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    pattern = "%#{query_string}%"

    Story
    |> where(visibility: :public)
    |> where([s], ilike(s.title, ^pattern) or ilike(s.synopsis, ^pattern))
    |> limit(^limit)
    |> preload(:user)
    |> Repo.all()
  end

  ## Helpers

  defp build_repo_path(user_id, slug) do
    base = Application.get_env(:kwento, :git_repos_path, "priv/repos")
    Path.join([base, to_string(user_id), slug])
  end

  defp sort_stories(query, :recent), do: order_by(query, desc: :updated_at)

  defp sort_stories(query, :bookmarks) do
    from s in query,
      left_join: b in Bookmark,
      on: b.story_id == s.id,
      group_by: s.id,
      order_by: [desc: count(b.id)]
  end

  defp sort_stories(query, :forks) do
    from s in query,
      left_join: f in Story,
      on: f.forked_from_id == s.id,
      group_by: s.id,
      order_by: [desc: count(f.id)]
  end

  defp sort_stories(query, _), do: order_by(query, desc: :updated_at)
end
