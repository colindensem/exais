defmodule ExAIS.AisTest do
  use ExUnit.Case

  describe "decode sentences" do

    test "decode class 1" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,B,13IbQQ000100lq`LD7J6Vi<n88AM,0*52")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 1
      assert attr.mmsi == "228237700"
      assert attr.true_heading == 38
    end

    test "decode class 3" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,B,39NSDjP02201T0HLBJDBv2GD02s1,0*14")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 3
      assert attr.mmsi == "636015818"
      assert attr.true_heading == 75
    end

    test "decode class 4" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,A,402;bFQv@kkLc00Dl4LE52100@J6,0*58")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 4
      assert attr.mmsi == "2288218"
      assert attr.utc_day == 7
      assert attr.utc_year == 2020
    end

    test "decode class 5" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,2,1,9,B,53qH`N0286j=<p8b220ti`62222222222222221?9p;554oF0;B3k51CPEH888888888880,0*68")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 5
      assert attr.mmsi == "261499000"
      assert attr.destination == "HOLTENAU"
      assert attr.call_sign == "SNBJ"
    end

    test "decode class 6" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,A,6>jCKIkfJjOt>db;q700@20,2*16")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 6
      assert attr.destination_id == 999999999
    end

    test "decode class 7" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,A,777QkG00RW38,0*62")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 7
      assert attr.mmsi == "477655900"
    end

    test "decode class 8" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,A,83HT5APj2P00000001BQJ@2E0000,0*72")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 8
      assert attr.mmsi == "227083590"
    end

    test "decode class 9" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,B,91b55vRAirOn<94M097lV@@20<6=,0*5D")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 9
      assert attr.mmsi == "111232506"
      assert attr.sog == 122
    end

    test "decode class 10" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,A,:81:Jf1D02J0,0*0E")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 10
      assert attr.mmsi == "538090168"
      assert attr.destination_id == 352324000
    end

    test "decode class 12" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,A,<42Lati0W:Ov=C7P6B?=Pjoihhjhqq0,2*2B")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 12
      assert attr.mmsi == "271002099"
      assert attr.destination_id == 271002111
    end

    test "decode class 14" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,A,>5?Per18=HB1U:1@E=B0m<L,2*51")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 14
      assert attr.mmsi == "351809000"
      assert attr.safety_related_text == "RCVD YR TEST MSG"
    end

    test "decode class 16 - 144 bit" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,B,@6STUk004lQ206bCKNOBAb6SJ@5s,0*74")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 16
      assert attr.mmsi == "439952844"
      assert attr.destination_a_id == 315920
      assert attr.destination_b_id == 230137673
    end

    test "decode class 17" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,A,A04757QAv0agH2JdGlLP7Oqa0@TGw9H170,4*5A")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 17
      assert attr.mmsi == "4310302"
      assert attr.latitude == 0.035618333333333335
      assert attr.longitude == 0.13989333333333334
    end

    test "decode class 18" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,B,B3HOIj000H08MeW52k4F7wo5oP06,0*42")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 18
      assert attr.mmsi == "227006920"
      assert attr.longitude == 0.115565
      assert attr.latitude == 49.484455
    end

    test "decode class 19" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,B,C69DqeP0Ar8;JH3R6<4O7wWPl@:62L>jcaQgh0000000?104222P,0*32")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 19
      assert attr.mmsi == "412432822"
      assert attr.longitude == 118.99442666666667
      assert attr.latitude == 24.695788333333333
      assert attr.name == "ZHECANGYU4078"
    end

    test "decode class 20" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,A,Dh3OvjB8IN>4,0*1D")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 20
      assert attr.id == 3669705
      assert attr.offset_1 == 2182
    end

    test "decode class 21" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,B,E>jCfrv2`0c2h0W:0a2ah@@@@@@004WD>;2<H50hppN000,4*0A")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 21
      assert attr.mmsi == "992276203"
      assert attr.latitude == 49.536165
      assert attr.longitude == 0.0315
      assert attr.assembled_name == "EPAVE ANTARES"
    end

    test "decode class 22" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,B,F030p?j2N2P73FiiNesU3FR10000,0*32")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 22
      assert attr.id == 3160127
      assert attr.channel_a == 2087
      assert attr.channel_b == 2088
      assert attr.zone_size == 2
    end

    test "decode class 23" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,B,G02:Kn01R`sn@291nj600000900,2*12")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 23
      assert attr.mmsi == "2268120"
      assert attr.interval == 9
    end

    test "decode class 24 part B" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,A,H3HOIFTl00000006Gqjhm01p?650,0*4F")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 24
      assert attr.mmsi == "227006810"
      assert attr.call_sign == "FW9205"
      assert attr.ship_type == 52
    end

    test "decode class 24 part A" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,A,H3HOIj0LhuE@tp0000000000000,2*2B")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 24
      assert attr.mmsi == "227006920"
      assert attr.name == "GLOUTON"
    end

    test "decode class 25" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,2,1,3,A,I`1ifG20UrcNTFE?UgLeo@Dk:o6G4hhI8;?vW2?El>Deju@c3Si451FJd9WPU<>B,0*04")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 25
      assert attr.mmsi == "538734172"
      assert attr.repeat_indicator == 2
      assert attr.binary_data == <<128, 151, 170, 222, 145, 101, 79, 150, 247, 45, 221, 5, 51, 43,
      113, 151, 19, 12, 25, 32, 179, 254, 156, 35, 213, 208, 229, 45, 203, 212,
      43, 14, 60, 68, 20, 21, 154, 176, 153, 224, 148, 195, 146>>
    end

    test "decode class 26" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,A,J1@@0IK70PGgT740000000000@000?D0ih1e00006JlPC9C3,0*6B")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 26
      assert attr.mmsi == "84148325"
      assert attr.destination_id == 834699643
      assert attr.binary_data == 83076754475605189869857356738384388

    end

    test "decode class 27" do
      {:ok, sentence} = ExAIS.Data.NMEA.parse("!AIVDM,1,1,,A,KCQ9r=hrFUnH7P00,0*41")
      {:ok, attr} = ExAIS.Data.Ais.parse(sentence.payload, sentence.padding)
      assert attr.msg_type == 27
      assert attr.mmsi == "236091959"
      assert attr.latitude == 87.065
      assert attr.longitude == -154.20166666666665

    end
  end
end
