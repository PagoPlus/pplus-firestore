defmodule PPlusFireStore.TokenFetcher do
  @moduledoc """

  Interface to implement a token fetcher service for Google Firestore access tokens.

  The token fetcher service is responsible for fetching and caching access tokens to Google Firestore.

  The token fetcher service must implement the `fetch/1` callback that receives the module of the repository that is requesting the access token.

  See the `PPlusFireStore.TokenFetcherMock` module for an example implementation of a token fetcher service.
  """
  @callback fetch(module :: module()) :: {:ok, %{token: String.t()}} | {:error, any()}

  defmacro __using__(_opts) do
    quote do
      @behaviour PPlusFireStore.TokenFetcher

      use GenServer
    end
  end
end
