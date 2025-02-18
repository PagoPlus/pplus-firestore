defmodule PPlusFireStore.APITest do
  use ExUnit.Case

  import Tesla.Mock

  alias PPlusFireStore.API
  alias PPlusFireStore.Model.Document
  alias PPlusFireStore.Model.Page

  setup do
    Application.put_env(:tesla, :adapter, Tesla.Mock)
  end

  describe "create_document/4" do
    test "creates a document returns decoded document" do
      auth_token = "my-token"
      parent = "projects/my_project/databases/(default)/documents"
      collection = "books"
      data = %{"author" => "John Doe"}
      document_id = "esgXQM7pqNCwQwYRJeBJ"

      mock(fn %Tesla.Env{
                method: :post,
                url: "https://firestore.googleapis.com/v1/" <> ^parent <> "/" <> ^collection,
                headers: [_, {"authorization", "Bearer " <> ^auth_token} | _],
                body: ~s({"fields":{"author":{"stringValue":"John Doe"}}})
              } ->
        json(
          %{
            "name" => Path.join([parent, collection, document_id]),
            "fields" => %{"author" => %{"stringValue" => "John Doe"}},
            "createTime" => "2025-01-10T17:14:04.738331Z",
            "updateTime" => "2025-01-10T17:14:04.738331Z"
          },
          status: 200
        )
      end)

      assert API.create_document(auth_token, parent, collection, data) == {
               :ok,
               %Document{
                 created_at: ~U[2025-01-10 17:14:04.738331Z],
                 data: %{"author" => "John Doe"},
                 path: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
                 updated_at: ~U[2025-01-10 17:14:04.738331Z]
               }
             }
    end

    test "returns error if document already exists" do
      auth_token = "my-token"
      parent = "projects/my_project/databases/(default)/documents"
      collection = "books"
      document_id = "esgXQM7pqNCwQwYRJeBJ"
      data = %{"author" => "John Doe"}

      response =
        json(
          %{
            "error" => %{
              "code" => 409,
              "message" => "Document already exists: #{parent}/#{collection}/#{document_id}",
              "status" => "ALREADY_EXISTS"
            }
          },
          status: 409
        )

      mock(fn %Tesla.Env{
                method: :post,
                url: "https://firestore.googleapis.com/v1/" <> ^parent <> "/" <> ^collection,
                query: [documentId: ^document_id],
                headers: [_, {"authorization", "Bearer " <> ^auth_token} | _],
                body: ~s({"fields":{"author":{"stringValue":"John Doe"}}})
              } ->
        response
      end)

      assert API.create_document(auth_token, parent, collection, data, documentId: document_id) ==
               {:error, :conflict, response}
    end

    test "return error when token is invalid" do
      auth_token = "invalid-token"
      parent = "projects/my_project/databases/(default)/documents"
      collection = "books"
      data = %{"author" => "John Doe"}

      response =
        json(
          %{
            "error" => %{
              "code" => 401,
              "message" =>
                "Request had invalid authentication credentials. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project.",
              "status" => "UNAUTHENTICATED",
              "details" => [
                %{
                  "@type" => "type.googleapis.com/google.rpc.ErrorInfo",
                  "reason" => "ACCESS_TOKEN_TYPE_UNSUPPORTED",
                  "metadata" => %{
                    "method" => "google.firestore.v1.Firestore.GetOrListDocuments",
                    "service" => "firestore.googleapis.com"
                  }
                }
              ]
            }
          },
          status: 401
        )

      mock(fn %Tesla.Env{
                method: :post,
                url: "https://firestore.googleapis.com/v1/" <> ^parent <> "/" <> ^collection,
                headers: [_, {"authorization", "Bearer " <> ^auth_token} | _],
                body: ~s({"fields":{"author":{"stringValue":"John Doe"}}})
              } ->
        response
      end)

      assert API.create_document(auth_token, parent, collection, data) == {:error, :unauthorized, response}
    end

    test "returns error when unable to establish connection" do
      auth_token = "my-token"
      parent = "projects/my_project/databases/(default)/documents"
      collection = "books"
      data = %{"author" => "John Doe"}

      mock(fn %Tesla.Env{
                method: :post,
                url: "https://firestore.googleapis.com/v1/" <> ^parent <> "/" <> ^collection,
                headers: [_, {"authorization", "Bearer " <> ^auth_token} | _],
                body: ~s({"fields":{"author":{"stringValue":"John Doe"}}})
              } ->
        {:error, :econnrefused}
      end)

      assert API.create_document(auth_token, parent, collection, data) == {:error, :econnrefused}
    end
  end

  describe "get_document/2" do
    test "gets a document returns decoded document" do
      auth_token = "my-token"
      path = "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ"

      mock(fn %Tesla.Env{
                method: :get,
                url: "https://firestore.googleapis.com/v1/" <> ^path,
                headers: [_, {"authorization", "Bearer " <> ^auth_token} | _]
              } ->
        json(
          %{
            "name" => path,
            "fields" => %{"author" => %{"stringValue" => "John Doe"}},
            "createTime" => "2025-01-10T17:14:04.738331Z",
            "updateTime" => "2025-01-10T17:14:04.738331Z"
          },
          status: 200
        )
      end)

      assert API.get_document(auth_token, path) == {
               :ok,
               %Document{
                 created_at: ~U[2025-01-10 17:14:04.738331Z],
                 data: %{"author" => "John Doe"},
                 path: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
                 updated_at: ~U[2025-01-10 17:14:04.738331Z]
               }
             }
    end
  end

  describe "list_documents/3" do
    test "lists documents returns decoded page" do
      auth_token = "my-token"
      parent = "projects/my_project/databases/(default)/documents"
      collection = "books"

      mock(fn %Tesla.Env{
                method: :get,
                url: "https://firestore.googleapis.com/v1/" <> ^parent <> "/" <> ^collection,
                headers: [_, {"authorization", "Bearer " <> ^auth_token} | _]
              } ->
        json(
          %{
            "documents" => [
              %{
                "name" => "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
                "fields" => %{"author" => %{"stringValue" => "John Doe"}},
                "createTime" => "2025-01-10T17:14:04.738331Z",
                "updateTime" => "2025-01-10T17:14:04.738331Z"
              },
              %{
                "name" => "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBK",
                "fields" => %{"author" => %{"stringValue" => "Jane Doe"}},
                "createTime" => "2025-01-10T17:14:04.738331Z",
                "updateTime" => "2025-01-10T17:14:04.738331Z"
              }
            ],
            "nextPageToken" => nil
          },
          status: 200
        )
      end)

      assert API.list_documents(auth_token, parent, collection) == {
               :ok,
               %Page{
                 data: [
                   %Document{
                     created_at: ~U[2025-01-10 17:14:04.738331Z],
                     data: %{"author" => "John Doe"},
                     path: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
                     updated_at: ~U[2025-01-10 17:14:04.738331Z]
                   },
                   %Document{
                     created_at: ~U[2025-01-10 17:14:04.738331Z],
                     data: %{"author" => "Jane Doe"},
                     path: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBK",
                     updated_at: ~U[2025-01-10 17:14:04.738331Z]
                   }
                 ],
                 next_page_token: nil
               }
             }
    end
  end

  describe "list_documents/4" do
    test "lists documents with opts returns decoded page" do
      auth_token = "my-token"
      parent = "projects/my_project/databases/(default)/documents"
      collection = "books"

      mock(fn %Tesla.Env{
                method: :get,
                url: "https://firestore.googleapis.com/v1/" <> ^parent <> "/" <> ^collection,
                headers: [_, {"authorization", "Bearer " <> ^auth_token} | _]
              } ->
        json(
          %{
            "documents" => [
              %{
                "name" => "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
                "fields" => %{"author" => %{"stringValue" => "John Doe"}},
                "createTime" => "2025-01-10T17:14:04.738331Z",
                "updateTime" => "2025-01-10T17:14:04.738331Z"
              }
            ],
            "nextPageToken" =>
              "AFTOeJwGTcAtgJAapbJ0K7tPwpH9saWYfm4bG991Kk4qdP3NXq9pFfp5IW-E6lwbnRW661DKMJjo5EA7y2iF8GFjaCPLlXN7c0jMYATSRgclgLEChgsSIBjt"
          },
          status: 200
        )
      end)

      assert API.list_documents(auth_token, parent, collection) == {
               :ok,
               %Page{
                 data: [
                   %Document{
                     created_at: ~U[2025-01-10 17:14:04.738331Z],
                     data: %{"author" => "John Doe"},
                     path: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
                     updated_at: ~U[2025-01-10 17:14:04.738331Z]
                   }
                 ],
                 next_page_token:
                   "AFTOeJwGTcAtgJAapbJ0K7tPwpH9saWYfm4bG991Kk4qdP3NXq9pFfp5IW-E6lwbnRW661DKMJjo5EA7y2iF8GFjaCPLlXN7c0jMYATSRgclgLEChgsSIBjt"
               }
             }
    end
  end

  describe "update_document/4" do
    test "updates a document returns decoded document" do
      auth_token = "my-token"
      path = "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ"
      data = %{"author" => "John Doe da Silva"}

      mock(fn %Tesla.Env{
                method: :patch,
                url: "https://firestore.googleapis.com/v1/" <> ^path,
                headers: [_, {"authorization", "Bearer " <> ^auth_token} | _],
                body: ~s({"fields":{"author":{"stringValue":"John Doe da Silva"}}})
              } ->
        json(
          %{
            "name" => path,
            "fields" => %{"author" => %{"stringValue" => "John Doe da Silva"}},
            "createTime" => "2025-01-10T17:14:04.738331Z",
            "updateTime" => "2025-01-10T17:14:04.738331Z"
          },
          status: 200
        )
      end)

      assert API.update_document(auth_token, path, data) == {
               :ok,
               %Document{
                 created_at: ~U[2025-01-10 17:14:04.738331Z],
                 data: %{"author" => "John Doe da Silva"},
                 path: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
                 updated_at: ~U[2025-01-10 17:14:04.738331Z]
               }
             }
    end
  end

  describe "delete_document/2" do
    test "deletes a document" do
      auth_token = "my-token"
      path = "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ"

      mock(fn %Tesla.Env{
                method: :delete,
                url: "https://firestore.googleapis.com/v1/" <> ^path,
                headers: [_, {"authorization", "Bearer " <> ^auth_token} | _],
                query: ["currentDocument.exists": true]
              } ->
        json(%{}, status: 200)
      end)

      assert API.delete_document(auth_token, path) == :ok
    end

    test "return error if document does not exist" do
      auth_token = "my-token"
      path = "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ"

      response =
        json(
          %{
            "error" => %{
              "code" => 404,
              "message" => "No document to update: #{path}",
              "status" => "NOT_FOUND"
            }
          },
          status: 404
        )

      mock(fn %Tesla.Env{
                method: :delete,
                url: "https://firestore.googleapis.com/v1/" <> ^path,
                headers: [_, {"authorization", "Bearer " <> ^auth_token} | _],
                query: ["currentDocument.exists": true]
              } ->
        response
      end)

      assert API.delete_document(auth_token, path) == {:error, :not_found, response}
    end
  end
end
