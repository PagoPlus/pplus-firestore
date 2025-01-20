defmodule PPlusFireStore.APITest do
  use ExUnit.Case

  import Mock

  alias GoogleApi.Firestore.V1.Api.Projects
  alias GoogleApi.Firestore.V1.Model.Empty
  alias GoogleApi.Firestore.V1.Model.ListDocumentsResponse
  alias GoogleApi.Firestore.V1.Model.Value
  alias PPlusFireStore.API
  alias PPlusFireStore.Model.Page
  alias Tesla.Middleware.Headers

  describe "create_document/4" do
    test "creates a document returns decoded document" do
      auth_token = "my-token"
      parent = "projects/my_project/databases/(default)/documents"
      collection = "books"
      data = %{"author" => "John Doe"}

      with_mock(Projects,
        firestore_projects_databases_documents_create_document: fn
          %Tesla.Client{
            pre: [
              {
                Headers,
                :call,
                [[{"authorization", "Bearer " <> ^auth_token}]]
              }
            ]
          },
          ^parent,
          ^collection,
          [body: %{fields: %{"author" => %{stringValue: "John Doe"}}}] ->
            {:ok,
             %GoogleApi.Firestore.V1.Model.Document{
               name: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
               fields: %{"author" => %Value{stringValue: "John Doe"}},
               createTime: ~U[2025-01-10 17:14:04.738331Z],
               updateTime: ~U[2025-01-10 17:14:04.738331Z]
             }}
        end
      ) do
        assert API.create_document(auth_token, parent, collection, data) == {
                 :ok,
                 %PPlusFireStore.Model.Document{
                   created_at: ~U[2025-01-10 17:14:04.738331Z],
                   data: %{"author" => "John Doe"},
                   path: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
                   updated_at: ~U[2025-01-10 17:14:04.738331Z]
                 }
               }
      end
    end
  end

  describe "get_document/2" do
    test "gets a document returns decoded document" do
      auth_token = "my-token"
      path = "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ"

      with_mock(Projects,
        firestore_projects_databases_documents_get: fn
          %Tesla.Client{
            pre: [
              {
                Headers,
                :call,
                [[{"authorization", "Bearer " <> ^auth_token}]]
              }
            ]
          },
          ^path,
          [] ->
            {:ok,
             %GoogleApi.Firestore.V1.Model.Document{
               name: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
               fields: %{"author" => %Value{stringValue: "John Doe"}},
               createTime: ~U[2025-01-10 17:14:04.738331Z],
               updateTime: ~U[2025-01-10 17:14:04.738331Z]
             }}
        end
      ) do
        assert API.get_document(auth_token, path) == {
                 :ok,
                 %PPlusFireStore.Model.Document{
                   created_at: ~U[2025-01-10 17:14:04.738331Z],
                   data: %{"author" => "John Doe"},
                   path: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
                   updated_at: ~U[2025-01-10 17:14:04.738331Z]
                 }
               }
      end
    end
  end

  describe "list_documents/3" do
    test "lists documents returns decoded page" do
      auth_token = "my-token"
      parent = "projects/my_project/databases/(default)/documents"
      collection = "books"

      with_mock(Projects,
        firestore_projects_databases_documents_list: fn
          %Tesla.Client{
            pre: [
              {
                Headers,
                :call,
                [[{"authorization", "Bearer " <> ^auth_token}]]
              }
            ]
          },
          ^parent,
          ^collection,
          [] ->
            {:ok,
             %ListDocumentsResponse{
               documents: [
                 %GoogleApi.Firestore.V1.Model.Document{
                   name: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
                   fields: %{"author" => %Value{stringValue: "John Doe"}},
                   createTime: ~U[2025-01-10 17:14:04.738331Z],
                   updateTime: ~U[2025-01-10 17:14:04.738331Z]
                 },
                 %GoogleApi.Firestore.V1.Model.Document{
                   name: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBK",
                   fields: %{"author" => %Value{stringValue: "Jane Doe"}},
                   createTime: ~U[2025-01-10 17:14:04.738331Z],
                   updateTime: ~U[2025-01-10 17:14:04.738331Z]
                 }
               ],
               nextPageToken: nil
             }}
        end
      ) do
        assert API.list_documents(auth_token, parent, collection) == {
                 :ok,
                 %Page{
                   data: [
                     %PPlusFireStore.Model.Document{
                       created_at: ~U[2025-01-10 17:14:04.738331Z],
                       data: %{"author" => "John Doe"},
                       path: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
                       updated_at: ~U[2025-01-10 17:14:04.738331Z]
                     },
                     %PPlusFireStore.Model.Document{
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
  end

  describe "list_documents/4" do
    test "lists documents with opts returns decoded page" do
      auth_token = "my-token"
      parent = "projects/my_project/databases/(default)/documents"
      collection = "books"

      with_mock(Projects,
        firestore_projects_databases_documents_list: fn _conn, _parent, _collection, _opts ->
          {:ok,
           %ListDocumentsResponse{
             documents: [
               %GoogleApi.Firestore.V1.Model.Document{
                 name: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
                 fields: %{"author" => %Value{stringValue: "John Doe"}},
                 createTime: ~U[2025-01-10 17:14:04.738331Z],
                 updateTime: ~U[2025-01-10 17:14:04.738331Z]
               }
             ],
             nextPageToken:
               "AFTOeJwGTcAtgJAapbJ0K7tPwpH9saWYfm4bG991Kk4qdP3NXq9pFfp5IW-E6lwbnRW661DKMJjo5EA7y2iF8GFjaCPLlXN7c0jMYATSRgclgLEChgsSIBjt"
           }}
        end
      ) do
        assert API.list_documents(auth_token, parent, collection) == {
                 :ok,
                 %Page{
                   data: [
                     %PPlusFireStore.Model.Document{
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
  end

  describe "update_document/4" do
    test "updates a document returns decoded document" do
      auth_token = "my-token"
      path = "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ"

      with_mock(Projects,
        firestore_projects_databases_documents_patch: fn
          %Tesla.Client{
            pre: [
              {
                Headers,
                :call,
                [[{"authorization", "Bearer " <> ^auth_token}]]
              }
            ]
          },
          ^path,
          [body: %{fields: %{"author" => %{stringValue: "John Doe da Silva"}}}] ->
            {:ok,
             %GoogleApi.Firestore.V1.Model.Document{
               name: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
               fields: %{"author" => %Value{stringValue: "John Doe da Silva"}},
               createTime: ~U[2025-01-10 17:14:04.738331Z],
               updateTime: ~U[2025-01-10 17:14:04.738331Z]
             }}
        end
      ) do
        assert API.update_document(auth_token, path, %{"author" => "John Doe da Silva"}) == {
                 :ok,
                 %PPlusFireStore.Model.Document{
                   created_at: ~U[2025-01-10 17:14:04.738331Z],
                   data: %{"author" => "John Doe da Silva"},
                   path: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
                   updated_at: ~U[2025-01-10 17:14:04.738331Z]
                 }
               }
      end
    end
  end

  describe "delete_document/2" do
    test "deletes a document" do
      auth_token = "my-token"
      path = "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ"

      with_mock(Projects,
        firestore_projects_databases_documents_delete: fn
          %Tesla.Client{
            pre: [
              {
                Headers,
                :call,
                [[{"authorization", "Bearer " <> ^auth_token}]]
              }
            ]
          },
          ^path,
          ["currentDocument.exists": true] ->
            {:ok, %Empty{}}
        end
      ) do
        assert API.delete_document(auth_token, path) == {:ok, :deleted}
      end
    end

    test "return error if document does not exist" do
      auth_token = "my-token"
      path = "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ"

      response =
        {:error,
         %Tesla.Env{
           method: :delete,
           url: "https://firestore.googleapis.com/v1/#{path}",
           query: ["currentDocument.exists": true],
           headers: [
             {"date", "Mon, 20 Jan 2025 13:11:21 GMT"},
             {"server", "ESF"},
             {"vary", "Origin"},
             {"content-type", "application/json; charset=UTF-8"},
             {"x-debug-tracking-id", "7981810200057583707;o=1"},
             {"x-xss-protection", "0"},
             {"x-frame-options", "SAMEORIGIN"},
             {"x-content-type-options", "nosniff"},
             {"alt-svc", ~s(h3=":443"; ma=2592000,h3-29=":443"; ma=2592000)}
           ],
           body:
             "{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"No document to update: #{path},\n    \"status\": \"NOT_FOUND\"\n  }\n}\n",
           status: 404,
           opts: [],
           __module__: GoogleApi.Firestore.V1.Connection,
           __client__: %Tesla.Client{
             fun: nil,
             pre: [
               {Tesla.Middleware.Headers, :call,
                [
                  [
                    {"authorization", "Bearer #{auth_token}"}
                  ]
                ]}
             ],
             post: [],
             adapter: {Tesla.Adapter.Httpc, :call, [[]]}
           }
         }}

      with_mock(Projects,
        firestore_projects_databases_documents_delete: fn
          %Tesla.Client{
            pre: [
              {
                Headers,
                :call,
                [[{"authorization", "Bearer " <> ^auth_token}]]
              }
            ]
          },
          ^path,
          ["currentDocument.exists": true] ->
            response
        end
      ) do
        assert API.delete_document(auth_token, path) == response
      end
    end
  end
end
