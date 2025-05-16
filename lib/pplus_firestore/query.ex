defmodule PPlusFireStore.Query do
  @moduledoc """
  Create Firestore queries using Elixir syntax.

  The operations supported by Firestore are:
  - `==` (EQUALS)
  - `!=` (NOT_EQUALS)
  - `>` (GREATER_THAN)
  - `<` (LESS_THAN)
  - `>=` (GREATER_THAN_OR_EQUAL)
  - `<=` (LESS_THAN_OR_EQUAL)
  - `in` (IN)
  - `not in` (NOT_IN)
  - `contains` (ARRAY_CONTAINS)
  - `contains_any` (ARRAY_CONTAINS_ANY)
  - `is_nil` (IS_NULL)

  ## Example

  Get from "books" filtered by author and ordered by author name in ascending order:
  ```elixir
  from("books")
  |> where("author" == "John Doe")
  |> order_by("author", :asc)
  |> limit(5)
  |> offset(10)
  ```

  NOTE: Although it is possible to paginate with `limit` and `offset`, the query result does not inform the total number of documents in the collection or if there is a next page.


  Get from "books" filtered by author and ordered by author name in ascending order:
  ```elixir
  from("books")
  |> where("author" in ["John Doe", "Alice Smith", "Bob Brown"])
  |> order_by("author", :asc)
  ```

  When a field is an array, you can use the `contains` operator to filter by the array content:
  ```elixir
  from("books")
  |> where(contains("tags", "fiction") and "pages" > 300)
  ```

  You can also use the `contains_any` operator to filter by any of the values in the array:
  ```elixir
  from("books")
  |> where(contains_any("tags", ["fiction", "non-fiction"]))
  ```

  You can also pass the values dynamically:
  ```elixir
  collection = "books"
  field = "pages"
  value = 300

  query =
    from(collection)
    |> where(field > value)
  ```
  """

  alias GoogleApi.Firestore.V1.Model.CollectionSelector
  alias GoogleApi.Firestore.V1.Model.CompositeFilter
  alias GoogleApi.Firestore.V1.Model.FieldFilter
  alias GoogleApi.Firestore.V1.Model.FieldReference
  alias GoogleApi.Firestore.V1.Model.Filter
  alias GoogleApi.Firestore.V1.Model.Order
  alias GoogleApi.Firestore.V1.Model.Projection
  alias GoogleApi.Firestore.V1.Model.StructuredQuery
  alias GoogleApi.Firestore.V1.Model.UnaryFilter
  alias PPlusFireStore.Encoder

  @doc """
  Create a query from a collection with options

  ## Example

  ```elixir
  from("books", where: "author" == "John Doe", limit: 5, order_by: {"author", :asc})
  ```

  ```elixir
  from("books", all_descendants: true)
  ```
  """
  @spec from(collection :: String.t(), opts :: Keyword.t()) :: StructuredQuery.t()
  defmacro from(collection, opts \\ []) do
    all_descendants = Keyword.get(opts, :all_descendants, false)

    query =
      quote do
        %StructuredQuery{
          from: [
            %CollectionSelector{
              collectionId: unquote(collection),
              allDescendants: unquote(all_descendants)
            }
          ]
        }
      end

    query = apply_hints(query, Keyword.take(opts, [:where, :or_where, :limit, :offset, :order_by, :select]))

    quote do
      unquote(query)
    end
  end

  @doc """
  Add a filter to the query

  ## Example

  ```elixir
  from("books")
  |> where("author" == "John Doe")
  ```

  ```elixir
  from("books")
  |> where("author" == "John Doe" and "pages" > 300)
  ```

  Multiple chained filters are equivalent to an `AND`.
  ```elixir
  from("books")
  |> where("author" in ["John Doe", "Alice Smith", "Bob Brown"])
  |> where("pages" > 300)
  |> where("metadata.year" <= 2021)
  ```
  """
  @spec where(StructuredQuery.t(), expression :: Macro.t()) :: StructuredQuery.t()
  defmacro where(query, expression, opts \\ []), do: build_where(query, expression, "AND", opts)

  @doc """
  Add an `OR` filter to the query

  ## Example

  ```elixir
  from("books")
  |> where("author" == "John Doe" and "pages" > 300)
  |> or_where("author" == "Alice Smith" and "pages" <= 200)
  ```
  Essa consulta é equivalente a:
  ```
  SELECT * FROM books
  WHERE (author = "John Doe" AND pages > 300) OR (author = "Alice Smith" AND pages <= 200)
  ```

  Assim como where, você pode encadear vários or_where.
  ```elixir
  from("books")
  |> where("author" == "John Doe" and "pages" > 300)
  |> or_where("author" == "Alice Smith" and "pages" <= 200)
  |> or_where("author" == "Bob Brown" and "metadata.year" <= 2021)
  |> or_where("author" == "Charlie Brown" and "metadata.publisher" == "Publisher A")

  ```
  """
  @spec or_where(StructuredQuery.t(), expression :: Macro.t()) :: StructuredQuery.t()
  defmacro or_where(query, expression), do: build_where(query, expression, "OR", [])

  @doc """
  Define quantity of documents to return

  ## Example

  ```elixir
  from("books")
  |> limit(5)
  ```
  """
  @spec limit(StructuredQuery.t(), limit :: non_neg_integer()) :: StructuredQuery.t()
  def limit(%StructuredQuery{} = query, limit), do: struct(query, limit: limit)

  @doc """
  Define the offset of the query

  ## Example

  ```elixir
  from("books")
  |> limit(5)
  |> offset(10)
  ```
  """
  @spec offset(StructuredQuery.t(), offset :: non_neg_integer()) :: StructuredQuery.t()
  def offset(%StructuredQuery{} = query, offset), do: struct(query, offset: offset)

  @spec order_by(StructuredQuery.t(), field :: String.t() | [String.t()], direction :: :asc | :desc) ::
          StructuredQuery.t()

  def order_by(%StructuredQuery{} = query, field) when is_binary(field), do: order_by(query, [field], :asc)

  def order_by(%StructuredQuery{} = query, fields) when is_list(fields), do: order_by(query, fields, :asc)

  def order_by(%StructuredQuery{} = query, field, direction) when is_binary(field),
    do: order_by(query, [field], direction)

  @doc """
  Orders the query by one or more fields in ascending or descending order

  ## Example

  ```elixir
  from("books")
  |> order_by("author", :asc)
  ```

  ```elixir
  from("books")
  |> order_by(["author", "metadata.year"], :desc)
  ```
  """
  def order_by(%StructuredQuery{} = query, fields, direction) when is_list(fields) and direction in [:asc, :desc] do
    direction = if direction == :asc, do: "ASCENDING", else: "DESCENDING"
    fields = Enum.map(fields, &%Order{field: %FieldReference{fieldPath: &1}, direction: direction})

    case query.orderBy do
      nil -> struct(query, orderBy: fields)
      list -> struct(query, orderBy: list ++ fields)
    end
  end

  @doc """
  Selects the fields to return in the query

  ## Example

  ```elixir
  from("books")
  |> select(["author", "metadata.publisher"])
  ```
  """
  @spec select(StructuredQuery.t(), fields :: list(String.t())) :: StructuredQuery.t()
  def select(%StructuredQuery{} = query, fields) when is_list(fields) do
    fields = Enum.map(fields, &%FieldReference{fieldPath: &1})
    struct(query, select: %Projection{fields: fields})
  end

  def build_where(%StructuredQuery{where: nil} = query, filter, _op) do
    struct(query, where: filter)
  end

  def build_where(%StructuredQuery{where: %Filter{unaryFilter: %UnaryFilter{}} = current} = query, filter, op) do
    struct(query,
      where: %Filter{compositeFilter: %CompositeFilter{op: op, filters: [current, filter]}}
    )
  end

  def build_where(%StructuredQuery{where: %Filter{fieldFilter: %FieldFilter{}} = current} = query, filter, op) do
    struct(query,
      where: %Filter{compositeFilter: %CompositeFilter{op: op, filters: [current, filter]}}
    )
  end

  def build_where(%StructuredQuery{where: %Filter{compositeFilter: %CompositeFilter{}} = current} = query, filter, op) do
    struct(query,
      where: %Filter{compositeFilter: %CompositeFilter{op: op, filters: [current, filter]}}
    )
  end

  def build_where(collection, filter, _op) when is_binary(collection) do
    %StructuredQuery{
      from: [%CollectionSelector{collectionId: collection}],
      where: filter
    }
  end

  def build_where(query, expression, op, opts) do
    filter = parse_expression(expression)

    query =
      quote do
        build_where(unquote(query), unquote(filter), unquote(op))
      end

    query = apply_hints(query, Keyword.take(opts, [:limit, :offset, :order_by, :select]))

    quote do
      unquote(query)
    end
  end

  defp parse_expression({:and, _, [field, value]}) do
    build_composite_filter("AND", [parse_expression(field), parse_expression(value)])
  end

  defp parse_expression({:or, _, [field, value]}) do
    build_composite_filter("OR", [parse_expression(field), parse_expression(value)])
  end

  defp parse_expression({:==, _, [field, nil]}), do: build_unary_filter(field, "IS_NULL")
  defp parse_expression({:==, _, [field, value]}), do: build_field_filter(field, "EQUAL", value)
  defp parse_expression({:>, _, [field, value]}), do: build_field_filter(field, "GREATER_THAN", value)
  defp parse_expression({:>=, _, [field, value]}), do: build_field_filter(field, "GREATER_THAN_OR_EQUAL", value)
  defp parse_expression({:<, _, [field, value]}), do: build_field_filter(field, "LESS_THAN", value)
  defp parse_expression({:<=, _, [field, value]}), do: build_field_filter(field, "LESS_THAN_OR_EQUAL", value)
  defp parse_expression({:!=, _, [field, value]}), do: build_field_filter(field, "NOT_EQUAL", value)

  defp parse_expression({:not, _, [{:in, _, [field, value]}]}) do
    build_field_filter(field, "NOT_IN", value)
  end

  defp parse_expression({:in, _, [field, value]}), do: build_field_filter(field, "IN", value)

  defp parse_expression({:is_nil, _, [field]}), do: build_unary_filter(field, "IS_NULL")

  defp parse_expression({:contains, _, [field, value]}), do: build_field_filter(field, "ARRAY_CONTAINS", value)

  defp parse_expression({:contains_any, _, [field, value]}) do
    build_field_filter(field, "ARRAY_CONTAINS_ANY", value)
  end

  defp build_field_filter(field, op, value) do
    quote do
      maybe_raise_operator_error(unquote(op), unquote(value))

      %Filter{
        fieldFilter: %FieldFilter{
          op: unquote(op),
          field: %FieldReference{fieldPath: unquote(field)},
          value: Encoder.encode(unquote(value))
        }
      }
    end
  end

  defp build_unary_filter(field, op) do
    quote do
      %Filter{
        unaryFilter: %UnaryFilter{
          op: unquote(op),
          field: %FieldReference{fieldPath: unquote(field)}
        }
      }
    end
  end

  defp build_composite_filter(op, filters) do
    quote do
      %Filter{
        compositeFilter: %CompositeFilter{
          op: unquote(op),
          filters: unquote(filters)
        }
      }
    end
  end

  defp apply_hints(query, hints) do
    Enum.reduce(hints, query, fn {key, value}, query -> apply_hint(query, key, value) end)
  end

  defp apply_hint(query, :where, expression) do
    quote do
      where(unquote(query), unquote(expression))
    end
  end

  defp apply_hint(query, :limit, limit) do
    quote do
      limit(unquote(query), unquote(limit))
    end
  end

  defp apply_hint(query, :offset, offset) do
    quote do
      offset(unquote(query), unquote(offset))
    end
  end

  defp apply_hint(query, :order_by, {field, direction}) do
    quote do
      order_by(unquote(query), unquote(field), unquote(direction))
    end
  end

  defp apply_hint(query, :order_by, field) do
    quote do
      order_by(unquote(query), unquote(field))
    end
  end

  defp apply_hint(query, :select, fields) do
    quote do
      select(unquote(query), unquote(fields))
    end
  end

  def maybe_raise_operator_error(op, value) when op in ["IN", "NOT_IN"] and not is_list(value) do
    raise(ArgumentError, "IN operator requires a list as the right side of the expression\n\n")
  end

  def maybe_raise_operator_error(_, _), do: :ok
end
