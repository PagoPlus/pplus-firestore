defmodule PPlusFireStore.API do
  @moduledoc """
  Module to interact with Google Firestore API
  """
  alias GoogleApi.Firestore.V1.Api.Projects
  alias GoogleApi.Firestore.V1.Model.RunQueryRequest
  alias GoogleApi.Firestore.V1.Model.StructuredQuery
  alias PPlusFireStore.Connection
  alias PPlusFireStore.Decoder
  alias PPlusFireStore.Encoder
  alias PPlusFireStore.Model.Document
  alias PPlusFireStore.Model.Page

  @doc """
  Create document

  ## Parameters
    - auth_token: auth token
    - parent: The parent resource. For example: `projects/{project_id}/databases/{database_id}/documents` or `projects/{project_id}/databases/{database_id}/documents/chatrooms/{chatroom_id}`
    - collection: collection name
    - data: map with document data
    - opts: optional parameters. See: https://hexdocs.pm/google_api_firestore/GoogleApi.Firestore.V1.Api.Projects.html#firestore_projects_databases_documents_create_document/5

    Example:

      iex> PPlusFireStore.API.create_document("token", "projects/my_project/databases/(default)/documents", "books", %{author: "John Doe"})
      {:ok,
        %PPlusFireStore.Model.Document{
          path: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
          data: %{"author" => "Jhon Due"},
          created_at: ~U[2025-01-10 17:14:04.738331Z],
          updated_at: ~U[2025-01-10 17:14:04.738331Z]
        }}

    Note: One of the optional parameters is `documentId`, which is the id of the document to be created. If not provided, Firestore will generate an id automatically. It is important to pass the document id if you want to control the creation of duplicate documents.
  """
  @spec create_document(
          auth_token :: String.t(),
          parent :: String.t(),
          collection :: String.t(),
          data :: map(),
          opts :: Keyword.t()
        ) ::
          {:ok, Document.t()}
          | {:error, :conflict, Tesla.Env.t()}
          | {:error, Tesla.Env.t()}
          | {:error, any()}

  def create_document(auth_token, parent, collection, data, opts \\ []) do
    opts = Keyword.put(opts, :body, Encoder.encode(data))

    auth_token
    |> Connection.new()
    |> Projects.firestore_projects_databases_documents_create_document(parent, collection, opts)
    |> handle_response()
  end

  @doc """
  Get document from firestore

  ## Parameters
    - auth_token: auth token
    - path: The name of the document to retrieve. For example: `projects/{project_id}/databases/{database_id}/documents/{document_path}`
    - opts: optional parameters. See: https://hexdocs.pm/google_api_firestore/GoogleApi.Firestore.V1.Api.Projects.html#firestore_projects_databases_documents_get/4

    Example:
      iex> PPlusFireStore.API.get_document("token", "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ")
      {:ok,
        %PPlusFireStore.Model.Document{
          path: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
          data: %{"author" => "Jhon Due"},
          created_at: ~U[2025-01-10 17:14:04.738331Z],
          updated_at: ~U[2025-01-10 17:14:04.738331Z]
        }}
  """
  @spec get_document(
          auth_token :: String.t(),
          path :: String.t(),
          opts :: Keyword.t()
        ) ::
          {:ok, Document.t()}
          | {:error, :not_found, Tesla.Env.t()}
          | {:error, Tesla.Env.t()}
          | {:error, any()}

  def get_document(auth_token, path, opts \\ []) do
    auth_token
    |> Connection.new()
    |> Projects.firestore_projects_databases_documents_get(path, opts)
    |> handle_response()
  end

  @doc """
  List documents from firestore

  ## Parameters
    - auth_token: auth token
    - parent: The parent resource. For example: `projects/{project_id}/databases/{database_id}/documents` or `projects/{project_id}/databases/{database_id}/documents/chatrooms/{chatroom_id}`
    - collection: collection name
    - opts: optional parameters. See: https://hexdocs.pm/google_api_firestore/GoogleApi.Firestore.V1.Api.Projects.html#firestore_projects_databases_documents_list/5

    Example:
      iex> PPlusFireStore.API.list_documents("token", "projects/my_project/databases/(default)/documents", "books", pageSize: 1)
      {:ok,
        %PPlusFireStore.Model.Page{
          data: [
            %PPlusFireStore.Model.Document{
              path: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
              data: %{"author" => "Jhon Due"},
              created_at: ~U[2025-01-10 17:14:04.738331Z],
              updated_at: ~U[2025-01-10 17:14:04.738331Z]
            }
          ],
          next_page_token: "AFTOeJwGTcAtgJAapbJ0K7tPwpH9saWYfm4bG991Kk4qdP3NXq9pFfp5IW-E6lwbnRW661DKMJjo5EA7y2iF8GFjaCPLlXN7c0jMYATSRgclgLEChgsSIBjt"
        }}
  """
  @spec list_documents(
          auth_token :: String.t(),
          parent :: String.t(),
          collection :: String.t(),
          opts :: Keyword.t()
        ) ::
          {:ok, Page.t(Document.t())}
          | {:error, Tesla.Env.t()}
          | {:error, any()}

  def list_documents(auth_token, parent, collection, opts \\ []) do
    auth_token
    |> Connection.new()
    |> Projects.firestore_projects_databases_documents_list(parent, collection, opts)
    |> handle_response()
  end

  @spec run_query(auth_token :: String.t(), parent :: String.t(), query :: StructuredQuery.t(), opts :: Keyword.t()) ::
          {:ok, Page.t(Document.t())}
          | {:error, Tesla.Env.t()}
          | {:error, any()}
  def run_query(auth_token, parent, query, opts \\ []) do
    body = %RunQueryRequest{structuredQuery: query}
    opts = Keyword.put(opts, :body, body)

    auth_token
    |> Connection.new()
    |> Projects.firestore_projects_databases_documents_run_query(parent, opts)
    |> handle_response()
  end

  @doc """
  Update document in firestore

  ## Parameters
    - auth_token: auth token
    - path: The name of the document to update. For example: `projects/{project_id}/databases/{database_id}/documents/{document_path}`
    - data: map with document data
    - opts: optional parameters. See: https://hexdocs.pm/google_api_firestore/GoogleApi.Firestore.V1.Api.Projects.html#firestore_projects_databases_documents_patch/5

    Example:

      iex> PPlusFireStore.API.update_document("token", "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ", %{author: "John Doe da Silva"})
      {:ok,
        %PPlusFireStore.Model.Document{
          path: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
          data: %{"author" => "Jhon Due da Silva"},
          created_at: ~U[2025-01-10 17:14:04.738331Z],
          updated_at: ~U[2025-01-10 17:14:04.738331Z]
        }}
  """
  @spec update_document(
          auth_token :: String.t(),
          path :: String.t(),
          data :: map(),
          opts :: Keyword.t()
        ) ::
          {:ok, Document.t()}
          | {:error, Tesla.Env.t()}
          | {:error, any()}

  def update_document(auth_token, path, data, opts \\ []) do
    opts = Keyword.put(opts, :body, Encoder.encode(data))

    auth_token
    |> Connection.new()
    |> Projects.firestore_projects_databases_documents_patch(path, opts)
    |> handle_response()
  end

  @doc """
  Delete document from firestore

  ## Parameters
    - auth_token: auth token
    - path: The name of the document to delete. For example: `projects/{project_id}/databases/{database_id}/documents/{document_path}`
    - opts: optional parameters. See: https://hexdocs.pm/google_api_firestore/GoogleApi.Firestore.V1.Api.Projects.html#firestore_projects_databases_documents_delete/4

    Example:

      iex> PPlusFireStore.API.delete_document("token", "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ")
      {:ok, :deleted}
  """
  @spec delete_document(
          auth_token :: String.t(),
          path :: String.t(),
          opts :: Keyword.t()
        ) ::
          :ok
          | {:error, :not_found, Tesla.Env.t()}
          | {:error, Tesla.Env.t()}
          | {:error, any()}

  def delete_document(auth_token, path, opts \\ []) do
    document_exists = Keyword.get(opts, :"currentDocument.exists", true)
    opts = Keyword.put(opts, :"currentDocument.exists", document_exists)

    response =
      auth_token
      |> Connection.new()
      |> Projects.firestore_projects_databases_documents_delete(path, opts)
      |> handle_response()

    case response do
      {:ok, nil} -> :ok
      _ -> response
    end
  end

  defp handle_response({:ok, response}) when is_list(response), do: {:ok, Enum.map(response, &Decoder.decode/1)}
  defp handle_response({:ok, response}), do: {:ok, Decoder.decode(response)}

  defp handle_response({:error, %Tesla.Env{status: 404} = reason}), do: {:error, :not_found, reason}
  defp handle_response({:error, %Tesla.Env{status: 409} = reason}), do: {:error, :conflict, reason}
  defp handle_response({:error, reason}), do: {:error, reason}
end
