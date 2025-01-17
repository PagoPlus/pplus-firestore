defmodule PPlusFireStore.DecoderTest do
  use ExUnit.Case

  alias GoogleApi.Firestore.V1.Model.ArrayValue
  alias GoogleApi.Firestore.V1.Model.Document
  alias GoogleApi.Firestore.V1.Model.Empty
  alias GoogleApi.Firestore.V1.Model.LatLng
  alias GoogleApi.Firestore.V1.Model.ListDocumentsResponse
  alias GoogleApi.Firestore.V1.Model.MapValue
  alias GoogleApi.Firestore.V1.Model.Value
  alias PPlusFireStore.Decoder
  alias PPlusFireStore.Model.Page

  doctest PPlusFireStore.Decoder

  describe "decode Document" do
    test "decode document with all field types" do
      document = %Document{
        name: "projects/my_project/databases/(default)/documents/tracking/Hd7XQM7pqNCwQwYRJeBJ",
        fields: %{
          "string_field" => %Value{stringValue: "A string value"},
          "integer_field" => %Value{integerValue: "42"},
          "double_field" => %Value{doubleValue: 3.14},
          "boolean_field" => %Value{booleanValue: true},
          "timestamp_field" => %Value{timestampValue: ~U[2025-01-10 17:14:04.738331Z]},
          "null_field" => %Value{nullValue: nil},
          "geo_point_field" => %Value{geoPointValue: %LatLng{latitude: 10.0, longitude: 20.0}},
          "array_field" => %Value{arrayValue: %{values: [%Value{stringValue: "Item1"}, %Value{integerValue: "2"}]}},
          "map_field" => %Value{
            mapValue: %MapValue{
              fields: %{
                "nested_string" => %Value{stringValue: "Nested Value"},
                "nested_number" => %Value{integerValue: "7"}
              }
            }
          },
          "reference_field" => %Value{
            referenceValue: "projects/my_project/databases/(default)/documents/other_collection/other_document"
          }
        },
        createTime: ~U[2025-01-10 17:14:04.738331Z],
        updateTime: ~U[2025-01-10 17:14:04.738331Z]
      }

      assert Decoder.decode(document) == %PPlusFireStore.Model.Document{
               data: %{
                 "array_field" => nil,
                 "boolean_field" => true,
                 "double_field" => 3.14,
                 "geo_point_field" => %{"latitude" => 10.0, "longitude" => 20.0},
                 "integer_field" => 42,
                 "map_field" => %{"nested_number" => 7, "nested_string" => "Nested Value"},
                 "null_field" => nil,
                 "reference_field" =>
                   "projects/my_project/databases/(default)/documents/other_collection/other_document",
                 "string_field" => "A string value",
                 "timestamp_field" => ~U[2025-01-10 17:14:04.738331Z]
               },
               path: "projects/my_project/databases/(default)/documents/tracking/Hd7XQM7pqNCwQwYRJeBJ",
               created_at: ~U[2025-01-10 17:14:04.738331Z],
               updated_at: ~U[2025-01-10 17:14:04.738331Z]
             }
    end

    test "decode document with empty fields" do
      document = %Document{
        name: "projects/my_project/databases/(default)/documents/tracking/EmptyFields",
        fields: %{},
        createTime: ~U[2025-01-10 17:14:04.738331Z],
        updateTime: ~U[2025-01-10 17:14:04.738331Z]
      }

      assert Decoder.decode(document) == %PPlusFireStore.Model.Document{
               data: %{},
               path: "projects/my_project/databases/(default)/documents/tracking/EmptyFields",
               created_at: ~U[2025-01-10 17:14:04.738331Z],
               updated_at: ~U[2025-01-10 17:14:04.738331Z]
             }
    end

    test "decode document with nested map fields" do
      document = %Document{
        name: "projects/my_project/databases/(default)/documents/tracking/NestedMapFields",
        fields: %{
          "map_field" => %Value{
            mapValue: %MapValue{
              fields: %{
                "nested_map" => %Value{
                  mapValue: %MapValue{
                    fields: %{
                      "deeply_nested_string" => %Value{stringValue: "Deeply Nested Value"}
                    }
                  }
                }
              }
            }
          }
        },
        createTime: ~U[2025-01-10 17:14:04.738331Z],
        updateTime: ~U[2025-01-10 17:14:04.738331Z]
      }

      assert Decoder.decode(document) == %PPlusFireStore.Model.Document{
               data: %{
                 "map_field" => %{
                   "nested_map" => %{
                     "deeply_nested_string" => "Deeply Nested Value"
                   }
                 }
               },
               path: "projects/my_project/databases/(default)/documents/tracking/NestedMapFields",
               created_at: ~U[2025-01-10 17:14:04.738331Z],
               updated_at: ~U[2025-01-10 17:14:04.738331Z]
             }
    end

    test "decode document with map inside array" do
      document = %Document{
        name: "projects/my_project/databases/(default)/documents/tracking/MapInsideArray",
        fields: %{
          "array_field" => %Value{
            arrayValue: %ArrayValue{
              values: [
                %Value{mapValue: %MapValue{fields: %{"key1" => %Value{stringValue: "value1"}}}},
                %Value{mapValue: %MapValue{fields: %{"key2" => %Value{integerValue: 2}}}}
              ]
            }
          }
        },
        createTime: ~U[2025-01-10 17:14:04.738331Z],
        updateTime: ~U[2025-01-10 17:14:04.738331Z]
      }

      assert Decoder.decode(document) == %PPlusFireStore.Model.Document{
               data: %{
                 "array_field" => [
                   %{"key1" => "value1"},
                   %{"key2" => 2}
                 ]
               },
               path: "projects/my_project/databases/(default)/documents/tracking/MapInsideArray",
               created_at: ~U[2025-01-10 17:14:04.738331Z],
               updated_at: ~U[2025-01-10 17:14:04.738331Z]
             }
    end

    test "decode document with byte field" do
      document = %Document{
        name: "projects/my_project/databases/(default)/documents/tracking/ByteField",
        fields: %{
          "byte_field" => %Value{bytesValue: <<1, 2, 3, 4>>}
        },
        createTime: ~U[2025-01-10 17:14:04.738331Z],
        updateTime: ~U[2025-01-10 17:14:04.738331Z]
      }

      assert Decoder.decode(document) == %PPlusFireStore.Model.Document{
               data: %{
                 "byte_field" => <<1, 2, 3, 4>>
               },
               path: "projects/my_project/databases/(default)/documents/tracking/ByteField",
               created_at: ~U[2025-01-10 17:14:04.738331Z],
               updated_at: ~U[2025-01-10 17:14:04.738331Z]
             }
    end

    test "encode double value when value is a string" do
      document = %Document{
        name: "projects/my_project/databases/(default)/documents/tracking/DoubleAsString",
        fields: %{
          "double_field" => %Value{doubleValue: "3.14"}
        },
        createTime: ~U[2025-01-10 17:14:04.738331Z],
        updateTime: ~U[2025-01-10 17:14:04.738331Z]
      }

      assert Decoder.decode(document) == %PPlusFireStore.Model.Document{
               data: %{
                 "double_field" => 3.14
               },
               path: "projects/my_project/databases/(default)/documents/tracking/DoubleAsString",
               created_at: ~U[2025-01-10 17:14:04.738331Z],
               updated_at: ~U[2025-01-10 17:14:04.738331Z]
             }
    end

    test "decode document with nil array field" do
      document = %Document{
        name: "projects/my_project/databases/(default)/documents/tracking/NilArrayField",
        fields: %{
          "array_field" => %Value{arrayValue: %ArrayValue{values: nil}}
        },
        createTime: ~U[2025-01-10 17:14:04.738331Z],
        updateTime: ~U[2025-01-10 17:14:04.738331Z]
      }

      assert Decoder.decode(document) == %PPlusFireStore.Model.Document{
               data: %{
                 "array_field" => []
               },
               path: "projects/my_project/databases/(default)/documents/tracking/NilArrayField",
               created_at: ~U[2025-01-10 17:14:04.738331Z],
               updated_at: ~U[2025-01-10 17:14:04.738331Z]
             }
    end

    test "decode document with nil fields" do
      document = %Document{
        name: "projects/my_project/databases/(default)/documents/tracking/NilFields",
        fields: nil,
        createTime: ~U[2025-01-10 17:14:04.738331Z],
        updateTime: ~U[2025-01-10 17:14:04.738331Z]
      }

      assert Decoder.decode(document) == %PPlusFireStore.Model.Document{
               data: %{},
               path: "projects/my_project/databases/(default)/documents/tracking/NilFields",
               created_at: ~U[2025-01-10 17:14:04.738331Z],
               updated_at: ~U[2025-01-10 17:14:04.738331Z]
             }
    end

    test "decode list of documents with nil documents" do
      list_response = %ListDocumentsResponse{
        documents: nil
      }

      assert Decoder.decode(list_response) == %Page{
               data: [],
               next_page_token: nil
             }
    end

    test "decode document with map field having nil fields" do
      document = %Document{
        name: "projects/my_project/databases/(default)/documents/tracking/MapFieldWithNilFields",
        fields: %{
          "map_field" => %Value{
            mapValue: %MapValue{
              fields: nil
            }
          }
        },
        createTime: ~U[2025-01-10 17:14:04.738331Z],
        updateTime: ~U[2025-01-10 17:14:04.738331Z]
      }

      assert Decoder.decode(document) == %PPlusFireStore.Model.Document{
               data: %{
                 "map_field" => %{}
               },
               path: "projects/my_project/databases/(default)/documents/tracking/MapFieldWithNilFields",
               created_at: ~U[2025-01-10 17:14:04.738331Z],
               updated_at: ~U[2025-01-10 17:14:04.738331Z]
             }
    end
  end

  describe "decode ListDocumentsResponse" do
    test "decode list of documents" do
      list_response = %ListDocumentsResponse{
        documents: [
          %Document{
            name: "projects/my_project/databases/(default)/documents/tracking/Doc1",
            fields: %{
              "string_field" => %Value{stringValue: "First document"}
            },
            createTime: ~U[2025-01-10 17:14:04.738331Z],
            updateTime: ~U[2025-01-10 17:14:04.738331Z]
          },
          %Document{
            name: "projects/my_project/databases/(default)/documents/tracking/Doc2",
            fields: %{
              "string_field" => %Value{stringValue: "Second document"}
            },
            createTime: ~U[2025-01-10 17:14:04.738331Z],
            updateTime: ~U[2025-01-10 17:14:04.738331Z]
          }
        ]
      }

      assert Decoder.decode(list_response) == %Page{
               data: [
                 %PPlusFireStore.Model.Document{
                   data: %{"string_field" => "First document"},
                   path: "projects/my_project/databases/(default)/documents/tracking/Doc1",
                   created_at: ~U[2025-01-10 17:14:04.738331Z],
                   updated_at: ~U[2025-01-10 17:14:04.738331Z]
                 },
                 %PPlusFireStore.Model.Document{
                   data: %{"string_field" => "Second document"},
                   path: "projects/my_project/databases/(default)/documents/tracking/Doc2",
                   created_at: ~U[2025-01-10 17:14:04.738331Z],
                   updated_at: ~U[2025-01-10 17:14:04.738331Z]
                 }
               ],
               next_page_token: nil
             }
    end

    test "decode list of documents with varied field types" do
      list_response = %ListDocumentsResponse{
        documents: [
          %Document{
            name: "projects/my_project/databases/(default)/documents/tracking/Doc1",
            fields: %{
              "string_field" => %Value{stringValue: "First document"},
              "integer_field" => %Value{integerValue: 1}
            },
            createTime: ~U[2025-01-10 17:14:04.738331Z],
            updateTime: ~U[2025-01-10 17:14:04.738331Z]
          },
          %Document{
            name: "projects/my_project/databases/(default)/documents/tracking/Doc2",
            fields: %{
              "boolean_field" => %Value{booleanValue: false},
              "double_field" => %Value{doubleValue: 2.718}
            },
            createTime: ~U[2025-01-10 17:14:04.738331Z],
            updateTime: ~U[2025-01-10 17:14:04.738331Z]
          }
        ]
      }

      assert Decoder.decode(list_response) == %Page{
               data: [
                 %PPlusFireStore.Model.Document{
                   data: %{
                     "integer_field" => 1,
                     "string_field" => "First document"
                   },
                   path: "projects/my_project/databases/(default)/documents/tracking/Doc1",
                   created_at: ~U[2025-01-10 17:14:04.738331Z],
                   updated_at: ~U[2025-01-10 17:14:04.738331Z]
                 },
                 %PPlusFireStore.Model.Document{
                   data: %{"boolean_field" => false, "double_field" => 2.718},
                   path: "projects/my_project/databases/(default)/documents/tracking/Doc2",
                   created_at: ~U[2025-01-10 17:14:04.738331Z],
                   updated_at: ~U[2025-01-10 17:14:04.738331Z]
                 }
               ],
               next_page_token: nil
             }
    end
  end

  describe "decode Empty" do
    test "decode empty response" do
      empty_response = %Empty{}

      assert Decoder.decode(empty_response) == nil
    end
  end
end
