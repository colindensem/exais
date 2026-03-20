defmodule ExAIS.Data.Decoders.Type6 do
  @moduledoc """
  Dispatcher for AIS message type 6 sub-protocol decoders.

  Routes to the appropriate decoder based on DAC + FI:

    - FI 10     → GLA electrical/system status
    - FI  0     → Zeni electrical/system status
  """

  alias ExAIS.Data.Decoders.Type6.Gla
  alias ExAIS.Data.Decoders.Type6.Zeni

  @gla_fid 10
  @zeni_fid 0

  @spec decode(non_neg_integer(), non_neg_integer(), bitstring()) :: map()
  def decode(_dac, @gla_fid, data), do: Gla.from_binary(data) |> Map.from_struct()
  def decode(_dac, @zeni_fid, data), do: Zeni.from_binary(data) |> Map.from_struct()
  def decode(_dac, _fid, _data), do: %{}
end
