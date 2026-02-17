defmodule KwentoWeb.ProfileLive do
  use KwentoWeb, :live_view

  alias Kwento.Accounts
  alias Kwento.Stories

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    case Accounts.get_user_by_username(username) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "User not found")
         |> redirect(to: "/")}

      profile_user ->
        stories =
          if socket.assigns[:current_scope] &&
               socket.assigns.current_scope.user.id == profile_user.id do
            Stories.list_user_stories(profile_user)
          else
            Stories.list_user_public_stories(profile_user)
          end

        {:ok,
         socket
         |> assign(:page_title, profile_user.username)
         |> assign(:profile_user, profile_user)
         |> assign(:stories, stories)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mb-8">
        <div class="flex items-center gap-4 mb-4">
          <div class="avatar placeholder">
            <div class="bg-neutral text-neutral-content w-16 rounded-full">
              <span class="text-2xl">{String.first(@profile_user.username) |> String.upcase()}</span>
            </div>
          </div>
          <div>
            <h1 class="text-2xl font-bold">{@profile_user.display_name || @profile_user.username}</h1>
            <p class="text-base-content/70">@{@profile_user.username}</p>
          </div>
        </div>
        <%= if @profile_user.bio do %>
          <p class="text-base-content/80 mb-4">{@profile_user.bio}</p>
        <% end %>
      </div>

      <div class="divider">Stories ({length(@stories)})</div>

      <%= if @stories == [] do %>
        <div class="text-center py-8 text-base-content/50">
          <p>No stories yet.</p>
        </div>
      <% else %>
        <div class="space-y-3">
          <div :for={story <- @stories} class="card bg-base-200 shadow-sm">
            <div class="card-body py-4">
              <div class="flex justify-between items-start">
                <div>
                  <h2 class="text-lg font-semibold">
                    <.link navigate={"/" <> @profile_user.username <> "/" <> story.slug} class="link link-hover">
                      {story.title}
                    </.link>
                  </h2>
                  <%= if story.synopsis do %>
                    <p class="text-sm text-base-content/70 mt-1 line-clamp-2">{story.synopsis}</p>
                  <% end %>
                </div>
                <div class="flex gap-2">
                  <%= if story.visibility == :private do %>
                    <span class="badge badge-warning">Private</span>
                  <% end %>
                  <%= if story.genre do %>
                    <span class="badge badge-outline">{story.genre}</span>
                  <% end %>
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
