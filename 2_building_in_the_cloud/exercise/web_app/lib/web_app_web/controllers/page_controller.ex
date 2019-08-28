defmodule WebAppWeb.PageController do
  use WebAppWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
