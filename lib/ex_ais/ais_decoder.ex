defmodule ExAIS.Decoder do
  @moduledoc """
  Documentation for `ExAIS.Decoder`.

  Decoder is a Genserver that receives messages and decodes them into a state.

  By default Decoders decode all Ais message types but can be initialized with
  a list of message types to decode if you want to restrict the scope.

  Example:

    %{
      id: :satdecoder,
      module: ExAIS.Decoder,
      name: :satdecoder,
      batch_size: 10_000,
      processor: :satprocessor,
      supervisor: Portal.TaskSupervisor,
      msg_types: [1, 2, 3]
    }
  """
  require Logger
  import Bitwise
  use GenServer

  alias ExAIS.Data.Ais
  alias ExAIS.Data.NMEA

  @regex ~r/^\\[psgctq]:[^\\,*]+(?:,[psgctq]:[^\\,*]+)*\*[A-Fa-f0-9]{2}\\!(AIVDM|AIVDO),[^
  *]+\*[A-Fa-f0-9]{2}$/

  @initial_state %{
    # Used to handle fragmented messages
    fragment: "",
    decoded: [],
    # Map of list of grouped messages keyed by group id
    groups: %{},
    count: 0,
    latest: DateTime.from_unix!(0)
  }

  def start_link(opts) do
    Logger.info("Starting #{opts.name} feed")
    GenServer.start_link(__MODULE__, Map.merge(opts, @initial_state), name: opts.name)
  end

  def init(state) do
    Logger.info("Ais Decoder init #{inspect(state)}")

    {:ok, state}
  end

  def terminate(reason, _state) do
    Logger.warning("decoder terminate reason: #{inspect(reason)}")
  end

  def handle_cast({:decode, msgs}, %{supervisor: task_supervisor} = state) do
    msg_types = Map.get(state, :msg_types, Ais.all_msg_types())

    Task.Supervisor.async_nolink(
      task_supervisor,
      fn ->
        {new_decoded, groups, latest} = decode_messages(msgs, state, msg_types)

        {:decoded, new_decoded, groups, latest}
      end
    )

    {:noreply, state}
  end

  def handle_call({:decode, msgs}, _from, %{supervisor: task_supervisor} = state) do
    msg_types = Map.get(state, :msg_types, Ais.all_msg_types())

    Task.Supervisor.async_nolink(
      task_supervisor,
      fn ->
        {new_decoded, groups, latest} = decode_messages(msgs, state, msg_types)

        {:decoded, new_decoded, groups, latest}
      end
    )

    {:reply, :ok, state}
  end

  def handle_info(
        {_ref, {:decoded, new_decoded, groups, latest}},
        %{processor: processor} = state
      ) do
    decoded = state[:decoded] ++ new_decoded
    count = Enum.count(decoded)

    state =
      if count > state[:batch_size] do
        GenServer.call(processor, {:decoded, decoded}, :infinity)
        :erlang.garbage_collect()
        %{state | decoded: [], count: state[:count] + count}
      else
        %{state | decoded: decoded, count: state[:count] + count}
      end

    {:noreply, %{state | groups: prune_groups(groups), latest: latest}}
  end

  def handle_info({:DOWN, _ref, :process, _pid, :normal}, state) do
    # Logger.warning("Got :DOWN")
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, reason}, state) do
    Logger.warning("AisDecoder, got :DOWN #{inspect(reason)}")
    {:noreply, state}
  end

  def decode_messages(msgs, state, msg_types) do
    {decoded, %{groups: groups, latest: latest}} =
      Enum.map_reduce(msgs, %{groups: state[:groups], latest: state[:latest]}, fn m, acc ->
        decode_message(m, acc, msg_types)
      end)

    _failed = Enum.filter(decoded, &is_nil(&1))
    decoded = Enum.filter(decoded, &(!is_nil(&1)))
    {decoded, groups, latest}
  end

  def decode_message(msg, %{groups: groups, latest: latest}, msg_types) do
    with true <- Regex.match?(@regex, msg),
         [sentence | _] <- Regex.run(@regex, msg),
         {:ok, parts} when parts != [] <- check_sum(sentence) do
      process_sentence_parts(parts, groups, latest, msg_types)
    else
      _ -> {nil, %{groups: groups, latest: latest}}
    end
  end

  defp process_sentence_parts(parts, groups, latest, msg_types) do
    parts = normalize_parts(parts)

    if group_message?(parts) do
      handle_group_message(parts, groups, latest, msg_types)
    else
      handle_single_message(parts, groups, latest, msg_types)
    end
  end

  defp normalize_parts(parts) do
    if Regex.match?(~r/!(AIVDM|AIVDO)/, Enum.at(parts, 0, "")) do
      Enum.drop(parts, 1)
    else
      parts
    end
  end

  defp group_message?(parts) do
    Regex.match?(~r/,g:/, Enum.at(parts, 0))
  end

  defp handle_group_message(parts, groups, latest, msg_types) do
    {decoded, new_groups} = process_group(parts, groups, msg_types)

    if decoded do
      {decoded, %{groups: new_groups, latest: update_latest(latest, decoded)}}
    else
      {nil, %{groups: new_groups, latest: latest}}
    end
  end

  defp handle_single_message(parts, groups, latest, msg_types) do
    decoded = decode_parts(parts, msg_types)
    {decoded, %{groups: groups, latest: update_latest(latest, decoded)}}
  end

  defp update_latest(latest, nil), do: latest
  defp update_latest(latest, %{timestamp: nil}), do: latest

  defp update_latest(latest, decoded) do
    if decoded[:timestamp] do
      case DateTime.compare(decoded[:timestamp], latest) do
        :gt -> decoded[:timestamp]
        _ -> latest
      end
    else
      latest
    end
  end

  def process_group(parts, groups, msg_types) do
    tags = decode_tags(Enum.at(parts, 0))
    [n, s, id] = String.split(tags[:g], "-")
    num = String.to_integer(n)
    size = String.to_integer(s)

    cond do
      num == 1 -> process_first_message(parts, groups, tags, id)
      num == size -> process_last_message(parts, groups, tags, id, msg_types)
      num > 1 -> process_middle_message(parts, groups, tags, id)
    end
  end

  # Handles the first message in a group sequence
  defp process_first_message(parts, groups, tags, id) do
    case get_valid_msg(Enum.at(parts, 1)) do
      nil ->
        {nil, groups}

      msg ->
        group_entry = %{tag: tags, msg: msg, time: DateTime.now!("Etc/UTC")}
        new_groups = update_provider_group(groups, tags[:p], id, group_entry)
        {nil, new_groups}
    end
  end

  # Handles the last message in a group sequence
  defp process_last_message(parts, groups, tags, id, msg_types) do
    provider_groups = Map.get(groups, tags[:p], %{})

    with {:group, group} when not is_nil(group) <- {:group, provider_groups[id]},
         true <- nmea_checksum(Enum.at(parts, 1)),
         {:msg_frag, msg_frag} when not is_nil(msg_frag) <-
           {:msg_frag, get_valid_msg(Enum.at(parts, 1))} do
      complete_group_message(group, msg_frag, groups, provider_groups, tags, id, msg_types)
    else
      _ -> {nil, groups}
    end
  end

  # Completes a group message by merging fragments and decoding
  defp complete_group_message(group, msg_frag, groups, _provider_groups, tags, id, msg_types) do
    new_msg = merge_fragment(group[:msg], msg_frag)
    new_groups = remove_provider_group(groups, tags[:p], id)

    case decode_nmea(new_msg, msg_types) do
      {:ok, data} ->
        {Map.merge(group[:tag], data), new_groups}

      {:error, _} ->
        {nil, new_groups}
    end
  end

  # Handles intermediate messages in a group sequence
  defp process_middle_message(parts, groups, tags, id) do
    provider_groups = Map.get(groups, tags[:p], %{})

    with {:group, group} when not is_nil(group) <- {:group, provider_groups[id]},
         true <- nmea_checksum(Enum.at(parts, 1)),
         {:msg_frag, msg_frag} when not is_nil(msg_frag) <-
           {:msg_frag, get_valid_msg(Enum.at(parts, 1))} do
      new_msg = merge_fragment(group[:msg], msg_frag)
      updated_group = %{group | msg: new_msg}
      new_groups = update_provider_group(groups, tags[:p], id, updated_group)
      {nil, new_groups}
    else
      _ -> {nil, groups}
    end
  end

  # Helper to update a specific group for a provider
  defp update_provider_group(groups, provider, group_id, group_data) do
    provider_groups = Map.get(groups, provider, %{})
    new_provider_groups = Map.put(provider_groups, group_id, group_data)
    Map.put(groups, provider, new_provider_groups)
  end

  # Helper to remove a specific group for a provider
  defp remove_provider_group(groups, provider, group_id) do
    provider_groups = Map.get(groups, provider, %{})
    {_, new_provider_groups} = Map.pop(provider_groups, group_id)
    Map.put(groups, provider, new_provider_groups)
  end

  def prune_groups(groups) do
    now = DateTime.now!("Etc/UTC")

    groups
    |> Enum.map(fn {provider, grps} ->
      new_grps =
        grps
        |> Enum.filter(fn {_, v} -> DateTime.diff(now, v[:time]) > 30 end)
        |> Enum.into(%{})

      {provider, new_grps}
    end)
    |> Enum.into(%{})
  end

  defp merge_fragment(msg, frag) do
    [msg_0, _msg_1, msg_2, msg_3, msg_4, msg_5, _msg_6] = String.split(msg, ",")
    [_frag_0, _frag_1, _frag_2, _frag_3, _frag_4, frag_5, _frag_6] = String.split(frag, ",")

    # reset total number of messages to 1
    [msg_0, "1", msg_2, msg_3, msg_4, msg_5 <> frag_5, "0"]
    |> Enum.join(",")
    |> append_checksum()
  end

  defp append_checksum(str) do
    checksum = calc_checksum(str)
    str <> "*" <> checksum
  end

  defp get_valid_msg(sentence) do
    with true <- nmea_checksum(sentence),
         [msg, _chk] <- String.split(sentence, "*") do
      msg
    else
      _ -> nil
    end
  end

  defp decode_parts(parts, msg_types) do
    with tags <- decode_tags(Enum.at(parts, 0)),
         {:ok, message} <- decode_nmea(Enum.at(parts, 1), msg_types) do
      Map.merge(tags, message)
    else
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
    # Remove the checksum part before parsing
    tag_str
    |> String.split("*")
    |> List.first()
    |> String.split(",")
    |> Enum.reduce(%{}, fn x, acc ->
      Map.merge(acc, decode_tag(String.split(x, ":")))
    end)
  end

  defp decode_tag(["p", val]), do: %{p: val}
  defp decode_tag(["g", val]), do: %{g: val}
  defp decode_tag(["s", val]), do: %{s: val}

  defp decode_tag(["c", val]) when byte_size(val) == 10,
    do: %{c: val, timestamp: DateTime.from_unix!(String.to_integer(val))}

  defp decode_tag(["c", val]) when byte_size(val) == 16,
    do: %{c: val, timestamp: DateTime.from_unix!(String.to_integer(val), :microsecond)}

  defp decode_tag(["c", val]),
    do: %{c: val, timestamp: DateTime.now!("Etc/UTC")}

  defp decode_tag(["q", val]), do: %{q: val}
  defp decode_tag(["t", val]), do: %{t: val}
  defp decode_tag(_), do: %{}

  def decode_nmea(str, msg_types) do
    {state, sentence} = NMEA.parse(str)

    try do
      cond do
        state == :error ->
          {:error, sentence}

        sentence[:total] == "1" ->
          {state, attributes} = Ais.parse(sentence.payload, sentence.padding, msg_types)

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
      e ->
        Logger.error("error decoding NMEA #{inspect(state)} #{inspect(sentence)} #{inspect(e)}")
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

      sum =
        calc_checksum(String.slice(Enum.join(Enum.take(fields, 6), ",") <> "," <> z, 1..-1//1))

      sum == chk
    rescue
      _e ->
        false
    end
  end

  defp calc_checksum(x) do
    chk =
      Integer.to_string(
        for <<x <- String.replace(x, "!", "")>>, reduce: 0 do
          acc -> bxor(acc, x)
        end,
        16
      )

    if String.length(chk) == 1 do
      "0" <> chk
    else
      chk
    end
  end
end
