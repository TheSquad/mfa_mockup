defmodule MfaMockup.Router do
  use MfaMockup.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :copy_req_body
    plug :accepts, ["text"]
  end

  defp copy_req_body(conn, _) do
    Plug.Conn.put_private(conn, :my_app_body, Plug.Conn.read_body(conn))
  end

  scope "/", MfaMockup do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    resources "/users", UserController
  end

  # Other scopes may use custom stacks.
  scope "/confirm", MfaMockup do
    pipe_through :api

    post "/", MfaController, :callback
  end
end
