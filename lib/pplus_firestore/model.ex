defmodule PPlusFireStore.Model do
  @moduledoc false
  defmodule Document do
    @moduledoc false
    defstruct [:path, :data, :created_at, :updated_at]

    @type t :: %__MODULE__{
            path: String.t(),
            data: map(),
            created_at: DateTime.t(),
            updated_at: DateTime.t()
          }
  end

  defmodule Page do
    @moduledoc false

    defstruct [:data, :next_page_token]

    @type t(t) :: %__MODULE__{
            data: [t],
            next_page_token: String.t()
          }
  end
end
