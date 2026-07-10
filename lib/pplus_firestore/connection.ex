# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Modified by MedFlow: adapted from the `GoogleApi.Gax.Connection` `__using__` macro
# into a concrete module with a configurable `Tesla.Middleware.DecompressResponse` option.

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
  @decompress_opts Application.compile_env(:pplus_firestore, [__MODULE__, :decompress_opts],
                     max_body_size: 32 * 1024 * 1024
                   )

  plug(Tesla.Middleware.BaseUrl, @base_url)
  plug(Tesla.Middleware.DecompressResponse, @decompress_opts)
  plug(Tesla.Middleware.EncodeJson, engine: Poison)

  @doc """
  Configure a client connection using a provided OAuth2 token as a Bearer token,
  or a function which yields one.

  ## Parameters

  *   `token` (*type:* `String.t`) - Bearer token
  *   `token_fetcher` (*type:* `list(String.t()) -> String.t()`) - Callback
      which provides an OAuth2 token given a list of scopes

  ## Returns

  *   `Tesla.Env.client`
  """
  @spec new(String.t() | (list(String.t()) -> String.t())) :: Tesla.Client.t()
  def new(token) when is_binary(token) do
    Tesla.client([
      {Tesla.Middleware.Headers, [{"authorization", "Bearer #{token}"}]}
    ])
  end

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
