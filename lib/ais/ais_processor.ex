defmodule AIS.Processor do
  @moduledoc """
  Genserver for handling decoded AIS messages.

  Receives incoming messages from Decoder via GenServer.call(:aisprocessor, {:decoded, decoded}, 10_000)
  (Originally used PubSub but this seemed to have a performance impact)

  Is responsible for processing messages to maintain and update it's internal AisState

  Sends updated state to the AisRepo Genserver (which handles api calls needing that state).
  Tracks all updates made to the state and publishes those via Phoenix PubSub to the
  entity:update topic.

  decoded AIS messages take the form:

    %{
      :mmsi => 636016337,
      :timestamp => ~U[2024-02-15 14:30:46Z],
      :ship_type => 70,
      :formatter => "VDM",
      "q" => "",
      "g" => "1-2-20395571",
      "c" => "1708007446",
      :padding => "0",
      :dimension_to_stern => 29,
      :destination => "PABLB",
      :repeat_indicator => 1,
      :position_fix_type => 1,
      :eta => %{month: 2, day: 14, minute: 0, hour: 20},
      :channel => "A",
      :sequential => "1",
      :name => "EVANGELIA D",
      "p" => "spire",
      :dte => 0,
      :dimension_to_starboard => 13,
      :current => "1",
      :msg_type => 5,
      :checksum => "16",
      "s" => "",
      :dimension_to_port => 19,
      :spare => 0,
      :imo_number => 9689184,
      :call_sign => "D5FQ3",
      :payload => "5INSFlH2Cn60CDI7>20EH4pLDhT60B2222222216EHMC=4WD0ND0@S0`888888888888880",
      :draught => 12.1,
      :ais_version_indicator => 2,
      :talker => "!AI",
      :dimension_to_bow => 171,
      :total => "1"
    }

  """
  require Logger
  use GenServer

  alias Phoenix.PubSub
  alias AIS.Data.AisState
  alias AIS.Data.Messages
  alias AIS.Geo.QuadKeyTree
  alias AIS.Geo.Util

  def whereis(id) do
    case :global.whereis_name({__MODULE__, id}) do
      :undefined -> nil
      pid -> pid
    end
  end

  def register_process(pid, id) do
    case :global.register_name({__MODULE__, id}, pid) do
      :yes -> {:ok, pid}
      :no -> {:error, {:already_started, pid}}
    end
  end

  @spec start_link(any) :: {:ok, pid}
  def start_link(opts) do
    Logger.info("Ais Processor opts: #{inspect opts}")
    GenServer.start_link(__MODULE__, opts, name: Map.get(opts, :name, :aisprocessor), pubsub: opts.pubsub)
  end

  def init(opts) do
    # Make sure that this process does not terminate abruptly
    # in case it is persisting to disk. terminate/2 is still a no-op.
    Process.flag(:trap_exit, true)

    Logger.info("#{inspect opts[:name]} init (config; #{inspect opts})")
    db_file = Map.get(opts, :db)
   # {:ok, conn} = Mongo.start_link(url: mongo_url(), timeout: 60_000, read_preference: :primary)
   # schedule_work(:fetch, 10)
   schedule_work(:prune, 3600) # seconds
   schedule_work(:save, 60)

    # Read cached state or create new
    ais =
      try do
        case File.read(db_file) do
          {:ok, binary} ->
            :erlang.binary_to_term(binary)
          {:error, reason} ->
            IO.puts("Failed to read ais.db. reason: #{inspect reason}")
            IO.puts("#{inspect File.cwd()}")
            AisState.create()
        end
      rescue
        e ->
          AisState.create()
      end

    ais = update_vessels(ais)

    # ais = %AisState{
    #   vessels: ais.vessels,
    #   updates: ais.updates,
    #   trips: ais.trips,
    #   index: ais.index,
    #   latest: %{}
    # }
    ais = update_flags(ais)

    ais =
      if opts[:name] == :geovsprocessor do
        update_type(ais, Map.get(opts, :type_override))
      else
        ais
      end

    # ais = init_from_vessels()

    {:ok, %{conn: nil, ais: ais, db_file: db_file, name: opts[:name], pubsub: opts[:pubsub], type_override: Map.get(opts, :type_override)}}
  end

  # def handle_info(:fetch, state) do
  #   #IO.puts("#{DateTime.utc_now()} #{inspect state.ais.index.count}")

  #   new_state = update_state(state)
  #   try do
  #     GenServer.cast(:aisrepo, {:update_ais_state, new_state.ais})
  #   rescue
  #     _e ->
  #       IO.puts("error ")
  #   end

  #   schedule_work(:fetch, 10)

  #   {:noreply, new_state}
  # end

  def handle_info(:save, state) do
    Task.Supervisor.start_child(
      Portal.TaskSupervisor,
      fn ->
        File.write(state.db_file, :erlang.term_to_binary(state.ais))
      end)
    schedule_work(:save, 60)

    {:noreply, state}
  end

  @doc """
  Handle incoming decoded ais messages sent from the
  Portal.Data.Ais.Decoder genserver.
  """
  def handle_cast({:decoded, decoded}, state) do
    {_, len} = Process.info(self(), :message_queue_len)
    IO.inspect(len, label: "#{inspect state[:name]} queue len")
    {_, len} = Process.info(self(), :heap_size)
    IO.inspect(trunc((len * 8)/1048576), label: "#{inspect state[:name]} heap size")
    #{_, len} = Process.info(self(), :stack_size)
    #IO.inspect(trunc((len * 8)/1048576), label: "processor stack size")

    state = process_decoded(decoded, state)
    {:noreply, state}
  end

  def handle_call({:decoded, decoded}, _from, state) do
    state = process_decoded(decoded, state)
    {:reply, %{}, state}
  end

  @impl true
  def handle_call({:get_tile, x, y, "0"}, _from, state) do
    # Handle zero zoom which won't convert to valid quadkey
    {:reply, {:ok, []}, state}
  end

  @impl true
  def handle_call({:get_tile, x, y, z}, _from, state) do
    quadkey = Util.quadkey({String.to_integer(x), String.to_integer(y)}, String.to_integer(z))
    IO.puts("quadkey: #{x}, #{y}, #{z} - [#{quadkey}]")
    keys = QuadKeyTree.query(state.ais.index, quadkey)

    {:reply, {:ok, Map.values(Map.take(state.ais.vessels, keys))}, state}
  end

  @impl true
  def handle_call({:get_entity, id}, _from, state) do
    # Return the vessel or empty defaults for the associated fleet_live.ex table columns
    {:reply, Map.get(state.ais.vessels, id, nil), state}
  end

  @impl true
  def handle_call({:get_trip, id}, _from, state) do
    # Return the trip
    {:reply, Map.get(state.ais.trips, id, nil), state}
  end

  @impl true
  def handle_call(:get_count, _from, state) do
    # Return the vessel or empty defaults for the associated fleet_live.ex table columns
    {:reply, Enum.count(state.ais.vessels), state}
  end

  defp process_decoded(decoded, %{ais: ais, pubsub: pubsub} = state) do
    Task.Supervisor.async_nolink(
      Portal.TaskSupervisor,
      fn -> #IO.puts("Task pid: #{inspect self()}")
            new_ais = Messages.process_messages(decoded, ais, Map.get(state, :type_override))
            if new_ais.position_updates != [] do
              PubSub.broadcast(pubsub, "ais:update", {:update, %{data: new_ais.position_updates, from: state[:name] }})
            end
            if new_ais.trip_updates != [] do
              PubSub.broadcast(pubsub, "ais:trip", {:update, %{data: new_ais.trip_updates, from: state[:name] }})
            end
            new_ais = AisState.clear_updates(new_ais)
            {:ais_update, new_ais}
      end)
    #IO.puts("Task count: #{inspect Enum.count(Task.Supervisor.children(Portal.Supervisor))}")
    #IO.puts("Message Queue: #{inspect Process.info(self(), :message_queue_len)}")
    :telemetry.execute([:portal, state[:name], :message_queue_len], %{message_queue_len: Process.info(self(), :message_queue_len)}, %{})
    :telemetry.execute([:portal, state[:name], :decoded], %{count: Enum.count(decoded)}, %{})
    {:memory, bytes} = Process.info(self(), :memory)
    #IO.puts("Memory (MB): #{inspect :erlang.float_to_binary((bytes * 0.000001), [decimals: 0])}")
    state
  end

  def handle_info({ref, {:ais_update, new_ais}}, state) do
    #Logger.info("AIS update: #{inspect Enum.count(new_ais.vessels)} total vessel count")
    # try do
    #  GenServer.cast(:aisrepo, {:update_ais_state, %{updates: new_ais, from: state[:name]}})
    # rescue
    #  e ->
    #    Logger.error("#{inspect state[:name]} :update_ais_state error #{inspect e}")
    # end
    {:noreply, %{state | ais: new_ais}}
  end

  def handle_info(:prune, %{ais: ais} = state) do
    Task.Supervisor.async_nolink(
      Portal.TaskSupervisor,
      fn -> Logger.info("\n=== Pruning AIS ===\n")
            new_ais = prune_ais(ais)
            {:ais_update, new_ais}
      end)

    schedule_work(:prune, 3600)

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, :normal}, state) do
    #Logger.warning("Got :DOWN")
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    #Logger.warning("Got #{inspect msg}")
    {:noreply, state}
  end

  defp schedule_work(task, time) do
    Process.send_after(self(), task, time * 1000) # In 10 seconds
  end

  defp prune_ais(ais) do
    now = DateTime.utc_now()
    to_prune = Enum.filter(Map.values(ais.vessels),
                  fn x -> DateTime.diff(now, x.timestamp)/3600 > 24 end)
    Logger.debug("Pruning #{inspect Enum.count(to_prune)} at #{inspect now}")

    new_ais =
      to_prune
      |> Enum.reduce(ais, fn x, acc -> AisState.remove_entity(acc,x) end)

      new_ais
  end

  # defp update_state(%{conn: conn, ais: ais, db_file: db_file} = state) do
  #   earliest = DateTime.utc_now() |> DateTime.add(-10, :second)
  #   cursor = conn
  #             |> Mongo.find(@collection, %{inserted: %{"$gt" => earliest}})
  #   new_ais =
  #     cursor
  #     |> Enum.to_list()
  #     |> Messages.process_messages(ais)

  #   # PubSub broadcast updates here
  #   PubSub.broadcast(Portal.PubSub, "entity:update", {:update, new_ais.updates})

  #   new_ais = AisState.clear_updates(new_ais)
  #   # Spawn as task?
  #   File.write(db_file, :erlang.term_to_binary(new_ais))
  #   %{state | ais: new_ais}
  # end

  # defp init_from_vessels() do
  #   vessels =
  #     case File.read("vessels.db") do
  #       {:ok, binary} ->
  #         :erlang.binary_to_term(binary)
  #     end

  #   index = Enum.reduce(vessels, QuadKeyTree.create(),
  #                           fn x, idx -> QuadKeyTree.insert(idx, x.quadkey, x.id) end)

  #   %AisState{
  #     vessels: Enum.reduce(vessels, %{}, fn x, acc -> Map.put(acc, x.id, x) end),
  #     updates: [],
  #     trips: %{},
  #     index: index
  #   }
  # end

  defp update_flags(ais_state) do

    %AisState{
      vessels: Enum.reduce(Map.values(ais_state.vessels), %{},
                  fn x, acc ->
                    Map.put(acc, x.id, %{x | flag: Messages.get_country(x.id)})
                  end),
      position_updates: ais_state.position_updates,
      trips: ais_state.trips,
      trip_updates: ais_state.trip_updates,
      index: ais_state.index
    }
  end

  defp update_vessels(ais_state) do
    # Pre-process cached vessel data and replace any nil Lname or :speed with default values
    %AisState{
      vessels: Enum.reduce(Map.values(ais_state.vessels), %{},
                  fn x, acc ->
                    Map.put(acc, x.id, %{Map.put(x, :name, Map.get(x, :name, "")) | speed: Map.get(x, :speed, 0.0)})
                  end),
      position_updates: ais_state.position_updates,
      trips: ais_state.trips,
      trip_updates: ais_state.trip_updates,
      index: ais_state.index
    }
  end

  defp update_type(ais_state, type_override) do

    %AisState{
      vessels: Enum.reduce(Map.values(ais_state.vessels), %{},
                  fn x, acc ->
                    Map.put(acc, x.id, %{x | type: type_override})
                  end),
      position_updates: ais_state.position_updates,
      trips: ais_state.trips,
      trip_updates: ais_state.trip_updates,
      index: ais_state.index
    }
  end

end
