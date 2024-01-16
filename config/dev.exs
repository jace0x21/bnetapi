import Config

config :bnetapi,
  api_base_url: "https://us.api.blizzard.com",
  auth_uri: "https://oauth.battle.net/token"

config :bnetapi, RateLimiter,
  rate_limiter: Bnetapi.RateLimiters.LeakyBucket,
  timeframe_max_requests: 10,
  timeframe_units: :seconds,
  timeframe: 1
