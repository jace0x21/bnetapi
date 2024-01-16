import Config

config :bnetapi,
  api_base_url: "http://localhost:8081",
  auth_uri: "http://localhost:8081/token",
  client_id: "test",
  client_secret: "test"

config :bnetapi, RateLimiter,
  rate_limiter: Bnetapi.RateLimiters.LeakyBucket,
  timeframe_max_requests: 1000,
  timeframe_units: :seconds,
  timeframe: 1
