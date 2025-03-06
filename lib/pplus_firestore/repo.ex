defmodule PPlusFireStore.Repo do
  @moduledoc """
  Documentation for `PPlusFireStore.Repo`.

  PPlusFireStore.Repo is a simplified API to interact with Google Firestore.

  Each repository refers to a specific project and database.

  ## Usage

      defmodule MyFireStoreRepo do
        use PPlusFireStore.Repo, otp_app: :my_app
      end

  ## Configuration

      config :my_app, MyFireStoreRepo,
        project_id: "project-fake-123-xy-9zz",
        private_key_id: "abc123def456ghi789jkl012mno345pqr678stu901vwx234yz",
        private_key: "-----BEGIN PRIVATE KEY-----\\nMIIEvQIBAFAKEPRIVATEKEYwTDSERHFwLqESDgLKFDWFLRHSDFo5LKJDFA\\nAKDJFSLkfj3+4LKFJSDklsjfdlskJFLDSJKLFJSDFLJSDFLKJSDfljSDLJF\\n-----END PRIVATE KEY-----\\n",
        client_email: "firebase-adminsdk-fake@project-fake-123-xy-9zz.iam.gserviceaccount.com",
        client_id: "123456789012345678901",
        auth_uri: "https://accounts.google.com/o/oauth2/auth",
        token_uri: "https://oauth2.googleapis.com/token",
        auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
        client_x509_cert_url: "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fake%40project-fake-123-xy-9zz.iam.gserviceaccount.com"
        database_id: "(default)"

  By default `database_id` is "(default)", so it is optional.

  You can have a repository for each project and database you want to interact with.

  ## Examples

      defmodule MyFireStoreRepo do
        use PPlusFireStore.Repo, otp_app: :my_app
      end

      defmodule MyOtherFireStoreRepo do
        use PPlusFireStore.Repo, otp_app: :my_app
      end
  """

  alias PPlusFireStore.Model.Document
  alias PPlusFireStore.Model.Page

  @doc """
  Return firestore repo credentials

  ## Example

      iex> PPlusFireStore.Repo.config()
      [
        project_id: "project-fake-123-xy-9zz",
        private_key_id: "abc123def456ghi789jkl012mno345pqr678stu901vwx234yz",
        private_key: "-----BEGIN PRIVATE KEY-----\nMIIEvQIBAFAKEPRIVATEKEYwTDSERHFwLqESDgLKFDWFLRHSDFo5LKJDFA\nAKDJFSLkfj3+4LKFJSDklsjfdlskJFLDSJKLFJSDFLJSDFLKJSDfljSDLJF\n-----END PRIVATE KEY-----\n",
        client_email: "firebase-adminsdk-fake@project-fake-123-xy-9zz.iam.gserviceaccount.com",
        client_id: "123456789012345678901",
        auth_uri: "https://accounts.google.com/o/oauth2/auth",
        token_uri: "https://oauth2.googleapis.com/token",
        auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
        client_x509_cert_url: "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fake%40project-fake-123-xy-9zz.iam.gserviceaccount.com"
      ]
  """
  @callback config :: Keyword.t()

  @doc """
  Return firestore repo token

  ## Example

      iex> PPlusFireStore.Repo.token
      "ya29.c.c0FAKE0TOKEN1234ABC567DEFGHIJKLMNOPQR890STUVWXYZabcd567efghijklmno123pqrstuvw456xyz789ABCDEFGHIJKLMNOpqrstuvWXYz1234567890ABCDEFabcdefGHIJKLMNO98765PQRST4321UVWXYZabc123def456ghi789jkl012mno345pqr678stu901vwx234yzABCDEF123456GHIJKLMNOPQ789RSTUVWXYZabc123def456ghi789jkl012mno345pqr678stu901vwx234yz"

  """
  @callback token :: String.t()

  @doc """
  Create document in firestore

  ## Parameters
    - path: path to document:
      - example: "books" or "projects/project_id/databases/(default)/documents/books"
    - data: document data
    - opts: optional parameters. See: https://hexdocs.pm/google_api_firestore/GoogleApi.Firestore.V1.Api.Projects.html#firestore_projects_databases_documents_create_document/5

    Example:

      iex> PPlusFireStore.Repo.create_document("books/esgXQM7pqNCwQwYRJeBJ", %{author: "John Doe"})
      {:ok,
        %PPlusFireStore.Model.Document{
          path: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
          data: %{"author" => "John Due"},
          created_at: ~U[2025-01-10 17:14:04.738331Z],
          updated_at: ~U[2025-01-10 17:14:04.738331Z]
        }}
  """
  @callback create_document(path :: String.t(), data :: map(), opts :: Keyword.t()) ::
              {:ok, Document.t()} | {:error, any()}

  @doc """
  Get document from firestore

  ## Parameters
    - path: path to document:
      - example: "books/esgXQM7pqNCwQwYRJeBJ" or "projects/project_id/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ"
    - opts: optional parameters. See: https://hexdocs.pm/google_api_firestore/GoogleApi.Firestore.V1.Api.Projects.html#firestore_projects_databases_documents_get/4

    Example:

      iex> PPlusFireStore.Repo.get_document("books/esgXQM7pqNCwQwYRJeBJ")
      {:ok,
        %PPlusFireStore.Model.Document{
          path: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
          data: %{"author" => "John Due"},
          created_at: ~U[2025-01-10 17:14:04.738331Z],
          updated_at: ~U[2025-01-10 17:14:04.738331Z]
        }}
  """
  @callback get_document(path :: String.t(), opts :: Keyword.t()) ::
              {:ok, Document.t()} | {:error, any()}

  @doc """
  List documents from firestore

  ## Parameters
    - path: path to document:
      - example: "books" or "projects/project_id/databases/(default)/documents/books"
    - opts: optional parameters. See: https://hexdocs.pm/google_api_firestore/GoogleApi.Firestore.V1.Api.Projects.html#firestore_projects_databases_documents_list/5

    Examples:

      iex> PPlusFireStore.Repo.list_documents("books", pageSize: 1)
      {:ok,
        %PPlusFireStore.Model.Page{
          data: [
            %PPlusFireStore.Model.Document{
              path: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
              data: %{"author" => "John Due"},
              created_at: ~U[2025-01-10 17:14:04.738331Z],
              updated_at: ~U[2025-01-10 17:14:04.738331Z]
            }
          ],
          next_page_token: "AFTOeJwGTcAtgJAapbJ0K7tPwpH9saWYfm4bG991Kk4qdP3NXq9pFfp5IW-E6lwbnRW661DKMJjo5EA7y2iF8GFjaCPLlXN7c0jMYATSRgclgLEChgsSIBjt"
        }}

      iex> PPlusFireStore.Repo.list_documents("books", pageSize: 1, pageToken: "AFTOeJwGTcAtgJAapbJ0K7tPwpH9saWYfm4bG991Kk4qdP3NXq9pFfp5IW-E6lwbnRW661DKMJjo5EA7y2iF8GFjaCPLlXN7c0jMYATSRgclgLEChgsSIBjt")
      {:ok,
        %PPlusFireStore.Model.Page{
          data: [
            %PPlusFireStore.Model.Document{
              path: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
              data: %{"author" => "Another John Due"},
              created_at: ~U[2025-01-10 17:14:04.738331Z],
              updated_at: ~U[2025-01-10 17:14:04.738331Z]
            }
          ],
          next_page_token: "AFTOeJwZgHAqLXB5MfQy9RdN8KJ7vYWLn8KdGpM9X1EqMf2RJwL9Y5JrN3GpJwT4XKuT93HLKDZJg5LP8YiJ8QWnhCVLW7f5Tg2MRB7RKCwFgNJKgQ1VB"
        }}
  """
  @callback list_documents(path :: String.t(), opts :: Keyword.t()) ::
              {:ok, Page.t(Document.t())} | {:error, any()}

  @doc """
  Update document in firestore

  ## Parameters
    - path: path to document:
      - example: "books/esgXQM7pqNCwQwYRJeBJ" or "projects/project_id/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ"
    - data: document data
    - opts: optional parameters. See: https://hexdocs.pm/google_api_firestore/GoogleApi.Firestore.V1.Api.Projects.html#firestore_projects_databases_documents_update_document/5

    Example:

      iex> PPlusFireStore.Repo.update_document("books/esgXQM7pqNCwQwYRJeBJ", %{author: "John Doe da Silva"})
      {:ok,
        %PPlusFireStore.Model.Document{
          path: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
          data: %{"author" => "John Due da Silva"},
          created_at: ~U[2025-01-10 17:14:04.738331Z],
          updated_at: ~U[2025-01-10 17:14:04.738331Z]
        }}
  """
  @callback update_document(path :: String.t(), data :: map(), opts :: Keyword.t()) ::
              {:ok, Document.t()} | {:error, any()}

  @doc """
  Delete document from firestore

  ## Parameters
    - path: path to document:
      - example: "books/esgXQM7pqNCwQwYRJeBJ" or "projects/project_id/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ"
    - opts: optional parameters. See: https://hexdocs.pm/google_api_firestore/GoogleApi.Firestore.V1.Api.Projects.html#firestore_projects_databases_documents_delete/4

    Example:

      iex> PPlusFireStore.Repo.delete_document("books/esgXQM7pqNCwQwYRJeBJ")
      {:ok, :deleted}
  """
  @callback delete_document(path :: String.t(), opts :: Keyword.t()) ::
              {:ok, :deleted} | {:error, any()}

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour PPlusFireStore.Repo

      alias GoogleApi.Firestore.V1.Connection
      alias PPlusFireStore.API
      alias PPlusFireStore.Repo

      @config Application.compile_env(opts[:otp_app], __MODULE__, [])
      @project_id Keyword.get_lazy(@config, :project_id, fn ->
                    raise ArgumentError, "`project_id` is not set in config file for #{__MODULE__}"
                  end)
      @database_id Keyword.get(@config, :database_id, "(default)")
      @base_path "projects/#{@project_id}/databases/#{@database_id}/documents"
      @token_fetcher Keyword.get(@config, :token_fetcher, Goth)

      def config, do: @config

      def token do
        with {:ok, %{token: token}} <- @token_fetcher.fetch(__MODULE__) do
          token
        end
      end

      def create_document(path, data, opts \\ []) do
        full_path = build_path(path)
        parent = Path.dirname(full_path)
        collection = Path.basename(full_path)

        API.create_document(token(), parent, collection, data, opts)
      end

      def get_document(path, opts \\ []) do
        API.get_document(token(), build_path(path), opts)
      end

      def list_documents(path, opts \\ []) do
        full_path = build_path(path)
        parent = Path.dirname(full_path)
        collection = Path.basename(full_path)

        API.list_documents(token(), parent, collection, opts)
      end

      def run_query(path \\ "", query, opts \\ []) do
        API.run_query(token(), build_path(path), query, opts)
      end

      def update_document(path, data, opts \\ []) do
        API.update_document(token(), build_path(path), data, opts)
      end

      def delete_document(path, opts \\ []) do
        API.delete_document(token(), build_path(path), opts)
      end

      # if path is already a full path, don't prepend the base path
      defp build_path(path) do
        if String.contains?(path, @base_path) do
          path
        else
          Path.join(@base_path, path)
        end
      end

      defoverridable config: 0,
                     token: 0,
                     create_document: 3,
                     get_document: 2,
                     list_documents: 2,
                     update_document: 3,
                     delete_document: 2
    end
  end
end
