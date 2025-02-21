import PPlusFireStore.Query

alias GoogleApi.Firestore.V1.Api.Projects
alias GoogleApi.Firestore.V1.Connection
alias GoogleApi.Firestore.V1.Model.Document
alias GoogleApi.Firestore.V1.Model.ListDocumentsResponse
alias PPlusFireStore.Encoder
alias PPlusFireStore.TokenFetcherMock
alias PPlusFireStore.API

# Configure Firestore connection
Application.put_env(:google_api_firestore, :base_url, "http://localhost:8200")
{:ok, %{token: token}} = TokenFetcherMock.fetch(PPulsFireStore)
parent = "projects/my-project/databases/(default)/documents"
collection = "books"
client = Connection.new(token)

create_test_data = fn test_data ->
  Enum.each(test_data, fn document_data ->
    {:ok, _doc} =
      Projects.firestore_projects_databases_documents_create_document(
        client,
        parent,
        collection,
        body: Encoder.encode(document_data)
      )
  end)
end

execute_query = fn query ->
  API.run_query(token, parent, query)
end

clear_all_data = fn ->
  {:ok, %ListDocumentsResponse{documents: documents}} =
    Projects.firestore_projects_databases_documents_list(client, parent, collection)

  documents
  |> Kernel.||([])
  |> Enum.map(fn %Document{name: name} -> name end)
  |> Enum.each(fn doc_name ->
    Projects.firestore_projects_databases_documents_delete(client, doc_name)
  end)
end

test_data = [
  %{
    "author" => "John Doe",
    "tags" => ["fiction", "romance"],
    "pages" => 300,
    "age" => 30,
    "metadata" => %{"publisher" => "Publisher A", "year" => 2020}
  },
  %{
    "author" => "Jane Doe",
    "tags" => ["non-fiction", "biography"],
    "pages" => 250,
    "age" => 45,
    "metadata" => %{"publisher" => "Publisher B", "year" => 2018}
  },
  %{
    "author" => "John Doe",
    "tags" => ["fiction", "mystery"],
    "pages" => 400,
    "age" => 35,
    "metadata" => %{"publisher" => "Publisher A", "year" => 2021}
  },
  %{
    "author" => "Alice Smith",
    "tags" => ["romance", "drama"],
    "pages" => 350,
    "age" => 25,
    "metadata" => %{"publisher" => "Publisher C", "year" => 2019}
  },
  %{
    "author" => "John Doe",
    "tags" => ["science", "education"],
    "pages" => 200,
    "age" => 40,
    "metadata" => %{"publisher" => "Publisher D", "year" => 2017}
  },
  %{
    "author" => "Bob Brown",
    "tags" => ["fiction", "thriller"],
    "pages" => 320,
    "age" => 28,
    "metadata" => %{"publisher" => "Publisher E", "year" => 2022}
  },
  %{
    "author" => "Carol White",
    "tags" => ["non-fiction", "self-help"],
    "pages" => 180,
    "age" => 50,
    "metadata" => %{"publisher" => "Publisher F", "year" => 2016}
  },
  %{
    "author" => "Dave Black",
    "tags" => ["fiction", "fantasy"],
    "pages" => 500,
    "age" => 22,
    "metadata" => %{"publisher" => "Publisher G", "year" => 2023}
  },
  %{
    "author" => "Eve Green",
    "tags" => ["romance", "comedy"],
    "pages" => 270,
    "age" => 33,
    "metadata" => %{"publisher" => "Publisher H", "year" => 2021}
  },
  %{
    "author" => "Frank Blue",
    "tags" => ["science", "fiction"],
    "pages" => 410,
    "age" => 38,
    "metadata" => %{"publisher" => "Publisher I", "year" => 2020}
  }
]

create_test_data.(test_data)

# Query all documents
# query =
#   from("books")
#   |> order_by("author", :asc)
#   |> limit(5)

# result = execute_query.(query)
# IO.inspect(result)


# ------------------------------------------------------------------------------

# Query documents with author "John Doe"
# query =
#   from("books")
#   |> where("author" == "John Doe")

# result = execute_query.(query)
# IO.inspect(result)


# ------------------------------------------------------------------------------



# query =
#   from("books")
#   |> where("author" in ["John Doe", "Alice Smith", "Bob Brown"])
#   |> order_by("author", :asc)

# result = execute_query.(query)
# IO.inspect(result)


# ------------------------------------------------------------------------------


# query =
#   from("books")
#   |> where(contains("tags", "fiction") and "pages" > 300)
#   |> order_by("author", :asc)
#   |> limit(2)
#   |> offset(2)

# result = execute_query.(query)
# IO.inspect(result)


# ------------------------------------------------------------------------------


query =
  from("books")
  |> where("metadata.publisher" == "Publisher A")
  |> order_by("author", :asc)

result = execute_query.(query)
IO.inspect(result)

clear_all_data.()
