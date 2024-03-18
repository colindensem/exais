# AIS

AIS Library in Elixir. This library can decode the common NMEA 0183 v4.0 format sentences relating to AIS. It also handles
the tag block prefix common to satellite AIS providers such as Spire:
```
\c:1503079500*55\!AIVDM,1,1,,B,C6:b0Kh09b3t1K4ChsS2FK008NL>`2CT@2N000000000S4h8S400,0*50
```
and message groups. 