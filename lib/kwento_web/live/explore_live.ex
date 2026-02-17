defmodule KwentoWeb.ExploreLive do
  use KwentoWeb, :live_view

  alias Kwento.Stories

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Explore")
     |> assign(:search, "")
     |> assign(:sort, "recent")
     |> assign(:stories, Stories.list_public_stories(limit: 20, sort: :recent))}
  end

  @impl true
  def handle_event("search", %{"search" => query}, socket) do
    stories =
      if String.trim(query) == "" do
        sort = String.to_existing_atom(socket.assigns.sort)
        Stories.list_public_stories(limit: 20, sort: sort)
      else
        Stories.search_stories(query, limit: 20)
      end

    {:noreply, assign(socket, stories: stories, search: query)}
  end

  @impl true
  def handle_event("sort", %{"sort" => sort}, socket) do
    sort_atom = String.to_existing_atom(sort)
    stories = Stories.list_public_stories(limit: 20, sort: sort_atom)
    {:noreply, assign(socket, stories: stories, sort: sort)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <h1 class="text-3xl font-bold mb-6">Explore Stories</h1>

      <div class="flex flex-col sm:flex-row gap-4 mb-6">
        <form phx-change="search" phx-submit="search" class="flex-1">
          <input
            type="text"
            name="search"
            value={@search}
            placeholder="Search stories..."
            class="input input-bordered w-full"
            phx-debounce="300"
          />
        </form>
        <form phx-change="sort">
          <select name="sort" class="select select-bordered">
            <option value="recent" selected={@sort == "recent"}>Most Recent</option>
            <option value="bookmarks" selected={@sort == "bookmarks"}>Most Bookmarked</option>
            <option value="forks" selected={@sort == "forks"}>Most Forked</option>
          </select>
        </form>
      </div>

      <%= if @stories == [] do %>
        <div class="text-center py-8 text-base-content/50">
          <p>No stories found.</p>
        </div>
      <% else %>
        <div class="space-y-3">
          <div :for={story <- @stories} class="card bg-base-200 shadow-sm">
            <div class="card-body py-4">
              <div class="flex justify-between items-start">
                <div>
                  <h2 class="text-lg font-semibold">
                    <.link navigate={"/" <> story.user.username <> "/" <> story.slug} class="link link-hover">
                      {story.user.username}/{story.slug}
                    </.link>
                  </h2>
                  <p class="text-sm mt-1">{story.title}</p>
                  <%= if story.synopsis do %>
                    <p class="text-sm text-base-content/70 mt-1 line-clamp-2">{story.synopsis}</p>
                  <% end %>
                </div>
                <%= if story.genre do %>
                  <span class="badge badge-outline">{story.genre}</span>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </Layouts.app>
    """
  end
end
