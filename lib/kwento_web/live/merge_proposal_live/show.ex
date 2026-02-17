defmodule KwentoWeb.MergeProposalLive.Show do
  use KwentoWeb, :live_view

  alias Kwento.Stories
  alias Kwento.Collaboration

  @impl true
  def mount(%{"username" => username, "slug" => slug, "id" => id}, _session, socket) do
    case Stories.get_story(username, slug) do
      nil ->
        {:ok, socket |> put_flash(:error, "Story not found") |> redirect(to: "/")}

      story ->
        proposal = Collaboration.get_proposal!(id)

        diff =
          case Collaboration.get_proposal_diff(proposal) do
            {:ok, d} -> d
            {:error, _} -> []
          end

        is_owner? =
          socket.assigns[:current_scope] &&
            socket.assigns.current_scope.user.id == story.user_id

        {:ok,
         socket
         |> assign(:page_title, proposal.title)
         |> assign(:story, story)
         |> assign(:proposal, proposal)
         |> assign(:diff, diff)
         |> assign(:is_owner?, is_owner?)
         |> assign(:new_comment, "")}
    end
  end

  @impl true
  def handle_event("merge", _params, socket) do
    proposal = socket.assigns.proposal

    case Collaboration.merge_proposal(proposal) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> put_flash(:info, "Merged!")
         |> assign(:proposal, updated)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Merge failed: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("close", _params, socket) do
    case Collaboration.close_proposal(socket.assigns.proposal) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> put_flash(:info, "Proposal closed.")
         |> assign(:proposal, updated)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to close.")}
    end
  end

  @impl true
  def handle_event("add_comment", %{"body" => body}, socket) do
    user = socket.assigns.current_scope.user

    case Collaboration.create_comment(%{
           body: body,
           author_id: user.id,
           merge_proposal_id: socket.assigns.proposal.id
         }) do
      {:ok, _comment} ->
        proposal = Collaboration.get_proposal!(socket.assigns.proposal.id)
        {:noreply, assign(socket, proposal: proposal, new_comment: "")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to add comment.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mb-6">
        <div class="flex items-center gap-2 text-sm text-base-content/70 mb-2">
          <.link navigate={"/" <> @story.user.username <> "/" <> @story.slug <> "/proposals"} class="link">
            {@story.user.username}/{@story.slug} / proposals
          </.link>
        </div>

        <div class="flex justify-between items-start">
          <div>
            <h1 class="text-2xl font-bold">{@proposal.title}</h1>
            <p class="text-sm text-base-content/70 mt-1">
              <span class={"badge " <> status_badge(@proposal.status)}>{@proposal.status}</span>
              &middot;
              <span class="font-mono">{@proposal.source_storyline}</span>
              into
              <span class="font-mono">{@proposal.target_storyline}</span>
              &middot; by {@proposal.author.username}
            </p>
          </div>

          <%= if @is_owner? && @proposal.status == :open do %>
            <div class="flex gap-2">
              <button phx-click="merge" class="btn btn-sm btn-primary" data-confirm="Merge this proposal?">
                Merge
              </button>
              <button phx-click="close" class="btn btn-sm btn-error btn-outline" data-confirm="Close this proposal?">
                Close
              </button>
            </div>
          <% end %>
        </div>
      </div>

      <%= if @proposal.description do %>
        <div class="card bg-base-200 mb-6">
          <div class="card-body py-3">
            <p>{@proposal.description}</p>
          </div>
        </div>
      <% end %>

      <%!-- Diff --%>
      <div class="mb-6">
        <h2 class="text-lg font-semibold mb-2">Changes</h2>
        <%= if @diff == [] do %>
          <p class="text-base-content/50">No differences found.</p>
        <% else %>
          <div :for={file_diff <- @diff} class="mb-4">
            <div class="bg-base-300 px-3 py-1 font-mono text-sm rounded-t">
              {file_diff.new_file || file_diff.old_file}
            </div>
            <div :for={hunk <- file_diff.hunks} class="border border-base-300 rounded-b overflow-x-auto">
              <div class="bg-base-200 px-3 py-1 text-xs font-mono text-base-content/70">
                {hunk.header}
              </div>
              <table class="table table-xs font-mono w-full">
                <tbody>
                  <tr :for={line <- hunk.lines} class={line_class(line.type)}>
                    <td class="w-12 text-right text-base-content/40 select-none pr-2 border-r border-base-300">
                      {line.old_line || ""}
                    </td>
                    <td class="w-12 text-right text-base-content/40 select-none pr-2 border-r border-base-300">
                      {line.new_line || ""}
                    </td>
                    <td class="pl-2 whitespace-pre-wrap">
                      <span class="select-none">{line_prefix(line.type)}</span>{line.content}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        <% end %>
      </div>

      <%!-- Comments --%>
      <div class="divider">Discussion</div>

      <div class="space-y-3 mb-4">
        <div :for={comment <- @proposal.comments} class="card bg-base-200">
          <div class="card-body py-3">
            <div class="flex justify-between items-center mb-1">
              <span class="font-semibold text-sm">{comment.author.username}</span>
              <span class="text-xs text-base-content/50">
                {Calendar.strftime(comment.inserted_at, "%b %d, %Y")}
              </span>
            </div>
            <p>{comment.body}</p>
          </div>
        </div>
      </div>

      <%= if @current_scope do %>
        <form phx-submit="add_comment" class="flex gap-2">
          <input
            type="text"
            name="body"
            value={@new_comment}
            placeholder="Write a comment..."
            class="input input-bordered flex-1"
            required
          />
          <button type="submit" class="btn btn-primary">Comment</button>
        </form>
      <% end %>
    </Layouts.app>
    """
  end

  defp status_badge(:open), do: "badge-success"
  defp status_badge(:merged), do: "badge-primary"
  defp status_badge(:closed), do: "badge-error"
  defp status_badge(_), do: ""

  defp line_class(:add), do: "bg-success/10"
  defp line_class(:remove), do: "bg-error/10"
  defp line_class(_), do: ""

  defp line_prefix(:add), do: "+"
  defp line_prefix(:remove), do: "-"
  defp line_prefix(_), do: " "
end
