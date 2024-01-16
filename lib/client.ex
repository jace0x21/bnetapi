defmodule Bnetapi.Client do
  @baseURI Application.compile_env(:bnetapi, :api_base_url, "https://us.api.blizzard.com")
  @oAuthURI Application.compile_env(:bnetapi, :auth_uri, "https://oauth.battle.net/token")

  alias Bnetapi.RateLimiter

  defp credentials() do
    clientId = Application.get_env(:bnetapi, :client_id, "")
    clientSecret = Application.get_env(:bnetapi, :client_secret, "")
    Base.encode64(clientId <> ":" <> clientSecret)
  end

  def get_access_token() do
    headers = [
      {"Authorization", "Basic " <> credentials()},
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Accept" , "*/*"}
    ]
    response = simple_post(@oAuthURI |> URI.parse(), headers, "grant_type=client_credentials")
    case response do
      {:ok, response} ->
        case response.status do
          200 -> {:ok, Poison.decode!(response.body)}
          _ -> {:err, "Unhandled response code: #{response.status}"}
        end
    end
  end

  def get(req, headers, response_handler \\ nil) do
    {endpoint, parameters} = req

    uri = (@baseURI <> endpoint) |> URI.parse()
    uri = case is_nil(parameters) do
      true  -> uri
      false -> uri |> Map.put(:query, URI.encode_query(parameters))
    end

    simple_get(uri, headers, response_handler)
  end

  defp simple_post(uri, headers, body, response_handler \\ nil) do
    case is_nil(response_handler) do
      true  -> post_request(uri, headers, body)
      false -> queue_post_request(uri, headers, body, response_handler)
    end
  end

  defp simple_get(uri, headers, response_handler \\ nil) do
    case is_nil(response_handler) do
      true  -> get_request(uri, headers)
      false -> queue_get_request(uri, headers, response_handler)
    end
  end

  defp queue_post_request(req, headers, body, response_handler) do
    RateLimiter.make_request(
      {Bnetapi.Client, :finch_post, [req, headers, body]},
      {Bnetapi.Client, response_handler}
    )
  end

  defp post_request(req, headers, body) do
    RateLimiter.make_request_sync(
      {Bnetapi.Client, :finch_post, [req, headers, body]}
    )
  end

  defp queue_get_request(req, headers, response_handler) do
    RateLimiter.make_request(
      {Bnetapi.Client, :finch_get, [req, headers]},
      {Bnetapi.Client, response_handler}
    )
  end

  defp get_request(req, headers) do
    RateLimiter.make_request_sync(
      {Bnetapi.Client, :finch_get, [req, headers]}
    )
  end

  def finch_post(uri, headers, body) do
    Finch.build(:post, URI.to_string(uri), headers, body) |> Finch.request(ThisFinch)
  end

  def finch_get(uri, headers) do
    Finch.build(:get, URI.to_string(uri), headers) |> Finch.request(ThisFinch)
  end
end
