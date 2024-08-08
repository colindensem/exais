defmodule ExAIS.NMEATest do
  use ExUnit.Case

  describe "decode sentences" do
    test "decode !AIVDM" do
      {:ok, result} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,B,177KQJ5000G?tO`K>RA1wUbN0TKH,0*5C")
      assert result.talker == "!AI"
      assert result.formatter == "VDM"
      assert result.channel == "B"
      assert result.payload == "177KQJ5000G?tO`K>RA1wUbN0TKH"
    end

    test "decode $GPGLL" do
      {:ok, result} = ExAIS.Data.NMEA.parse("$GPGLL,5133.81,N,00042.25,W*75")
      assert result.talker == "$GP"
      assert result.formatter == "GLL"
      assert result.north_south == "N"
      assert result.east_west == "W"
      assert result.longitude == "00042.25"
      assert result.latitude == "5133.81"
    end
  end
end
