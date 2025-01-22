defmodule ExAIS.Data.Messages do
  @moduledoc """
  Functions for updating AIS state based upon decoded AIS messages. At the moment
  handles message types: 1, 2, 3, 5, 18, 21, 24, 27
  """
  require Logger

  alias GeoUtils.Coords
  alias ExAIS.Data.Country
  alias ExAIS.Data.AisState

  @nav_status [
    "underway_using_engine",
    "at_anchor",
    "not_under_command",
    "restricted_maneuverability",
    "constrained_by_her_draught",
    "moored",
    "aground",
    "engaged_in_fishing",
    "underway_sailing",
    "reserved",
    "reserved",
    "power-driven_vessel_towing_astern",
    "power-driven_vessel_pushing_ahead_or_towing_alongside",
    "reserved",
    "AIS-SART_Active",
    "undefined"
  ]

  @new_entity %{
    id: nil,
    name: nil,
    coordinates: nil,
    hdg: nil,
    speed: nil,
    source: nil,
    timestamp: DateTime.from_unix!(0),
    nav_status: nil,
    quadkey: nil,
    flag: nil,
    ais_type: nil,
    type: 1,
    icon_type: 1
  }

  @doc """
  Process AIS messages and update state. state is a map comprising:
    %{
      vessels: %{}, # Map of vessels keyed by MMSI
      updates: %{}, # Map of the updates arising from this batch of messages
      quadkey: %{}  # Map os vessel MMSIs keyed by quadkey (used to server map tiles)
    }
  """
  def process_messages(msgs, state, type_override \\ nil) do
    # Update the state given the set of messages, keep a separate
    # record of those updates so we can publish them to clients via a websocket
    # if Enum.count(msgs) > 0 do
    #  IO.puts("Processing #{inspect Enum.count(msgs)} messages")
    # end

    # We want to collect message stats:
    # - how many messages per provider by type
    # - how many messages per provider with null static data (ais_type, name)
    stats = init_stats()

    Enum.reduce(msgs, %{state: state, stats: stats}, fn x, acc ->
      process_message(Map.get(x, :timestamp), x, acc, type_override)
    end)
  end

  defp process_message(%DateTime{} = timestamp, msg, %{state: state, stats: stats}, type_override) do
    key = msg[:mmsi]
    current = Map.get(state.vessels, key, @new_entity)

    state = AisState.update_latest(state, msg[:p], timestamp)

    # Get latest timestamp from current vessel state
    current_time = Map.get(current, :timestamp, DateTime.from_unix!(0))

    if DateTime.diff(timestamp, current_time) > 0 do
      new_state =
        case msg[:msg_type] do
          1 ->
            update_stats(stats, msg, "1")
            merge_update(state, process_position(msg, current, type_override))

          2 ->
            update_stats(stats, msg, "2")
            merge_update(state, process_position(msg, current, type_override))

          3 ->
            update_stats(stats, msg, "3")
            merge_update(state, process_position(msg, current, type_override))

          5 ->
            update_stats(stats, msg, "5")
            {trip, vessel} = process_static(msg, current, type_override)

            state
            |> merge_update(vessel)
            |> merge_trip(trip)

          9 ->
            state

          18 ->
            update_stats(stats, msg, "18")
            merge_update(state, process_position(msg, current, type_override))

          19 ->
            state

          21 ->
            update_stats(stats, msg, "21")
            merge_update(state, process_aton(msg, current))

          24 ->
            update_stats(stats, msg, "24")
            merge_update(state, process_24(msg, current, type_override))

          27 ->
            update_stats(stats, msg, "27")
            merge_update(state, process_position(msg, current, type_override))

          _ ->
            state
        end

      %{state: new_state, stats: stats}
    else
      %{state: state, stats: stats}
    end
  end

  # Pattern match timestamps that aren't %DateTime{}
  defp process_message(_timestamp, _msg, %{state: state, stats: stats}, _type_override) do
    %{state: state, stats: stats}
  end

  defp process_position(msg, current, type_override) do
    update =
      if Map.has_key?(current, :nav_status) do
        %{current | nav_status: Map.get(msg, :nav_status, 15)}
      else
        Map.put_new(current, :nav_status, Map.get(msg, :nav_status, 15))
      end

    update =
      if Map.has_key?(update, :rot) do
        %{update | rot: Map.get(msg, :rot, 0)}
      else
        Map.put_new(update, :rot, Map.get(msg, :rot, 0))
      end

    [lon, lat] = [msg[:longitude], msg[:latitude]]

    if lat < 90.0 and lat > -90.0 do
      update =
        update
        |> Map.put(:id, msg[:mmsi])
        |> Map.put(:coordinates, [lon, lat])
        |> Map.put(:hdg, Map.get(msg, :cog, 0.0))
        |> Map.put(:speed, Map.get(msg, :sog, 0.0))
        |> Map.put(:vms100, Map.get(msg, :vms100, false))
        |> Map.put(:source, Map.get(msg, :p, "spire"))
        |> Map.put(:timestamp, msg[:timestamp])
        |> Map.put(:nav_status, get_nav_status(update[:nav_status]))
        |> Map.put(:quadkey, Coords.quadkey(Coords.tile(lon, lat, 9), 9))
        |> Map.put(:flag, get_country(msg[:mmsi]))
        |> is_aton(msg)

      if type_override do
        update |> Map.put(:type, type_override) |> Map.put(:icon_type, type_override)
      else
        update
      end
    else
      nil
    end
  end

  defp is_aton(update, msg) do
    try do
      if String.to_integer(msg[:mmsi]) >= 990_000_000 do
        update
        |> Map.put(:type, 10)
        |> Map.put(:icon_type, 10)
      else
        update
      end
    rescue
      _e ->
        update
    end
  end

  defp process_static(msg, current, type_override) do
    # if msg[:ship_type] == nil, do: Logger.warning("null static data: #{inspect msg}")
    reported = msg[:timestamp]

    trip =
      if msg[:eta][:day] <= 31 and
           msg[:eta][:hour] <= 23 and
           msg[:eta][:minute] <= 59 do
        eta = %DateTime{
          year: reported.year,
          month: msg[:eta][:month],
          day: msg[:eta][:day],
          hour: msg[:eta][:hour],
          minute: msg[:eta][:minute],
          second: 0,
          zone_abbr: "UTC",
          time_zone: "Etc/UTC",
          utc_offset: 0,
          std_offset: 0
        }

        %{
          id: msg[:mmsi],
          eta: eta,
          destination: msg[:destination],
          timestamp: msg[:timestamp]
        }
      else
        nil
      end

    update =
      current
      |> Map.put(:id, msg[:mmsi])
      |> update_map(:callsign, Map.get(msg, :call_sign))
      |> update_map(:name, Map.get(msg, :name))
      |> update_map(:imo, msg[:imo_number])
      |> update_map(:type, msg[:ship_type], Map.get(msg, :name, ""), type_override)
      |> update_map(:icon_type, msg[:ship_type], Map.get(msg, :name, ""), type_override)
      |> update_map(:ais_type, msg[:ship_type])
      |> update_map(:dimensions, [
        msg[:dimension_to_bow],
        msg[:dimension_to_stern],
        msg[:dimension_to_port],
        msg[:dimension_to_starboard]
      ])
      |> update_map(:draught, msg[:draught])
      |> update_map(:source, Map.get(msg, :p, "spire"))
      |> update_map(:timestamp, msg[:timestamp])
      |> update_map(:flag, get_country(msg[:mmsi]))

    {trip, update}
  end

  defp process_aton(msg, current) do
    [lon, lat] = [msg[:longitude], msg[:latitude]]

    if lat < 90.0 and lat > -90.0 do
      current
      |> Map.put(:id, msg[:mmsi])
      |> Map.put(:name, String.trim(Map.get(msg, :assembled_name, "")))
      |> Map.put(:coordinates, [lon, lat])
      |> Map.put(:dimensions, [
        msg[:dimension_a],
        msg[:dimension_b],
        msg[:dimension_c],
        msg[:dimension_d]
      ])
      |> Map.put(:aid_type, msg[:aid_type])
      |> Map.put(:type, 0)
      |> Map.put(:source, Map.get(msg, :p, "spire"))
      |> Map.put(:speed, 0)
      |> Map.put(:hdg, 0)
      |> Map.put(:timestamp, msg[:timestamp])
      |> Map.put(:quadkey, Coords.quadkey(Coords.tile(lon, lat, 9), 9))
      |> Map.put(:flag, get_country(msg[:mmsi]))
    else
      nil
    end
  end

  defp process_24(msg, current, type_override) do
    # if msg[:ship_type] == nil, do: Logger.warning("null static data: #{inspect msg}")
    try do
      cond do
        msg[:part_number] == 0 ->
          current
          |> Map.put(:id, msg[:mmsi])
          |> update_map(:name, Map.get(msg, :name))
          |> update_map(:source, Map.get(msg, :p, "spire"))
          |> update_map(:timestamp, msg[:timestamp])
          |> update_map(:flag, Map.get(msg, :flag, get_country(msg[:mmsi])))
          |> update_map(:type, msg[:ship_type], Map.get(msg, :name, ""), type_override)
          |> update_map(:icon_type, msg[:ship_type], Map.get(msg, :name, ""), type_override)
          |> update_map(:ais_type, msg[:ship_type])

        msg[:part_number] == 1 ->
          current
          |> Map.put(:id, msg[:mmsi])
          |> update_map(:callsign, Map.get(msg, :call_sign))
          |> update_map(:name, Map.get(msg, :name))
          |> update_map(:imo, msg[:imo_number])
          |> update_map(:type, msg[:ship_type], Map.get(msg, :name, ""), type_override)
          |> update_map(:icon_type, msg[:ship_type], Map.get(msg, :name, ""), type_override)
          |> update_map(:ais_type, msg[:ship_type])
          |> update_map(:dimensions, [
            msg[:dimension_a],
            msg[:dimensions_b],
            msg[:dimension_c],
            msg[:dimension_d]
          ])
          |> update_map(:source, Map.get(msg, :p, "spire"))
          |> update_map(:timestamp, msg[:timestamp])
          |> update_map(:flag, get_country(msg[:mmsi]))

        true ->
          nil
      end
    rescue
      e ->
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        nil
    end
  end

  #
  # Pattern Matching to update map but ensure
  # we don't over-write valid data with nil data
  #
  defp update_map(current, _key, nil) do
    current
  end

  defp update_map(current, key, value) when is_binary(value) do
    Map.put(current, key, String.trim(value))
  end

  defp update_map(current, key, value) do
    Map.put(current, key, value)
  end

  defp update_map(current, :type, nil, _name, _override) do
    current
  end

  defp update_map(current, :type, value, name, override) do
    Map.put(current, :type, type_or_buoy(value, name, override))
  end

  defp update_map(current, :icon_type, nil, _name, _override) do
    current
  end

  defp update_map(current, :icon_type, value, name, override) do
    Map.put(current, :icon_type, type_or_buoy(value, name, override))
  end

  defp type_or_buoy(type, name, override) do
    name_str =
      String.downcase(String.trim(name))

    cond do
      String.contains?(name_str, "buoy") ->
        10

      String.contains?(name_str, "%") ->
        10

      true ->
        get_type(type, override)
    end
  end

  defp merge_update(state, update) do
    # Given update merge into state
    #   - replace vessels entry with updated value in vessels map
    #   - add update to updates map
    if update do
      AisState.update(state, update)
    else
      state
    end
  end

  defp merge_trip(state, trip) do
    if trip do
      AisState.add_trip(state, trip)
    else
      state
    end
  end

  defp get_type(shipType, type_override) do
    if type_override do
      type_override
    else
      cond do
        # Cargo
        shipType >= 70 and shipType < 80 -> 2
        # Fishing
        shipType == 30 -> 3
        # HighSpeed
        (shipType >= 40 and shipType < 50) or shipType == 35 -> 4
        # Passenger
        shipType >= 58 and shipType < 70 -> 5
        # Tanker
        shipType >= 80 and shipType < 90 -> 6
        # Tug
        (shipType >= 50 and shipType < 57) or (shipType >= 31 and shipType < 34) -> 7
        # Yacht
        shipType == 36 or shipType == 37 -> 8
        # Other
        true -> 1
      end
    end
  end

  defp get_nav_status(code) do
    if code do
      Enum.at(@nav_status, code)
    else
      Enum.at(@nav_status, 15)
    end
  end

  def get_country(mmsi) do
    try do
      mmsi_int = String.to_integer(mmsi)

      flag =
        cond do
          String.length(mmsi) == 7 ->
            Country.get_flag(String.slice(mmsi, 0..2))

          trunc(mmsi_int / 100_000_000) == 8 ->
            Country.get_flag(String.slice(mmsi, 1..3))

          trunc(mmsi_int / 1_000_000) == 111 ->
            Country.get_flag(String.slice(mmsi, 3..5))

          trunc(mmsi_int / 10_000_000) == 99 ->
            Country.get_flag(String.slice(mmsi, 2..4))

          trunc(mmsi_int / 10_000_000) == 98 ->
            Country.get_flag(String.slice(mmsi, 2..4))

          trunc(mmsi_int / 1_000_000) == 970 ->
            Country.get_flag(String.slice(mmsi, 3..5))

          String.length(mmsi) != 9 ->
            ""

          true ->
            Country.get_flag(String.slice(mmsi, 0..2))
        end

      # if flag == "", do: IO.puts("mmsi: #{inspect mmsi} - flag: #{inspect flag}")
      flag
    rescue
      _e ->
        # Not an MMSI id so default to national flag
        "PH"
    end
  end

  defp update_stats(stats, msg, key) do
    if Enum.member?(["spire", "orbcomm", "exactearth"], Map.get(msg, :p)) do
      put_in(stats, [msg[:p], :totals, key], get_in(stats, [msg[:p], :totals, key]) + 1)
    end
  end

  defp init_stats() do
    %{
      "spire" => %{
        totals: %{
          "1" => 0,
          "2" => 0,
          "3" => 0,
          "5" => 0,
          "18" => 0,
          "21" => 0,
          "24" => 0,
          "27" => 0
        },
        null: %{"5" => 0, "24" => 0}
      },
      "orbcomm" => %{
        totals: %{
          "1" => 0,
          "2" => 0,
          "3" => 0,
          "5" => 0,
          "18" => 0,
          "21" => 0,
          "24" => 0,
          "27" => 0
        },
        null: %{"5" => 0, "24" => 0}
      },
      "exactearth" => %{
        totals: %{
          "1" => 0,
          "2" => 0,
          "3" => 0,
          "5" => 0,
          "18" => 0,
          "21" => 0,
          "24" => 0,
          "27" => 0
        },
        null: %{"5" => 0, "24" => 0}
      }
    }
  end
end
