defmodule Bnetapi.RequestHandler do
  use GenServer

  alias Bnetapi.Client

  # --- Client --- functions

  @spec make_request_sync(any()) :: any()
  def make_request_sync(request) do
    GenServer.call(__MODULE__, {:do_request, request})
  end

  # --- Server --- functions

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_elements) do
    initial_state = %{
      access_token: ""
    }
    {:ok, initial_state}
  end

  defp schedule_timer(expires_in) do
    Process.send_after(self(), :invalidate, :timer.seconds(expires_in - 20))
  end

  @impl true
  defp refresh() do
    access_token_info = Client.get_access_token()
    case access_token_info do
      {:ok, info} ->
        new_state = %{
          access_token: info["access_token"]
        }
        schedule_timer(info["expires_in"])
        {:ok, new_state}
      {:err, error} -> {:err, error}
    end
  end

  @impl true
  def handle_info(:invalidate, _state) do
    {:noreply, %{access_token: ""}}
  end

  @impl true
  def handle_call({:do_request, request}, _from, state) do
    case state.access_token do
      "" ->
        case refresh() do
          {:ok, new_state} ->
            headers = [{"Authorization", "Bearer " <> new_state.access_token}]
            {:reply, Client.get(request, headers), new_state}
          {:err, error} -> {:reply, {:err, error}, state}
        end
      _ ->
        headers = [{"Authorization", "Bearer " <> state.access_token}]
        {:reply, Client.get(request, headers), state}
    end
  end
end
