defmodule ManualHandling.Consumer do
  use GenStage

  @max_demand 10

  defstruct [:next_id, :producer, :producer_from, :pending_requests]

  # Client

  def start_link(producer) do
    GenStage.start_link(__MODULE__, producer)
  end

  # Server

  @impl GenStage
  def init(producer) do
    state = %__MODULE__{
      next_id: 0,
      producer: producer,
      producer_from: nil,
      pending_requests: %{},
    }

    send(self(), :init)

    {:consumer, state}
  end

  @impl GenStage
  def handle_info(:init, %{producer: producer} = state) do
    GenStage.async_subscribe(self(), to: producer, cancel: :temporary)
    {:noreply, [], state}
  end

  @impl GenStage
  def handle_info({:response, response}, state) do
    IO.inspect("Responsed msg - #{inspect response}", label: "Debug")
    new_state = handle_response(response, state)
    {:noreply, [], new_state}
  end

  @impl GenStage
  def handle_info(unknown_msg, state) do
    IO.puts("Received unknown_msg - #{inspect unknown_msg}")
    {:noreply, state}
  end

  @impl GenStage
  def handle_subscribe(:producer, _opts, from, state) do
    GenStage.ask(from, @max_demand)
    IO.inspect("Subscribe to #{inspect from}", label: "Debug")
    {:manual, %{state | producer_from: from}}
  end

  @impl GenStage
  def handle_events(messages, _from, state) do
    state = Enum.reduce(messages, state, &do_send/2)

    {:noreply, [], state}
  end

  defp do_send(message, %{pending_requests: pending_requests} = state) do
    {task_id, state} = generate_id(state)

    consumer = self()
    spawn(fn ->
      #3_000
      10
      |> :rand.uniform
      |> div(1000)
      |> :timer.seconds()
      |> Process.sleep()
      IO.puts("[Task##{task_id}] Received msg: #{message}")
      send(consumer, {:response, %{dispatch_id: task_id}})
    end)

    pending_requests = Map.put(pending_requests, task_id, message)

    %{state | pending_requests: pending_requests}
  end

  defp handle_response(
         %{dispatch_id: dispatch_id} = response,
         %{pending_requests: pending_requests, producer_from: producer_from} = state
       )
  do
    {_, pending_requests} = Map.pop(pending_requests, dispatch_id)

    GenStage.ask(producer_from, 1)

    %{state | pending_requests: pending_requests}
  end

  def generate_id(%{next_id: next_id} = state) do
    {to_string(next_id), %{state | next_id: next_id + 1}}
  end
end
