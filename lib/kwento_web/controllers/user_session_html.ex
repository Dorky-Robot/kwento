defmodule KwentoWeb.UserSessionHTML do
  use KwentoWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:kwento, Kwento.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
