defmodule KwentoWeb.UserLive.Settings do
  use KwentoWeb, :live_view

  alias Kwento.Accounts

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    changeset = Accounts.change_user_profile(user)

    {:ok,
     socket
     |> assign(:page_title, "Profile Settings")
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.current_scope.user
      |> Accounts.change_user_profile(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    user = socket.assigns.current_scope.user

    case Accounts.update_user_profile(user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile updated!")
         |> redirect(to: "/settings")}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-lg mx-auto">
        <h1 class="text-2xl font-bold mb-6">Profile Settings</h1>

        <.form :let={f} for={@changeset} phx-change="validate" phx-submit="save">
          <div class="space-y-4">
            <.input field={f[:display_name]} type="text" label="Display name" />
            <.input field={f[:bio]} type="textarea" label="Bio" placeholder="Tell us about yourself..." />
            <.input field={f[:avatar_url]} type="text" label="Avatar URL" placeholder="https://..." />

            <div class="mt-6">
              <.button phx-disable-with="Saving..." class="btn btn-primary">
                Save Changes
              </.button>
            </div>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end
end
