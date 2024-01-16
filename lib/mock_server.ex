defmodule Bnetapi.MockServer do
  use Plug.Router
  plug :match
  plug :dispatch

  post "/token" do
    authorization_header = get_req_header(conn, "authorization")
    content_type_header = get_req_header(conn, "content-type")
    {:ok, body, _} = read_body(conn, length: 29)
    case {authorization_header, content_type_header, body} do
      {["Basic dGVzdDp0ZXN0"], ["application/x-www-form-urlencoded"], "grant_type=client_credentials"} ->
        success(conn, File.read!("test/mock_responses/access_token.json"))
      _ -> failure(conn, "error")
    end
  end

  get "/profile/wow/character/proudmoore/yungaltarboy" do
    authorization_header = get_req_header(conn, "authorization")
    query = URI.decode_query(conn.query_string)
    case {authorization_header, query} do
      {["Bearer testlRn6TX1Ea1EBLR1tK2wkpvVVPdF1md"], %{"region" => "us", "namespace" => "profile-us", "locale" => "en_US"}} ->
        success(conn, File.read!("test/mock_responses/yungaltarboy_summary.json"))
      _ -> failure(conn, "error")
    end
  end

  get "/profile/wow/character/proudmoore/yungaltarboy/character-media" do
    authorization_header = get_req_header(conn, "authorization")
    query = URI.decode_query(conn.query_string)
    case {authorization_header, query} do
      {["Bearer testlRn6TX1Ea1EBLR1tK2wkpvVVPdF1md"], %{"region" => "us", "namespace" => "profile-us", "locale" => "en_US"}} ->
        success(conn, File.read!("test/mock_responses/yungaltarboy_media_summary.json"))
      _ -> failure(conn, "error")
    end
  end

  defp success(conn, response) do
    conn
    |> Plug.Conn.send_resp(200, response)
  end

  defp failure(conn, response) do
    conn
    |> Plug.Conn.send_resp(404, response)
  end
  end
