defmodule KwentoWeb.MergeProposalLive.Index do
  use KwentoWeb, :live_view

  alias Kwento.Stories
  alias Kwento.Collaboration

  @impl true
  def mount(%{"username" => username, "slug" => slug}, _session, socket) do
    case Stories.get_story(username, slug) do
      nil ->
        {:ok, socket |> put_flash(:error, "Story not found") |> redirect(to: "/")}

      story ->
        proposals = Collaboration.list_proposals(story)

        {:ok,
         socket
         |> assign(:page_title, "Merge Proposals - #{story.title}")
         |> assign(:story, story)
         |> assign(:proposals, proposals)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mb-6">
        <div class="flex items-center gap-2 text-sm text-base-content/70 mb-2">
          <.link navigate={"/" <> @story.user.username <> "/" <> @story.slug} class="link">
            {@story.user.username}/{@story.slug}
          </.link>
        </div>

        <div class="flex justify-between items-center">
          <h1 class="text-2xl font-bold">Merge Proposals</h1>
          <%= if @current_scope do %>
            <.link
              navigate={"/" <> @story.user.username <> "/" <> @story.slug <> "/proposals/new"}
              class="btn btn-sm btn-primary"
            >
              New Proposal
            </.link>
          <% end %>
        </div>
      </div>

      <%= if @proposals == [] do %>
        <div class="text-center py-8 text-base-content/50">
          <p>No merge proposals yet.</p>
        </div>
      <% else %>
        <div class="space-y-2">
          <div :for={proposal <- @proposals} class="card bg-base-200 shadow-sm">
            <div class="card-body py-3">
              <div class="flex justify-between items-start">
                <div>
                  <.link
                    navigate={"/" <> @story.user.username <> "/" <> @story.slug <> "/proposals/" <> to_string(proposal.id)}
                    class="font-semibold link link-hover"
                  >
                    {proposal.title}
                  </.link>
                  <p class="text-sm text-base-content/70 mt-1">
                    <span class="font-mono">{proposal.source_storyline}</span>
                    into
                    <span class="font-mono">{proposal.target_storyline}</span>
                    &middot; opened by {proposal.author.username}
                  </p>
                </div>
                <span class={"badge " <> status_badge(proposal.status)}>{proposal.status}</span>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  defp status_badge(:open), do: "badge-success"
  defp status_badge(:merged), do: "badge-primary"
  defp status_badge(:closed), do: "badge-error"
  defp status_badge(_), do: ""
end
