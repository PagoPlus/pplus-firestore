defmodule PPlusFireStore.EncoderTest do
  use ExUnit.Case

  alias PPlusFireStore.Encoder

  doctest PPlusFireStore.Encoder

  describe "encode/1" do
    test "encode empty map" do
      assert Encoder.encode(%{}) == %{fields: %{}}
    end

    test "encode map with values" do
      assert Encoder.encode(%{"key" => "value"}) == %{
               fields: %{
                 "key" => %{
                   stringValue: "value"
                 }
               }
             }
    end

    test "encode map with arrays" do
      assert Encoder.encode(%{"key" => ["value1", "value2"]}) == %{
               fields: %{
                 "key" => %{
                   arrayValue: %{
                     values: [
                       %{
                         stringValue: "value1"
                       },
                       %{
                         stringValue: "value2"
                       }
                     ]
                   }
                 }
               }
             }
    end

    test "encode map with nested maps" do
      map_to_encode = %{
        "key" => %{
          "nested_key" => %{
            "deeply_nested_key" => "deeply_nested_value"
          }
        },
        "another_key" => %{
          "another_nested_key" => "another_nested_value"
        }
      }

      assert Encoder.encode(map_to_encode) == %{
               fields: %{
                 "key" => %{
                   mapValue: %{
                     fields: %{
                       "nested_key" => %{
                         mapValue: %{fields: %{"deeply_nested_key" => %{stringValue: "deeply_nested_value"}}}
                       }
                     }
                   }
                 },
                 "another_key" => %{
                   mapValue: %{fields: %{"another_nested_key" => %{stringValue: "another_nested_value"}}}
                 }
               }
             }
    end

    test "encode map with nested arrays" do
      map_to_encode = %{
        "key" => [
          [
            ["value1", "value2"],
            ["value3", "value4"]
          ],
          [
            ["value5", "value6"],
            ["value7", "value8"]
          ]
        ]
      }

      assert Encoder.encode(map_to_encode) == %{
               fields: %{
                 "key" => %{
                   arrayValue: %{
                     values: [
                       %{
                         arrayValue: %{
                           values: [
                             %{arrayValue: %{values: [%{stringValue: "value1"}, %{stringValue: "value2"}]}},
                             %{arrayValue: %{values: [%{stringValue: "value3"}, %{stringValue: "value4"}]}}
                           ]
                         }
                       },
                       %{
                         arrayValue: %{
                           values: [
                             %{arrayValue: %{values: [%{stringValue: "value5"}, %{stringValue: "value6"}]}},
                             %{arrayValue: %{values: [%{stringValue: "value7"}, %{stringValue: "value8"}]}}
                           ]
                         }
                       }
                     ]
                   }
                 }
               }
             }
    end

    test "encode map with geo_point value as map" do
      map_to_encode = %{
        "key" => %{latitude: 1.0, longitude: 2.0}
      }

      assert Encoder.encode(map_to_encode) == %{
               fields: %{
                 "key" => %{
                   geoPointValue: %{latitude: 1.0, longitude: 2.0}
                 }
               }
             }
    end

    test "encode map with geo_point value as tuple" do
      map_to_encode = %{
        "key" => {1.0, 2.0}
      }

      assert Encoder.encode(map_to_encode) == %{
               fields: %{
                 "key" => %{
                   geoPointValue: %{latitude: 1.0, longitude: 2.0}
                 }
               }
             }
    end

    test "encode map with geo_point value as tuple {geo, {lat, lng}}" do
      map_to_encode = %{
        "key" => {:geo, {1.0, 2.0}}
      }

      assert Encoder.encode(map_to_encode) == %{
               fields: %{
                 "key" => %{
                   geoPointValue: %{latitude: 1.0, longitude: 2.0}
                 }
               }
             }
    end

    test "encode map with bytes value" do
      map_to_encode = %{
        "key" => {:bytes, "value"}
      }

      assert Encoder.encode(map_to_encode) == %{
               fields: %{
                 "key" => %{
                   bytesValue: "value"
                 }
               }
             }
    end

    test "encode map with reference value" do
      map_to_encode = %{
        "key" => {:ref, "projects/my_project/databases/(default)/documents/other_collection/other_document"}
      }

      assert Encoder.encode(map_to_encode) == %{
               fields: %{
                 "key" => %{
                   referenceValue: "projects/my_project/databases/(default)/documents/other_collection/other_document"
                 }
               }
             }
    end

    test "encode map with nil value" do
      map_to_encode = %{
        "key" => nil
      }

      assert Encoder.encode(map_to_encode) == %{
               fields: %{
                 "key" => %{
                   nullValue: nil
                 }
               }
             }
    end

    test "encode map with boolean value" do
      map_to_encode = %{
        "key" => true
      }

      assert Encoder.encode(map_to_encode) == %{
               fields: %{
                 "key" => %{
                   booleanValue: true
                 }
               }
             }
    end

    test "encode map with float value" do
      map_to_encode = %{
        "key" => 1.0
      }

      assert Encoder.encode(map_to_encode) == %{
               fields: %{
                 "key" => %{
                   doubleValue: 1.0
                 }
               }
             }
    end

    test "encode map with integer value" do
      map_to_encode = %{
        "key" => 42
      }

      assert Encoder.encode(map_to_encode) == %{
               fields: %{
                 "key" => %{
                   integerValue: 42
                 }
               }
             }
    end

    test "encode map with datetime value" do
      map_to_encode = %{
        "key" => ~U[2025-01-10 17:14:04.738331Z]
      }

      assert Encoder.encode(map_to_encode) == %{
               fields: %{
                 "key" => %{
                   timestampValue: %{
                     seconds: 1_736_529_244,
                     nanos: 738_331_000
                   }
                 }
               }
             }
    end

    test "encode map with nested map with datetime value" do
      map_to_encode = %{
        "key" => %{
          "nested_key" => ~U[2025-01-10 17:14:04.738331Z]
        }
      }

      assert Encoder.encode(map_to_encode) == %{
               fields: %{
                 "key" => %{
                   mapValue: %{
                     fields: %{
                       "nested_key" => %{
                         timestampValue: %{
                           seconds: 1_736_529_244,
                           nanos: 738_331_000
                         }
                       }
                     }
                   }
                 }
               }
             }
    end
  end
end
