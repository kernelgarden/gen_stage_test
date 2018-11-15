defmodule DemandHandling.Consumer do
  use GenStage

  require Logger

  @min_demand 1
  @max_demand 2


  def start_link(), do: start_link([])
  def start_link(_), do: GenStage.start_link(__MODULE__, :ok)

  def init(:ok) do
    state = %{producer: DemandHandling.Producer, subscription: nil}

    GenStage.async_subscribe(
      self(),
      to: state.producer,
      min_demand: @min_demand,
      max_demand: @max_demand
    )

    {:consumer, state}
  end

  def handle_subscribe(:producer, _opts, from, state) do
    {:automatic, Map.put(state, :subscription, from)}
  end

  def handle_info(:init_ask, %{subscription: subscription} = state) do
    GenStage.ask(subscription, @max_demand)

    {:noreply, [], state}
  end
  def handle_info(_, state), do: {:noreply, [], state}

  def handle_events(events, _from, %{subscription: subscription} = state)
    when is_list(events)
  do
    IO.puts("Received Msg From #{inspect subscription} - #{inspect events}")

    {:noreply, [], state}
  end
  def handle_events(_events, _from, state), do: {:noreply, [], state}
end
