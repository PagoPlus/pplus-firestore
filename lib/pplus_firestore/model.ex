defmodule PPlusFireStore.Model do
  @moduledoc """
  This module defines structs adapted from the Models of the Google Firestore API
  """
  defmodule Document do
    @moduledoc """
    Struct adapted from the Google Firestore API Document model

    ## Fields
      - path: The resource name of the document. For example: `projects/{project_id}/databases/{database_id}/documents/{document_path}`
      - data: The document fields and values. For example: `%{"author" => "John Doe"}`
      - created_at: The time at which the document was created. Automatically set by Firestore.
      - updated_at: The time at which the document was last updated. Automatically set by Firestore.
    """
    defstruct [:path, :data, :created_at, :updated_at]

    @type t :: %__MODULE__{
            path: String.t(),
            data: map(),
            created_at: DateTime.t(),
            updated_at: DateTime.t()
          }
  end

  defmodule Page do
    @moduledoc """
    Struct adapted from the Google Firestore API documents list response

    ## Fields
      - data: The list of documents returned.
      - next_page_token: The next page token. If not set, there are no subsequent pages.
    """

    defstruct data: [],
              next_page_token: nil

    @type t(t) :: %__MODULE__{
            data: [t],
            next_page_token: String.t()
          }
  end
end
