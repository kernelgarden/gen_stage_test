defmodule DemandHandling.Producer do
  use GenStage

  require Logger

  def start_link() do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    state = %{events: [], events_count: 0, demand: 0}

    {:producer, state, []}
  end

  def handle_info(msg, state) do
    IO.inspect("recevied msg - #{msg}", label: "debug")
    {:noreply, [], state}
  end

  def handle_demand(incomming_demand, %{demand: demand} = state) do
    new_state = Map.put(state, :demand, demand + incomming_demand)

    dispatch_events(new_state)
  end

  defp dispatch_events(%{events: events, events_count: events_count, demand: demand} = state)
       when events_count >= demand do
    {events_to_dispatch, remaining_events} = Enum.split(events, demand)

    # IO.puts("dispatch #{demand} msgs.")

    new_state =
      state
      |> Map.put(:events, remaining_events)
      |> Map.put(:events_count, events_count - demand)
      |> Map.put(:demand, 0)

    {:noreply, events_to_dispatch, new_state}
  end

  defp dispatch_events(%{events: events, events_count: events_count, demand: demand} = state)
       when events_count < demand do
    events = events ++ fetch_events(demand)

    state
    |> Map.put(:events, events)
    |> Map.put(:events_count, events_count + demand)
    |> Map.put(:demand, demand)
    |> dispatch_events()
  end

  defp fetch_events(demand) do
    List.duplicate("This is an event.", demand)
  end
end
