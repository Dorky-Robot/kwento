defmodule KwentoWeb.Router do
  use KwentoWeb, :router

  import KwentoWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {KwentoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:kwento, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: KwentoWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes (must be before catch-all LiveView routes)

  scope "/", KwentoWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
  end

  scope "/", KwentoWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
  end

  scope "/", KwentoWeb do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    get "/users/log-in/:token", UserSessionController, :confirm
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  # Authenticated LiveView routes
  scope "/", KwentoWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated,
      on_mount: [{KwentoWeb.UserAuth, :ensure_authenticated}] do
      live "/new", StoryLive.New
      live "/settings", UserLive.Settings
      live "/:username/:slug/edit", StoryLive.Edit
      live "/:username/:slug/edit/:storyline", StoryLive.Edit
      live "/:username/:slug/proposals/new", MergeProposalLive.New
      live "/:username/:slug/threads/new", ThreadLive.New
      live "/:username/:slug/storylines/new", StoryLive.NewStoryline
    end
  end

  # Public LiveView routes (catch-all routes must be last)
  scope "/", KwentoWeb do
    pipe_through [:browser]

    live_session :public,
      on_mount: [{KwentoWeb.UserAuth, :mount_current_scope}] do
      live "/", HomeLive
      live "/explore", ExploreLive
      live "/:username", ProfileLive
      live "/:username/:slug", StoryLive.Show
      live "/:username/:slug/storylines", StoryLive.Storylines
      live "/:username/:slug/tree/:storyline", StoryLive.Show
      live "/:username/:slug/history", StoryLive.History
      live "/:username/:slug/history/:storyline", StoryLive.History
      live "/:username/:slug/proposals", MergeProposalLive.Index
      live "/:username/:slug/proposals/:id", MergeProposalLive.Show
      live "/:username/:slug/threads", ThreadLive.Index
      live "/:username/:slug/threads/:id", ThreadLive.Show
    end
  end
end
