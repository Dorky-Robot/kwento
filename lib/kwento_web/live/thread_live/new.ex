defmodule KwentoWeb.ThreadLive.New do
  use KwentoWeb, :live_view

  alias Kwento.Stories
  alias Kwento.Collaboration
  alias Kwento.Collaboration.Thread

  @impl true
  def mount(%{"username" => username, "slug" => slug}, _session, socket) do
    case Stories.get_story(username, slug) do
      nil ->
        {:ok, socket |> put_flash(:error, "Story not found") |> redirect(to: "/")}

      story ->
        changeset = Collaboration.change_thread(%Thread{})

        {:ok,
         socket
         |> assign(:page_title, "New Thread")
         |> assign(:story, story)
         |> assign(:changeset, changeset)}
    end
  end

  @impl true
  def handle_event("validate", %{"thread" => params}, socket) do
    changeset =
      %Thread{}
      |> Thread.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"thread" => params}, socket) do
    story = socket.assigns.story
    user = socket.assigns.current_scope.user

    case Collaboration.create_thread(story, user, params) do
      {:ok, thread} ->
        {:noreply,
         socket
         |> put_flash(:info, "Thread created!")
         |> redirect(
           to:
             "/" <>
               story.user.username <>
               "/" <> story.slug <> "/threads/" <> to_string(thread.id)
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-lg mx-auto">
        <h1 class="text-2xl font-bold mb-6">New Thread</h1>

        <.form :let={f} for={@changeset} phx-change="validate" phx-submit="save">
          <div class="space-y-4">
            <.input field={f[:title]} type="text" label="Title" required />
            <.input field={f[:body]} type="textarea" label="Body" required rows="6" />

            <div class="mt-6">
              <.button phx-disable-with="Creating..." class="btn btn-primary">
                Create Thread
              </.button>
            </div>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end
end
