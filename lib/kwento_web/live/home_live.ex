defmodule KwentoWeb.HomeLive do
  use KwentoWeb, :live_view

  alias Kwento.Stories

  @impl true
  def mount(_params, _session, socket) do
    stories = Stories.list_public_stories(limit: 12, sort: :recent)

    {:ok,
     socket
     |> assign(:page_title, "Home")
     |> assign(:stories, stories)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="text-center mb-8">
        <h1 class="text-4xl font-bold mb-2">Welcome to Kwento</h1>
        <p class="text-lg text-base-content/70">
          A collaborative platform for writers. Create stories, branch into alternate storylines, and merge ideas together.
        </p>
        <%= if !@current_scope do %>
          <div class="mt-4 flex gap-2 justify-center">
            <.link href={~p"/users/register"} class="btn btn-primary">Get Started</.link>
            <.link navigate="/explore" class="btn btn-ghost">Explore Stories</.link>
          </div>
        <% end %>
      </div>

      <div class="divider">Recent Stories</div>

      <%= if @stories == [] do %>
        <div class="text-center py-8 text-base-content/50">
          <p>No stories yet. Be the first to create one!</p>
        </div>
      <% else %>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <div :for={story <- @stories} class="card bg-base-200 shadow-sm">
            <div class="card-body">
              <h2 class="card-title">
                <.link navigate={"/" <> story.user.username <> "/" <> story.slug} class="link link-hover">
                  {story.title}
                </.link>
              </h2>
              <p class="text-sm text-base-content/70">
                by <.link navigate={"/" <> story.user.username} class="link">{story.user.username}</.link>
              </p>
              <%= if story.synopsis do %>
                <p class="text-sm mt-1 line-clamp-3">{story.synopsis}</p>
              <% end %>
              <%= if story.genre do %>
                <div class="card-actions justify-end mt-2">
                  <span class="badge badge-outline">{story.genre}</span>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>
    </Layouts.app>
    """
  end
end
