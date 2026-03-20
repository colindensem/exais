defmodule Decoders.Type6.GlaTest do
  @moduledoc false
  use ExUnit.Case

  alias ExAIS.Data.Decoders.Type6.Gla

  describe "from_binary/1 analogue channels" do
    test "decodes analogue_internal and converts it to voltage" do
      # analogue_internal = 512  -> 25.6 V
      # rest is just dummy values
      payload =
        <<512::10, 0::10, 0::10, 0b00000::5, 0b00000000::8, 0::1>>

      msg = Gla.from_binary(payload)

      assert msg.analogue_internal == 512
    end

    test "decodes analogue_external_1 and converts it to voltage" do
      # analogue_external_1 = 600 -> 30.0 V
      payload =
        <<0::10, 600::10, 0::10, 0b00000::5, 0b00000000::8, 0::1>>

      msg = Gla.from_binary(payload)

      assert msg.analogue_external_1 == 600
    end

    test "decodes analogue_external_1 and converts it to zero voltage" do
      # analogue_external_1 = 0 -> 0.0 V
      payload =
        <<0::10, 0::10, 0::10, 0b00000::5, 0b00000000::8, 0::1>>

      msg = Gla.from_binary(payload)

      assert msg.analogue_external_1 == 0
    end

    test "decodes analogue_external_2 and converts it to voltage" do
      # analogue_external_2 = 720 -> 36.0 V
      payload =
        <<0::10, 0::10, 720::10, 0b00000::5, 0b00000000::8, 0::1>>

      msg = Gla.from_binary(payload)

      assert msg.analogue_external_2 == 720
    end

    test "decodes analogue_external_2 and converts it to zero voltage" do
      # analogue_external_2 = 0 -> 0.0 V
      payload =
        <<0::10, 0::10, 0::10, 0b00000::5, 0b00000000::8, 0::1>>

      msg = Gla.from_binary(payload)

      assert msg.analogue_external_2 == 0
    end

    test "all three analogue channels populated together" do
      # internal: 512 -> 25.6V
      # ext1:    600 -> 30.0V
      # ext2:    720 -> 36.0V
      payload =
        <<512::10, 600::10, 720::10, 0b00000::5, 0b00000000::8, 0::1>>

      msg = Gla.from_binary(payload)

      assert msg.analogue_internal == 512

      assert msg.analogue_external_1 == 600

      assert msg.analogue_external_2 == 720
    end
  end

  describe "from_binary/1 status fields & off_position" do
    test "decodes status_internal" do
      payload =
        <<0::10, 0::10, 0::10, 0b10110::5, 0b00000000::8, 0::1>>

      msg = Gla.from_binary(payload)

      assert msg.status_internal == 0b10110
    end

    test "decodes status_external 8-bit field into 5-bit status + spare_flags" do
      # status_external = 0b10110110 (0xB6, 182)
      # lower 5 bits (0b10110) decode same way as internal
      # upper 3 bits are spare_flags (0b101 = 5)
      payload =
        <<0::10, 0::10, 0::10, 0b00000::5, 0b10110110::8, 0::1>>

      msg = Gla.from_binary(payload)

      assert msg.status_external == 0b10110110
    end

    test "off_position bit 0 -> on_position" do
      payload =
        <<0::10, 0::10, 0::10, 0b00000::5, 0b00000000::8, 0::1>>

      msg = Gla.from_binary(payload)
      assert msg.off_position_indicator == 0
    end

    test "off_position bit 1 -> off_position" do
      payload =
        <<0::10, 0::10, 0::10, 0b00000::5, 0b00000000::8, 1::1>>

      msg = Gla.from_binary(payload)
      assert msg.off_position_indicator == 1
    end
  end
end
