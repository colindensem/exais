defmodule Decoders.Type6.GlaTest do
  @moduledoc false
  use ExUnit.Case

  alias ExAIS.Data.Decoders.Type6.Gla
  import Bitwise

  describe "decode_status/1" do
    test "decodes racon and light combinations correctly" do
      # 0b10110 = racon_operational (10), light_off (10), health=0 (good)
      result = Gla.decode_status(0b10100)

      assert result.racon_status == "racon_operational"
      assert result.light_status == "light_off"
      assert result.health == "good"
      refute result.alarm?
    end
  end

  describe "racon_status decoding" do
    test "00 → racon_not_installed" do
      bits = 0b00 <<< 3
      assert Gla.decode_status(bits).racon_status == "racon_not_installed"
    end

    test "01 → racon_not_monitored" do
      bits = 0b01 <<< 3
      assert Gla.decode_status(bits).racon_status == "racon_not_monitored"
    end

    test "10 → racon_operational" do
      bits = 0b10 <<< 3
      assert Gla.decode_status(bits).racon_status == "racon_operational"
    end

    test "11 → racon_error" do
      bits = 0b11 <<< 3
      assert Gla.decode_status(bits).racon_status == "racon_error"
    end
  end

  describe "light_status decoding" do
    test "00 → no_light_or_not_monitored" do
      bits = 0b00 <<< 1
      assert Gla.decode_status(bits).light_status == "no_light_or_not_monitored"
    end

    test "01 → light_on" do
      bits = 0b01 <<< 1
      assert Gla.decode_status(bits).light_status == "light_on"
    end

    test "10 → light_off" do
      bits = 0b10 <<< 1
      assert Gla.decode_status(bits).light_status == "light_off"
    end

    test "11 → light_error" do
      bits = 0b11 <<< 1
      assert Gla.decode_status(bits).light_status == "light_error"
    end
  end

  describe "health decoding" do
    test "0 → good" do
      assert Gla.decode_status(0).health == "good"
      refute Gla.decode_status(0).alarm?
    end

    test "1 → alarm" do
      assert Gla.decode_status(1).health == "alarm"
      assert Gla.decode_status(1).alarm?
    end
  end

  describe "combined sanity checks" do
    test "racon operational, light off, health good" do
      bits = 0b10100
      decoded = Gla.decode_status(bits)

      assert decoded.racon_status == "racon_operational"
      assert decoded.light_status == "light_off"
      assert decoded.health == "good"
    end

    test "racon error, light on, alarm" do
      bits = 0b11 <<< 3 ||| 0b10 <<< 1 ||| 0b1
      decoded = Gla.decode_status(bits)

      assert decoded.racon_status == "racon_error"
      assert decoded.light_status == "light_off"
      assert decoded.health == "alarm"
    end
  end

  describe "from_binary/1 analogue channels" do
    test "decodes analogue_internal and converts it to voltage" do
      # analogue_internal = 512  -> 25.6 V
      # rest is just dummy values
      payload =
        <<512::10, 0::10, 0::10, 0b00000::5, 0b00000000::8, 0::1>>

      msg = Gla.from_binary(payload)

      assert msg.analogue_internal == 512
      assert msg.analogue_internal_v == 25.6
    end

    test "decodes analogue_external_1 and converts it to voltage" do
      # analogue_external_1 = 600 -> 30.0 V
      payload =
        <<0::10, 600::10, 0::10, 0b00000::5, 0b00000000::8, 0::1>>

      msg = Gla.from_binary(payload)

      assert msg.analogue_external_1 == 600
      assert msg.analogue_external_1_v == 30.0
    end

    test "decodes analogue_external_1 and converts it to zero voltage" do
      # analogue_external_1 = 0 -> 0.0 V
      payload =
        <<0::10, 0::10, 0::10, 0b00000::5, 0b00000000::8, 0::1>>

      msg = Gla.from_binary(payload)

      assert msg.analogue_external_1 == 0
      assert msg.analogue_external_1_v == 0.0
    end

    test "decodes analogue_external_2 and converts it to voltage" do
      # analogue_external_2 = 720 -> 36.0 V
      payload =
        <<0::10, 0::10, 720::10, 0b00000::5, 0b00000000::8, 0::1>>

      msg = Gla.from_binary(payload)

      assert msg.analogue_external_2 == 720
      assert msg.analogue_external_2_v == 36.0
    end

    test "decodes analogue_external_2 and converts it to zero voltage" do
      # analogue_external_2 = 0 -> 0.0 V
      payload =
        <<0::10, 0::10, 0::10, 0b00000::5, 0b00000000::8, 0::1>>

      msg = Gla.from_binary(payload)

      assert msg.analogue_external_2 == 0
      assert msg.analogue_external_2_v == 0.0
    end

    test "all three analogue channels populated together" do
      # internal: 512 -> 25.6V
      # ext1:    600 -> 30.0V
      # ext2:    720 -> 36.0V
      payload =
        <<512::10, 600::10, 720::10, 0b00000::5, 0b00000000::8, 0::1>>

      msg = Gla.from_binary(payload)

      assert msg.analogue_internal == 512
      assert msg.analogue_internal_v == 25.6

      assert msg.analogue_external_1 == 600
      assert msg.analogue_external_1_v == 30.0

      assert msg.analogue_external_2 == 720
      assert msg.analogue_external_2_v == 36.0
    end
  end

  describe "from_binary/1 status fields & off_position" do
    test "decodes status_internal into racon/light/health and preserves raw" do
      # status_internal = 0b10110
      #   racon bits (4–3): 10 -> racon_operational
      #   light bits (2–1): 11 -> light_error
      #   health bit (0):  0  -> good
      payload =
        <<0::10, 0::10, 0::10, 0b10110::5, 0b00000000::8, 0::1>>

      msg = Gla.from_binary(payload)

      assert msg.status_internal_raw == 0b10110

      assert msg.status_internal_decoded.racon_status == "racon_operational"
      assert msg.status_internal_decoded.light_status == "light_error"
      assert msg.status_internal_decoded.health == "good"
      refute msg.status_internal_decoded.alarm?
    end

    test "decodes status_external 8-bit field into 5-bit status + spare_flags" do
      # status_external = 0b10110110 (0xB6, 182)
      # lower 5 bits (0b10110) decode same way as internal
      # upper 3 bits are spare_flags (0b101 = 5)
      payload =
        <<0::10, 0::10, 0::10, 0b00000::5, 0b10110110::8, 0::1>>

      msg = Gla.from_binary(payload)

      assert msg.status_external_raw == 0b10110110

      assert msg.status_external_decoded.racon_status == "racon_operational"
      assert msg.status_external_decoded.light_status == "light_error"
      assert msg.status_external_decoded.health == "good"
      refute msg.status_external_decoded.alarm?

      # spare flags should be the top 3 bits of the external byte
      assert msg.status_external_decoded.spare_flags == 0b101
    end

    test "off_position bit 0 -> in_position" do
      payload =
        <<0::10, 0::10, 0::10, 0b00000::5, 0b00000000::8, 0::1>>

      msg = Gla.from_binary(payload)
      assert msg.off_position == "in_position"
    end

    test "off_position bit 1 -> off_position" do
      payload =
        <<0::10, 0::10, 0::10, 0b00000::5, 0b00000000::8, 1::1>>

      msg = Gla.from_binary(payload)
      assert msg.off_position == "off_position"
    end
  end

  describe "integration sanity check" do
    test "decodes everything together in a realistic frame" do
      # internal=512 (25.6V), ext1=600 (30.0V), ext2=720 (36.0V)
      # status_internal=0b10110:
      #   racon_operational, light_error, good
      # status_external=0b10110110:
      #   same 5b status + spare_flags = 0b101
      # off_position=1
      payload =
        <<512::10, 600::10, 720::10, 0b10110::5, 0b10110110::8, 1::1>>

      msg = Gla.from_binary(payload)

      # voltages
      assert msg.analogue_internal_v == 25.6
      assert msg.analogue_external_1_v == 30.0
      assert msg.analogue_external_2_v == 36.0

      # internal status
      assert msg.status_internal_decoded.racon_status == "racon_operational"
      assert msg.status_internal_decoded.light_status == "light_error"
      assert msg.status_internal_decoded.health == "good"
      refute msg.status_internal_decoded.alarm?

      # external status
      assert msg.status_external_decoded.racon_status == "racon_operational"
      assert msg.status_external_decoded.light_status == "light_error"
      assert msg.status_external_decoded.health == "good"
      assert msg.status_external_decoded.spare_flags == 0b101

      # position status
      assert msg.off_position == "off_position"
    end
  end
end
