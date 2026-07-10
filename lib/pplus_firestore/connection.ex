defmodule PPlusFireStore.Connection do
  @moduledoc """
  Handle connection with Google Firestore API


  configuration:

      config :google_api_firestore, :base_url, "https://my-custom-url.com/"

      config :pplus_firestore, PPlusFireStore.Connection,
        decompress_opts: [format: "gzip"]
  """

  use Tesla

  @type t :: Tesla.Env.client()
  @scopes [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/datastore"
  ]

  @base_url Application.compile_env(:google_api_firestore, :base_url, "https://firestore.googleapis.com/")
  @decompress_opts Application.compile_env(:pplus_firestore, [__MODULE__, :decompress_opts], [])

  plug(Tesla.Middleware.BaseUrl, @base_url)
  plug(Tesla.Middleware.DecompressResponse, @decompress_opts)
  plug(Tesla.Middleware.EncodeJson, engine: Poison)

  @doc """
  Configure a client connection using a provided OAuth2 token as a Bearer token

  ## Parameters

  *   `token` (*type:* `String.t`) - Bearer token

  ## Returns

  *   `Tesla.Env.client`
  """
  @spec new(String.t()) :: Tesla.Client.t()
  def new(token) when is_binary(token) do
    Tesla.client([
      {Tesla.Middleware.Headers, [{"authorization", "Bearer #{token}"}]}
    ])
  end

  @doc """
  Configure a client connection using a function which yields a Bearer token.

  ## Parameters

  *   `token_fetcher` (*type:* `list(String.t()) -> String.t()`) - Callback
      which provides an OAuth2 token given a list of scopes

  ## Returns

  *   `Tesla.Env.client`
  """
  @spec new((list(String.t()) -> String.t())) :: Tesla.Client.t()
  def new(token_fetcher) when is_function(token_fetcher) do
    @scopes
    |> token_fetcher.()
    |> new()
  end

  @doc """
  Configure an authless client connection

  ## Returns

  *   `Tesla.Env.client`
  """
  @spec new() :: Tesla.Client.t()
  def new do
    Tesla.client([])
  end

  @doc """
  Execute a request on this connection

  ## Returns

  *   `{:ok, Tesla.Env.t}` - If the call was successful
  *   `{:error, reason}` - If the call failed
  """
  @spec execute(Tesla.Client.t(), GoogleApi.Gax.Request.t()) :: {:ok, Tesla.Env.t()}
  def execute(connection, request) do
    request
    |> GoogleApi.Gax.Connection.build_request()
    |> then(&request(connection, &1))
  end
end
