defmodule Kwento.Git do
  @moduledoc """
  Core module wrapping git CLI operations via System.cmd/3.
  All paths should be absolute paths to git repositories.
  """

  @doc """
  Initialize a new git repository with an initial empty commit.
  """
  def init_repo(path) do
    with :ok <- File.mkdir_p(path),
         {_, 0} <- System.cmd("git", ["init"], cd: path, stderr_to_stdout: true),
         {_, 0} <-
           System.cmd("git", ["config", "user.email", "kwento@local"],
             cd: path,
             stderr_to_stdout: true
           ),
         {_, 0} <-
           System.cmd("git", ["config", "user.name", "Kwento"],
             cd: path,
             stderr_to_stdout: true
           ) do
      # Create initial commit with a README-like file
      {:ok, path}
    else
      {:error, reason} -> {:error, reason}
      {output, _code} -> {:error, output}
    end
  end

  @doc """
  Write files and create a commit.
  content_map is a map of %{"filename" => "content"}.
  """
  def commit(path, message, author, content_map) when is_map(content_map) do
    # Write all files
    Enum.each(content_map, fn {filename, content} ->
      file_path = Path.join(path, filename)
      File.mkdir_p!(Path.dirname(file_path))
      File.write!(file_path, content)
    end)

    filenames = Map.keys(content_map)

    with {_, 0} <- System.cmd("git", ["add" | filenames], cd: path, stderr_to_stdout: true),
         {_, 0} <-
           System.cmd(
             "git",
             [
               "commit",
               "-m",
               message,
               "--author",
               author,
               "--allow-empty-message"
             ],
             cd: path,
             stderr_to_stdout: true
           ) do
      {:ok, get_head_sha(path)}
    else
      {output, _code} -> {:error, output}
    end
  end

  @doc """
  Create a new branch from the given ref (defaults to HEAD).
  """
  def create_branch(path, branch_name, from \\ "HEAD") do
    case System.cmd("git", ["branch", branch_name, from], cd: path, stderr_to_stdout: true) do
      {_, 0} -> :ok
      {output, _} -> {:error, output}
    end
  end

  @doc """
  List all branches in the repository.
  """
  def list_branches(path) do
    case System.cmd("git", ["branch", "--list", "--format=%(refname:short)"],
           cd: path,
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        branches =
          output
          |> String.trim()
          |> String.split("\n", trim: true)

        {:ok, branches}

      {output, _} ->
        {:error, output}
    end
  end

  @doc """
  Read file content at a specific branch/ref.
  """
  def read_file(path, branch, file_path) do
    case System.cmd("git", ["show", "#{branch}:#{file_path}"],
           cd: path,
           stderr_to_stdout: true
         ) do
      {content, 0} -> {:ok, content}
      {output, _} -> {:error, output}
    end
  end

  @doc """
  Get commit history for a branch.
  opts can include :limit (integer).
  """
  def log(path, branch, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    args = [
      "log",
      branch,
      "--format=%H|%an|%ae|%at|%s",
      "-n",
      to_string(limit)
    ]

    case System.cmd("git", args, cd: path, stderr_to_stdout: true) do
      {output, 0} ->
        commits =
          output
          |> String.trim()
          |> String.split("\n", trim: true)
          |> Enum.map(&parse_log_line/1)

        {:ok, commits}

      {output, _} ->
        {:error, output}
    end
  end

  @doc """
  Diff between two refs (branches, commits, etc).
  """
  def diff(path, ref_a, ref_b) do
    case System.cmd("git", ["diff", ref_a, ref_b], cd: path, stderr_to_stdout: true) do
      {output, 0} -> {:ok, output}
      {output, _} -> {:error, output}
    end
  end

  @doc """
  Merge source_branch into target_branch.
  Checks out target, merges source, then returns to original branch.
  """
  def merge(path, source_branch, target_branch) do
    original_branch = get_current_branch(path)

    with {_, 0} <-
           System.cmd("git", ["checkout", target_branch], cd: path, stderr_to_stdout: true),
         {_, 0} <-
           System.cmd(
             "git",
             ["merge", source_branch, "-m", "Merge #{source_branch} into #{target_branch}"],
             cd: path,
             stderr_to_stdout: true
           ) do
      # Return to original branch if different
      if original_branch && original_branch != target_branch do
        System.cmd("git", ["checkout", original_branch], cd: path, stderr_to_stdout: true)
      end

      {:ok, get_head_sha(path)}
    else
      {output, _code} ->
        # Abort merge if it failed
        System.cmd("git", ["merge", "--abort"], cd: path, stderr_to_stdout: true)

        if original_branch do
          System.cmd("git", ["checkout", original_branch], cd: path, stderr_to_stdout: true)
        end

        {:error, output}
    end
  end

  @doc """
  Check if a merge between source and target would be clean.
  Returns :ok if clean, {:conflict, details} if not.
  """
  def merge_check(path, source_branch, target_branch) do
    # Use merge-tree for a non-destructive check
    case System.cmd(
           "git",
           ["merge-tree", "--write-tree", target_branch, source_branch],
           cd: path,
           stderr_to_stdout: true
         ) do
      {_, 0} -> :ok
      {output, _} -> {:conflict, output}
    end
  end

  @doc """
  Clone a repository (for forks).
  """
  def clone(source_path, dest_path) do
    with :ok <- File.mkdir_p(Path.dirname(dest_path)),
         {_, 0} <-
           System.cmd("git", ["clone", source_path, dest_path], stderr_to_stdout: true),
         {_, 0} <-
           System.cmd("git", ["config", "user.email", "kwento@local"],
             cd: dest_path,
             stderr_to_stdout: true
           ),
         {_, 0} <-
           System.cmd("git", ["config", "user.name", "Kwento"],
             cd: dest_path,
             stderr_to_stdout: true
           ) do
      {:ok, dest_path}
    else
      {:error, reason} -> {:error, reason}
      {output, _code} -> {:error, output}
    end
  end

  @doc """
  Checkout a branch (used internally for writing to specific branches).
  """
  def checkout(path, branch) do
    case System.cmd("git", ["checkout", branch], cd: path, stderr_to_stdout: true) do
      {_, 0} -> :ok
      {output, _} -> {:error, output}
    end
  end

  # Private helpers

  defp get_head_sha(path) do
    case System.cmd("git", ["rev-parse", "HEAD"], cd: path, stderr_to_stdout: true) do
      {sha, 0} -> String.trim(sha)
      _ -> nil
    end
  end

  defp get_current_branch(path) do
    case System.cmd("git", ["rev-parse", "--abbrev-ref", "HEAD"],
           cd: path,
           stderr_to_stdout: true
         ) do
      {branch, 0} -> String.trim(branch)
      _ -> nil
    end
  end

  defp parse_log_line(line) do
    case String.split(line, "|", parts: 5) do
      [sha, name, email, timestamp, message] ->
        %{
          sha: sha,
          author_name: name,
          author_email: email,
          timestamp: parse_unix_timestamp(timestamp),
          message: message
        }

      _ ->
        %{sha: line, author_name: "", author_email: "", timestamp: nil, message: ""}
    end
  end

  defp parse_unix_timestamp(ts_string) do
    case Integer.parse(ts_string) do
      {ts, _} -> DateTime.from_unix!(ts)
      :error -> nil
    end
  end
end
