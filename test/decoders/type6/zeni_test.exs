defmodule Decoders.Type6.ZeniTest do
  @moduledoc false
  use ExUnit.Case

  alias ExAIS.Data
  alias ExAIS.Data.Decoders.Type6.Zeni

  describe "from_binary/1 – voltage field" do
    test "decodes voltage raw value and converts to volts (0.1 V steps)" do
      # voltage = 840 -> 84.0 V
      payload = <<1::16, 840::12, 0::10, 0::1, 0::1, 0::1, 0::1, 0::6>>
      msg = Zeni.from_binary(payload)

      assert msg.voltage_raw == 840
      assert msg.voltage_v == 84.0
    end

    test "zero voltage" do
      payload = <<1::16, 0::12, 0::10, 0::1, 0::1, 0::1, 0::1, 0::6>>
      msg = Zeni.from_binary(payload)

      assert msg.voltage_raw == 0
      assert msg.voltage_v == 0.0
    end

    test "maximum voltage value (4096 * 0.1 = 409.6 V)" do
      payload = <<1::16, 4095::12, 0::10, 0::1, 0::1, 0::1, 0::1, 0::6>>
      msg = Zeni.from_binary(payload)

      assert msg.voltage_raw == 4095
      assert msg.voltage_v == 409.5
    end
  end

  describe "from_binary/1 – current field" do
    test "decodes current raw value and converts to amps (0.1 A steps)" do
      # current = 83 -> 8.3 A
      payload = <<1::16, 0::12, 83::10, 0::1, 0::1, 0::1, 0::1, 0::6>>
      msg = Zeni.from_binary(payload)

      assert msg.current_raw == 83
      assert msg.current_a == 8.3
    end

    test "zero current" do
      payload = <<1::16, 0::12, 0::10, 0::1, 0::1, 0::1, 0::1, 0::6>>
      msg = Zeni.from_binary(payload)

      assert msg.current_raw == 0
      assert msg.current_a == 0.0
    end
  end

  describe "from_binary/1 – power supply type" do
    test "0 -> raw 0, ac" do
      payload = <<1::16, 0::12, 0::10, 0::1, 0::1, 0::1, 0::1, 0::6>>
      msg = Zeni.from_binary(payload)
      assert msg.power_supply_raw == 0
      assert msg.power_supply == "ac"
    end

    test "1 -> raw 1, dc" do
      payload = <<1::16, 0::12, 0::10, 1::1, 0::1, 0::1, 0::1, 0::6>>
      msg = Zeni.from_binary(payload)
      assert msg.power_supply_raw == 1
      assert msg.power_supply == "dc"
    end
  end

  describe "from_binary/1 – light status" do
    test "0 -> raw false, light_off" do
      payload = <<1::16, 0::12, 0::10, 0::1, 0::1, 0::1, 0::1, 0::6>>
      msg = Zeni.from_binary(payload)
      assert msg.light_status_raw == false
      assert msg.light_status == "light_off"
    end

    test "1 -> raw true, light_on" do
      payload = <<1::16, 0::12, 0::10, 0::1, 1::1, 0::1, 0::1, 0::6>>
      msg = Zeni.from_binary(payload)
      assert msg.light_status_raw == true
      assert msg.light_status == "light_on"
    end
  end

  describe "from_binary/1 – battery status" do
    test "0 -> raw false, good" do
      payload = <<1::16, 0::12, 0::10, 0::1, 0::1, 0::1, 0::1, 0::6>>
      msg = Zeni.from_binary(payload)
      assert msg.battery_status_raw == false
      assert msg.battery_status == "good"
    end

    test "1 -> raw true, low_voltage" do
      payload = <<1::16, 0::12, 0::10, 0::1, 0::1, 1::1, 0::1, 0::6>>
      msg = Zeni.from_binary(payload)
      assert msg.battery_status_raw == true
      assert msg.battery_status == "low_voltage"
    end
  end

  describe "from_binary/1 – off position status" do
    test "0 -> raw false, on_position" do
      payload = <<1::16, 0::12, 0::10, 0::1, 0::1, 0::1, 0::1, 0::6>>
      msg = Zeni.from_binary(payload)
      assert msg.off_position_raw == false
      assert msg.off_position == "on_position"
    end

    test "1 -> raw true, off_position" do
      payload = <<1::16, 0::12, 0::10, 0::1, 0::1, 0::1, 1::1, 0::6>>
      msg = Zeni.from_binary(payload)
      assert msg.off_position_raw == true
      assert msg.off_position == "off_position"
    end
  end

  describe "from_binary/1 – sub_application_id" do
    test "preserves sub_application_id raw value" do
      payload = <<42::16, 0::12, 0::10, 0::1, 0::1, 0::1, 0::1, 0::6>>
      assert Zeni.from_binary(payload).sub_application_id == 42
    end
  end

  describe "from_binary/1 – sample message integration" do
    # Sample: !AIVDM,1,1,,B,6>h98`holKo<00000@Q@1h0,2*5D
    # DAC=0 / FI=0, the data decodes to:
    #   sub_application_id = 1
    #   voltage = 133 -> 13.3 V
    #   current = 1   -> 0.1 A
    #   power_supply  = "dc"
    #   light_status  = "light_on"
    #   battery_status = "good"
    #   off_position  = "on_position"
    test "decodes all fields from the real Zeni sample payload" do
      {:ok, sentence} =
        Data.NMEA.parse("!AIVDM,1,1,,B,6>h98`holKo<00000@Q@1h0,2*5D")

      {:ok, attr} = Data.Ais.parse(sentence.payload, sentence.padding)

      assert attr.msg_type == 6
      assert attr.application_identifier == "00"

      assert attr.sub_application_id == 1

      assert attr.voltage_raw == 133
      assert attr.voltage_v == 13.3

      assert attr.current_raw == 1
      assert attr.current_a == 0.1

      assert attr.power_supply_raw == 1
      assert attr.power_supply == "dc"
      assert attr.light_status_raw == true
      assert attr.light_status == "light_on"
      assert attr.battery_status_raw == false
      assert attr.battery_status == "good"
      assert attr.off_position_raw == false
      assert attr.off_position == "on_position"
    end
  end

  describe "from_binary/1 – Zeni Lite (DAC=0, FI=0) integration" do
    # Payload: 6>h98`holKo<00000@QP0P0, padding 2
    # Python decoder: sub_application_id=1, voltage_raw=134 (13.4V),
    # current_raw=0 (0.0A), power_supply_raw=1 (DC),
    # light_on=False, battery_low=False, off_position=False
    test "decodes all fields from the Zeni Lite sample payload" do
      {:ok, attr} = Data.Ais.parse("6>h98`holKo<00000@QP0P0", 2)

      assert attr.msg_type == 6
      assert attr.application_identifier == "00"

      assert attr.sub_application_id == 1

      assert attr.voltage_raw == 134
      assert attr.voltage_v == 13.4

      assert attr.current_raw == 0
      assert attr.current_a == 0.0

      assert attr.power_supply_raw == 1
      assert attr.power_supply == "dc"
      assert attr.light_status_raw == false
      assert attr.light_status == "light_off"
      assert attr.battery_status_raw == false
      assert attr.battery_status == "good"
      assert attr.off_position_raw == false
      assert attr.off_position == "on_position"
    end
  end
end
