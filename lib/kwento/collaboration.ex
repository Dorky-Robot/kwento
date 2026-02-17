defmodule Kwento.Collaboration do
  @moduledoc """
  Context for merge proposals, threads, and comments.
  """

  import Ecto.Query, warn: false
  alias Kwento.Repo
  alias Kwento.Git
  alias Kwento.Git.DiffParser
  alias Kwento.Collaboration.{MergeProposal, Thread, Comment}

  ## Merge Proposals

  def list_proposals(story, opts \\ []) do
    status = Keyword.get(opts, :status)

    MergeProposal
    |> where(story_id: ^story.id)
    |> maybe_filter_status(status)
    |> order_by(desc: :inserted_at)
    |> preload(:author)
    |> Repo.all()
  end

  def get_proposal!(id) do
    MergeProposal
    |> Repo.get!(id)
    |> Repo.preload([:author, :story, comments: :author])
  end

  def create_proposal(story, user, attrs) do
    %MergeProposal{story_id: story.id, author_id: user.id}
    |> MergeProposal.changeset(attrs)
    |> Repo.insert()
  end

  def merge_proposal(proposal) do
    proposal = Repo.preload(proposal, :story)
    story = proposal.story

    case Git.merge(story.repo_path, proposal.source_storyline, proposal.target_storyline) do
      {:ok, _sha} ->
        proposal
        |> MergeProposal.status_changeset(:merged)
        |> Repo.update()

      {:error, reason} ->
        {:error, reason}
    end
  end

  def close_proposal(proposal) do
    proposal
    |> MergeProposal.status_changeset(:closed)
    |> Repo.update()
  end

  def get_proposal_diff(proposal) do
    proposal = Repo.preload(proposal, :story)
    story = proposal.story

    case Git.diff(story.repo_path, proposal.target_storyline, proposal.source_storyline) do
      {:ok, raw_diff} -> {:ok, DiffParser.parse(raw_diff)}
      {:error, reason} -> {:error, reason}
    end
  end

  def change_proposal(proposal, attrs \\ %{}) do
    MergeProposal.changeset(proposal, attrs)
  end

  ## Threads

  def list_threads(story, opts \\ []) do
    status = Keyword.get(opts, :status)

    Thread
    |> where(story_id: ^story.id)
    |> maybe_filter_status(status)
    |> order_by(desc: :inserted_at)
    |> preload(:author)
    |> Repo.all()
  end

  def get_thread!(id) do
    Thread
    |> Repo.get!(id)
    |> Repo.preload([:author, :story, comments: :author])
  end

  def create_thread(story, user, attrs) do
    %Thread{story_id: story.id, author_id: user.id}
    |> Thread.changeset(attrs)
    |> Repo.insert()
  end

  def close_thread(thread) do
    thread
    |> Thread.status_changeset(:closed)
    |> Repo.update()
  end

  def reopen_thread(thread) do
    thread
    |> Thread.status_changeset(:open)
    |> Repo.update()
  end

  def change_thread(thread, attrs \\ %{}) do
    Thread.changeset(thread, attrs)
  end

  ## Comments

  def create_comment(attrs) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Ecto.Changeset.cast(attrs, [:author_id, :thread_id, :merge_proposal_id])
    |> Repo.insert()
  end

  def list_comments_for_thread(thread_id) do
    Comment
    |> where(thread_id: ^thread_id)
    |> order_by(asc: :inserted_at)
    |> preload(:author)
    |> Repo.all()
  end

  def list_comments_for_proposal(proposal_id) do
    Comment
    |> where(merge_proposal_id: ^proposal_id)
    |> order_by(asc: :inserted_at)
    |> preload(:author)
    |> Repo.all()
  end

  ## Helpers

  defp maybe_filter_status(query, nil), do: query
  defp maybe_filter_status(query, status), do: where(query, status: ^status)
end
