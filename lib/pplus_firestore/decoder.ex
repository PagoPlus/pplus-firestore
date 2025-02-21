defmodule PPlusFireStore.Decoder do
  @moduledoc """
  Documentation for `PPlusFireStore.Decoder`.

  This module is responsible for decoding the response from Google Firestore API.

  ## Example

      iex> PPlusFireStore.Decoder.decode(%GoogleApi.Firestore.V1.Model.Document{
      ...>   name: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
      ...>   fields: %{
      ...>     "author" => %GoogleApi.Firestore.V1.Model.Value{stringValue: "John Doe"}
      ...>   },
      ...>   createTime: ~U[2025-01-10 17:14:04.738331Z],
      ...>   updateTime: ~U[2025-01-10 17:14:04.738331Z]
      ...> })
      %PPlusFireStore.Model.Document{
        path: "projects/my_project/databases/(default)/documents/books/esgXQM7pqNCwQwYRJeBJ",
        data: %{"author" => "John Doe"},
        created_at: ~U[2025-01-10 17:14:04.738331Z],
        updated_at: ~U[2025-01-10 17:14:04.738331Z]
      }
  """
  alias GoogleApi.Firestore.V1.Model.RunQueryResponse
  alias GoogleApi.Firestore.V1.Model.ArrayValue
  alias GoogleApi.Firestore.V1.Model.Document
  alias GoogleApi.Firestore.V1.Model.Empty
  alias GoogleApi.Firestore.V1.Model.LatLng
  alias GoogleApi.Firestore.V1.Model.ListDocumentsResponse
  alias GoogleApi.Firestore.V1.Model.MapValue
  alias GoogleApi.Firestore.V1.Model.Value

  # Internal models
  alias PPlusFireStore.Model.Document, as: PPlusDocument
  alias PPlusFireStore.Model.Page, as: PPlusPage

  @spec decode(GoogleApi.Firestore.V1.Model.Document.t()) :: PPlusDocument.t()
  @spec decode(GoogleApi.Firestore.V1.Model.ListDocumentsResponse.t()) :: PPlusPage.t(PPlusDocument.t())
  @spec decode(GoogleApi.Firestore.V1.Model.RunQueryResponse.t()) :: PPlusPage.t(PPlusDocument.t())
  @spec decode(GoogleApi.Firestore.V1.Model.Empty.t()) :: nil
  def decode(%Document{fields: nil} = document) do
    decode(struct(document, fields: %{}))
  end

  def decode(%Document{fields: fields, name: name, createTime: create_time}) do
    %PPlusDocument{
      path: name,
      data: Map.new(fields, fn {k, v} -> {k, decode_value(v)} end),
      created_at: create_time,
      updated_at: create_time
    }
  end

  def decode(%ListDocumentsResponse{documents: nil}), do: %PPlusPage{}

  def decode(%ListDocumentsResponse{documents: documents, nextPageToken: token}) do
    %PPlusPage{
      data: Enum.map(documents, &decode/1),
      next_page_token: token
    }
  end

  def decode(%RunQueryResponse{document: %Document{} = document}), do: decode(document)

  def decode(%Empty{}), do: nil

  defp decode_value(%Value{stringValue: value}) when is_binary(value), do: value
  defp decode_value(%Value{referenceValue: value}) when is_binary(value), do: value
  defp decode_value(%Value{bytesValue: value}) when is_binary(value), do: value
  defp decode_value(%Value{integerValue: value}) when is_integer(value), do: value

  defp decode_value(%Value{integerValue: value}) when is_binary(value) do
    String.to_integer(value)
  end

  defp decode_value(%Value{doubleValue: value}) when is_float(value), do: value
  defp decode_value(%Value{doubleValue: value}) when is_binary(value), do: String.to_float(value)
  defp decode_value(%Value{booleanValue: value}) when is_boolean(value), do: value
  defp decode_value(%Value{timestampValue: %DateTime{} = value}), do: value

  defp decode_value(%Value{arrayValue: %ArrayValue{values: nil}}), do: []

  defp decode_value(%Value{arrayValue: %ArrayValue{values: values}}) do
    Enum.map(values, &decode_value/1)
  end

  defp decode_value(%Value{geoPointValue: %LatLng{latitude: lat, longitude: lng}}) do
    %{"latitude" => lat, "longitude" => lng}
  end

  defp decode_value(%Value{mapValue: %MapValue{fields: nil}}), do: %{}

  defp decode_value(%Value{mapValue: %MapValue{fields: fields}}) do
    Map.new(fields, fn {k, v} -> {k, decode_value(v)} end)
  end

  defp decode_value(%Value{nullValue: nil}), do: nil
end
