defmodule ExAIS.Data.Decoders.Type6.Zeni do
  @moduledoc """
  Decode a Zeni Type 6 (FI 9) Electrical / System Status payload.

  Bit layout of the data portion (after DAC/FI):

      0–15   : sub_application_id (16)
     16–27   : voltage (12) — 0.1 V increments, max 409.6 V
     28–37   : current (10) — 0.1 A increments, max 102.3 A
     38      : power_supply_type (1) — 0: AC, 1: DC
     39      : light_status (1)      — 0: Light Off, 1: Light On
     40      : battery_status (1)    — 0: Good, 1: Low voltage
     41      : off_position (1)      — 0: On position, 1: Off position
     42–47   : spare (6)

  Total: 48 bits (full Type 6 message occupies 136 bits / 1 slot).
  """

  defstruct [
    :sub_application_id,
    :voltage_raw,
    :voltage_v,
    :current_raw,
    :current_a,
    :power_supply_raw,
    :power_supply,
    :light_status_raw,
    :light_status,
    :battery_status_raw,
    :battery_status,
    :off_position_raw,
    :off_position
  ]

  @type t :: %__MODULE__{
          sub_application_id: non_neg_integer(),
          voltage_raw: non_neg_integer(),
          voltage_v: float(),
          current_raw: non_neg_integer(),
          current_a: float(),
          power_supply_raw: 0 | 1,
          power_supply: String.t(),
          light_status_raw: boolean(),
          light_status: String.t(),
          battery_status_raw: boolean(),
          battery_status: String.t(),
          off_position_raw: boolean(),
          off_position: String.t()
        }

  @spec from_binary(bitstring()) :: t()
  def from_binary(<<
        sub_application_id::16,
        voltage::12,
        current::10,
        power_supply_bit::1,
        light_status_bit::1,
        battery_status_bit::1,
        off_position_bit::1,
        _spare::6,
        _rest::bitstring
      >>) do
    %__MODULE__{
      sub_application_id: sub_application_id,
      voltage_raw: voltage,
      voltage_v: Float.round(voltage * 0.1, 1),
      current_raw: current,
      current_a: Float.round(current * 0.1, 1),
      power_supply_raw: power_supply_bit,
      power_supply: decode_power_supply(power_supply_bit),
      light_status_raw: light_status_bit == 1,
      light_status: decode_light_status(light_status_bit),
      battery_status_raw: battery_status_bit == 1,
      battery_status: decode_battery_status(battery_status_bit),
      off_position_raw: off_position_bit == 1,
      off_position: decode_off_position(off_position_bit)
    }
  end

  defp decode_power_supply(0), do: "ac"
  defp decode_power_supply(1), do: "dc"

  defp decode_light_status(0), do: "light_off"
  defp decode_light_status(1), do: "light_on"

  defp decode_battery_status(0), do: "good"
  defp decode_battery_status(1), do: "low_voltage"

  defp decode_off_position(0), do: "on_position"
  defp decode_off_position(1), do: "off_position"
end
