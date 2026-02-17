defmodule KwentoWeb.ThreadLive.Show do
  use KwentoWeb, :live_view

  alias Kwento.Stories
  alias Kwento.Collaboration

  @impl true
  def mount(%{"username" => username, "slug" => slug, "id" => id}, _session, socket) do
    case Stories.get_story(username, slug) do
      nil ->
        {:ok, socket |> put_flash(:error, "Story not found") |> redirect(to: "/")}

      story ->
        thread = Collaboration.get_thread!(id)

        is_owner? =
          socket.assigns[:current_scope] &&
            socket.assigns.current_scope.user.id == story.user_id

        {:ok,
         socket
         |> assign(:page_title, thread.title)
         |> assign(:story, story)
         |> assign(:thread, thread)
         |> assign(:is_owner?, is_owner?)
         |> assign(:new_comment, "")}
    end
  end

  @impl true
  def handle_event("close", _params, socket) do
    case Collaboration.close_thread(socket.assigns.thread) do
      {:ok, updated} ->
        {:noreply, assign(socket, thread: updated) |> put_flash(:info, "Thread closed.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to close.")}
    end
  end

  @impl true
  def handle_event("reopen", _params, socket) do
    case Collaboration.reopen_thread(socket.assigns.thread) do
      {:ok, updated} ->
        {:noreply, assign(socket, thread: updated) |> put_flash(:info, "Thread reopened.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to reopen.")}
    end
  end

  @impl true
  def handle_event("add_comment", %{"body" => body}, socket) do
    user = socket.assigns.current_scope.user

    case Collaboration.create_comment(%{
           body: body,
           author_id: user.id,
           thread_id: socket.assigns.thread.id
         }) do
      {:ok, _comment} ->
        thread = Collaboration.get_thread!(socket.assigns.thread.id)
        {:noreply, assign(socket, thread: thread, new_comment: "")}

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
          <.link navigate={"/" <> @story.user.username <> "/" <> @story.slug <> "/threads"} class="link">
            {@story.user.username}/{@story.slug} / threads
          </.link>
        </div>

        <div class="flex justify-between items-start">
          <div>
            <h1 class="text-2xl font-bold">{@thread.title}</h1>
            <p class="text-sm text-base-content/70 mt-1">
              <span class={"badge " <> if(@thread.status == :open, do: "badge-success", else: "badge-error")}>
                {@thread.status}
              </span>
              &middot; opened by {@thread.author.username}
            </p>
          </div>

          <%= if @is_owner? do %>
            <%= if @thread.status == :open do %>
              <button phx-click="close" class="btn btn-sm btn-error btn-outline">Close</button>
            <% else %>
              <button phx-click="reopen" class="btn btn-sm btn-success btn-outline">Reopen</button>
            <% end %>
          <% end %>
        </div>
      </div>

      <%!-- Original post --%>
      <div class="card bg-base-200 mb-4">
        <div class="card-body">
          <div class="flex justify-between items-center mb-2">
            <span class="font-semibold">{@thread.author.username}</span>
            <span class="text-xs text-base-content/50">
              {Calendar.strftime(@thread.inserted_at, "%b %d, %Y")}
            </span>
          </div>
          <p class="whitespace-pre-wrap">{@thread.body}</p>
          <div class="flex gap-1 mt-2">
            <span :for={label <- @thread.labels} class="badge badge-outline badge-sm">{label}</span>
          </div>
        </div>
      </div>

      <div class="divider">Comments ({length(@thread.comments)})</div>

      <div class="space-y-3 mb-4">
        <div :for={comment <- @thread.comments} class="card bg-base-200">
          <div class="card-body py-3">
            <div class="flex justify-between items-center mb-1">
              <span class="font-semibold text-sm">{comment.author.username}</span>
              <span class="text-xs text-base-content/50">
                {Calendar.strftime(comment.inserted_at, "%b %d, %Y")}
              </span>
            </div>
            <p class="whitespace-pre-wrap">{comment.body}</p>
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
end
