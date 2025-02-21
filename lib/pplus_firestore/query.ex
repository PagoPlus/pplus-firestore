defmodule PPlusFireStore.Query do
  @moduledoc """
  Module to interact with Google Firestore API

  ## Example

  ```elixir
  query =
    from("books")
    |> where("author" == "John Doe")
    |> order_by("author", :asc)
    |> limit(5)
    |> offset(10)
  ```
  """

  alias GoogleApi.Firestore.V1.Model.CollectionSelector
  alias GoogleApi.Firestore.V1.Model.CompositeFilter
  alias GoogleApi.Firestore.V1.Model.FieldFilter
  alias GoogleApi.Firestore.V1.Model.FieldReference
  alias GoogleApi.Firestore.V1.Model.Filter
  alias GoogleApi.Firestore.V1.Model.Order
  alias GoogleApi.Firestore.V1.Model.StructuredQuery
  alias PPlusFireStore.Encoder

  def from(collection) when is_binary(collection), do: from(%StructuredQuery{}, collection)
  def from(collection, opts) when is_binary(collection), do: from(%StructuredQuery{}, collection, opts)
  def from(%StructuredQuery{} = query, collection) when is_binary(collection), do: from(query, collection, [])

  def from(%StructuredQuery{} = query, collection, opts) when is_binary(collection) do
    selector = %CollectionSelector{
      collectionId: collection,
      allDescendants: Keyword.get(opts, :allDescendants, false)
    }

    case query.from do
      nil -> struct(query, from: [selector])
      list -> struct(query, from: [selector | list])
    end
  end

  defmacro where(query, expression), do: build_where(query, expression, "AND")
  defmacro or_where(query, expression), do: build_where(query, expression, "OR")

  def limit(%StructuredQuery{} = query, limit), do: struct(query, limit: limit)
  def offset(%StructuredQuery{} = query, offset), do: struct(query, offset: offset)

  def order_by(%StructuredQuery{} = query, field) when is_binary(field), do: order_by(query, [field], :asc)

  def order_by(%StructuredQuery{} = query, field, direction) when is_binary(field),
    do: order_by(query, [field], direction)

  def order_by(%StructuredQuery{} = query, fields, direction) when is_list(fields) and direction in [:asc, :desc] do
    direction = if direction == :asc, do: "ASCENDING", else: "DESCENDING"
    fields = Enum.map(fields, &%Order{field: %FieldReference{fieldPath: &1}, direction: direction})

    case query.orderBy do
      nil -> struct(query, orderBy: fields)
      list -> struct(query, orderBy: list ++ fields)
    end
  end

  def contains(left, right), do: {:contains, [], [left, right]}

  defp build_where(query, expression, op) do
    filter = expression |> build_filter() |> Macro.escape()

    quote do
      case unquote(query).where do
        nil ->
          struct(unquote(query), where: unquote(filter))

        %Filter{fieldFilter: %FieldFilter{}} = current ->
          struct(unquote(query),
            where: %Filter{compositeFilter: %CompositeFilter{op: unquote(op), filters: [current, unquote(filter)]}}
          )

        %Filter{compositeFilter: %CompositeFilter{filters: current}} ->
          struct(unquote(query),
            where: %Filter{compositeFilter: %CompositeFilter{op: unquote(op), filters: current ++ [unquote(filter)]}}
          )
      end
    end
  end

  defp parse_expression({:and, _, [left, right]}),
    do: %CompositeFilter{op: "AND", filters: [build_filter(left), build_filter(right)]}

  defp parse_expression({:or, _, [left, right]}),
    do: %CompositeFilter{op: "OR", filters: [build_filter(left), build_filter(right)]}

  defp parse_expression({:==, _, [left, right]}), do: build_field_filter(left, "EQUAL", right)
  defp parse_expression({:>, _, [left, right]}), do: build_field_filter(left, "GREATER_THAN", right)
  defp parse_expression({:>=, _, [left, right]}), do: build_field_filter(left, "GREATER_THAN_OR_EQUAL", right)
  defp parse_expression({:<, _, [left, right]}), do: build_field_filter(left, "LESS_THAN", right)
  defp parse_expression({:<=, _, [left, right]}), do: build_field_filter(left, "LESS_THAN_OR_EQUAL", right)
  defp parse_expression({:!=, _, [left, right]}), do: build_field_filter(left, "NOT_EQUAL", right)
  defp parse_expression({:in, _, [left, right]}) when is_list(right), do: build_field_filter(left, "IN", right)

  defp parse_expression({:in, _, [_left, _right]}) do
    raise(ArgumentError, "IN operator requires a list as the right operand")
  end

  defp parse_expression({:contains, _, [left, right]}), do: build_field_filter(left, "ARRAY_CONTAINS", right)

  defp parse_expression({:contains_any, _, [left, right]}) when is_list(right) do
    build_field_filter(left, "ARRAY_CONTAINS_ANY", right)
  end

  defp build_field_filter(field, op, value) do
    %FieldFilter{field: %FieldReference{fieldPath: field}, op: op, value: Encoder.encode(value)}
  end

  defp build_filter(expression) do
    case parse_expression(expression) do
      %FieldFilter{} = filter -> %Filter{fieldFilter: filter}
      %CompositeFilter{} = filter -> %Filter{compositeFilter: filter}
    end
  end
end
