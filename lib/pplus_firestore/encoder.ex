defmodule PPlusFireStore.Encoder do
  @moduledoc """
  Documentation for `PPlusFireStore.Encoder`.

  The Google Firestore API expects a map in a complex format containing the data and their respective types.

  The Encoder module is responsible for encoding the data to be sent.

  Example:

  ```elixir
  iex> PPlusFireStore.Encoder.encode(%{"name" => "John Doe", "age" => 42})
  %{
    fields: %{
      "name" => %{stringValue: "John Doe"},
      "age" => %{integerValue: 42}
    }
  }
  ```

  There are also special types such as `DateTime`, `GeoPoint`, and `Reference`.

  ```elixir
  iex> PPlusFireStore.Encoder.encode(%{"name" => "John Doe", "age" => 42, "birth_data" => ~U[1998-06-02 09:30:01.023149Z]})
  %{
    fields: %{
      "age" => %{integerValue: 42},
      "birth_data" => %{timestampValue: ~U[1998-06-02 09:30:01.023149Z]},
      "name" => %{stringValue: "John Doe"}
    }
  }
  ```

  ```elixir
  iex> PPlusFireStore.Encoder.encode(%{"location" => {:geo, {5.96989, 31.19063}}})
  %{
    fields: %{
      "location" => %{geoPointValue: %{latitude: 5.96989, longitude: 31.19063}}
    }
  }
  ```

  ```elixir
  iex> PPlusFireStore.Encoder.encode(%{"location" => %{latitude: 5.96989, longitude: 31.19063}})
  %{
    fields: %{
      "location" => %{geoPointValue: %{latitude: 5.96989, longitude: 31.19063}}
    }
  }
  ```

  ```elixir
  iex> PPlusFireStore.Encoder.encode(%{"next" => {:ref, "projects/my-project/databases/(default)/documents/my-collection/my-document"}})
  %{
    fields: %{
      "next" => %{referenceValue: "projects/my-project/databases/(default)/documents/my-collection/my-document"}
    }
  }
  ```
  """

  @spec encode(data :: map()) :: map()

  def encode(%DateTime{} = value), do: encode_value(value)

  def encode(data) when is_map(data) do
    %{fields: Map.new(data, fn {k, v} -> {k, encode_value(v)} end)}
  end

  def encode(value), do: encode_value(value)

  defp encode_value(nil), do: %{nullValue: nil}
  defp encode_value({:bytes, value}), do: %{bytesValue: value}
  defp encode_value({:ref, value}), do: %{referenceValue: value}
  defp encode_value({:geo, {lat, lng}}), do: %{geoPointValue: %{latitude: lat, longitude: lng}}
  defp encode_value(value) when is_boolean(value), do: %{booleanValue: value}
  defp encode_value(value) when is_float(value), do: %{doubleValue: value}
  defp encode_value(value) when is_integer(value), do: %{integerValue: value}
  defp encode_value(value) when is_binary(value), do: %{stringValue: value}
  defp encode_value(%DateTime{} = value), do: %{timestampValue: value}

  defp encode_value({lat, lng}) when is_number(lat) and is_number(lng) do
    %{geoPointValue: %{latitude: lat, longitude: lng}}
  end

  defp encode_value(%{latitude: lat, longitude: lng}) when is_number(lat) and is_number(lng) do
    %{geoPointValue: %{latitude: lat, longitude: lng}}
  end

  defp encode_value(value) when is_list(value) do
    %{arrayValue: %{values: Enum.map(value, &encode_value/1)}}
  end

  defp encode_value(value) when is_map(value) do
    %{
      mapValue: %{
        fields: Map.new(value, fn {k, v} -> {k, encode_value(v)} end)
      }
    }
  end
end
