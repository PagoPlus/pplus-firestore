defmodule PPlusFireStore.Decoder do
  @moduledoc false
  alias GoogleApi.Firestore.V1.Model.ArrayValue
  alias GoogleApi.Firestore.V1.Model.Document
  alias GoogleApi.Firestore.V1.Model.Empty
  alias GoogleApi.Firestore.V1.Model.LatLng
  alias GoogleApi.Firestore.V1.Model.ListDocumentsResponse
  alias GoogleApi.Firestore.V1.Model.MapValue
  alias GoogleApi.Firestore.V1.Model.Value

  def decode(%Document{fields: nil} = document) do
    %PPlusFireStore.Model.Document{
      path: document.name,
      data: %{},
      created_at: document.createTime,
      updated_at: document.updateTime
    }
  end

  def decode(%Document{fields: fields, name: name, createTime: create_time}) do
    %PPlusFireStore.Model.Document{
      path: name,
      data: Map.new(fields, fn {k, v} -> {k, decode_value(v)} end),
      created_at: create_time,
      updated_at: create_time
    }
  end

  def decode(%Empty{}), do: nil

  def decode(%ListDocumentsResponse{documents: nil}) do
    %{
      data: [],
      next_page_token: nil
    }
  end

  def decode(%ListDocumentsResponse{documents: documents, nextPageToken: token}) do
    %{
      data: Enum.map(documents, &decode/1),
      next_page_token: token
    }
  end

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

  defp decode_value(%Value{geoPointValue: %LatLng{latitude: lat, longitude: lng}}), do: {lat, lng}

  defp decode_value(%Value{mapValue: %MapValue{fields: nil}}), do: %{}

  defp decode_value(%Value{mapValue: %MapValue{fields: fields}}) do
    Map.new(fields, fn {k, v} -> {k, decode_value(v)} end)
  end

  defp decode_value(%Value{nullValue: nil}), do: nil
end
