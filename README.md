# PPlusFireStore

**TODO: Add description**

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

Define your firestore Repo

```elixir
defmodule MyApp.MyFireStoreRepo do
  use PPlusFireStore.Repo, otp_app: :my_app
end
```

Define your firestore credentials in config.exs

```elixir
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

Start PPlusFireStore service in your application

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

You can define multiple repositories

```elixir
children = [
  {PPlusFireStore, [MyApp.MyFireStoreRepo, MyApp.MyOtherFireStoreRepo]}
]
```

## Examples

**TODO: Add examples**

## License

**TODO: Add license**
