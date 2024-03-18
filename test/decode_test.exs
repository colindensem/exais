defmodule AIS.DecodeTest do
  use ExUnit.Case

  @messages ["\\p:spire,s:terrestrial,c:1692781258*54\\!AIVDM,1,1,,B,B3MA@I007?sDoVW;bE=23wpUoP06,0*4B",
     "\\p:spire,s:terrestrial,c:1692781259*55\\!AIVDM,1,1,,A,33aKV05P00PG@O@N7gI@0?wT2>`<,0*3C",
     "\\p:spire,s:terrestrial,c:1692781249*54\\!AIVDM,1,1,,B,B3MA@I007?sDoVW;bE=23wpUoP06,0*4B",
     "\\p:spire,s:terrestrial,c:1692781259*55\\!AIVDM,1,1,,B,13cgCP0wi`176I0EgB<7U61L0>`<,0*10",
     "\\p:spire,s:terrestrial,c:1692781259*55\\!AIVDM,1,1,,A,B5NWW<P00=kd7T6t:c2uOwq5oP06,0*3B",
     "\\p:spire,s:terrestrial,c:1692781258*54\\!AIVDM,1,1,,B,H0qH9Wl000000000000000000000,0*56",
     "\\p:spire,s:terrestrial,c:1692781258*54\\!AIVDM,1,1,,B,13MC:58P00WK=P>0fG=@kwwT2>`<,0*02",
     "\\p:spire,s:terrestrial,c:1692781250*5C\\!AIVDM,1,1,,A,B4hE8f000889fWV?448l7wq5oP06,0*1B",
     "\\p:spire,s:terrestrial,c:1692781258*54\\!AIVDM,1,1,,A,13m`WR00001G4VLWpb5d8p9l00T9,0*10",
     "\\p:spire,s:terrestrial,c:1692781258*54\\!AIVDM,1,1,,B,H3@pcu4TCBD:MfPH@9kopj10321t,0*76",
     "\\p:spire,s:terrestrial,c:1692781257*5B\\!AIVDM,1,1,,B,177>p2002@0DOq:QO@5=EbWj0<07,0*2D",
     "\\p:spire,s:terrestrial,c:1692781243*5E\\!AIVDM,1,1,,B,16<g:S@P008WWQL=oR67rwwF0@H6,0*1E",
     "\\p:spire,s:terrestrial,c:1692781258*54\\!AIVDM,1,1,,B,B52OcB@00=pLF>4o3TbF;wpUoP06,0*7F",
     "\\p:spire,s:terrestrial,c:1692781258*54\\!AIVDM,1,1,,A,35R`V2002t0hVidVBtvPiPcl83Wk,0*74",
     "\\p:spire,s:terrestrial,c:1692781250*5C\\!AIVDM,1,1,,B,13kigf00111<frBP4`lBE1kT0>`<,0*4C",
     "\\p:spire,s:terrestrial,c:1692781259*55\\!AIVDM,1,1,,B,H42O>ClU9=1B9>5I=1jnqm00?050,0*72",
     "\\p:spire,s:terrestrial,c:1692781258*54\\!AIVDM,1,1,,B,13@oJQOu@IOgww<NdU2A3PuP0>`<,0*2C",
     "\\p:spire,s:terrestrial,c:1692781204*5D\\!AIVDM,1,1,,A,15Nd;9dOh3qTO`t@t`8:bbb80d4P,0*38",
     "\\p:spire,s:terrestrial,c:1692781259*55\\!AIVDM,1,1,,B,H5MCJcTTCBD6v:w00000001P1140,0*62",
     "\\p:spire,g:1-2-7337123,s:terrestrial,c:1692781258*16\\!AIVDM,2,1,3,A,53aDr3D000010KW?780Tp4000000000000000016;h<66v8605RiB3000000,0*62",
     "\\p:spire,g:2-2-7337123*6D\\!AIVDM,2,2,3,A,00000000000,2*27",
     "\\p:spire,s:terrestrial,c:1692781259*55\\!AIVDM,1,1,,B,B3KF;DP0AH:tsSWhAuRAKwq5oP06,0*78",
     "\\p:spire,s:terrestrial,c:1692781259*55\\!AIVDM,1,1,,A,H3TmNt4U>F36Ie5CF1nqpn106440,0*69",
     "\\p:spire,s:terrestrial,c:1692781258*54\\!AIVDM,1,1,,A,H3tfbw4U1=30000C6plhoP000000,0*3A",
     "\\p:spire,s:terrestrial,c:1692781258*54\\!AIVDM,1,1,,A,H3tfbw4U1=30000C6plhoP000000,0*3A",
     "\\p:spire,s:terrestrial,c:1692781258*54\\!AIVDM,1,1,,B,H7OmE<4UCBD:MWEDB5CEB500000t,0*46",
     "\\p:spire,s:terrestrial,c:1692781259*55\\!AIVDM,1,1,,B,16K3J3@0009`3>lCm0O9WbCP0>`<,0*77",
     "\\p:spire,g:1-2-7337124,s:terrestrial,c:1692781258*11\\!AIVDM,2,1,4,B,55BPGR02A<po<HHk>21`DIU8u>2222222222221IBPS<D5lA5<Ai0CTjp43k,0*7D",
     "\\p:spire,g:2-2-7337124*6A\\!AIVDM,2,2,4,B,0CQ88888880,2*39",
     "\\p:spire,g:1-2-7337125,s:terrestrial,c:1692781258*10\\!AIVDM,2,1,5,B,548bmt01iETdiW??760M9Dl4qB2222222222221@8P?3;5<P0?Rk0BD1A0H8,0*5F",
     "\\p:spire,g:2-2-7337125*6B\\!AIVDM,2,2,5,B,88888888880,2*22",
     "\\p:orbcomm,g:1-3-8368053,s:terrestrial,c:1692784374*1E\\!AIVDM,3,1,3,A,8h30ot1?0@6;`=D9e2B94oCPH54M`Owwqpwwj`9M@P2;`@D9e2B94oCPH54M,0*18",
     "\\p:orbcomm,g:2-3-8368053*6F\\!AIVDM,3,2,3,A,`OwwqJwwj`9M@P2;`CPPP121IoCol54cd0EwsLwwja8owP2;`DD9e2B94oCP,0*34",
     "\\p:orbcomm,g:3-3-8368053*6E\\!AIVDM,3,3,3,A,H54M`Owwqpwwj`9M@P0,2*63"
    ]

  # @decoded = [
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781258"}, "nmea": ["!AIVDM,1,1,,B,B3MA@I007?sDoVW;bE=23wpUoP06,0*4B"], "decoded": {"msg_type": 18, "repeat": 0, "mmsi": 232018020, "reserved_1": 0, "speed": 2.8, "accuracy": True, "lon": -4.084138, "lat": 50.207285, "course": 105.6, "heading": 511, "second": 49, "reserved_2": 0, "cs": True, "display": False, "dsc": True, "band": True, "msg22": True, "assigned": False, "raim": True, "radio": 917510}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 58, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781259"}, "nmea": ["!AIVDM,1,1,,A,33aKV05P00PG@O@N7gI@0?wT2>`<,0*3C"], "decoded": {"msg_type": 3, "repeat": 0, "mmsi": 244770304, "status": <NavigationStatus.Moored: 5>, "turn": <TurnRate.NO_TI_DEFAULT: -128.0>, "speed": 0.0, "accuracy": True, "lon": 5.080707, "lat": 52.640168, "course": 0.0, "heading": 511, "second": 50, "maneuver": <ManeuverIndicator.NotAvailable: 0>, "spare_1": b"\x00", "raim": True, "radio": 59916}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 59, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781249"}, "nmea": ["!AIVDM,1,1,,B,B3MA@I007?sDoVW;bE=23wpUoP06,0*4B"], "decoded": {"msg_type": 18, "repeat": 0, "mmsi": 232018020, "reserved_1": 0, "speed": 2.8, "accuracy": True, "lon": -4.084138, "lat": 50.207285, "course": 105.6, "heading": 511, "second": 49, "reserved_2": 0, "cs": True, "display": False, "dsc": True, "band": True, "msg22": True, "assigned": False, "raim": True, "radio": 917510}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 49, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781259"}, "nmea": ["!AIVDM,1,1,,B,13cgCP0wi`176I0EgB<7U61L0>`<,0*10"], "decoded": {"msg_type": 1, "repeat": 0, "mmsi": 247190400, "status": <NavigationStatus.UnderWayUsingEngine: 0>, "turn": -0.0, "speed": 10.4, "accuracy": False, "lon": 15.532, "lat": 37.991333, "course": 194.0, "heading": 192, "second": 46, "maneuver": <ManeuverIndicator.NotAvailable: 0>, "spare_1": b"\x00", "raim": False, "radio": 59916}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 59, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781259"}, "nmea": ["!AIVDM,1,1,,A,B5NWW<P00=kd7T6t:c2uOwq5oP06,0*3B"], "decoded": {"msg_type": 18, "repeat": 0, "mmsi": 367650610, "reserved_1": 0, "speed": 0.0, "accuracy": True, "lon": -122.60532, "lat": 48.514853, "course": 303.1, "heading": 511, "second": 50, "reserved_2": 0, "cs": True, "display": False, "dsc": True, "band": True, "msg22": True, "assigned": False, "raim": True, "radio": 917510}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 59, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781258"}, "nmea": ["!AIVDM,1,1,,B,H0qH9Wl000000000000000000000,0*56"], "decoded": {"msg_type": 24, "repeat": 0, "mmsi": 60164511, "partno": 1, "ship_type": 0, "vendorid": "", "model": 0, "serial": 0, "callsign": "", "to_bow": 0, "to_stern": 0, "to_port": 0, "to_starboard": 0, "spare_1": b"\x00"}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 58, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781258"}, "nmea": ["!AIVDM,1,1,,B,13MC:58P00WK=P>0fG=@kwwT2>`<,0*02"], "decoded": {"msg_type": 1, "repeat": 0, "mmsi": 232049172, "status": <NavigationStatus.UnderWaySailing: 8>, "turn": <TurnRate.NO_TI_DEFAULT: -128.0>, "speed": 0.0, "accuracy": True, "lon": 103.811425, "lat": 1.266008, "course": 20.7, "heading": 511, "second": 50, "maneuver": <ManeuverIndicator.NotAvailable: 0>, "spare_1": b"\x00", "raim": True, "radio": 59916}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 58, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781250"}, "nmea": ["!AIVDM,1,1,,A,B4hE8f000889fWV?448l7wq5oP06,0*1B"], "decoded": {"msg_type": 18, "repeat": 0, "mmsi": 319113400, "reserved_1": 0, "speed": 0.0, "accuracy": True, "lon": 7.123332, "lat": 43.588377, "course": 83.3, "heading": 511, "second": 50, "reserved_2": 0, "cs": True, "display": False, "dsc": True, "band": True, "msg22": True, "assigned": False, "raim": True, "radio": 917510}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 50, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781258"}, "nmea": ["!AIVDM,1,1,,A,13m`WR00001G4VLWpb5d8p9l00T9,0*10"], "decoded": {"msg_type": 1, "repeat": 0, "mmsi": 257566600, "status": <NavigationStatus.UnderWayUsingEngine: 0>, "turn": 0.0, "speed": 0.0, "accuracy": False, "lon": 19.021143, "lat": 69.70457, "course": 310.7, "heading": 260, "second": 58, "maneuver": <ManeuverIndicator.NotAvailable: 0>, "spare_1": b"\x00", "raim": False, "radio": 2313}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 58, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781258"}, "nmea": ["!AIVDM,1,1,,B,H3@pcu4TCBD:MfPH@9kopj10321t,0*76"], "decoded": {"msg_type": 24, "repeat": 0, "mmsi": 219032564, "partno": 1, "ship_type": 36, "vendorid": "SRT", "model": 2, "serial": 646048, "callsign": "XPI3782", "to_bow": 8, "to_stern": 3, "to_port": 2, "to_starboard": 1, "spare_1": b"\xf0"}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 58, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781257"}, "nmea": ["!AIVDM,1,1,,B,177>p2002@0DOq:QO@5=EbWj0<07,0*2D"], "decoded": {"msg_type": 1, "repeat": 0, "mmsi": 477345800, "status": <NavigationStatus.UnderWayUsingEngine: 0>, "turn": 0.0, "speed": 14.4, "accuracy": False, "lon": 4.477928, "lat": 58.525047, "course": 341.4, "heading": 339, "second": 57, "maneuver": <ManeuverIndicator.NotAvailable: 0>, "spare_1": b"\x00", "raim": False, "radio": 49159}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 57, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781243"}, "nmea": ["!AIVDM,1,1,,B,16<g:S@P008WWQL=oR67rwwF0@H6,0*1E"], "decoded": {"msg_type": 1, "repeat": 0, "mmsi": 416008845, "status": <NavigationStatus.UnderWayUsingEngine: 0>, "turn": <TurnRate.NO_TI_DEFAULT: -128.0>, "speed": 0.0, "accuracy": False, "lon": 120.50269, "lat": 24.23556, "course": 202.7, "heading": 511, "second": 43, "maneuver": <ManeuverIndicator.NotAvailable: 0>, "spare_1": b"\x00", "raim": False, "radio": 67078}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 43, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781258"}, "nmea": ["!AIVDM,1,1,,B,B52OcB@00=pLF>4o3TbF;wpUoP06,0*7F"], "decoded": {"msg_type": 18, "repeat": 0, "mmsi": 338160457, "reserved_1": 0, "speed": 0.0, "accuracy": True, "lon": -118.45158, "lat": 33.97559, "course": 240.2, "heading": 511, "second": 49, "reserved_2": 0, "cs": True, "display": False, "dsc": True, "band": True, "msg22": True, "assigned": False, "raim": True, "radio": 917510}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 58, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781258"}, "nmea": ["!AIVDM,1,1,,A,35R`V2002t0hVidVBtvPiPcl83Wk,0*74"], "decoded": {"msg_type": 3, "repeat": 0, "mmsi": 371861000, "status": <NavigationStatus.UnderWayUsingEngine: 0>, "turn": 0.0, "speed": 18.8, "accuracy": False, "lon": 10.618117, "lat": 66.92735, "course": 19.8, "heading": 21, "second": 58, "maneuver": <ManeuverIndicator.NotAvailable: 0>, "spare_1": b"@", "raim": False, "radio": 14835}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 58, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781250"}, "nmea": ["!AIVDM,1,1,,B,13kigf00111<frBP4`lBE1kT0>`<,0*4C"], "decoded": {"msg_type": 1, "repeat": 0, "mmsi": 255619000, "status": <NavigationStatus.UnderWayUsingEngine: 0>, "turn": 0.0, "speed": 6.5, "accuracy": False, "lon": 16.762575, "lat": 56.050695, "course": 59.6, "heading": 57, "second": 50, "maneuver": <ManeuverIndicator.NotAvailable: 0>, "spare_1": b"\x00", "raim": False, "radio": 59916}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 50, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781259"}, "nmea": ["!AIVDM,1,1,,B,H42O>ClU9=1B9>5I=1jnqm00?050,0*72"], "decoded": {"msg_type": 24, "repeat": 0, "mmsi": 271044175, "partno": 1, "ship_type": 37, "vendorid": "IMA", "model": 4, "serial": 562053, "callsign": "YMA2695", "to_bow": 0, "to_stern": 15, "to_port": 0, "to_starboard": 5, "spare_1": b"\x00"}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 59, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781258"}, "nmea": ["!AIVDM,1,1,,B,13@oJQOu@IOgww<NdU2A3PuP0>`<,0*2C"], "decoded": {"msg_type": 1, "repeat": 0, "mmsi": 219011717, "status": <NavigationStatus.Undefined: 15>, "turn": -5.0, "speed": 2.5, "accuracy": False, "lon": -3.495297, "lat": 53.646095, "course": 27.0, "heading": 30, "second": 48, "maneuver": <ManeuverIndicator.NotAvailable: 0>, "spare_1": b"\x00", "raim": False, "radio": 59916}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 58, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781204"}, "nmea": ["!AIVDM,1,1,,A,15Nd;9dOh3qTO`t@t`8:bbb80d4P,0*38"], "decoded": {"msg_type": 1, "repeat": 0, "mmsi": 367725350, "status": <NavigationStatus.Undefined: 15>, "turn": <TurnRate.NO_TI_RIGHT: 127.0>, "speed": 0.3, "accuracy": True, "lon": -89.894777, "lat": 29.617547, "course": 273.0, "heading": 341, "second": 4, "maneuver": <ManeuverIndicator.NotAvailable: 0>, "spare_1": b"\x00", "raim": False, "radio": 180512}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 4, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781259"}, "nmea": ["!AIVDM,1,1,,B,H5MCJcTTCBD6v:w00000001P1140,0*62"], "decoded": {"msg_type": 24, "repeat": 0, "mmsi": 366271150, "partno": 1, "ship_type": 36, "vendorid": "SRT", "model": 1, "serial": 778943, "callsign": "", "to_bow": 12, "to_stern": 1, "to_port": 1, "to_starboard": 4, "spare_1": b"\x00"}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 59, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire"}, "nmea": ["!AIVDM,2,1,3,A,53aDr3D000010KW?780Tp4000000000000000016;h<66v8605RiB3000000,0*62", "!AIVDM,2,2,3,A,00000000000,2*27"], "decoded": {"msg_type": 5, "repeat": 0, "mmsi": 244660749, "ais_version": 1, "imo": 0, "callsign": "PF9312", "shipname": "INA", "ship_type": <ShipType.Cargo: 70>, "to_bow": 94, "to_stern": 12, "to_port": 6, "to_starboard": 6, "epfd": <EpfdType.Undefined: 0>, "month": 8, "day": 16, "hour": 6, "minute": 0, "draught": 2.2, "destination": "KEHL", "dte": False, "spare_1": b"\x00"}, "timestamp": None},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781259"}, "nmea": ["!AIVDM,1,1,,B,B3KF;DP0AH:tsSWhAuRAKwq5oP06,0*78"], "decoded": {"msg_type": 18, "repeat": 0, "mmsi": 230001490, "reserved_1": 0, "speed": 6.9, "accuracy": True, "lon": 9.570038, "lat": 54.20708, "course": 232.6, "heading": 511, "second": 50, "reserved_2": 0, "cs": True, "display": False, "dsc": True, "band": True, "msg22": True, "assigned": False, "raim": True, "radio": 917510}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 59, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781259"}, "nmea": ["!AIVDM,1,1,,A,H3TmNt4U>F36Ie5CF1nqpn106440,0*69"], "decoded": {"msg_type": 24, "repeat": 0, "mmsi": 239951600, "partno": 1, "ship_type": 37, "vendorid": "NVC", "model": 1, "serial": 629573, "callsign": "SVA6986", "to_bow": 8, "to_stern": 6, "to_port": 4, "to_starboard": 4, "spare_1": b"\x00"}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 59, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781258"}, "nmea": ["!AIVDM,1,1,,A,H3tfbw4U1=30000C6plhoP000000,0*3A"], "decoded": {"msg_type": 24, "repeat": 0, "mmsi": 265005820, "partno": 1, "ship_type": 37, "vendorid": "AMC", "model": 0, "serial": 0, "callsign": "SF8407", "to_bow": 0, "to_stern": 0, "to_port": 0, "to_starboard": 0, "spare_1": b"\x00"}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 58, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781258"}, "nmea": ["!AIVDM,1,1,,A,H3tfbw4U1=30000C6plhoP000000,0*3A"], "decoded": {"msg_type": 24, "repeat": 0, "mmsi": 265005820, "partno": 1, "ship_type": 37, "vendorid": "AMC", "model": 0, "serial": 0, "callsign": "SF8407", "to_bow": 0, "to_stern": 0, "to_port": 0, "to_starboard": 0, "spare_1": b"\x00"}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 58, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781258"}, "nmea": ["!AIVDM,1,1,,B,H7OmE<4UCBD:MWEDB5CEB500000t,0*46"], "decoded": {"msg_type": 24, "repeat": 0, "mmsi": 503141680, "partno": 1, "ship_type": 37, "vendorid": "SRT", "model": 2, "serial": 645589, "callsign": "TRESURE", "to_bow": 0, "to_stern": 0, "to_port": 0, "to_starboard": 0, "spare_1": b"\xf0"}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 58, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire", "s": "terrestrial", "c": "1692781259"}, "nmea": ["!AIVDM,1,1,,B,16K3J3@0009`3>lCm0O9WbCP0>`<,0*77"], "decoded": {"msg_type": 1, "repeat": 0, "mmsi": 431020557, "status": <NavigationStatus.UnderWayUsingEngine: 0>, "turn": 0.0, "speed": 0.0, "accuracy": False, "lon": 134.578283, "lat": 34.652367, "course": 246.2, "heading": 329, "second": 48, "maneuver": <ManeuverIndicator.NotAvailable: 0>, "spare_1": b"\x00", "raim": False, "radio": 59916}, "timestamp": datetime.datetime(2023, 8, 23, 9, 0, 59, tzinfo=datetime.timezone.utc)},
  #   {"tags": {"p": "spire"}, "nmea": ["!AIVDM,2,1,4,B,55BPGR02A<po<HHk>21`DIU8u>2222222222221IBPS<D5lA5<Ai0CTjp43k,0*7D", "!AIVDM,2,2,4,B,0CQ88888880,2*39"], "decoded": {"msg_type": 5, "repeat": 0, "mmsi": 354949000, "ais_version": 0, "imo": 9515917, "callsign": "3FFL3", "shipname": "ZEFYROS", "ship_type": <ShipType.Tanker_NoAdditionalInformation: 89>, "to_bow": 148, "to_stern": 35, "to_port": 12, "to_starboard": 20, "epfd": <EpfdType.GPS: 1>, "month": 7, "day": 8, "hour": 17, "minute": 5, "draught": 4.9, "destination": "GDANSK POLAND", "dte": False, "spare_1": b"\x00"}, "timestamp": None},
  #   {"tags": {"p": "spire"}, "nmea": ["!AIVDM,2,1,5,B,548bmt01iETdiW??760M9Dl4qB2222222222221@8P?3;5<P0?Rk0BD1A0H8,0*5F", "!AIVDM,2,2,5,B,88888888880,2*22"], "decoded": {"msg_type": 5, "repeat": 0, "mmsi": 277526000, "ais_version": 0, "imo": 7427659, "callsign": "LY3311", "shipname": "GRUMANT", "ship_type": <ShipType.Tanker: 80>, "to_bow": 68, "to_stern": 15, "to_port": 3, "to_starboard": 11, "epfd": <EpfdType.GPS: 1>, "month": 4, "day": 25, "hour": 0, "minute": 0, "draught": 6.2, "destination": "KLAIPEDA", "dte": False, "spare_1": b"\x00"}, "timestamp": None}
  # ]

  describe "decode messages" do
  #   test "all" do
  #     {decoded, groups} =
  #       Portal.Data.Ais.Decoder.decode_messages(@messages, %{
  #         fragment: "",   # Used to handle fragmented messages
  #         decoded: [],
  #         groups: %{}     # Map of list of grouped messages keyed by group id
  #       })

  #     assert Enum.count(decoded) == 29
  #   end

  #   test "spire group" do
  #     {decoded, groups} =
  #       Portal.Data.Ais.Decoder.decode_messages(
  #         ["\\p:spire,g:1-2-40348012,s:terrestrial,c:1692880962*22\\!AIVDM,2,1,2,B,53M@a:H00000l5acV20T<DpV0hDLDpB22222220`0`B4467@S5S58;H1ikmi,0*52",
  #          "\\p:spire,g:2-2-40348012*55\\!AIVDM,2,2,2,B,`;H35888880,2*08",
  #          "\\p:spire,g:1-2-3269328,s:terrestrial,c:1694649009*14\\!AIVDM,2,1,8,B,59NSDF82ASwDCD<SR2104<THT>1`U8<tr222221@B`QE;6K@0BkS4U3H8888,0*74",
  #          "\\p:spire,s:spire,g:2-2-3269328*6A\\!AIVDM,2,2,8,B,88888888880,2*2F",],
  #         %{
  #           fragment: "",   # Used to handle fragmented messages
  #           decoded: [],
  #           groups: %{}     # Map of list of grouped messages keyed by group id
  #         })
  #     IO.inspect(decoded, label: "group")
  #     assert Enum.count(decoded) == 2
  #   end

    test "group" do
      IO.inspect(AIS.Decoder.decode_message("\\p:orbcomm,g:1-2-8641949,s:terrestrial,c:1694768536*17\\!AIVDM,2,1,9,A,53m9Vi400000hULJ220TpLD8u8N10h5@uF22220l0p:3240Ht03lk3iRSlQ1,0*0A", %{groups: %{}, latest: DateTime.from_unix(0)}))
    end
  end

  describe "decode tags" do

    test "decode provider" do
      tags = AIS.Decoder.decode_tags("p:spire,g:1-2-40348012,s:terrestrial,c:1692880962*22")
      IO.inspect(tags, label: "tags")

      tags = AIS.Decoder.decode_tags("p:spire,g:2-2-40348012*55")
      IO.inspect(tags, label: "tags")
    end

  end

end
