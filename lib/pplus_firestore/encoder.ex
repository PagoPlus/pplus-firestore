defmodule PPlusFireStore.Encoder do
  @moduledoc false
  def encode(data) do
    %{fields: Map.new(data, fn {k, v} -> {k, encode_value(v)} end)}
  end

  def encode_value(nil), do: %{nullValue: nil}
  def encode_value({:bytes, value}), do: %{bytesValue: value}
  def encode_value({:ref, value}), do: %{referenceValue: value}
  def encode_value({:geo, {lat, lng}}), do: %{geoPointValue: %{latitude: lat, longitude: lng}}
  def encode_value(value) when is_boolean(value), do: %{booleanValue: value}
  def encode_value(value) when is_float(value), do: %{doubleValue: value}
  def encode_value(value) when is_integer(value), do: %{integerValue: value}
  def encode_value(value) when is_binary(value), do: %{stringValue: value}

  def encode_value({lat, lng}) when is_number(lat) and is_number(lng) do
    %{geoPointValue: %{latitude: lat, longitude: lng}}
  end

  def encode_value(%{latitude: lat, longitude: lng}) when is_number(lat) and is_number(lng) do
    %{geoPointValue: %{latitude: lat, longitude: lng}}
  end

  def encode_value(%DateTime{} = value) do
    %{
      timestampValue: %{
        seconds: DateTime.to_unix(value),
        nanos:
          value.microsecond
          |> elem(0)
          |> Kernel.*(1000)
      }
    }
  end

  def encode_value(value) when is_list(value) do
    %{arrayValue: %{values: Enum.map(value, &encode_value/1)}}
  end

  def encode_value(value) when is_map(value) do
    %{
      mapValue: %{
        fields: Map.new(value, fn {k, v} -> {k, encode_value(v)} end)
      }
    }
  end
end
