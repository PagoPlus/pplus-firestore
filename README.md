<img width="400" src="priv/images/pplus_firestore_light_mode.svg#gh-light-mode-only" alt="PPlusFireStore">
<img width="400" src="priv/images/pplus_firestore_dark_mode.svg#gh-dark-mode-only" alt="PPlusFireStore">

---

Provides a simple interface to interact with the official Google API [GoogleApi.Firestore](https://github.com/googleapis/elixir-google-api/tree/master/clients/firestore). It also automatically manages access tokens for Google Firestore.

## Installation

```elixir
def deps do
  [
    {:pplus_firestore, "~> 0.1.0"}
  ]
end
```

## Get firestore credentials

After creating your project in Firestore, go to `Project Settings` > `Service Accounts` > `Generate New Private Key` or use the link https://console.firebase.google.com/u/0/project/_/settings/serviceaccounts/adminsdk

You will receive something like this:

```json
{
  "type": "service_account",
  "project_id": "test-project-12345",
  "private_key_id": "abc123def456ghi789jkl012mno345pqr678stu901vwx234",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQD123fakeprivatekey987\n1234567890ABCDEFGHIJKLMN\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk@test-project-12345.iam.gserviceaccount.com",
  "client_id": "123456789012345678901",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk%40test-project-12345.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
```

## Usage

### Create a repository module

```elixir
defmodule MyApp.MyFireStoreRepo do
  use PPlusFireStore.Repo, otp_app: :my_app
end
```

### Configure your project credentials

```elixir
# config/config.exs
config :my_app, MyApp.MyFireStoreRepo,
  project_id: System.fetch_env!("FIRESTORE_PROJECT_ID"),
  private_key_id: System.fetch_env!("FIRESTORE_PRIVATE_KEY_ID"),
  private_key: System.fetch_env!("FIRESTORE_PRIVATE_KEY"),
  client_email: System.fetch_env!("FIRESTORE_CLIENT_EMAIL"),
  client_id: System.fetch_env!("FIRESTORE_CLIENT_ID"),
  auth_uri: System.fetch_env!("FIRESTORE_AUTH_URI"),
  token_uri: System.fetch_env!("FIRESTORE_TOKEN_URI"),
  auth_provider_x509_cert_url: System.fetch_env!("FIRESTORE_AUTH_PROVIDER_CERT_URL"),
  client_x509_cert_url: fetch_env!("FIRESTORE_CLIENT_CERT_URL"),
  database_id: System.get_env("FIRESTORE_DATABASE_ID") # optional, default: "(default)"
```

### Start PPlusFireStore service in your application

PPlusFireStore will initialize the service that will manage access tokens to the repositories.
By default, PPlusFireStore uses [Goth](https://github.com/peburrows/goth) to manage access tokens to the repositories.
Goth uses the project credentials to generate access tokens for the repositories and stores them in a cache.
When requested, the service retrieves the access tokens from the cache and checks if they are still valid.
If the access tokens are not in the cache or are expired, Goth will fetch new access tokens and store them in the cache.

If you do not want to use Goth, you can implement a custom [TokenFetcher](https://hexdocs.pm/pplus_firestore/PPlusFireStore.TokenFetcher.html) service.

```elixir
defmodule MyApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {PPlusFireStore, [MyApp.MyFireStoreRepo]}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

PPlusFireStore accepts a list of repositories as an argument. Each repository will have its own credential configuration. Goth will generate and store a different access token for each repository.

```elixir
children = [
  {PPlusFireStore, [MyApp.MyFireStoreRepo, MyApp.MyOtherFireStoreRepo]}
]
```

**Note:** You do not need to initialize this service if you do not want to. You can override the `token/0` function in your repository module to return the token in a different way without using this service.

## Examples

### Create a document

The `create_document/3` function provides a simple way to create your documents in Firestore.

Your repository module is already configured with the base path and the database ID.

`projects/<project_id>/databases/<database_id>/documents`

So you only need to specify which collection you want to create the document in.

```elixir
iex> MyApp.MyFireStoreRepo.create_document("addresses", %{
...>   street: "123 Main St",
...>   city: "Anytown",
...>   state: "CA",
...>   postal_code: "12345",
...>   country: "USA",
...>   coordinates: %{
...>     latitude: 37.7749,
...>     longitude: -122.4194
...>   },
...>   additional_info: %{
...>     is_residential: true,
...>     delivery_instructions: nil,
...>     contact_number: "+1-555-555-5555",
...>     last_verified: ~U[2025-01-10 17:14:04.738331Z]
...>   },
...>   created_at: ~U[2025-01-10 17:14:04.738331Z],
...>   delivery_attempts: 3,
...>   delivery_notes: ["Leave at the front door", "Ring the bell"],
...>   document_reference:
...>     {:ref, "projects/my_project/databases/my_database/documents/collection1/doccument1"}
...> })
{:ok,
 %PPlusFireStore.Model.Document{
   path: "projects/my_project/databases/my_database/documents/addresses/DxN4EvMyWCh7oTfVmxP9",
   data: %{
     "additional_info" => %{
       "contact_number" => "+1-555-555-5555",
       "delivery_instructions" => nil,
       "is_residential" => true,
       "last_verified" => ~U[2025-01-10 17:14:04.738331Z]
     },
     "city" => "Anytown",
     "coordinates" => %{"latitude" => 37.7749, "longitude" => -122.4194},
     "country" => "USA",
     "created_at" => ~U[2025-01-10 17:14:04.738331Z],
     "delivery_attempts" => 3,
     "delivery_notes" => ["Leave at the front door", "Ring the bell"],
     "document_reference" => "projects/my_project/databases/my_database/documents/collection1/doccument1",
     "postal_code" => "12345",
     "state" => "CA",
     "street" => "123 Main St"
   },
   created_at: ~U[2025-01-20 21:23:18.762968Z],
   updated_at: ~U[2025-01-20 21:23:18.762968Z]
 }}
```

There are 3 types that are special:

- `:ref` - Reference to an existing document.
- `:geo` - GeoPoint
- `:bytes` - Bytes

You can pass them in a map using tuples:

```elixir
# Reference
{:ref, "projects/my_project/databases/my_database/documents/collection1/doccument1"}

# GeoPoint - Can be 3 ways
{:geo, {37.7749, -122.4194}}
{:geo, %{latitude: 37.7749, longitude: -122.4194}}
%{latitude: 37.7749, longitude: -122.4194}

# Bytes
{:bytes, "aGVsbG8gd29ybGQ="}
```

### Read a document

The `get_document/2` function provides a simple way to read your documents in Firestore.

Your repository module is already configured with the base path and the database ID.

`projects/<project_id>/databases/<database_id>/documents`

So you only need to specify which collection you want to read from and the document ID.

```elixir
iex> MyApp.MyFireStoreRepo.get_document("addresses/DxN4EvMyWCh7oTfVmxP9")
{:ok,
 %PPlusFireStore.Model.Document{
   path: "projects/my_project/databases/my_database/documents/addresses/DxN4EvMyWCh7oTfVmxP9",
   data: %{
     "additional_info" => %{
       "contact_number" => "+1-555-555-5555",
       "delivery_instructions" => nil,
       "is_residential" => true,
       "last_verified" => ~U[2025-01-10 17:14:04.738331Z]
     },
     "city" => "Anytown",
     "coordinates" => %{"latitude" => 37.7749, "longitude" => -122.4194},
     "country" => "USA",
     "created_at" => ~U[2025-01-10 17:14:04.738331Z],
     "delivery_attempts" => 3,
     "delivery_notes" => ["Leave at the front door", "Ring the bell"],
     "postal_code" => "12345",
     "state" => "CA",
     "street" => "123 Main St"
   },
   created_at: ~U[2025-01-20 21:23:18.762968Z],
   updated_at: ~U[2025-01-20 21:23:18.762968Z]
 }}
```

Since a document can store a reference to another document, and that reference contains the full path, you can also pass the full path to `get_document/2`.

```elixir
MyApp.MyFireStoreRepo.get_document("projects/my_project/databases/my_database/documents/addresses/DxN4EvMyWCh7oTfVmxP9")
```

### Update a document

The `update_document/3` function provides a simple way to update your documents in Firestore.

Your repository module is already configured with the base path and the database ID.

`projects/<project_id>/databases/<database_id>/documents`

So you only need to specify the path within the collection and the updated data.

```elixir
iex> MyApp.MyFireStoreRepo.update_document("addresses/DxN4EvMyWCh7oTfVmxP9", %{
...>   street: "123 Main St",
...>   city: "Anytown",
...>   state: "CA",
...>   postal_code: "12345",
...>   country: "USA",
...>   coordinates: %{
...>     latitude: 37.7749,
...>     longitude: -122.4194
...>   },
...>   additional_info: %{
...>     is_residential: true,
...>     delivery_instructions: nil,
...>     contact_number: "+1-555-555-5555",
...>     last_verified: ~U[2025-01-10 17:14:04.738331Z]
...>   },
...>   created_at: ~U[2025-01-10 17:14:04.738331Z],
...>   delivery_attempts: 3,
...>   delivery_notes: ["Leave at the front door", "Ring the bell"],
...>   document_reference:
...>     {:ref, "projects/my_project/databases/my_database/documents/collection1/doccument1"}
...> })
{:ok,
 %PPlusFireStore.Model.Document{
   path: "projects/my_project/databases/my_database/documents/addresses/DxN4EvMyWCh7oTfVmxP9",
   data: %{
     "additional_info" => %{
       "contact_number" => "+1-555-555-5555",
       "delivery_instructions" => nil,
       "is_residential" => true,
       "last_verified" => ~U[2025-01-10 17:14:04.738331Z]
     },
     "city" => "Anytown",
     "coordinates" => %{"latitude" => 37.7749, "longitude" => -122.4194},
     "country" => "USA",
     "created_at" => ~U[2025-01-10 17:14:04.738331Z],
     "delivery_attempts" => 3,
     "delivery_notes" => ["Leave at the front door", "Ring the bell"],
     "document_reference" => "projects/my_project/databases/my_database/documents/collection1/doccument1",
     "postal_code" => "12345",
     "state" => "CA",
     "street" => "123 Main St"
   },
   created_at: ~U[2025-01-20 21:23:18.762968Z],
   updated_at: ~U[2025-01-20 21:23:18.762968Z]
}}
```

### Delete a document

The `delete_document/2` function provides a simple way to delete your documents in Firestore.

Your repository module is already configured with the base path and the database ID.

`projects/<project_id>/databases/<database_id>/documents`

So you only need to specify the path within the collection.

```elixir
iex> MyApp.MyFireStoreRepo.delete_document("addresses/DxN4EvMyWCh7oTfVmxP9")
{:ok, :deleted}
```

The Google API returns `GoogleApi.Firestore.V1.Model.Empty{}` when a document is deleted, even if it does not exist or has already been deleted. This can cause some confusion, so by default `delete_document/1` sends the parameter `:"currentDocument.exists"` with the value `true`. This makes FireStore return an error if the document does not exist or has already been deleted.

You can pass the `:currentDocument.exists` parameter in the options to avoid this behavior.

```elixir
MyApp.MyFireStoreRepo.delete_document("addresses/DxN4EvMyWCh7oTfVmxP9", ["currentDocument.exists": false])
```

## Contributing

### Requirements

- Elixir 1.18+
- Erlang 27+
- Docker
- Docker Compose

### Steps

1. Fork the project
2. Create a feature branch
3. Create a pull request

### Tests

Run the firestore emulator container:

```bash
docker compose up -d
```

Run tests:

```bash
mix test
```

Run Coverage, checks and tests:

```bash
mix ci
```

### Publishing

Pull requests format

Feature

```bash
git checkout -b feature/feature-name
```

fix

```bash
git checkout -b fix/bugfix-name
```

Commit

```bash
git commit -am "feat: commit message"
```

## License

[MIT License](LICENSE)
