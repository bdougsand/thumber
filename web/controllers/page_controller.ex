defmodule Thumber.PageController do
  use Thumber.Web, :controller
  alias Thumber.Thumbnail

  def index(conn, %{ "url" => url }) do
    path = "thumb/test.png"
    thumb = %{url: url, path: path}
    changeset = Thumbnail.changeset(%Thumbnail{}, thumb)

    case Repo.insert(changeset) do
      {:ok, newThumb} ->
        conn
        |> put_resp_header("content-type", "image/png")
        |> put_resp_header("cache-control", "public, max-age=60")
        |> send_file(200, newThumb)

    end
    render conn, "index.html", url: url
  end

  def index(conn, _params) do
    render conn, "index.html", url: "none set"
  end
end
