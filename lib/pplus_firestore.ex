defmodule PPlusFireStore do
  @moduledoc """
  Documentation for `PPlusFireStore`.

  This module is responsible for initializing the service that will manage access tokens to Google Firestore with the access credentials configured for your Firestore repository module.

  By default, the service responsible for fetching the access token is [Goth](https://github.com/peburrows/goth), but you can configure another access token fetching service through the `:token_fetcher` key in your repository configuration.

  [Goth](https://github.com/peburrows/goth) uses the configured access credentials to fetch the access token and cache it. When requested, the service retrieves the access token from the cache and checks if it is still valid. If the access token is not in the cache or has expired, the service will fetch a new access token.

  ## Usage

  Define a repository module that implements the PPlusFireStore.Repo interface.
  ```elixir
  defmodule MyFireStoreRepo do
    use PPlusFireStore.Repo, otp_app: :my_app
  end
  ```

  Configure the repository module with Google Firestore credentials and add it to your supervision tree.
  ```elixir
  defmodule MyApp.Application do
    use Application

    @impl true
    def start(_type, _args) do
      children = [
        {PPlusFireStore, [MyFireStoreRepo]}
      ]

      opts = [strategy: :one_for_one, name: MyApp.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end
  ```

  You can have more than one configured repository module, just add more repository modules to the list of modules.
  ```elixir
  children = [
    {PPlusFireStore, [MyFireStoreRepo, MyOtherFireStoreRepo]}
  ]
  ```
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
