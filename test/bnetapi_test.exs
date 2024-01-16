defmodule BnetapiTest do
  use ExUnit.Case, async: false

  test "access_token" do
    {:ok, resp} = Bnetapi.Client.get_access_token()
    assert resp["access_token"] == "testlRn6TX1Ea1EBLR1tK2wkpvVVPdF1md"
    assert resp["expires_in"] == 86399
  end

  test "character summary" do
    {:ok, summary} = Bnetapi.Api.character_profile_summary("proudmoore", "yungaltarboy")
    assert summary["level"] == 26
    assert summary["name"] == "Yungaltarboy"
    assert summary["faction"]["type"] == "ALLIANCE"
  end

  test "character media summary" do
    {:ok, summary} = Bnetapi.Api.character_media_summary("proudmoore", "yungaltarboy")
    assert Enum.at(summary["assets"], 2)["key"] == "main-raw"
    assert Enum.at(summary["assets"], 2)["value"] == "https://render.worldofwarcraft.com/us/character/proudmoore/152/242158744-main-raw.png"
  end
end
