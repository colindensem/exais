defmodule ExAIS.DecodeTest do
  use ExUnit.Case

  import ExAIS.MessageFixtures

  alias ExAIS.Data.Ais

  setup do
    messages = messages()
    %{messages: messages}
  end

  describe "decode messages" do
    test "all", %{messages: messages} do
      {decoded, _groups, latest} =
        ExAIS.Decoder.decode_messages(
          messages,
          %{
            # Used to handle fragmented messages
            fragment: "",
            decoded: [],
            # Map of list of grouped messages keyed by group id
            groups: %{},
            latest: DateTime.from_unix!(0)
          },
          Ais.all_msg_types()
        )

      assert Enum.count(decoded) == 29
      assert latest == DateTime.from_unix!(1_692_784_374)
    end

    test "spire group" do
      {decoded, _groups, latest} =
        ExAIS.Decoder.decode_messages(
          [
            "\\p:spire,g:1-2-40348012,s:terrestrial,c:1692880962*22\\!AIVDM,2,1,2,B,53M@a:H00000l5acV20T<DpV0hDLDpB22222220`0`B4467@S5S58;H1ikmi,0*52",
            "\\p:spire,g:2-2-40348012*55\\!AIVDM,2,2,2,B,`;H35888880,2*08",
            "\\p:spire,g:1-2-3269328,s:terrestrial,c:1694649009*14\\!AIVDM,2,1,8,B,59NSDF82ASwDCD<SR2104<THT>1`U8<tr222221@B`QE;6K@0BkS4U3H8888,0*74",
            "\\p:spire,s:spire,g:2-2-3269328*6A\\!AIVDM,2,2,8,B,88888888880,2*2F"
          ],
          %{
            # Used to handle fragmented messages
            fragment: "",
            decoded: [],
            # Map of list of grouped messages keyed by group id
            groups: %{},
            latest: DateTime.from_unix!(0)
          },
          Ais.all_msg_types()
        )

      assert Enum.count(decoded) == 2
      assert latest == DateTime.from_unix!(1_694_649_009)
    end

    test "group" do
      {_, %{groups: groups, latest: _latest}} =
        ExAIS.Decoder.decode_message(
          "\\p:orbcomm,g:1-2-8641949,s:terrestrial,c:1694768536*17\\!AIVDM,2,1,9,A,53m9Vi400000hULJ220TpLD8u8N10h5@uF22220l0p:3240Ht03lk3iRSlQ1,0*0A",
          %{groups: %{}, latest: DateTime.from_unix(0)},
          Ais.all_msg_types()
        )

      assert Map.has_key?(groups, "orbcomm")
      assert Map.has_key?(groups["orbcomm"], "8641949")
    end
  end

  describe "decode tags" do
    test "decode provider" do
      tags = ExAIS.Decoder.decode_tags("p:spire,g:1-2-40348012,s:terrestrial,c:1692880962*22")
      assert tags.p == "spire"

      tags = ExAIS.Decoder.decode_tags("p:orbcomm,g:2-2-40348012*55")
      assert tags.p == "orbcomm"
    end

    test "decode all tags" do
      tags = ExAIS.Decoder.decode_tags("p:spire,g:1-2-40348012,s:terrestrial,c:1692880962*22")

      assert tags.p == "spire"
      assert tags.g == "1-2-40348012"
      assert tags.s == "terrestrial"
      assert tags.c == "1692880962"

      tags = ExAIS.Decoder.decode_tags("p:exact,s: ,c:1746184480,t:LIVE*6D")

      assert tags.p == "exact"
      assert tags.s == " "
      assert tags.c == "1746184480"
    end
  end

  describe "decode nmea/1" do
    test "nmea checksum" do
      assert ExAIS.Decoder.nmea_checksum("!AIVDM,1,1,,B,13IbQQ000100lq`LD7J6Vi<n88AM,0*52")
      refute ExAIS.Decoder.nmea_checksum("!AIVDM,1,1,,B,13IbQQ000100lq`LD7J6Vi<n88AM,0*51")
    end

    test "decode type 1" do
      {result, sentence} =
        ExAIS.Decoder.decode_nmea(
          "!AIVDM,1,1,,B,13IbQQ000100lq`LD7J6Vi<n88AM,0*52",
          Ais.all_msg_types()
        )

      assert result == :ok
      assert sentence.mmsi == "228237700"
      assert sentence.longitude == 0.18056666666666665
      assert sentence.latitude == 49.48284
    end
  end

  describe "decode errors" do
    test "" do
      msgs = [
        ",c:1756457771,t:LIVE*6A\\!AIVDM,1,1,,B,160rlr001\\s: ,c:1756457771,t:LIVE*6A\\!AIVDM,1,1,,B,1:fnGt?P00SQ@fNA7aOTlgvF253P,0*43",
        "\\p:poole,s: ,c:1756457772,t:LIVE*69\\!AIVDM,1,1,,B,15@@sn30@03fi0H?9:T<20GT0@7c,0*6A",
        "\\p:poole,s: ,c:1756457772,t:LIVE*69\\!AIVDM,1,1,,A,19@>idiP003tsAp>UvmUSwvH0d6=,0*01",
        "\\p:poole,s: ,c:1756457772,t:LIVE*69\\!AIVDM,1,1,,A,18IWmT000?3V=i@?Cl5jUB<H287d,0*03",
        "\\p:poole,s: ,c:1756457772,t:LIVE*69\\!AIVDM,2,1,5,A,5777T482<iqiI9QGB205H63J222222\\s: ,c:1756457772,t:LIVE*69\\!AIVDM,2,2,5,A,88888888880,2*21",
        "\\p:poole,s: ,c:1756457772,t:LIVE*69\\!AIVDM,1,1,,B,19?Q?B3000STj<d?H:5v452J2<FH,0*7F",
        "\\p:poole,s:POOLE,c:1756457773,t:LIVE*11\\$AIHBT,5.0,A,8*28",
        "\\p:poole,s: ,c:1756457772,t:LIVE*69\\!AIVDM,1,1,,A,15@><40000SQH>D@;Vw0`74J0`7m,0*2D",
        "\\p:poole,s: ,c:1756457772,t:LIVE*69\\!AIVDM,1,1,,A,1611a:00013VPrr?sQ:@O5DD00Rl,0*6D",
        "\\p:poole,s: ,c:1756457772,t:LIVE*69\\!AIVDM,1,1,,A,35?vL@50003RvOD@<ei7c9fH0000,0*4F"
      ]

      {decoded, _groups, latest} =
        ExAIS.Decoder.decode_messages(
          msgs,
          %{
            # Used to handle fragmented messages
            fragment: "",
            decoded: [],
            # Map of list of grouped messages keyed by group id
            groups: %{},
            latest: DateTime.from_unix!(0)
          },
          Ais.all_msg_types()
        )

      assert Enum.count(decoded) == 7
      assert latest == DateTime.from_unix!(1_756_457_772)
    end
  end
end
