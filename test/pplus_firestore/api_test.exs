defmodule PPlusFireStore.APITest do
  use ExUnit.Case

  import PPlusFireStore.Query

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

      assert {:ok, %{data: %{"key" => "value"}, path: ^path}} = API.get_document(token, path)
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

  describe "run_query/2" do
    setup %{token: token} do
      Enum.each(
        [
          %{
            "author" => "John Doe",
            "tags" => ["fiction", "romance"],
            "pages" => 300,
            "metadata" => %{"publisher" => "Publisher A", "year" => 2020}
          },
          %{
            "author" => "Jane Doe",
            "tags" => ["non-fiction", "biography"],
            "pages" => 250,
            "metadata" => %{"publisher" => "Publisher B", "year" => 2018}
          },
          %{
            "author" => "John Doe",
            "tags" => ["fiction", "mystery"],
            "pages" => 400,
            "metadata" => %{"publisher" => "Publisher A", "year" => 2021}
          },
          %{
            "author" => "Alice Smith",
            "tags" => ["romance", "drama"],
            "pages" => 350,
            "metadata" => %{"publisher" => "Publisher C", "year" => 2019}
          },
          %{
            "author" => "John Doe",
            "tags" => ["science", "education"],
            "pages" => 200,
            "metadata" => %{"publisher" => "Publisher D", "year" => 2017}
          },
          %{
            "author" => "Bob Brown",
            "tags" => ["fiction", "thriller"],
            "pages" => 320,
            "metadata" => %{"publisher" => "Publisher E", "year" => 2022}
          },
          %{
            "author" => "Carol White",
            "tags" => ["non-fiction", "self-help"],
            "pages" => 180,
            "metadata" => %{"publisher" => "Publisher F", "year" => 2016}
          },
          %{
            "author" => "Dave Black",
            "tags" => ["fiction", "fantasy"],
            "pages" => 500,
            "metadata" => %{"publisher" => "Publisher G", "year" => 2023}
          },
          %{
            "author" => "Eve Green",
            "tags" => ["romance", "comedy"],
            "pages" => 270,
            "metadata" => %{"publisher" => "Publisher H", "year" => 2021}
          },
          %{
            "author" => "Frank Blue",
            "tags" => ["science", "fiction"],
            "pages" => 410,
            "metadata" => %{"publisher" => "Publisher I", "year" => 2020}
          },
          %{
            "author" => nil,
            "tags" => ["non-fiction", "self-help"],
            "pages" => 180,
            "metadata" => %{"publisher" => "Publisher F", "year" => 2016}
          }
        ],
        fn book ->
          token
          |> Connection.new()
          |> Projects.firestore_projects_databases_documents_create_document(
            @parent,
            @collection,
            body: PPlusFireStore.Encoder.encode(book)
          )
        end
      )

      {:ok, token: token}
    end

    test "return all documents", %{token: token} do
      query = from("books")

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 11
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
        body: PPlusFireStore.Encoder.encode(%{"key" => "value"}),
        documentId: "doc"
      )

      query = from("col5", all_descendants: true)

      assert {:ok, books} = API.run_query(token, root, query)
      assert length(books) == 1
    end

    test "return all documents with limit", %{token: token} do
      query =
        "books"
        |> from()
        |> limit(2)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 2
    end

    test "return all documents filtered by author", %{token: token} do
      author = "John Doe"

      query =
        "books"
        |> from()
        |> where("author" == author)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 3
      assert Enum.all?(books, fn %_{data: %{"author" => author}} -> author == "John Doe" end)
    end

    test "return all documents filtered by author passing collection as string", %{token: token} do
      author = "John Doe"

      query = where("books", "author" == author)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 3
      assert Enum.all?(books, fn %_{data: %{"author" => author}} -> author == "John Doe" end)
    end

    test "return all documents filtered by tags", %{token: token} do
      tag = "romance"

      query =
        "books"
        |> from()
        |> where(contains("tags", tag))

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 3
      assert Enum.all?(books, fn %_{data: %{"tags" => tags}} -> Enum.member?(tags, "romance") end)
    end

    test "return all documents filtered by author == nil", %{token: token} do
      query =
        "books"
        |> from()
        |> where("author" == nil)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 1
      assert Enum.all?(books, fn %_{data: %{"author" => author}} -> is_nil(author) end)
    end

    test "return all documents filtered by is_nil(author)", %{token: token} do
      query =
        "books"
        |> from()
        |> where(is_nil("author"))

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 1
      assert Enum.all?(books, fn %_{data: %{"author" => author}} -> is_nil(author) end)
    end

    test "return all documents filtered by pages", %{token: token} do
      query =
        "books"
        |> from()
        |> where("pages" > 300)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 5
      assert Enum.all?(books, fn %_{data: %{"pages" => pages}} -> pages > 300 end)
    end

    test "return all documents filtered by publisher", %{token: token} do
      query =
        "books"
        |> from()
        |> where("metadata.publisher" == "Publisher A")

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 2
      assert Enum.all?(books, fn %_{data: %{"metadata" => metadata}} -> metadata["publisher"] == "Publisher A" end)
    end

    test "return all documents filtered by author not equal to", %{token: token} do
      query =
        "books"
        |> from()
        |> where("author" != "John Doe")

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 7
      assert Enum.all?(books, fn %_{data: %{"author" => author}} -> author != "John Doe" end)
    end

    test "return all documents filtered by year", %{token: token} do
      query =
        "books"
        |> from()
        |> where("metadata.year" >= 2020)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 6
      assert Enum.all?(books, fn %_{data: %{"metadata" => metadata}} -> metadata["year"] >= 2020 end)
    end

    test "return all documents filtered by year less than or equal to", %{token: token} do
      query =
        "books"
        |> from()
        |> where("metadata.year" <= 2020)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 7
      assert Enum.all?(books, fn %_{data: %{"metadata" => metadata}} -> metadata["year"] <= 2020 end)
    end

    test "return books published between 2018 and 2021", %{token: token} do
      query =
        "books"
        |> from()
        |> where("metadata.year" >= 2018 and "metadata.year" <= 2021)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 6

      assert Enum.all?(books, fn %_{data: %{"metadata" => metadata}} ->
               metadata["year"] in 2018..2021
             end)
    end

    test "return books filtered by pages when pages == 350 or pages == 400", %{token: token} do
      query =
        "books"
        |> from()
        |> where("pages" == 350 or "pages" == 400)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 2
      assert Enum.all?(books, fn %_{data: %{"pages" => pages}} -> pages in [350, 400] end)
    end

    test "return books filtered by pages when pages == 350 or pages == 400 using or_where clause", %{token: token} do
      query =
        "books"
        |> from()
        |> where("pages" == 350)
        |> or_where("pages" == 400)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 2
      assert Enum.all?(books, fn %_{data: %{"pages" => pages}} -> pages in [350, 400] end)
    end

    test "return books published between 2018 and 2021 using where clause with pipeline", %{token: token} do
      query =
        "books"
        |> from()
        |> where("metadata.year" >= 2018)
        |> where("metadata.year" <= 2021)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 6

      assert Enum.all?(books, fn %_{data: %{"metadata" => metadata}} ->
               metadata["year"] in 2018..2021
             end)
    end

    test "return documents sorted by pages in ascending order", %{token: token} do
      query =
        "books"
        |> from()
        |> order_by("pages", :asc)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert books == Enum.sort_by(books, fn %_{data: %{"pages" => pages}} -> pages end)
    end

    test "return documents sorted by multiple fields", %{token: token} do
      query =
        "books"
        |> from()
        |> order_by(["author", "metadata.year"])

      assert {:ok, books} = API.run_query(token, @parent, query)

      assert books ==
               Enum.sort_by(books, fn %_{data: %{"author" => author, "metadata" => %{"year" => year}}} ->
                 {author, year}
               end)

      assert books ==
               Enum.sort_by(books, fn %_{data: %{"author" => author, "metadata" => %{"year" => year}}} ->
                 {author, year}
               end)
    end

    test "get all books from author list", %{token: token} do
      query =
        "books"
        |> from()
        |> where("author" in ["John Doe", "Jane Doe"])

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 4
      assert Enum.all?(books, fn %_{data: %{"author" => author}} -> Enum.member?(["John Doe", "Jane Doe"], author) end)
    end

    test "return all documents filtered by any tags", %{token: token} do
      query =
        "books"
        |> from()
        |> where(contains_any("tags", ["romance", "science"]))

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 5
      assert Enum.all?(books, fn %_{data: %{"tags" => tags}} -> Enum.any?(tags, &(&1 in ["romance", "science"])) end)
    end

    test "return selected fields from documents", %{token: token} do
      query =
        "books"
        |> from()
        |> select(["author", "metadata.publisher"])

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 11

      assert Enum.all?(books, fn %_{data: data} -> Map.keys(data) == ["author", "metadata"] end)
    end

    test "return selected fields with filter", %{token: token} do
      query =
        "books"
        |> from()
        |> where("author" == "John Doe")
        |> select(["author", "metadata.year"])

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 3

      assert Enum.all?(books, fn %_{data: data} ->
               Map.has_key?(data, "author") and Map.has_key?(data, "metadata") and
                 Map.has_key?(data["metadata"], "year")
             end)
    end

    test "return all documents filtered by author or pages", %{token: token} do
      query =
        "books"
        |> from()
        |> where("author" == "John Doe")
        |> or_where("pages" > 400)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 5

      assert Enum.all?(books, fn %_{data: %{"author" => author, "pages" => pages}} ->
               author == "John Doe" or pages > 400
             end)
    end

    test "return all documents filtered by tags or year", %{token: token} do
      query =
        "books"
        |> from()
        |> where(contains("tags", "romance"))
        |> or_where("metadata.year" >= 2022)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 5

      assert Enum.all?(books, fn %_{data: %{"tags" => tags, "metadata" => metadata}} ->
               Enum.member?(tags, "romance") or metadata["year"] >= 2022
             end)
    end

    test "return all documents filtered by pages < 200", %{token: token} do
      query =
        "books"
        |> from()
        |> where("pages" < 200)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 2
      assert Enum.all?(books, fn %_{data: %{"pages" => pages}} -> pages < 200 end)
    end

    test "return all documents from collection with options", %{token: token} do
      query = limit(from("books"), 5)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 5
    end

    test "return all documents ordered by pages without direction return ascending", %{token: token} do
      query = order_by(from("books"), "pages")

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert books == Enum.sort_by(books, fn %_{data: %{"pages" => pages}} -> pages end, :asc)
    end

    test "return all documents with offset", %{token: token} do
      query = offset(from("books"), 2)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 9
    end

    test "return all documents ordered by pages", %{token: token} do
      query = order_by(from("books"), "pages", :desc)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert books == Enum.sort_by(books, fn %_{data: %{"pages" => pages}} -> pages end, :desc)
    end

    test "return all documents ordered by metadata.year", %{token: token} do
      query =
        from("books")
        |> limit(3)
        |> order_by("metadata.year", :asc)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 3
      assert books == Enum.sort_by(books, fn %_{data: %{"metadata" => metadata}} -> metadata["year"] end)
    end

    test "return all documents ordered by multiple fields", %{token: token} do
      query =
        from("books")
        |> limit(3)
        |> order_by(["author", "metadata.year"], :asc)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 3
      assert books == Enum.sort_by(books, fn %_{data: %{"metadata" => metadata}} -> metadata["year"] end)
    end

    test "return all documents ordered by multiple fields using pipeline syntax", %{token: token} do
      query =
        from("books")
        |> limit(3)
        |> order_by("author", :asc)
        |> order_by("metadata.year", :asc)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 3
      assert books == Enum.sort_by(books, fn %_{data: %{"metadata" => metadata}} -> metadata["year"] end)
    end

    test "returns error when the second argument of the in clause is not a list", %{token: token} do
      # This test had to be done differently because the exception was occurring at compile time,
      # before the test ran. So to avoid this, I first convert the code that threw the exception to
      # an AST and then call the Code.eval_quoted/3 function to execute it.

      assert_raise ArgumentError, "IN operator requires a list as the right side of the expression\n\n", fn ->
        ast =
          quote do
            query =
              "books"
              |> from()
              |> where("author" in "John Doe")

            API.run_query(token, parent, query)
          end

        Code.eval_quoted(ast, [token: token, parent: @parent], __ENV__)
      end
    end

    test "return all documents filtered by author not in list", %{token: token} do
      query =
        "books"
        |> from()
        |> where("author" not in ["John Doe", "Jane Doe"])

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 6

      assert Enum.all?(books, fn %_{data: %{"author" => author}} ->
               not Enum.member?(["John Doe", "Jane Doe"], author)
             end)
    end

    test "NOT IN operator returns error when the second argument of the in clause is not a list", %{token: token} do
      # This test had to be done differently because the exception was occurring at compile time,
      # before the test ran. So to avoid this, I first convert the code that threw the exception to
      # an AST and then call the Code.eval_quoted/3 function to execute it.

      assert_raise ArgumentError, "IN operator requires a list as the right side of the expression\n\n", fn ->
        ast =
          quote do
            query =
              "books"
              |> from()
              |> where("author" not in "John Doe")

            API.run_query(token, parent, query)
          end

        Code.eval_quoted(ast, [token: token, parent: @parent], __ENV__)
      end
    end

    test "using where after composite filter", %{token: token} do
      query =
        from("books")
        |> where("author" == "John Doe" and "pages" > 300)
        |> where("metadata.year" <= 2021)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 1

      assert Enum.all?(books, fn %_{data: %{"author" => author, "pages" => pages, "metadata" => metadata}} ->
               author == "John Doe" and pages > 300 and metadata["year"] <= 2021
             end)
    end

    test "using where after unary filter", %{token: token} do
      query =
        from("books")
        |> where(is_nil("author"))
        |> where("metadata.year" <= 2021)

      assert {:ok, books} = API.run_query(token, @parent, query)
      assert length(books) == 1
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

      assert {:ok, docs} = API.run_query(token, parent, query)
      assert length(docs) == 1

      assert hd(docs).data == %{"key" => "value"}
      assert hd(docs).path == "#{parent}/col5/doc"
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
