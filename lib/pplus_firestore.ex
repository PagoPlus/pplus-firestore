defmodule PPlusFireStore do
  @moduledoc """
  Documentation for `PPlusFireStore`.
  """
  use Supervisor

  @default_token_fetcher Goth

  def start_link(modules) when is_list(modules) do
    Supervisor.start_link(__MODULE__, modules, name: __MODULE__)
  end

  @impl true
  def init(modules) do
    children =
      Enum.map(modules, fn module ->
        {token_fetcher(module), name: module, source: {:service_account, credentials(module)}}
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp credentials(module) do
    module.config()
    |> Keyword.take([
      :project_id,
      :private_key_id,
      :private_key,
      :client_email,
      :client_id,
      :auth_uri,
      :token_uri,
      :auth_provider_x509_cert_url,
      :client_x509_cert_url
    ])
    |> Map.new(fn {k, v} -> {to_string(k), v} end)
  end

  defp token_fetcher(module) do
    module.config()[:token_fetcher] || @default_token_fetcher
  end
end
