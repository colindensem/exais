defmodule ExAIS.Data.Decoders.Type6.Electrical do
  @moduledoc """
  Decode a GLA Type 6 (FI 6) Electrical / System Status payload.

  Bit layout:

      0–9    : analogue_internal (10)
     10–19   : analogue_external_1 (10)
     20–29   : analogue_external_2 (10)
     30–34   : status_internal (5)
     35–42   : status_external (8)
     43      : off_position (1)
     44+     : spare bits
  """

  import Bitwise

  defstruct [
    :analogue_internal,
    :analogue_internal_v,
    :analogue_external_1,
    :analogue_external_1_v,
    :analogue_external_2,
    :analogue_external_2_v,
    :status_internal_raw,
    :status_external_raw,
    :status_internal_decoded,
    :status_external_decoded,
    :off_position
  ]

  @racon_map %{
    0b00 => "no_racon_installed",
    0b01 => "racon_not_monitored",
    0b10 => "racon_operational",
    0b11 => "racon_error"
  }

  @light_map %{
    0b00 => "no_light_or_not_monitored",
    0b01 => "light_on",
    0b10 => "light_off",
    0b11 => "light_error"
  }

  @doc """
  Decode the 5-bit GLA AtoN status field.
  bit4–3 → RACON (reversed order)
  bit2–1 → Light (reversed order)
  bit0   → Health
  """

  @spec decode_status(0..31) :: %{
          racon_status: String.t(),
          light_status: String.t(),
          health: String.t(),
          alarm?: boolean()
        }
  def decode_status(bits) when is_integer(bits) and bits in 0..31 do
    racon_bits = bits >>> 3 &&& 0b11
    light_bits = bits >>> 1 &&& 0b11
    health_bit = bits &&& 0b1

    %{
      racon_status: Map.fetch!(@racon_map, racon_bits),
      light_status: Map.fetch!(@light_map, light_bits),
      health: if(health_bit == 0, do: "good", else: "alarm"),
      alarm?: health_bit == 1
    }
  end

  @type t :: %__MODULE__{
          analogue_internal: non_neg_integer(),
          analogue_internal_v: float(),
          analogue_external_1: non_neg_integer(),
          analogue_external_1_v: float(),
          analogue_external_2: non_neg_integer(),
          analogue_external_2_v: float(),
          status_internal_raw: non_neg_integer(),
          status_external_raw: non_neg_integer(),
          status_internal_decoded: map(),
          status_external_decoded: map(),
          off_position: String.t()
        }

  @spec from_binary(bitstring()) :: t()
  def from_binary(<<
        analogue_internal::10,
        analogue_external_1::10,
        analogue_external_2::10,
        status_internal::5,
        status_external::8,
        off_position::1,
        _rest::bitstring
      >>) do
    %__MODULE__{
      analogue_internal: analogue_internal,
      analogue_internal_v: to_voltage(analogue_internal),
      analogue_external_1: analogue_external_1,
      analogue_external_1_v: to_voltage(analogue_external_1),
      analogue_external_2: analogue_external_2,
      analogue_external_2_v: to_voltage(analogue_external_2),
      status_internal_raw: status_internal,
      status_external_raw: status_external,
      status_internal_decoded: decode_status(status_internal),
      status_external_decoded: decode_8bit_status(status_external),
      off_position: decode_off_position(off_position)
    }
  end

  defp decode_8bit_status(bits) when is_integer(bits) and bits in 0..255 do
    internal_part = bits &&& 0b00011111
    spare = bits >>> 5
    Map.merge(decode_status(internal_part), %{spare_flags: spare})
  end

  defp decode_off_position(0b0), do: "in_position"
  defp decode_off_position(0b1), do: "off_position"

  # Convert raw analogue value to voltage (0.05 V steps)
  defp to_voltage(raw) when is_integer(raw) do
    Float.round(raw * 0.05, 2)
  end
end
