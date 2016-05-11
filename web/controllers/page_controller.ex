defmodule Thumber.PageController do
  use Thumber.Web, :controller
  alias Thumber.Thumbnail
  import Ecto.Query

  def index(conn, %{ "url" => url } = params) do
    thumb = case find_thumb(params) do
              %Thumbnail{} = thumb -> thumb
              nil -> create_thumb(url)
            end

    send_png(conn, thumb.path)
  end

  def index(conn, _params) do
    conn
    |> put_status(400)
    |> text("Missing parameter: url")
  end

  defp hash_path(path) do
    :crypto.hmac(:sha256, '', path)
    |> Base.encode64
  end

  defp send_png(conn, path, age \\ 604_800) do
    conn
    |> put_resp_header("content-type", "image/png")
    |> put_resp_header("cache-control", "public, max-age=#{age}")
    |> put_resp_header("etag", hash_path(path))
    |> send_file(200, path)
  end

  def find_thumb(%{"url" => url} = params) do
    # If no age is specified
    days = case params[:age] do
             nil -> -7
             x -> - String.to_integer(x)
           end

    Repo.one(from t in Thumbnail,
      where: t.url == ^url,
      where: t.inserted_at >= datetime_add(^Ecto.DateTime.utc, ^days, "day"))
  end

  def create_thumb(url) do
    qs = URI.encode_query(%{url: url, timeout: "1000"})
    phantom_url = String.to_char_list("http://localhost:8080?#{qs}")

    case :httpc.request(:get, {phantom_url, []}, [], []) do
      {:ok, {{_, 200, 'OK'}, _headers, body}} ->
        file = String.strip(to_string(body))
        if File.exists?(file) do
          changeset = Thumbnail.changeset(%Thumbnail{},
            %{url: url, path: file})
          case Repo.insert(changeset) do
            {:ok, thumbnail} -> thumbnail
            _ -> raise "Could not create a new thumbnail."
          end
        else
          raise "Invalid path: #{file}"
        end
      {:error, {:failed_connect, _}} ->
        # TODO: restart the phantom server?
        raise "The Phantom server has stopped!"
      other ->
        raise "Got response: #{other}"
    end
  end
end
