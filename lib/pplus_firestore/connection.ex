defmodule PPlusFireStore.Connection do
  @moduledoc """
  Handle connection with Google Firestore API


  configuration:

      config :google_api_firestore, :base_url, "https://my-custom-url.com/"
  """

  use GoogleApi.Gax.Connection,
    scopes: [
      "https://www.googleapis.com/auth/cloud-platform",
      # See, edit, configure, and delete your Google Cloud data and see the email address for your Google Account.
      "https://www.googleapis.com/auth/datastore"
    ],
    otp_app: :google_api_firestore,
    # View and manage your Google Cloud Datastore data
    base_url: Application.get_env(:google_api_firestore, :base_url, "https://firestore.googleapis.com/")

  @type t :: Tesla.Env.client()
end