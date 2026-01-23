defmodule ExAIS.Data.Decoders.Type6.Gla do
  @moduledoc """
  Decode a GLA Type 6 (FI 6) Electrical / System Status payload.

  Bit layout:

      0–9    : analogue_internal (10)
     10–19   : analogue_external_1 (10)
     20–29   : analogue_external_2 (10)
     30–34   : status_internal (5)
     35–42   : status_external (8)
     43      : off_position_indicator (1)
     44+     : spare bits
  """

  defstruct [
    :analogue_internal,
    :analogue_external_1,
    :analogue_external_2,
    :status_internal,
    :status_external,
    :off_position_indicator
  ]

  @type t :: %__MODULE__{
          analogue_internal: non_neg_integer(),
          analogue_external_1: non_neg_integer(),
          analogue_external_2: non_neg_integer(),
          status_internal: non_neg_integer(),
          status_external: non_neg_integer(),
          off_position_indicator: non_neg_integer()
        }

  @spec from_binary(bitstring()) :: t()
  def from_binary(<<
        analogue_internal::10,
        analogue_external_1::10,
        analogue_external_2::10,
        status_internal::5,
        status_external::8,
        off_position_indicator::1,
        _rest::bitstring
      >>) do
    %__MODULE__{
      analogue_internal: analogue_internal,
      analogue_external_1: analogue_external_1,
      analogue_external_2: analogue_external_2,
      status_internal: status_internal,
      status_external: status_external,
      off_position_indicator: off_position_indicator
    }
  end
end
