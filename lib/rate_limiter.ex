defmodule Bnetapi.RateLimiter do
  alias Bnetapi.RateLimiters
  @callback make_request(request_handler :: tuple(), response_handler :: tuple()) :: :ok

  def make_request(request_handler, response_handler) do
    get_rate_limiter().make_request(request_handler, response_handler)
  end

  def make_request_sync(request_handler) do
    get_rate_limiter().make_request_sync(request_handler)
  end

  def get_rate_limiter, do: get_rate_limiter_config(:rate_limiter)
  def get_requests_per_timeframe, do: get_rate_limiter_config(:timeframe_max_requests)
  def get_timeframe_unit, do: get_rate_limiter_config(:timeframe_units)
  def get_timeframe, do: get_rate_limiter_config(:timeframe)

  def calculate_refresh_rate(num_requests, time, timeframe_units) do
    floor(convert_time_to_milliseconds(timeframe_units, time) / num_requests)
  end

  def convert_time_to_milliseconds(:hours, time), do: :timer.hours(time)
  def convert_time_to_milliseconds(:minutes, time), do: :timer.minutes(time)
  def convert_time_to_milliseconds(:seconds, time), do: :timer.seconds(time)
  def convert_time_to_milliseconds(:milliseconds, milliseconds), do: milliseconds

  defp get_rate_limiter_config(config) do
    default = case config do
      :rate_limiter -> RateLimiters.LeakyBucket
      :timeframe_max_requests -> 10
      :timeframe_units -> :seconds
      :timeframe -> 1
    end

    env_config = :seer |> Application.get_env(RateLimiter)
    case is_nil(env_config) do
      true -> default
      false -> Keyword.get(env_config, config, default)
    end
  end
end
