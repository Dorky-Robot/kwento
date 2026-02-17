defmodule KwentoWeb.PageController do
  use KwentoWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
