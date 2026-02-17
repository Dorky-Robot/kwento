defmodule KwentoWeb.StoryLive.Edit do
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
        user = socket.assigns.current_scope.user

        if story.user_id != user.id do
          {:ok,
           socket
           |> put_flash(:error, "You can only edit your own stories")
           |> redirect(to: "/" <> username <> "/" <> slug)}
        else
          content =
            case Stories.read_content(story, storyline_name) do
              {:ok, c} -> c
              {:error, _} -> ""
            end

          {:ok,
           socket
           |> assign(:page_title, "Edit - #{story.title}")
           |> assign(:story, story)
           |> assign(:storyline_name, storyline_name)
           |> assign(:content, content)
           |> assign(:commit_message, "")}
        end
    end
  end

  @impl true
  def handle_event("update_content", %{"content" => content}, socket) do
    {:noreply, assign(socket, :content, content)}
  end

  @impl true
  def handle_event("save", %{"content" => content, "message" => message}, socket) do
    story = socket.assigns.story
    user = socket.assigns.current_scope.user
    storyline = socket.assigns.storyline_name

    message = if String.trim(message) == "", do: "Update story", else: message

    case Stories.save_content(story, storyline, user, content, message) do
      {:ok, _sha} ->
        {:noreply,
         socket
         |> put_flash(:info, "Saved!")
         |> assign(:content, content)
         |> assign(:commit_message, "")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to save: #{inspect(reason)}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mb-4">
        <div class="flex items-center gap-2 text-sm text-base-content/70 mb-2">
          <.link navigate={"/" <> @story.user.username <> "/" <> @story.slug} class="link">
            {String.slice(@story.user.username, 0..20)}/{@story.slug}
          </.link>
          <span class="font-mono badge badge-sm badge-outline">{@storyline_name}</span>
        </div>
        <h1 class="text-2xl font-bold">Editing: {@story.title}</h1>
      </div>

      <form phx-submit="save" class="space-y-4">
        <textarea
          name="content"
          phx-change="update_content"
          phx-debounce="500"
          class="textarea textarea-bordered w-full font-mono"
          rows="20"
          placeholder="Write your story in Markdown..."
        >{@content}</textarea>

        <div class="flex gap-2 items-end">
          <div class="flex-1">
            <label class="label">
              <span class="label-text">Commit message</span>
            </label>
            <input
              type="text"
              name="message"
              value={@commit_message}
              placeholder="Describe your changes..."
              class="input input-bordered w-full"
            />
          </div>
          <button type="submit" class="btn btn-primary" phx-disable-with="Saving...">
            Save Revision
          </button>
        </div>
      </form>

      <div class="mt-4">
        <.link
          navigate={"/" <> @story.user.username <> "/" <> @story.slug <> "/tree/" <> @storyline_name}
          class="btn btn-ghost btn-sm"
        >
          Cancel
        </.link>
      </div>
    </Layouts.app>
    """
  end
end
