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
      "birth_data" => %{timestampValue: %{seconds: 896779801, nanos: 23149000}},
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
  def encode(data) when is_map(data) do
    %{fields: Map.new(data, fn {k, v} -> {k, encode_value(v)} end)}
  end

  def encode(value), do: encode_value(value)

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
