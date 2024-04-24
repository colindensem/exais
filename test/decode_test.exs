defmodule AIS.DecodeTest do
  use ExUnit.Case

  import AIS.MessageFixtures

  setup do
    messages = messages()
    %{messages: messages}
  end

  describe "decode messages" do
    test "all", %{messages: messages} do
      {decoded, _groups, latest} =
        AIS.Decoder.decode_messages(messages, %{
          fragment: "",   # Used to handle fragmented messages
          decoded: [],
          groups: %{},     # Map of list of grouped messages keyed by group id
          latest: DateTime.from_unix!(0)
        })

      assert Enum.count(decoded) == 29
      assert latest == DateTime.from_unix!(1_692_784_374)
    end

    test "spire group" do
      {decoded, _groups, latest} =
        AIS.Decoder.decode_messages(
          ["\\p:spire,g:1-2-40348012,s:terrestrial,c:1692880962*22\\!AIVDM,2,1,2,B,53M@a:H00000l5acV20T<DpV0hDLDpB22222220`0`B4467@S5S58;H1ikmi,0*52",
           "\\p:spire,g:2-2-40348012*55\\!AIVDM,2,2,2,B,`;H35888880,2*08",
           "\\p:spire,g:1-2-3269328,s:terrestrial,c:1694649009*14\\!AIVDM,2,1,8,B,59NSDF82ASwDCD<SR2104<THT>1`U8<tr222221@B`QE;6K@0BkS4U3H8888,0*74",
           "\\p:spire,s:spire,g:2-2-3269328*6A\\!AIVDM,2,2,8,B,88888888880,2*2F",],
          %{
            fragment: "",   # Used to handle fragmented messages
            decoded: [],
            groups: %{},     # Map of list of grouped messages keyed by group id
            latest: DateTime.from_unix!(0)
          })
      assert Enum.count(decoded) == 2
      assert latest == DateTime.from_unix!(1_694_649_009)
    end

    test "group" do
      {_, %{groups: groups, latest: _latest}} = AIS.Decoder.decode_message("\\p:orbcomm,g:1-2-8641949,s:terrestrial,c:1694768536*17\\!AIVDM,2,1,9,A,53m9Vi400000hULJ220TpLD8u8N10h5@uF22220l0p:3240Ht03lk3iRSlQ1,0*0A", %{groups: %{}, latest: DateTime.from_unix(0)})
      assert Map.has_key?(groups, "orbcomm")
      assert Map.has_key?(groups["orbcomm"], "8641949")
    end
  end

  describe "decode tags" do

    test "decode provider" do
      tags = AIS.Decoder.decode_tags("p:spire,g:1-2-40348012,s:terrestrial,c:1692880962*22")
      assert tags.p == "spire"

      tags = AIS.Decoder.decode_tags("p:orbcomm,g:2-2-40348012*55")
      assert tags.p == "orbcomm"
    end

  end

  describe "decode nmea/1" do

    test "nmea checksum" do
      assert AIS.Decoder.nmea_checksum("!AIVDM,1,1,,B,13IbQQ000100lq`LD7J6Vi<n88AM,0*52")
      refute AIS.Decoder.nmea_checksum("!AIVDM,1,1,,B,13IbQQ000100lq`LD7J6Vi<n88AM,0*51")
    end

    test "decode type 1" do
      {result, sentence} = AIS.Decoder.decode_nmea("!AIVDM,1,1,,B,13IbQQ000100lq`LD7J6Vi<n88AM,0*52")
      assert result == :ok
      assert sentence.mmsi == "228237700"
      assert sentence.longitude == 0.18056666666666665
      assert sentence.latitude == 49.48284
    end

  end
end
