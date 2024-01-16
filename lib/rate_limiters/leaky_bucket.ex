defmodule Bnetapi.RateLimiters.LeakyBucket do
  use GenServer

  require Logger

  alias Bnetapi.RateLimiter

  @behaviour RateLimiter

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    # Erlang’s queue implementation does not keep track of the queue size,
    # and calling :queue.len(my_queue) is an O(N) operation
    # (https://erlang.org/doc/man/queue.html#len-1).
    state = %{
      request_queue: :queue.new(),
      request_queue_size: 0,
      request_queue_poll_rate:
        RateLimiter.calculate_refresh_rate(opts.timeframe_max_requests, opts.timeframe, opts.timeframe_units),
      send_after_ref: nil
    }

    {:ok, state, {:continue, :initial_timer}}
  end

  # --- Client ---

  @impl RateLimiter
  def make_request(request_handler, response_handler) do
    GenServer.cast(__MODULE__, {:enqueue_async_request, request_handler, response_handler})
  end

  def make_request_sync(request_handler) do
    GenServer.call(__MODULE__, {:enqueue_sync_request, request_handler})
  end

  # --- Server ---

  @impl true
  def handle_continue(:initial_timer, state) do
    {:noreply, %{state | send_after_ref: schedule_timer(state.request_queue_poll_rate)}}
  end

  @impl true
  def handle_cast({:enqueue_async_request, request_handler, response_handler}, state) do
    updated_queue = :queue.in({:async, {request_handler, response_handler}}, state.request_queue)
    new_queue_size = state.request_queue_size + 1

    {:noreply, %{state | request_queue: updated_queue, request_queue_size: new_queue_size}}
  end

  @impl true
  def handle_call({:enqueue_sync_request, request_handler}, from, state) do
    updated_queue = :queue.in({:sync, {request_handler, from}}, state.request_queue)
    new_queue_size = state.request_queue_size + 1

    {:noreply, %{state | request_queue: updated_queue, request_queue_size: new_queue_size}}
  end

  @impl true
  def handle_info(:pop_from_request_queue, %{request_queue_size: 0} = state) do
    {:noreply, %{state | send_after_ref: schedule_timer(state.request_queue_poll_rate)}}
  end

  @impl true
  def handle_info(:pop_from_request_queue, state) do
    {{:value, {request_type, arguments}}, new_request_queue} = :queue.out(state.request_queue)
    start_message = "Request started #{NaiveDateTime.utc_now()}"

    case request_type do
      :async ->
        Task.Supervisor.async_nolink(RateLimiter.TaskSupervisor, fn ->
          {request_handler, response_handler} = arguments
          {req_module, req_function, req_args} = request_handler
          {resp_module, resp_function} = response_handler

          response = apply(req_module, req_function, req_args)
          apply(resp_module, resp_function, [response])

          Logger.info("#{start_message}\nRequest completed #{NaiveDateTime.utc_now()}")
        end)
      :sync ->
        Task.Supervisor.async_nolink(RateLimiter.TaskSupervisor, fn ->
          {request_handler, from} = arguments
          {req_module, req_function, req_args} = request_handler

          response = apply(req_module, req_function, req_args)
          GenServer.reply(from, response)

          Logger.info("#{start_message}\nRequest completed #{NaiveDateTime.utc_now()}")
        end)
    end

    {:noreply,
      %{
        state
        | request_queue: new_request_queue,
          send_after_ref: schedule_timer(state.request_queue_poll_rate),
          request_queue_size: state.request_queue_size - 1
      }
    }
  end

  def handle_info({ref, _result}, state) do
    Process.demonitor(ref, [:flush])

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    {:noreply, state}
  end

  defp schedule_timer(queue_poll_rate) do
    Process.send_after(self(), :pop_from_request_queue, queue_poll_rate)
  end
end
