defmodule PPlusFireStore.APITest do
  use ExUnit.Case

  alias GoogleApi.Firestore.V1.Api.Projects
  alias PPlusFireStore.API
  alias PPlusFireStore.Connection
  alias PPlusFireStore.Model.Document
  alias PPlusFireStore.Model.Page
  alias PPlusFireStore.TokenFetcherMock

  @parent "projects/my-project/databases/(default)/documents"
  @collection "books"

  setup do
    Application.put_env(:google_api_firestore, :base_url, "http://localhost:8200")

    {:ok, %{token: token}} = TokenFetcherMock.fetch(__MODULE__)

    clear_database(token)

    {:ok, token: token}
  end

  describe "create_document/4" do
    test "creates a document returns decoded document", %{token: token} do
      data = %{"author" => "John Doe"}

      assert {
               :ok,
               %Document{
                 created_at: %DateTime{},
                 data: %{"author" => "John Doe"},
                 path: <<@parent, "/", @collection, "/", _document_id::binary>>,
                 updated_at: %DateTime{}
               }
             } = API.create_document(token, @parent, @collection, data)
    end

    test "returns error if document already exists" do
      {:ok, %{token: token}} = TokenFetcherMock.fetch(__MODULE__)
      document_id = "esgXQM7pqNCwQwYRJeBJ"
      data = %{"author" => "John Doe"}

      assert {:ok, _} = API.create_document(token, @parent, @collection, data, documentId: document_id)

      assert {:error, :already_exists, %Tesla.Env{status: 409}} =
               API.create_document(token, @parent, @collection, data, documentId: document_id)
    end

    test "return error when token is invalid" do
      token = "invalid-token"

      data = %{"author" => "John Doe"}

      assert {:error, %Tesla.Env{status: 400}} = API.create_document(token, @parent, @collection, data)
    end

    test "returns error when unable to establish connection", %{token: token} do
      Application.put_env(:google_api_firestore, :base_url, "http://localhost:0000")
      data = %{"author" => "John Doe"}

      assert API.create_document(token, @parent, @collection, data) == {:error, :econnrefused}
    end
  end

  describe "get_document/2" do
    test "gets a document returns decoded document", %{token: token} do
      document_id = "esgXQM7pqNCwQwYRJeBJ"
      path = "#{@parent}/#{@collection}/#{document_id}"

      token
      |> Connection.new()
      |> Projects.firestore_projects_databases_documents_create_document(
        @parent,
        @collection,
        body: PPlusFireStore.Encoder.encode(%{"author" => "John Doe"}),
        documentId: document_id
      )

      assert {
               :ok,
               %Document{
                 created_at: %DateTime{},
                 data: %{"author" => "John Doe"},
                 path: "projects/my-project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
                 updated_at: %DateTime{}
               }
             } = API.get_document(token, path)
    end
  end

  describe "list_documents/3" do
    test "lists documents returns decoded page", %{token: token} do
      token
      |> Connection.new()
      |> Projects.firestore_projects_databases_documents_create_document(
        @parent,
        @collection,
        body: PPlusFireStore.Encoder.encode(%{"author" => "John Doe 1"}),
        documentId: "esgXQM7pqNCwQwYRJeBJ"
      )

      token
      |> Connection.new()
      |> Projects.firestore_projects_databases_documents_create_document(
        @parent,
        @collection,
        body: PPlusFireStore.Encoder.encode(%{"author" => "Jane Doe 2"}),
        documentId: "esgXQM7pqNCwQwYRJeBK"
      )

      assert {
               :ok,
               %Page{
                 data: [
                   %Document{
                     created_at: %DateTime{},
                     data: %{"author" => "John Doe 1"},
                     path: "projects/my-project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
                     updated_at: %DateTime{}
                   },
                   %Document{
                     created_at: %DateTime{},
                     data: %{"author" => "Jane Doe 2"},
                     path: "projects/my-project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBK",
                     updated_at: %DateTime{}
                   }
                 ],
                 next_page_token: nil
               }
             } = API.list_documents(token, @parent, @collection)
    end
  end

  describe "list_documents/4" do
    test "lists documents with opts returns decoded page", %{token: token} do
      ids = ["esgXQM7pqNCwQwYRJeBJ", "esgXQM7pqNCwQwYRJeBK", "esgXQM7pqNCwQwYRJeBL"]

      ids
      |> Enum.with_index()
      |> Enum.each(fn {document_id, index} ->
        token
        |> Connection.new()
        |> Projects.firestore_projects_databases_documents_create_document(
          @parent,
          @collection,
          body: PPlusFireStore.Encoder.encode(%{"author" => "John Doe #{index + 1}"}),
          documentId: document_id
        )
      end)

      assert {:ok,
              %Page{
                data: [
                  %Document{
                    created_at: %DateTime{},
                    data: %{"author" => "John Doe 1"},
                    path: "projects/my-project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
                    updated_at: %DateTime{}
                  }
                ],
                next_page_token: _next_page_token
              }} = API.list_documents(token, @parent, @collection, pageSize: 1)
    end
  end

  describe "update_document/4" do
    test "updates a document returns decoded document", %{token: token} do
      {:ok, document} =
        token
        |> Connection.new()
        |> Projects.firestore_projects_databases_documents_create_document(
          "projects/my-project/databases/(default)/documents",
          "books",
          body: PPlusFireStore.Encoder.encode(%{"author" => "John Doe"}),
          documentId: "esgXQM7pqNCwQwYRJeBJ"
        )

      path = document.name
      data = %{"author" => "John Doe da Silva"}

      assert {
               :ok,
               %Document{
                 created_at: %DateTime{},
                 data: %{"author" => "John Doe da Silva"},
                 path: ^path,
                 updated_at: %DateTime{}
               }
             } = API.update_document(token, path, data)
    end
  end

  describe "delete_document/2" do
    test "deletes a document", %{token: token} do
      document_id = "esgXQM7pqNCwQwYRJeBJ"

      token
      |> Connection.new()
      |> Projects.firestore_projects_databases_documents_create_document(
        @parent,
        @collection,
        body: PPlusFireStore.Encoder.encode(%{"author" => "John Doe"}),
        documentId: document_id
      )

      path = "#{@parent}/#{@collection}/#{document_id}"

      assert API.delete_document(token, path) == :ok
    end

    test "return error if document does not exist", %{token: token} do
      path = "#{@parent}/#{@collection}/esgXQM7pqNCwQwYRJeBJ"

      assert {:error, :not_found, %Tesla.Env{status: 404}} = API.delete_document(token, path)
    end
  end

  defp clear_database(token) do
    client = Connection.new(token)

    client
    |> Projects.firestore_projects_databases_documents_list(@parent, @collection)
    |> elem(1)
    |> Map.get(:documents)
    |> Kernel.||([])
    |> Enum.map(& &1.name)
    |> Enum.map(&Projects.firestore_projects_databases_documents_delete(client, &1))
  end
end
