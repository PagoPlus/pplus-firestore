defmodule PPlusFireStore.RepoTest do
  use ExUnit.Case

  import PPlusFireStore.Query

  alias GoogleApi.Firestore.V1.Api.Projects
  alias PPlusFireStore.Connection
  alias PPlusFireStore.Encoder
  alias PPlusFireStore.Model.Document
  alias PPlusFireStore.Model.Page
  alias PPlusFireStore.TokenFetcherMock

  @parent "projects/test-project/databases/pplus_test/documents"
  @collection "authors"

  setup do
    {:ok, %{token: token}} = TokenFetcherMock.fetch(__MODULE__)

    clear_database(token)

    Application.put_env(:google_api_firestore, :base_url, "http://localhost:8200")

    Application.put_env(:my_app, TestFireStoreRepo,
      project_id: "test-project",
      private_key_id: "abc123def456ghi789jkl012mno345pqr678stu901vwx234",
      private_key:
        "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCN1IUO2QhgdI+Q\n-----END PRIVATE KEY-----\n",
      client_email: "firebase-adminsdk@test-project.iam.gserviceaccount.com",
      client_id: "123456789012345678901",
      auth_uri: "https://accounts.google.com/o/oauth2/auth",
      token_uri: "https://oauth2.googleapis.com/token",
      auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
      client_x509_cert_url:
        "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk%40test-project.iam.gserviceaccount.com",
      database_id: "pplus_test",
      token_fetcher: TokenFetcherMock
    )

    on_exit(fn -> clear_database(token) end)

    {:ok, token: token}
  end

  test "config/0" do
    assert TestFireStoreRepo.config() == [
             project_id: "test-project",
             private_key_id: "abc123def456ghi789jkl012mno345pqr678stu901vwx234",
             private_key:
               "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCN1IUO2QhgdI+Q\n-----END PRIVATE KEY-----\n",
             client_email: "firebase-adminsdk@test-project.iam.gserviceaccount.com",
             client_id: "123456789012345678901",
             auth_uri: "https://accounts.google.com/o/oauth2/auth",
             token_uri: "https://oauth2.googleapis.com/token",
             auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
             client_x509_cert_url:
               "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk%40test-project.iam.gserviceaccount.com",
             database_id: "pplus_test",
             token_fetcher: TokenFetcherMock
           ]
  end

  describe "create_document/4" do
    test "creates a document returns decoded document" do
      data = %{"author" => "John Doe"}
      collection = "authors"

      assert {
               :ok,
               %Document{
                 created_at: %DateTime{},
                 data: %{"author" => "John Doe"},
                 path: <<"projects/test-project/databases/pplus_test/documents/authors/", _::binary>>,
                 updated_at: %DateTime{}
               }
             } = TestFireStoreRepo.create_document(collection, data)
    end

    test "returns error if document already exists", %{token: token} do
      document_id = "esgXQM7pqNCwQwYRJeBJ"
      data = %{"author" => "John Doe"}

      token
      |> Connection.new()
      |> Projects.firestore_projects_databases_documents_create_document(
        @parent,
        @collection,
        body: Encoder.encode(data),
        documentId: document_id
      )

      assert {:error, :already_exists, %Tesla.Env{status: 409}} =
               TestFireStoreRepo.create_document(@collection, data, documentId: document_id)
    end

    test "returns error when unable to establish connection" do
      Application.put_env(:google_api_firestore, :base_url, "http://localhost:0000")
      collection = "authors"
      data = %{"author" => "John Doe"}

      assert TestFireStoreRepo.create_document(collection, data) == {:error, :econnrefused}

      Application.put_env(:google_api_firestore, :base_url, "http://localhost:8200")
    end
  end

  describe "get_document/2" do
    test "gets a document", %{token: token} do
      document_id = "esgXQM7pqNCwQwYRJeBJ"
      path = "#{@parent}/#{@collection}/#{document_id}"

      token
      |> Connection.new()
      |> Projects.firestore_projects_databases_documents_create_document(
        @parent,
        @collection,
        body: Encoder.encode(%{"author" => "John Doe"}),
        documentId: document_id
      )

      assert {
               :ok,
               %Document{
                 created_at: %DateTime{},
                 data: %{"author" => "John Doe"},
                 path: "projects/test-project/databases/pplus_test/documents/authors/esgXQM7pqNCwQwYRJeBJ",
                 updated_at: %DateTime{}
               }
             } = TestFireStoreRepo.get_document(path)
    end

    test "get documents from subcollection", %{token: token} do
      parent = @parent <> "/col0/doc/col1/doc/col2/doc/col3/doc/col4/doc"
      collection = "col5"

      token
      |> Connection.new()
      |> Projects.firestore_projects_databases_documents_create_document(
        parent,
        collection,
        body: PPlusFireStore.Encoder.encode(%{"key" => "value"}),
        documentId: "doc"
      )

      path = parent <> "/col5/doc"

      assert {:ok, %{data: %{"key" => "value"}, path: ^path}} = TestFireStoreRepo.get_document(path)
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
                     path: "projects/test-project/databases/pplus_test/documents/authors/esgXQM7pqNCwQwYRJeBJ",
                     updated_at: %DateTime{}
                   },
                   %Document{
                     created_at: %DateTime{},
                     data: %{"author" => "Jane Doe 2"},
                     path: "projects/test-project/databases/pplus_test/documents/authors/esgXQM7pqNCwQwYRJeBK",
                     updated_at: %DateTime{}
                   }
                 ],
                 next_page_token: nil
               }
             } = TestFireStoreRepo.list_documents(@collection)
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
                    path: "projects/test-project/databases/pplus_test/documents/authors/esgXQM7pqNCwQwYRJeBJ",
                    updated_at: %DateTime{}
                  }
                ],
                next_page_token: _next_page_token
              }} = TestFireStoreRepo.list_documents(@collection, pageSize: 1)
    end
  end

  describe "update_document/4" do
    test "updates a document returns decoded document", %{token: token} do
      {:ok, document} =
        token
        |> Connection.new()
        |> Projects.firestore_projects_databases_documents_create_document(
          @parent,
          @collection,
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
             } = TestFireStoreRepo.update_document(path, data)
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

      assert TestFireStoreRepo.delete_document(path) == :ok
    end

    test "return error if document does not exist" do
      path = "#{@parent}/#{@collection}/esgXQM7pqNCwQwYRJeBJ"

      assert {:error, :not_found, %Tesla.Env{status: 404}} = TestFireStoreRepo.delete_document(path)
    end
  end

  describe "run_query/2" do
    setup %{token: token} do
      Enum.each(
        [
          %{
            "name" => "Lucas Martins",
            "published_books" => 5,
            "metadata" => %{"last_published" => ~U[2021-01-01 00:00:00Z]}
          },
          %{
            "name" => "Mariana Silva",
            "published_books" => 2,
            "metadata" => %{"last_published" => ~U[2018-06-15 00:00:00Z]}
          },
          %{
            "name" => "Carlos Almeida",
            "published_books" => 3,
            "metadata" => %{"last_published" => ~U[2021-11-10 00:00:00Z]}
          },
          %{
            "name" => "Fernanda Costa",
            "published_books" => 1,
            "metadata" => %{"last_published" => ~U[2019-09-23 00:00:00Z]}
          },
          %{
            "name" => "Ricardo Lopes",
            "published_books" => 4,
            "metadata" => %{"last_published" => ~U[2017-05-30 00:00:00Z]}
          },
          %{
            "name" => "Beatriz Rocha",
            "published_books" => 6,
            "metadata" => %{"last_published" => ~U[2022-03-12 00:00:00Z]}
          },
          %{
            "name" => "Gabriel Santos",
            "published_books" => 2,
            "metadata" => %{"last_published" => ~U[2016-07-08 00:00:00Z]}
          },
          %{
            "name" => "Juliana Mendes",
            "published_books" => 5,
            "metadata" => %{"last_published" => ~U[2023-02-20 00:00:00Z]}
          },
          %{
            "name" => "Eduardo Nunes",
            "published_books" => 3,
            "metadata" => %{"last_published" => ~U[2021-08-17 00:00:00Z]}
          },
          %{
            "name" => "Vanessa Moreira",
            "published_books" => 7,
            "metadata" => %{"last_published" => ~U[2020-12-05 00:00:00Z]}
          },
          %{
            "name" => "Desconhecido",
            "published_books" => 1,
            "metadata" => %{"last_published" => ~U[2016-04-22 00:00:00Z]}
          }
        ],
        fn author ->
          token
          |> Connection.new()
          |> Projects.firestore_projects_databases_documents_create_document(
            @parent,
            @collection,
            body: Encoder.encode(author)
          )
        end
      )

      {:ok, token: token}
    end

    test "return all documents" do
      query = from(@collection)

      assert {:ok, authors} = TestFireStoreRepo.run_query(query)
      assert length(authors) == 11
    end

    test "return all documents with option 'all_descendants'", %{token: token} do
      root = @parent
      parent = root <> "/col0/doc/col1/doc/col2/doc/col3/doc/col4/doc"
      collection = "col5"

      token
      |> Connection.new()
      |> Projects.firestore_projects_databases_documents_create_document(
        parent,
        collection,
        body: Encoder.encode(%{"key" => "value"}),
        documentId: "doc"
      )

      query = from("col5", all_descendants: true)

      assert {:ok, docs} = TestFireStoreRepo.run_query(root, query)
      assert length(docs) == 1
    end

    test "return all documents with limit" do
      query =
        @collection
        |> from()
        |> limit(2)

      assert {:ok, authors} = TestFireStoreRepo.run_query(query)
      assert length(authors) == 2
    end

    test "return all documents filtered by author" do
      author = "Ricardo Lopes"

      query =
        @collection
        |> from()
        |> where("name" == author)

      assert {
               :ok,
               [
                 %Document{
                   path: _path,
                   data: %{
                     "metadata" => %{"last_published" => ~U[2017-05-30 00:00:00Z]},
                     "name" => "Ricardo Lopes",
                     "published_books" => 4
                   },
                   created_at: %DateTime{},
                   updated_at: %DateTime{}
                 }
               ]
             } = TestFireStoreRepo.run_query(query)
    end

    test "return all documents filtered by published_books > 3" do
      query =
        @collection
        |> from()
        |> where("published_books" > 3)

      assert {:ok, authors} = TestFireStoreRepo.run_query(query)
      assert length(authors) == 5
      assert Enum.all?(authors, fn %_{data: %{"published_books" => n}} -> n > 3 end)
    end

    test "return all documents filtered by last_published" do
      query =
        @collection
        |> from()
        |> where("metadata.last_published" >= ~U[2021-01-01 00:00:00Z])

      assert {:ok, authors} = TestFireStoreRepo.run_query(@parent, query)
      assert length(authors) == 5

      assert Enum.all?(authors, fn %_{data: %{"metadata" => metadata}} ->
               DateTime.compare(metadata["last_published"], ~U[2021-01-01 00:00:00Z]) != :lt
             end)
    end

    test "return all documents filtered by author not equal to" do
      query =
        @collection
        |> from()
        |> where("name" != "Beatriz Rocha")

      assert {:ok, authors} = TestFireStoreRepo.run_query(@parent, query)
      assert length(authors) == 10
      assert Enum.all?(authors, fn %_{data: %{"name" => author}} -> author != "Beatriz Rocha" end)
    end

    test "return all documents filtered by year less than or equal to" do
      query =
        @collection
        |> from()
        |> where("published_books" <= 2)

      assert {:ok, authors} = TestFireStoreRepo.run_query(@parent, query)
      assert length(authors) == 4
      assert Enum.all?(authors, fn %_{data: %{"published_books" => published_books}} -> published_books <= 2 end)
    end

    test "return authors published between 2018 and 2021 using where clause with pipeline" do
      query =
        @collection
        |> from()
        |> where("published_books" >= 2)
        |> where("published_books" <= 4)

      assert {:ok, authors} = TestFireStoreRepo.run_query(@parent, query)
      assert length(authors) == 5

      assert Enum.all?(authors, fn %_{data: %{"published_books" => published_books}} ->
               published_books in 2..4
             end)
    end

    test "return documents sorted by pages in ascending order" do
      query =
        @collection
        |> from()
        |> order_by("name", :asc)

      assert {:ok, authors} = TestFireStoreRepo.run_query(@parent, query)
      assert authors == Enum.sort_by(authors, fn %_{data: %{"name" => name}} -> name end)
    end

    test "return documents sorted by multiple fields" do
      query =
        @collection
        |> from()
        |> order_by(["author", "published_books"], :asc)

      assert {:ok, authors} = TestFireStoreRepo.run_query(@parent, query)

      assert authors ==
               Enum.sort_by(authors, fn %_{data: %{"author" => author, "published_books" => published_books}} ->
                 {author, published_books}
               end)

      assert authors ==
               Enum.sort_by(authors, fn %_{data: %{"author" => author, "metadata" => %{"year" => year}}} ->
                 {author, year}
               end)
    end

    test "get all authors from author list" do
      query =
        @collection
        |> from()
        |> where("name" in ["Gabriel Santos", "Fernanda Costa"])

      assert {:ok, authors} = TestFireStoreRepo.run_query(@parent, query)
      assert length(authors) == 2

      assert Enum.all?(authors, fn %_{data: %{"name" => author}} ->
               Enum.member?(["Gabriel Santos", "Fernanda Costa"], author)
             end)
    end

    test "return selected fields from documents" do
      query =
        @collection
        |> from()
        |> select(["name", "metadata.last_published"])

      assert {:ok, authors} = TestFireStoreRepo.run_query(@parent, query)
      assert length(authors) == 11

      assert Enum.all?(authors, fn %_{data: data} -> Map.keys(data) == ["metadata", "name"] end)
    end

    test "return selected fields with filter" do
      query =
        @collection
        |> from()
        |> where("name" == "Eduardo Nunes")
        |> select(["name"])

      assert {:ok, authors} = TestFireStoreRepo.run_query(@parent, query)
      assert length(authors) == 1

      assert Enum.all?(authors, fn %_{data: data} ->
               Map.has_key?(data, "name")
             end)
    end

    test "return all documents ordered by name without direction return ascending" do
      query = order_by(from(@collection), "name")

      assert {:ok, authors} = TestFireStoreRepo.run_query(@parent, query)
      assert authors == Enum.sort_by(authors, fn %_{data: %{"name" => name}} -> name end, :asc)
    end

    test "return all documents with offset" do
      query = offset(from(@collection), 2)

      assert {:ok, authors} = TestFireStoreRepo.run_query(@parent, query)
      assert length(authors) == 9
    end

    test "return all documents ordered by multiple fields using pipeline syntax" do
      query =
        from(@collection)
        |> limit(3)
        |> order_by("name", :asc)
        |> order_by("metadata.last_published", :asc)

      assert {:ok, authors} = TestFireStoreRepo.run_query(@parent, query)
      assert length(authors) == 3
      assert authors == Enum.sort_by(authors, fn %_{data: %{"metadata" => metadata}} -> metadata["year"] end)
    end

    test "return all documents filtered by author not in list" do
      query =
        @collection
        |> from()
        |> where("name" not in ["Gabriel Santos", "Fernanda Costa"])

      assert {:ok, authors} = TestFireStoreRepo.run_query(@parent, query)
      assert length(authors) == 9

      assert Enum.all?(authors, fn %_{data: %{"name" => author}} ->
               not Enum.member?(["Gabriel Santos", "Fernanda Costa"], author)
             end)
    end

    test "get documents from subcollection", %{token: token} do
      parent = @parent <> "/col0/doc/col1/doc/col2/doc/col3/doc/col4/doc"
      collection = "col5"

      token
      |> Connection.new()
      |> Projects.firestore_projects_databases_documents_create_document(
        parent,
        collection,
        body: PPlusFireStore.Encoder.encode(%{"key" => "value"}),
        documentId: "doc"
      )

      query = from(collection)

      assert {:ok, docs} = TestFireStoreRepo.run_query(parent, query)
      assert length(docs) == 1

      assert hd(docs).data == %{"key" => "value"}
      assert hd(docs).path == "#{parent}/col5/doc"
    end
  end

  defp clear_database(token) do
    parent = "projects/test-project/databases/pplus_test/documents"
    collection = "authors"

    client = Connection.new(token)

    client
    |> Projects.firestore_projects_databases_documents_list(parent, collection)
    |> elem(1)
    |> Map.get(:documents)
    |> Kernel.||([])
    |> Enum.map(& &1.name)
    |> Enum.map(&Projects.firestore_projects_databases_documents_delete(client, &1))
  end
end
