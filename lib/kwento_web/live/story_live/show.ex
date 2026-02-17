defmodule KwentoWeb.StoryLive.Show do
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
        content =
          case Stories.read_content(story, storyline_name) do
            {:ok, c} -> c
            {:error, _} -> "*No content yet.*"
          end

        bookmark_count = Stories.bookmark_count(story)
        fork_count = Stories.fork_count(story)

        bookmarked? =
          if socket.assigns[:current_scope] do
            Stories.bookmarked?(socket.assigns.current_scope.user, story)
          else
            false
          end

        is_owner? =
          socket.assigns[:current_scope] &&
            socket.assigns.current_scope.user.id == story.user_id

        {:ok,
         socket
         |> assign(:page_title, story.title)
         |> assign(:story, story)
         |> assign(:storyline_name, storyline_name)
         |> assign(:content, content)
         |> assign(:bookmark_count, bookmark_count)
         |> assign(:fork_count, fork_count)
         |> assign(:bookmarked?, bookmarked?)
         |> assign(:is_owner?, is_owner?)}
    end
  end

  @impl true
  def handle_event("bookmark", _params, socket) do
    user = socket.assigns.current_scope.user
    story = socket.assigns.story

    if socket.assigns.bookmarked? do
      Stories.unbookmark_story(user, story)
      {:noreply, assign(socket, bookmarked?: false, bookmark_count: socket.assigns.bookmark_count - 1)}
    else
      Stories.bookmark_story(user, story)
      {:noreply, assign(socket, bookmarked?: true, bookmark_count: socket.assigns.bookmark_count + 1)}
    end
  end

  @impl true
  def handle_event("fork", _params, socket) do
    user = socket.assigns.current_scope.user
    story = socket.assigns.story

    case Stories.fork_story(story, user) do
      {:ok, forked} ->
        {:noreply,
         socket
         |> put_flash(:info, "Story forked!")
         |> redirect(to: "/" <> user.username <> "/" <> forked.slug)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to fork: #{inspect(reason)}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mb-6">
        <div class="flex items-center gap-2 text-sm text-base-content/70 mb-2">
          <.link navigate={"/" <> @story.user.username} class="link">{@story.user.username}</.link>
          <span>/</span>
          <span class="font-semibold text-base-content">{@story.slug}</span>
        </div>

        <div class="flex flex-col sm:flex-row justify-between items-start gap-4">
          <div>
            <h1 class="text-3xl font-bold">{@story.title}</h1>
            <%= if @story.synopsis do %>
              <p class="text-base-content/70 mt-1">{@story.synopsis}</p>
            <% end %>
          </div>

          <div class="flex gap-2 flex-wrap">
            <%= if @current_scope do %>
              <button phx-click="bookmark" class={"btn btn-sm " <> if(@bookmarked?, do: "btn-primary", else: "btn-outline")}>
                <.icon name="hero-bookmark-solid" class="size-4" />
                {@bookmark_count}
              </button>

              <%= if !@is_owner? do %>
                <button phx-click="fork" class="btn btn-sm btn-outline">
                  <.icon name="hero-document-duplicate" class="size-4" />
                  Fork ({@fork_count})
                </button>
              <% end %>
            <% else %>
              <span class="btn btn-sm btn-ghost no-animation">
                <.icon name="hero-bookmark" class="size-4" /> {@bookmark_count}
              </span>
            <% end %>
          </div>
        </div>

        <%!-- Tab nav --%>
        <div class="tabs tabs-bordered mt-4">
          <.link
            navigate={"/" <> @story.user.username <> "/" <> @story.slug}
            class={"tab " <> if(@storyline_name == "main" && true, do: "tab-active", else: "")}
          >
            Story
          </.link>
          <.link
            navigate={"/" <> @story.user.username <> "/" <> @story.slug <> "/storylines"}
            class="tab"
          >
            Storylines
          </.link>
          <.link
            navigate={"/" <> @story.user.username <> "/" <> @story.slug <> "/proposals"}
            class="tab"
          >
            Proposals
          </.link>
          <.link
            navigate={"/" <> @story.user.username <> "/" <> @story.slug <> "/threads"}
            class="tab"
          >
            Threads
          </.link>
          <.link
            navigate={"/" <> @story.user.username <> "/" <> @story.slug <> "/history/" <> @storyline_name}
            class="tab"
          >
            History
          </.link>
        </div>
      </div>

      <%!-- Storyline selector --%>
      <div class="flex justify-between items-center mb-4">
        <div class="flex items-center gap-2">
          <.icon name="hero-code-bracket" class="size-4" />
          <span class="font-mono text-sm badge badge-outline">{@storyline_name}</span>
        </div>
        <%= if @is_owner? do %>
          <.link
            navigate={"/" <> @story.user.username <> "/" <> @story.slug <> "/edit/" <> @storyline_name}
            class="btn btn-sm btn-primary"
          >
            Edit
          </.link>
        <% end %>
      </div>

      <%!-- Story content --%>
      <article class="prose prose-lg max-w-none">
        {Phoenix.HTML.raw(render_markdown(@content))}
      </article>

      <%!-- Forked from notice --%>
      <%= if @story.forked_from_id do %>
        <div class="mt-8 text-sm text-base-content/50">
          Forked from another story
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  defp render_markdown(content) do
    content
    |> String.split("\n")
    |> Enum.map(fn line ->
      line
      |> convert_headers()
      |> convert_bold()
      |> convert_italic()
      |> convert_paragraphs()
    end)
    |> Enum.join("\n")
  end

  defp convert_headers("### " <> rest), do: "<h3>#{Phoenix.HTML.html_escape(rest) |> Phoenix.HTML.safe_to_string()}</h3>"
  defp convert_headers("## " <> rest), do: "<h2>#{Phoenix.HTML.html_escape(rest) |> Phoenix.HTML.safe_to_string()}</h2>"
  defp convert_headers("# " <> rest), do: "<h1>#{Phoenix.HTML.html_escape(rest) |> Phoenix.HTML.safe_to_string()}</h1>"
  defp convert_headers(line), do: line

  defp convert_bold(line) do
    Regex.replace(~r/\*\*(.+?)\*\*/, line, "<strong>\\1</strong>")
  end

  defp convert_italic(line) do
    Regex.replace(~r/\*(.+?)\*/, line, "<em>\\1</em>")
  end

  defp convert_paragraphs(""), do: "<br/>"
  defp convert_paragraphs("<h" <> _ = line), do: line
  defp convert_paragraphs(line), do: "<p>#{line}</p>"
end
