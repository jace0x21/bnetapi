defmodule Bnetapi.Api do
  alias Bnetapi.RequestHandler

  def character_profile_summary(realm, character, region \\ "us", namespace \\ "profile-us", locale \\ "en_US") do
    endpoint = "/profile/wow/character/" <> realm <> "/" <> character
    parameters = %{
      region: region,
      namespace: namespace,
      locale: locale
    }

    make_request({endpoint, parameters})
  end

  def character_media_summary(realm, character, region \\ "us", namespace \\ "profile-us", locale \\ "en_US") do
    endpoint = "/profile/wow/character/" <> realm <> "/" <> character <> "/character-media"
    parameters = %{
      region: region,
      namespace: namespace,
      locale: locale
    }

    make_request({endpoint, parameters})
  end

  defp make_request(request) do
    case RequestHandler.make_request_sync(request) do
      {:ok, response} ->
        case response.status do
          200 -> {:ok, Poison.decode!(response.body)}
          _ -> {:err, "Unhandled response code: " <> response.status}
        end
      {:err, error} -> {:err, error}
    end
  end
end
