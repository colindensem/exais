defmodule ExAIS.Data.AisState do
  require Logger

  alias ExAIS.Data.AisState
  alias GeoUtils.QuadKeyTree

  defstruct vessels: {}, trips: {}, position_updates: [], trip_updates: [], index: {}, latest: %{}

  @doc """
  Create a new instance of the AisState struct
  """
  def create() do
    %AisState{
      vessels: %{},
      position_updates: [],
      trips: %{},
      trip_updates: [],
      index: QuadKeyTree.create(),
      latest: %{}
    }
  end

  @doc """
  Update the given state:
    state.vessels - Adds or replaces the value for the update id key
    state.updates - appends the update t the list of updates
    state.index - removes the old entry in the index and inserts a new entry
  """
  def update(state, update) do
    vessel = Map.get(state.vessels, update.id, %{})
    vessel = Map.merge(vessel, update)

    if is_nil(update.quadkey) do
      new = %AisState{
        vessels: Map.put(state.vessels, update.id, vessel),
        position_updates: state.position_updates,
        trips: state.trips,
        trip_updates: state.trip_updates,
        index: state.index,
        latest: state.latest
      }

      new
    else
      try do
        index =
          if Map.has_key?(state.vessels, update.id) and update.quadkey do
            QuadKeyTree.remove(state.index, update.quadkey, update.id)
          else
            state.index
          end

        new = %AisState{
          vessels: Map.put(state.vessels, update.id, vessel),
          position_updates: state.position_updates ++ [vessel],
          trips: state.trips,
          trip_updates: state.trip_updates,
          index: QuadKeyTree.insert(index, update.quadkey, update.id),
          latest: state.latest
        }

        new
      rescue
        e ->
          IO.puts("AisState.update error: #{inspect(e)}")
          # IO.inspect(__STACKTRACE__)
          state
      end
    end
  end

  @doc """
  Update only the states index and position_updates with the new update.
  Doesn't make changes to state.vessels
  args:
    state - the current state
    update - the new update
    is_new - true if the update is a new vessel, false if it is an update to an existing vessel
  """
  def update_index(state, update, is_new) do
    if is_nil(update.quadkey) do
      %AisState{
        vessels: state.vessels,
        position_updates: state.position_updates,
        trips: state.trips,
        trip_updates: state.trip_updates,
        index: state.index,
        latest: state.latest
      }
    else
      try do
        index =
          if !is_new and update.quadkey do
            QuadKeyTree.remove(state.index, update.quadkey, update.id)
          else
            state.index
          end

        new = %AisState{
          vessels: state.vessels,
          position_updates: state.position_updates ++ [update],
          trips: state.trips,
          trip_updates: state.trip_updates,
          index: QuadKeyTree.insert(index, update.quadkey, update.id),
          latest: state.latest
        }

        new
      rescue
        e ->
          Logger.debug("AisState.update_index error: #{inspect(e)}")
          state
      end
    end
  end

  def add_trip(state, trip) do
    %AisState{
      vessels: state.vessels,
      position_updates: state.position_updates,
      trips: Map.put(state.trips, trip.id, trip),
      trip_updates: state.trip_updates ++ [trip],
      index: state.index,
      latest: state.latest
    }
  end

  def remove_entity(state, entity) do
    {_, new_vessels} = Map.pop(state.vessels, entity.id)
    new_index = QuadKeyTree.remove(state.index, entity.quadkey, entity.id)

    %AisState{
      vessels: new_vessels,
      position_updates: state.position_updates,
      trips: state.trips,
      trip_updates: state.trip_updates,
      index: new_index,
      latest: state.latest
    }
  end

  def clear_updates(state) do
    %AisState{
      vessels: state.vessels,
      position_updates: [],
      trips: state.trips,
      trip_updates: [],
      index: state.index,
      latest: state.latest
    }
  end

  #
  # Update the latest timestamp for a provider
  #
  def update_latest(state, nil, nil) do
    state
  end

  def update_latest(state, provider, %DateTime{} = timestamp) do
    time = Map.get(state.latest, provider)

    if time != nil do
      case DateTime.compare(timestamp, time) do
        :gt ->
          %AisState{
            vessels: state.vessels,
            position_updates: state.position_updates,
            trips: state.trips,
            trip_updates: state.trip_updates,
            index: state.index,
            latest: Map.put(state.latest, provider, timestamp)
          }

        :lt ->
          state

        :eq ->
          state
      end
    else
      %AisState{
        vessels: state.vessels,
        position_updates: state.position_updates,
        trips: state.trips,
        trip_updates: state.trip_updates,
        index: state.index,
        latest: Map.put(state.latest, provider, timestamp)
      }
    end
  end

  def update_latest(state, _provider, _val) do
    state
  end
end
