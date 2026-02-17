defmodule KwentoWeb.ThreadLive.Index do
  use KwentoWeb, :live_view

  alias Kwento.Stories
  alias Kwento.Collaboration

  @impl true
  def mount(%{"username" => username, "slug" => slug}, _session, socket) do
    case Stories.get_story(username, slug) do
      nil ->
        {:ok, socket |> put_flash(:error, "Story not found") |> redirect(to: "/")}

      story ->
        threads = Collaboration.list_threads(story)

        {:ok,
         socket
         |> assign(:page_title, "Threads - #{story.title}")
         |> assign(:story, story)
         |> assign(:threads, threads)}
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
          <h1 class="text-2xl font-bold">Threads</h1>
          <%= if @current_scope do %>
            <.link
              navigate={"/" <> @story.user.username <> "/" <> @story.slug <> "/threads/new"}
              class="btn btn-sm btn-primary"
            >
              New Thread
            </.link>
          <% end %>
        </div>
      </div>

      <%= if @threads == [] do %>
        <div class="text-center py-8 text-base-content/50">
          <p>No threads yet. Start a discussion!</p>
        </div>
      <% else %>
        <div class="space-y-2">
          <div :for={thread <- @threads} class="card bg-base-200 shadow-sm">
            <div class="card-body py-3">
              <div class="flex justify-between items-start">
                <div>
                  <.link
                    navigate={"/" <> @story.user.username <> "/" <> @story.slug <> "/threads/" <> to_string(thread.id)}
                    class="font-semibold link link-hover"
                  >
                    {thread.title}
                  </.link>
                  <p class="text-sm text-base-content/70 mt-1">
                    opened by {thread.author.username}
                  </p>
                </div>
                <div class="flex gap-2 items-center">
                  <span :for={label <- thread.labels} class="badge badge-outline badge-sm">{label}</span>
                  <span class={"badge " <> if(thread.status == :open, do: "badge-success", else: "badge-error")}>
                    {thread.status}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </Layouts.app>
    """
  end
end
