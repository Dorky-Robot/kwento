defmodule Kwento.Git.DiffParser do
  @moduledoc """
  Parses unified diff output from git into structured data for rendering.
  """

  defmodule FileDiff do
    @moduledoc false
    defstruct [:old_file, :new_file, :hunks]
  end

  defmodule Hunk do
    @moduledoc false
    defstruct [:header, :old_start, :old_count, :new_start, :new_count, :lines]
  end

  defmodule Line do
    @moduledoc false
    defstruct [:type, :content, :old_line, :new_line]
  end

  @doc """
  Parse a unified diff string into a list of FileDiff structs.
  """
  def parse(diff_string) when is_binary(diff_string) do
    diff_string
    |> String.split("\n")
    |> parse_lines([], nil, nil)
    |> Enum.reverse()
  end

  defp parse_lines([], acc, nil, _current_hunk), do: acc

  defp parse_lines([], acc, current_file, current_hunk) do
    file = finalize_file(current_file, current_hunk)
    [file | acc]
  end

  defp parse_lines(["diff --git " <> _ | rest], acc, nil, _current_hunk) do
    parse_lines(rest, acc, %FileDiff{hunks: []}, nil)
  end

  defp parse_lines(["diff --git " <> _ | rest], acc, current_file, current_hunk) do
    file = finalize_file(current_file, current_hunk)
    parse_lines(rest, [file | acc], %FileDiff{hunks: []}, nil)
  end

  defp parse_lines(["--- " <> old_file | rest], acc, current_file, current_hunk) do
    old_file = String.trim_leading(old_file, "a/")
    parse_lines(rest, acc, %{current_file | old_file: old_file}, current_hunk)
  end

  defp parse_lines(["+++ " <> new_file | rest], acc, current_file, current_hunk) do
    new_file = String.trim_leading(new_file, "b/")
    parse_lines(rest, acc, %{current_file | new_file: new_file}, current_hunk)
  end

  defp parse_lines(["@@" <> _ = header | rest], acc, current_file, current_hunk) do
    current_file =
      if current_hunk do
        %{current_file | hunks: [finalize_hunk(current_hunk) | current_file.hunks]}
      else
        current_file
      end

    {old_start, old_count, new_start, new_count} = parse_hunk_header(header)

    new_hunk = %Hunk{
      header: header,
      old_start: old_start,
      old_count: old_count,
      new_start: new_start,
      new_count: new_count,
      lines: []
    }

    parse_lines(rest, acc, current_file, new_hunk)
  end

  defp parse_lines(["+" <> content | rest], acc, current_file, %Hunk{} = current_hunk) do
    line = %Line{type: :add, content: content}
    parse_lines(rest, acc, current_file, %{current_hunk | lines: [line | current_hunk.lines]})
  end

  defp parse_lines(["-" <> content | rest], acc, current_file, %Hunk{} = current_hunk) do
    line = %Line{type: :remove, content: content}
    parse_lines(rest, acc, current_file, %{current_hunk | lines: [line | current_hunk.lines]})
  end

  defp parse_lines([" " <> content | rest], acc, current_file, %Hunk{} = current_hunk) do
    line = %Line{type: :context, content: content}
    parse_lines(rest, acc, current_file, %{current_hunk | lines: [line | current_hunk.lines]})
  end

  defp parse_lines([_skip | rest], acc, current_file, current_hunk) do
    parse_lines(rest, acc, current_file, current_hunk)
  end

  defp finalize_file(file, nil), do: %{file | hunks: Enum.reverse(file.hunks)}

  defp finalize_file(file, hunk) do
    %{file | hunks: Enum.reverse([finalize_hunk(hunk) | file.hunks])}
  end

  defp finalize_hunk(hunk) do
    lines = Enum.reverse(hunk.lines)
    {numbered_lines, _, _} = number_lines(lines, hunk.old_start, hunk.new_start)
    %{hunk | lines: numbered_lines}
  end

  defp number_lines(lines, old_num, new_num) do
    Enum.reduce(lines, {[], old_num, new_num}, fn line, {acc, old_n, new_n} ->
      case line.type do
        :context ->
          {[%{line | old_line: old_n, new_line: new_n} | acc], old_n + 1, new_n + 1}

        :add ->
          {[%{line | old_line: nil, new_line: new_n} | acc], old_n, new_n + 1}

        :remove ->
          {[%{line | old_line: old_n, new_line: nil} | acc], old_n + 1, new_n}
      end
    end)
    |> then(fn {lines, old_n, new_n} -> {Enum.reverse(lines), old_n, new_n} end)
  end

  defp parse_hunk_header(header) do
    case Regex.run(~r/@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@/, header) do
      [_, old_start, old_count, new_start, new_count] ->
        {String.to_integer(old_start), String.to_integer(old_count),
         String.to_integer(new_start), String.to_integer(new_count)}

      [_, old_start, "", new_start, new_count] ->
        {String.to_integer(old_start), 1, String.to_integer(new_start),
         String.to_integer(new_count)}

      [_, old_start, old_count, new_start, ""] ->
        {String.to_integer(old_start), String.to_integer(old_count),
         String.to_integer(new_start), 1}

      [_, old_start, "", new_start, ""] ->
        {String.to_integer(old_start), 1, String.to_integer(new_start), 1}

      _ ->
        {1, 0, 1, 0}
    end
  end
end
