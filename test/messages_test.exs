defmodule ExAIS.MessagesTest do
  use ExUnit.Case

  import ExAIS.MessageFixtures

  setup do
    {decoded, _groups, _latest} =
      ExAIS.Decoder.decode_messages(messages(), %{
        fragment: "",   # Used to handle fragmented messages
        decoded: [],
        groups: %{},     # Map of list of grouped messages keyed by group id
        latest: DateTime.from_unix!(0)
      })

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
      state = ExAIS.Data.Messages.process_messages(
        Enum.take(decoded, 1), state)
      assert Enum.count(state.position_updates) == 1
      assert state.index.count == 1
    end

    test "process_messages/2 processes a list of message", %{decoded: decoded, state: state} do
      state = ExAIS.Data.Messages.process_messages(
        decoded, state)

      assert Enum.count(state.vessels) == 26
      assert Enum.count(state.position_updates) == 16
      assert Enum.count(state.trips) == 3
      assert Enum.count(state.trip_updates) == 3
      assert state.index.count == 16
      assert state.latest["orbcomm"] == ~U[2023-08-23 09:52:54Z]
      assert state.latest["spire"] == ~U[2023-08-23 09:00:59Z]
    end
  end
end
