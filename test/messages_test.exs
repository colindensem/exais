defmodule ExAIS.MessagesTest do
  use ExUnit.Case

  import ExAIS.MessageFixtures

  alias ExAIS.Data.Ais

  setup do
    {decoded, _groups, _latest} =
      ExAIS.Decoder.decode_messages(
        messages(),
        %{
          # Used to handle fragmented messages
          fragment: "",
          decoded: [],
          # Map of list of grouped messages keyed by group id
          groups: %{},
          latest: DateTime.from_unix!(0)
        },
        Ais.all_msg_types()
      )

    state = %ExAIS.Data.AisState{
      vessels: %{},
      position_updates: [],
      trips: %{},
      trip_updates: [],
      index: GeoUtils.QuadKeyTree.create(),
      latest: %{}
    }

    %{decoded: decoded, state: state}
  end

  describe "Turns parsed sentences into AisState updates" do
    test "process_messages/2 processes a single message", %{decoded: decoded, state: state} do
      %{state: state, stats: _stats} =
        ExAIS.Data.Messages.process_messages(
          Enum.take(decoded, 1),
          state
        )

      assert Enum.count(state.position_updates) == 1
      assert state.index.count == 1
    end

    test "process_messages/2 processes a list of message", %{decoded: decoded, state: state} do
      %{state: state, stats: _stats} =
        ExAIS.Data.Messages.process_messages(
          decoded,
          state
        )

      assert Enum.count(state.vessels) == 26
      assert Enum.count(state.position_updates) == 16
      assert Enum.count(state.trips) == 3
      assert Enum.count(state.trip_updates) == 3
      assert state.index.count == 16
      assert state.latest["orbcomm"] == ~U[2023-08-23 09:52:54Z]
      assert state.latest["spire"] == ~U[2023-08-23 09:00:59Z]
    end
  end

  describe "Updates state" do
    test "Creates new state entry", %{state: state} do
      messages = [
        %{
          timestamp: ~U[2023-08-23 09:00:59Z],
          p: "spire",
          msg_type: 1,
          mmsi: "239951600",
          longitude: -114.0,
          latitude: 34.0,
          cog: 210.0,
          sog: 3.0
        }
      ]

      %{state: new, stats: _stats} = ExAIS.Data.Messages.process_messages(messages, state)
      assert Enum.count(new.vessels) == 1
    end

    test "Adds static to new state entry", %{state: state} do
      messages = [
        %{
          timestamp: ~U[2023-08-23 09:00:59Z],
          p: "spire",
          msg_type: 1,
          mmsi: "239951600",
          longitude: -114.0,
          latitude: 34.0,
          cog: 210.0,
          sog: 3.0
        },
        %{
          timestamp: ~U[2023-08-23 09:01:59Z],
          p: "spire",
          msg_type: 24,
          mmsi: "239951600",
          call_sign: "SVA6986",
          name: "HYDRA VIII",
          ship_type: 37,
          current: "1",
          part_number: 1,
          dimension_a: 8,
          dimension_b: 6,
          dimension_c: 4,
          dimension_d: 4
        }
      ]

      %{state: new, stats: _stats} = ExAIS.Data.Messages.process_messages(messages, state)
      assert Enum.count(new.vessels) == 1
      assert new.vessels["239951600"].callsign == "SVA6986"
      assert new.vessels["239951600"].type == 8
    end

    test "Type 5 doesn't over-write data with nil", %{state: state} do
      messages = [
        %{
          timestamp: ~U[2023-08-23 09:00:59Z],
          p: "spire",
          msg_type: 1,
          mmsi: "239951600",
          longitude: -114.0,
          latitude: 34.0,
          cog: 210.0,
          sog: 3.0
        },
        %{
          timestamp: ~U[2023-08-23 09:01:59Z],
          p: "spire",
          msg_type: 5,
          mmsi: "239951600",
          call_sign: "SVA6986",
          name: "HYDRA VIII",
          ship_type: 37,
          current: "1",
          part_number: 1,
          dimension_a: 8,
          dimension_b: 6,
          dimension_c: 4,
          dimension_d: 4
        },
        %{
          timestamp: ~U[2023-08-23 09:02:59Z],
          p: "spire",
          msg_type: 5,
          mmsi: "239951600",
          call_sign: nil,
          name: nil,
          ship_type: nil,
          current: "1",
          dimension_a: 8,
          dimension_b: 6,
          dimension_c: 4,
          dimension_d: 4
        }
      ]

      %{state: new, stats: _stats} = ExAIS.Data.Messages.process_messages(messages, state)
      assert Enum.count(new.vessels) == 1
      assert new.vessels["239951600"].callsign == "SVA6986"
      assert new.vessels["239951600"].name == "HYDRA VIII"
      assert new.vessels["239951600"].type == 8
    end

    test "Type 24 doesn't over-write data with nil", %{state: state} do
      messages = [
        %{
          timestamp: ~U[2023-08-23 09:00:59Z],
          p: "spire",
          msg_type: 1,
          mmsi: "239951600",
          longitude: -114.0,
          latitude: 34.0,
          cog: 210.0,
          sog: 3.0
        },
        %{
          timestamp: ~U[2023-08-23 09:01:59Z],
          p: "spire",
          msg_type: 24,
          mmsi: "239951600",
          call_sign: "SVA6986",
          name: "HYDRA VIII",
          ship_type: 37,
          current: "1",
          part_number: 1,
          dimension_a: 8,
          dimension_b: 6,
          dimension_c: 4,
          dimension_d: 4
        },
        %{
          timestamp: ~U[2023-08-23 09:02:59Z],
          p: "spire",
          msg_type: 24,
          mmsi: "239951600",
          call_sign: nil,
          name: nil,
          ship_type: nil,
          current: "1",
          part_number: 1,
          dimension_a: 8,
          dimension_b: 6,
          dimension_c: 4,
          dimension_d: 4
        }
      ]

      %{state: new, stats: _stats} = ExAIS.Data.Messages.process_messages(messages, state)
      assert Enum.count(new.vessels) == 1
      assert new.vessels["239951600"].callsign == "SVA6986"
      assert new.vessels["239951600"].name == "HYDRA VIII"
      assert new.vessels["239951600"].type == 8
    end
  end

  describe "Only decodes specified message types" do
    test "Only decodes specified message types [1, 2, 3]", %{state: state} do
      {decoded, _groups, _latest} =
        ExAIS.Decoder.decode_messages(
          messages(),
          %{
            # Used to handle fragmented messages
            fragment: "",
            decoded: [],
            # Map of list of grouped messages keyed by group id
            groups: %{},
            latest: DateTime.from_unix!(0)
          },
          [1, 2, 3]
        )

      assert Enum.count(decoded) == 11
    end

    test "Only decodes specified message types [18]", %{state: state} do
      {decoded, _groups, _latest} =
        ExAIS.Decoder.decode_messages(
          messages(),
          %{
            # Used to handle fragmented messages
            fragment: "",
            decoded: [],
            # Map of list of grouped messages keyed by group id
            groups: %{},
            latest: DateTime.from_unix!(0)
          },
          [18]
        )

      assert Enum.count(decoded) == 6
    end
  end
end
