import Config

{client_id, client_secret} = case Mix.env() do
  :dev ->
    client_id = System.get_env("BNET_CLIENT_ID") ||
      raise "Error: Please set BNET_CLIENT_ID"
    client_secret = System.get_env("BNET_CLIENT_SECRET") ||
      raise "Error: Please get BNET_CLIENT_SECRET"
    {client_id, client_secret}
  :test -> {"test", "test"}
end

config :bnetapi,
  client_id: client_id,
  client_secret: client_secret
