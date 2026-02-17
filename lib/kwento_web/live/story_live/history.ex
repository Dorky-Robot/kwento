defmodule KwentoWeb.StoryLive.History do
  use KwentoWeb, :live_view

  alias Kwento.Stories

  @impl true
  def mount(%{"username" => username, "slug" => slug} = params, _session, socket) do
    storyline_name = Map.get(params, "storyline", "main")

    case Stories.get_story(username, slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Story not found")
         |> redirect(to: "/")}

      story ->
        revisions =
          case Stories.list_revisions(story, storyline_name) do
            {:ok, revs} -> revs
            {:error, _} -> []
          end

        {:ok,
         socket
         |> assign(:page_title, "History - #{story.title}")
         |> assign(:story, story)
         |> assign(:storyline_name, storyline_name)
         |> assign(:revisions, revisions)}
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
        <h1 class="text-2xl font-bold">Revision History</h1>
        <p class="text-base-content/70">
          Storyline: <span class="font-mono badge badge-sm badge-outline">{@storyline_name}</span>
        </p>
      </div>

      <%= if @revisions == [] do %>
        <div class="text-center py-8 text-base-content/50">
          <p>No revisions yet.</p>
        </div>
      <% else %>
        <div class="space-y-2">
          <div :for={rev <- @revisions} class="card bg-base-200 shadow-sm">
            <div class="card-body py-3">
              <div class="flex justify-between items-start">
                <div>
                  <p class="font-semibold">{rev.message}</p>
                  <p class="text-sm text-base-content/70">
                    {rev.author_name} committed
                    <%= if rev.timestamp do %>
                      on {Calendar.strftime(rev.timestamp, "%b %d, %Y at %H:%M")}
                    <% end %>
                  </p>
                </div>
                <code class="text-xs font-mono badge badge-ghost">{String.slice(rev.sha, 0, 7)}</code>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </Layouts.app>
    """
  end
end
