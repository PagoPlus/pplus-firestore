import PPlusFireStore.Query

alias GoogleApi.Firestore.V1.Api.Projects
alias GoogleApi.Firestore.V1.Connection
alias GoogleApi.Firestore.V1.Model.Document
alias GoogleApi.Firestore.V1.Model.ListDocumentsResponse
alias GoogleApi.Firestore.V1.Model.RunQueryRequest
alias PPlusFireStore.Encoder
alias PPlusFireStore.TokenFetcherMock

# credentials = %{
#   "project_id" => System.fetch_env!("FIRESTORE_PROJECT_ID"),
#   "private_key_id" => System.fetch_env!("FIRESTORE_PRIVATE_KEY_ID"),
#   "private_key" => System.fetch_env!("FIRESTORE_PRIVATE_KEY"),
#   "client_email" => System.fetch_env!("FIRESTORE_CLIENT_EMAIL"),
#   "client_id" => System.fetch_env!("FIRESTORE_CLIENT_ID"),
#   "auth_uri" => System.fetch_env!("FIRESTORE_AUTH_URI"),
#   "token_uri" => System.fetch_env!("FIRESTORE_TOKEN_URI"),
#   "auth_provider_x509_cert_url" => System.fetch_env!("FIRESTORE_AUTH_PROVIDER_CERT_URL"),
#   "client_x509_cert_url" => System.fetch_env!("FIRESTORE_CLIENT_CERT_URL"),
#   "database_id" => System.get_env("FIRESTORE_DATABASE_ID", "(default)")
# }

# {:ok, %{token: token}} = Goth.Token.fetch(source: {:service_account, credentials})
# parent = "projects/project-test-54-fg-4hg/databases/(default)/documents"


Application.put_env(:google_api_firestore, :base_url, "http://localhost:8200")
{:ok, %{token: token}} = TokenFetcherMock.fetch(PPulsFireStore)
parent = "projects/my-project/databases/(default)/documents"


collection = "books"
client = Connection.new(token)

# Create documents
Enum.each(1..10, fn _ ->
  Projects.firestore_projects_databases_documents_create_document(
    client,
    parent,
    collection,
    body: Encoder.encode(%{"author" => "John Doe", "tags" => ["fiction", "romance"]})
  )
end)

query =
  from("books")
  |> where("author" in ["John Doe", "Jane Doe"])
  |> where(contains("tags", "romance"))
  |> or_where(contains_any("tags", ["fiction", "romance"]))
  |> or_where(contains_any("tags", ["fiction", "romance"]))
  |> order_by("author", :asc)
  |> limit(1)
  |> offset(2)
  |> IO.inspect(label: "query")

client
|> Projects.firestore_projects_databases_documents_run_query(parent,
  body: %RunQueryRequest{
    structuredQuery: query
  }
) |> IO.inspect(label: "response")

# Delete all documents
client
|> Projects.firestore_projects_databases_documents_list(
  parent,
  collection,
  body: Encoder.encode(%{author: "John Doe"})
)
|> then(fn {:ok, %ListDocumentsResponse{documents: documents}} -> documents end)
|> Kernel.||([])
|> Enum.map(fn %Document{name: name} -> name end)
|> Enum.each(&Projects.firestore_projects_databases_documents_delete(client, &1))
