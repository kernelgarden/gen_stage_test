defmodule ManualHandling.Producer do
  use GenStage

  @max_buffer_size 10_000

  # Client

  def start_link() do
    GenStage.start_link(__MODULE__, :ok)
  end

  def notify(pid, message) do
    GenStage.cast(pid, {:notify, message})
  end

  # Server

  @impl GenStage
  def init(_args) do
    {:producer, buffer_size: @max_buffer_size}
  end

  @impl GenStage
  def handle_cast({:notify, message}, state) do
    IO.inspect("Dispatch msg - #{message}", label: "Debug")
    {:noreply, [message], state}
  end

  @impl GenStage
  def handle_demand(imcomming_demand, state) do
    {:noreply, [], state}
  end
end
