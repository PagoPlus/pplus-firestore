defmodule PPlusFireStore do
  @moduledoc """
  Documentation for `PPlusFireStore`.
  """

  use Supervisor

  # Note:
  # Which is better?
  # - Receive a single module. Then we will have one process for each supervisor (PPlusFireStore)
  # - Receive a list of modules. Then we will have a single supervisor managing multiple processes.

  def start_link(modules) when is_list(modules) do
    Supervisor.start_link(__MODULE__, modules, name: __MODULE__)
  end

  @impl true
  def init(modules) do
    children =
      Enum.map(modules, fn module ->
        {Goth, name: module, source: {:service_account, credentials(module)}}
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp credentials(module) do
    Map.new(module.config(), fn {k, v} -> {to_string(k), v} end)
  end
end
