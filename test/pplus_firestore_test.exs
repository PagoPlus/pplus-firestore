defmodule PPlusFireStoreTest do
  use ExUnit.Case

  doctest PPlusFireStore

  setup do
    on_exit(fn ->
      Application.delete_env(:my_app, TestFireStoreRepo)
    end)
  end

  test "start_link/1" do
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
      token_fetcher: PPlusFireStore.TokenFetcherMock
    )

    Module.create(
      TestFireStoreRepo,
      quote do
        use PPlusFireStore.Repo, otp_app: :my_app
      end,
      Macro.Env.location(__ENV__)
    )

    assert {:ok, pid} = PPlusFireStore.start_link([TestFireStoreRepo])
    assert Process.alive?(pid)
  end
end
