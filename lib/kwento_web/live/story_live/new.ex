defmodule KwentoWeb.StoryLive.New do
  use KwentoWeb, :live_view

  alias Kwento.Stories
  alias Kwento.Stories.Story

  @impl true
  def mount(_params, _session, socket) do
    changeset = Stories.change_story(%Story{})

    {:ok,
     socket
     |> assign(:page_title, "New Story")
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"story" => story_params}, socket) do
    changeset =
      %Story{}
      |> Stories.change_story(story_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"story" => story_params}, socket) do
    user = socket.assigns.current_scope.user

    case Stories.create_story(user, story_params) do
      {:ok, story} ->
        {:noreply,
         socket
         |> put_flash(:info, "Story created!")
         |> redirect(to: "/" <> user.username <> "/" <> story.slug)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-2xl mx-auto">
        <h1 class="text-3xl font-bold mb-6">Create a new story</h1>

        <.form :let={f} for={@changeset} phx-change="validate" phx-submit="save">
          <div class="space-y-4">
            <.input field={f[:title]} type="text" label="Title" required phx-mounted={JS.focus()} />
            <.input field={f[:synopsis]} type="textarea" label="Synopsis" />
            <.input
              field={f[:genre]}
              type="select"
              label="Genre"
              options={[
                {"Select a genre", ""},
                "Fantasy",
                "Science Fiction",
                "Mystery",
                "Romance",
                "Horror",
                "Thriller",
                "Literary Fiction",
                "Historical Fiction",
                "Poetry",
                "Non-Fiction",
                "Other"
              ]}
            />
            <.input
              field={f[:visibility]}
              type="select"
              label="Visibility"
              options={[{"Public", "public"}, {"Private", "private"}]}
            />

            <div class="mt-6">
              <.button phx-disable-with="Creating..." class="btn btn-primary">
                Create Story
              </.button>
            </div>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end
end
