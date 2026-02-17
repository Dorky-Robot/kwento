defmodule KwentoWeb.StoryLive.NewStoryline do
  use KwentoWeb, :live_view

  alias Kwento.Stories
  alias Kwento.Stories.Storyline

  @impl true
  def mount(%{"username" => username, "slug" => slug}, _session, socket) do
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
           |> put_flash(:error, "Only the story owner can create storylines")
           |> redirect(to: "/" <> username <> "/" <> slug)}
        else
          changeset = Storyline.changeset(%Storyline{}, %{})

          {:ok,
           socket
           |> assign(:page_title, "New Storyline")
           |> assign(:story, story)
           |> assign(:changeset, changeset)}
        end
    end
  end

  @impl true
  def handle_event("validate", %{"storyline" => params}, socket) do
    changeset =
      %Storyline{}
      |> Storyline.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"storyline" => params}, socket) do
    story = socket.assigns.story

    case Stories.create_storyline(story, params) do
      {:ok, storyline} ->
        {:noreply,
         socket
         |> put_flash(:info, "Storyline created!")
         |> redirect(
           to:
             "/" <> story.user.username <> "/" <> story.slug <> "/tree/" <> storyline.name
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed: #{inspect(reason)}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-lg mx-auto">
        <h1 class="text-2xl font-bold mb-6">New Storyline</h1>
        <p class="text-base-content/70 mb-4">
          Create a new branch of the story to explore an alternate path.
        </p>

        <.form :let={f} for={@changeset} phx-change="validate" phx-submit="save">
          <div class="space-y-4">
            <.input
              field={f[:name]}
              type="text"
              label="Branch name"
              placeholder="e.g., alternate-ending"
              required
            />
            <.input
              field={f[:display_name]}
              type="text"
              label="Display name"
              placeholder="e.g., The Alternate Ending"
            />
            <.input
              field={f[:description]}
              type="textarea"
              label="Description"
              placeholder="What's this storyline about?"
            />

            <div class="mt-6">
              <.button phx-disable-with="Creating..." class="btn btn-primary">
                Create Storyline
              </.button>
            </div>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end
end
