defmodule KwentoWeb.StoryLive.Storylines do
  use KwentoWeb, :live_view

  alias Kwento.Stories

  @impl true
  def mount(%{"username" => username, "slug" => slug}, _session, socket) do
    case Stories.get_story(username, slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Story not found")
         |> redirect(to: "/")}

      story ->
        storylines = Stories.list_storylines(story)

        is_owner? =
          socket.assigns[:current_scope] &&
            socket.assigns.current_scope.user.id == story.user_id

        {:ok,
         socket
         |> assign(:page_title, "Storylines - #{story.title}")
         |> assign(:story, story)
         |> assign(:storylines, storylines)
         |> assign(:is_owner?, is_owner?)}
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
          <h1 class="text-2xl font-bold">Storylines</h1>
          <%= if @is_owner? do %>
            <.link
              navigate={"/" <> @story.user.username <> "/" <> @story.slug <> "/storylines/new"}
              class="btn btn-sm btn-primary"
            >
              New Storyline
            </.link>
          <% end %>
        </div>
      </div>

      <div class="space-y-2">
        <div :for={sl <- @storylines} class="card bg-base-200 shadow-sm">
          <div class="card-body py-3">
            <div class="flex justify-between items-center">
              <div>
                <.link
                  navigate={"/" <> @story.user.username <> "/" <> @story.slug <> "/tree/" <> sl.name}
                  class="font-mono link link-hover"
                >
                  {sl.name}
                </.link>
                <%= if sl.display_name do %>
                  <span class="text-sm text-base-content/70 ml-2">{sl.display_name}</span>
                <% end %>
                <%= if sl.is_default do %>
                  <span class="badge badge-primary badge-sm ml-2">default</span>
                <% end %>
              </div>
              <.link
                navigate={"/" <> @story.user.username <> "/" <> @story.slug <> "/tree/" <> sl.name}
                class="btn btn-ghost btn-sm"
              >
                View
              </.link>
            </div>
            <%= if sl.description do %>
              <p class="text-sm text-base-content/70">{sl.description}</p>
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
