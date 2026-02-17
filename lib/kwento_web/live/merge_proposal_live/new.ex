defmodule KwentoWeb.MergeProposalLive.New do
  use KwentoWeb, :live_view

  alias Kwento.Stories
  alias Kwento.Collaboration
  alias Kwento.Collaboration.MergeProposal

  @impl true
  def mount(%{"username" => username, "slug" => slug}, _session, socket) do
    case Stories.get_story(username, slug) do
      nil ->
        {:ok, socket |> put_flash(:error, "Story not found") |> redirect(to: "/")}

      story ->
        storylines = Stories.list_storylines(story)
        changeset = Collaboration.change_proposal(%MergeProposal{})

        {:ok,
         socket
         |> assign(:page_title, "New Merge Proposal")
         |> assign(:story, story)
         |> assign(:storylines, storylines)
         |> assign(:changeset, changeset)}
    end
  end

  @impl true
  def handle_event("validate", %{"merge_proposal" => params}, socket) do
    changeset =
      %MergeProposal{}
      |> MergeProposal.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"merge_proposal" => params}, socket) do
    story = socket.assigns.story
    user = socket.assigns.current_scope.user

    case Collaboration.create_proposal(story, user, params) do
      {:ok, proposal} ->
        {:noreply,
         socket
         |> put_flash(:info, "Merge proposal created!")
         |> redirect(
           to:
             "/" <>
               story.user.username <>
               "/" <> story.slug <> "/proposals/" <> to_string(proposal.id)
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
        <h1 class="text-2xl font-bold mb-6">New Merge Proposal</h1>

        <.form :let={f} for={@changeset} phx-change="validate" phx-submit="save">
          <div class="space-y-4">
            <.input field={f[:title]} type="text" label="Title" required />
            <.input field={f[:description]} type="textarea" label="Description" />
            <.input
              field={f[:source_storyline]}
              type="select"
              label="Source storyline (merge from)"
              options={Enum.map(@storylines, &{&1.display_name || &1.name, &1.name})}
            />
            <.input
              field={f[:target_storyline]}
              type="select"
              label="Target storyline (merge into)"
              options={Enum.map(@storylines, &{&1.display_name || &1.name, &1.name})}
            />

            <div class="mt-6">
              <.button phx-disable-with="Creating..." class="btn btn-primary">
                Create Proposal
              </.button>
            </div>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end
end
