defmodule Bnetapi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Bnetapi.RateLimiter

  @impl true
  def start(_type, args) do
    prod_children = [
      {Finch, name: BnetapiFinch},
      {Task.Supervisor, name: RateLimiter.TaskSupervisor},
      {Bnetapi.RequestHandler, name: RequestHandler},
      {RateLimiter.get_rate_limiter(),
        %{
          timeframe_max_requests: RateLimiter.get_requests_per_timeframe(),
          timeframe_units: RateLimiter.get_timeframe_unit(),
          timeframe: RateLimiter.get_timeframe()
        }}
    ]

    test_children = prod_children ++ [{Plug.Cowboy, scheme: :http, plug: Bnetapi.MockServer, options: [port: 8081]}]

    children = case args do
      [env: :prod] -> prod_children
      [env: :dev] -> prod_children
      [env: :test] -> test_children
    end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bnetapi.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
