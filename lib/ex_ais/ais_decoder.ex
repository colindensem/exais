defmodule ExAIS.Decoder do
  @moduledoc """
  Documentation for `Ais.Decode`.
  """
  require Logger
  import Bitwise
  use GenServer

  alias ExAIS.Data.Ais
  alias ExAIS.Data.NMEA


  @initial_state %{
    fragment: "",   # Used to handle fragmented messages
    decoded: [],
    groups: %{},     # Map of list of grouped messages keyed by group id
    count: 0,
    latest: DateTime.from_unix!(0)
  }

  def start_link(opts) do
    GenServer.start_link(__MODULE__, Map.merge(opts, @initial_state), name: :aisdecoder)
  end

  def init(state) do
    Logger.info("Ais Decoder init")
    schedule_work(:stats, 10)
    {:ok, state}
  end

  def terminate(reason, _state) do
    IO.inspect(reason, label: "decoder terminate reason")
  end

  def handle_cast({:decode, msgs}, state) do

    Task.Supervisor.async_nolink(
      Portal.TaskSupervisor,
      fn -> start = System.monotonic_time()
            {new_decoded, groups, latest} = decode_messages(msgs, state)
            :telemetry.execute(
              [:portal, :decoder, :decode_time],
              %{duration: System.convert_time_unit(System.monotonic_time() - start, :native, :millisecond)}, %{})
            {:decoded, new_decoded, groups, latest}
      end)

    {:noreply, state}
  end

  def handle_call({:decode, msgs}, _from, state) do

    Task.Supervisor.async_nolink(
      Portal.TaskSupervisor,
      fn -> start = System.monotonic_time()
            {new_decoded, groups, latest} = decode_messages(msgs, state)
            :telemetry.execute(
              [:portal, :decoder, :decode_time],
              %{duration: System.convert_time_unit(System.monotonic_time() - start, :native, :millisecond)}, %{})
            {:decoded, new_decoded, groups, latest}
      end)

    {:reply, :ok, state}
  end

  def handle_info({_ref, {:decoded, new_decoded, groups, latest}}, state) do
    decoded = state[:decoded] ++ new_decoded
    count = Enum.count(decoded)
    state =
      if count > 10000 do
        GenServer.call(Map.get(state, :processor), {:decoded, decoded}, :infinity)
        :erlang.garbage_collect()
        %{state | decoded: [], count: state[:count] + count}
      else
        %{state | decoded: decoded, count: state[:count] + count}
      end

    {:noreply, %{state | groups: prune_groups(groups), latest: latest}}
  end

  def handle_info(:stats, state) do
    #IO.puts("Decode count: #{inspect state[:count]}")
    :telemetry.execute([:portal, :decoder, :decoded], %{count: state[:count]/10}, %{})
    :telemetry.execute([:portal, :decoder, :message_queue_len], %{message_queue_len: Process.info(self(), :message_queue_len)}, %{})
    :telemetry.execute([:portal, :decoder, :decode_lag], %{time: DateTime.diff(DateTime.now!("Etc/UTC"), state[:latest])}, %{})
    #IO.puts("lag: #{inspect DateTime.now!("Etc/UTC")} #{inspect state[:latest]} #{inspect DateTime.diff(DateTime.now!("Etc/UTC"), state[:latest])}")
    schedule_work(:stats, 10)
    {:noreply, %{state | count: 0}}
  end

  def handle_info({:DOWN, _ref, :process, _pid, :normal}, state) do
    #Logger.warning("Got :DOWN")
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    Logger.warning("AisDecoder, got :DOWN #{inspect reason}")
    {:noreply, state}
  end

  def decode_messages(msgs, state) do
    {decoded, %{groups: groups, latest: latest}} =
      Enum.map_reduce(msgs, %{groups: state[:groups], latest: state[:latest]},
        fn m, acc ->
          decode_message(m, acc)
        end)

    _failed = Enum.filter(decoded, & is_nil(&1))
    decoded = Enum.filter(decoded, & !is_nil(&1))
    {decoded, groups, latest}
  end

  def decode_message(msg, %{groups: groups, latest: latest}) do
    if Regex.match?(~r/\\([a-z]:\w.{1,15})+\\!AIVDM,.{1,100},\d\*.{2}/, msg) do
      # Complete message sentence
      #IO.puts("#{inspect msg}")
      case check_sum(msg) do
        {:ok, []} ->
          {nil, %{groups: groups, latest: latest}}
        {:ok, parts} ->
          if Regex.match?(~r/,g:/, Enum.at(parts,0)) do
            {decoded, groups} = process_group(parts, groups)
            if decoded do
              {decoded, %{groups: groups, latest: update_latest(latest, decoded)}}
            else
              {decoded, %{groups: groups, latest: latest}}
            end
          else
            decoded = decode_parts(parts)
            {decoded, %{groups: groups, latest: update_latest(latest, decoded)}}
          end
      end
    else
      {nil, %{groups: groups, latest: latest}}
    end
  end

  defp update_latest(latest, decoded) do
    case decoded do
      nil -> latest
      _ -> case DateTime.compare(decoded[:timestamp], latest) do
        :gt -> decoded[:timestamp]
        _ -> latest
      end
    end
  end

  def process_group(parts, groups) do
    tags = decode_tags(Enum.at(parts,0))
    [n, s, id] = String.split(tags[:g], "-")
    num = String.to_integer(n)
    size = String.to_integer(s)
    cond do
      num == 1 ->
        # 1st message in group sequence
        msg = get_valid_msg(Enum.at(parts,1))
        if msg do
          provider_groups = Map.get(groups, tags[:p], %{})
          {nil, Map.put(groups, tags[:p], Map.put(provider_groups, id, %{tag: tags, msg: msg, time: DateTime.now!("Etc/UTC")}))}
        else
          #IO.puts("group invalid msg: #{inspect parts}")
          {nil, groups}
        end
      num == size ->
        # 2nd message in group sequence
        # Get sub-map for this provider
        provider_groups = Map.get(groups, tags[:p], %{})
        if group = provider_groups[id] do
          if nmea_checksum(Enum.at(parts,1)) do
            if msg_frag = get_valid_msg(Enum.at(parts,1)) do
              new_msg = merge_fragment(group[:msg], msg_frag)
              # New groups is existing groups with this group id removed for this provider
              {_, new_provider_groups} = Map.pop(provider_groups, id)
              new_groups = Map.put(groups, tags[:p], new_provider_groups)
              case decode_nmea(new_msg) do
                {:ok, data} ->
                  {Map.merge(group[:tag], data), new_groups}
                {:error, _} ->
                  {nil, new_groups}
              end
            else
              #IO.puts("group invalid msg: #{inspect parts}")
              {nil, groups}
            end
          else
            #IO.puts("group checksum fail: #{inspect parts}")
            {nil, groups}
          end
        else
          #IO.puts("group no group: #{inspect parts}")
          {nil, groups}
        end
      num > 1 ->
        # Get sub-map for this provider
        provider_groups = Map.get(groups, tags[:p], %{})
        if group = provider_groups[id] do
          if nmea_checksum(Enum.at(parts,1)) do
            if msg_frag = get_valid_msg(Enum.at(parts,1)) do
              new_msg = merge_fragment(group[:msg], msg_frag)
              {nil, %{groups | tags[:p] => %{provider_groups | id => %{group | msg: new_msg}}}}
            else
              #IO.puts("group invalid msg: #{inspect parts}")
              {nil, groups}
            end
          else
            #IO.puts("group checksum fail: #{inspect parts}")
            {nil, groups}
          end
        else
          #IO.puts("group no group: #{inspect parts}")
          {nil, groups}
        end
    end
  end

  def prune_groups(groups) do
    now = DateTime.now!("Etc/UTC")
    groups
    |> Enum.map(fn {provider, grps} ->
        new_grps = grps
        |> Enum.filter(fn {_, v} -> DateTime.diff(now, v[:time]) > 30 end)
        |> Enum.into(%{})
        {provider, new_grps}
      end)
    |> Enum.into(%{})
  end

  defp schedule_work(task, time) do
    Process.send_after(self(), task, time * 1000) # time in seconds
  end

  defp merge_fragment(msg, frag) do
    [msg_0, _msg_1, msg_2, msg_3, msg_4, msg_5, _msg_6] = String.split(msg, ",")
    [_frag_0, _frag_1, _frag_2, _frag_3, _frag_4, frag_5, _frag_6] = String.split(frag, ",")
    # reset total number of messages to 1
    str = Enum.join([msg_0, "1", msg_2, msg_3, msg_4, msg_5 <> frag_5, "0"], ",")
    chk = calc_checksum(str)
    str <> "*" <> chk
  end

  defp get_valid_msg(sentence) do
    if nmea_checksum(sentence) do
      [msg, _chk] = String.split(sentence, "*")
      msg
    end
  end

  defp decode_parts(parts) do
    tags = decode_tags(Enum.at(parts,0))
    case decode_nmea(Enum.at(parts,1)) do
      {:ok, message} -> Map.merge(tags, message)
      _ -> nil
    end
  end

  #
  # Convert tag string to map of tag values converting
  # timestamp to DateTime e.g.:
  #
  # decode_tags("s:terrestrial,c:1682853592*54") ->
  #    %{"c" => ~U[2023-04-30 11:19:52Z], "s" => "terrestrial"}
  #
  def decode_tags(tag_str) do
    tags =
      Regex.named_captures(
        ~r/(p:(?<p>\w+))?(,?s:(?<ss>.[0-9a-zA-Z]+))?(,?g:(?<g>[0-9]-[0-9]-[0-9]+))?(,?s:(?<s>.[0-9a-zA-Z]+))?(,q:(?<q>\w+))?(,?c:(?<c>\d+))?/,
        tag_str)

    # Convert keys to atoms
    tags = for {key, val} <- tags, into: %{}, do: {String.to_atom(key), val}
    tags = if Map.has_key?(tags, :ss) do
      tags |> Map.put(:s, Map.get(tags, :ss)) |> Map.delete(:ss)
    end

    if Map.has_key?(tags, :c) do
      try do
        Map.put(tags, :timestamp, DateTime.from_unix!(String.to_integer(Map.get(tags, :c))))
      rescue
        _e ->
          tags
      end
    else
      tags
    end
  end

  def decode_nmea(str) do
    {state, sentence} = NMEA.parse(str)

    try do
      cond do
        state == :error ->
          {:error, sentence}

        sentence[:total] == "1" ->
          {state, attributes} = Ais.parse(sentence.payload, sentence.padding)

          sentence = Map.merge(attributes, sentence)
          if state != :ok do
            {:error, {state, sentence}}
          else
            {state, sentence}
          end

        true ->
          {:error, {:incomplete, sentence}}
      end
    rescue
      _e ->
        Logger.error("error deocding NMEA #{inspect state} #{inspect sentence}")
        {:error, sentence}
    end
  end

  defp check_sum(sentence) do
    parts = Enum.drop(String.split(sentence, "\\"), 1)
    # Don't checksum the tags, we may have added our own tags
    case Enum.reduce(Enum.drop(parts, 1), true, fn x, acc -> nmea_checksum(x) || acc end) do
      true -> {:ok, parts}
      _ -> {:fail, parts}
    end
  end


  # Calculate NMEA checksum for sentence, sentence & checksum separated by *:
  # e.g.
  #   g:1-2-3244010,s:terrestrial,c:1682716530*10
  #  !AIVDM,2,1,0,B,53`lOt8000010W;WCD0m=AR37D0000000000000i0@721vP0004Sm51DQ0C@,0*32
  #
  # If sentence starts with !AIVDM, drop the ! before calculating checksum
  def nmea_checksum(x) do
    fields = String.split(x, ",")
    try do
      [z, chk] = String.split(Enum.at(fields, 6), "*")
      sum = calc_checksum(String.slice(Enum.join(Enum.take(fields, 6), ",") <> "," <> z, 1..-1//1))
      sum == chk
    rescue
      _e ->
        IO.puts("checksum error: #{inspect fields}")
        false
    end
  end

  defp calc_checksum(x) do
    chk = Integer.to_string(for <<x <- String.replace(x, "!", "")>>, reduce: 0 do acc -> bxor(acc, x) end, 16)
    if String.length(chk) == 1 do
      "0" <> chk
    else
      chk
    end
  end
end
