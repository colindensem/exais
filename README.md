# AIS

AIS Library in Elixir. This library can decode the common NMEA 0183 v4.0 format sentences relating to AIS. It also handles
the tag block prefix common to satellite AIS providers such as Spire:
```
\c:1503079500*55\!AIVDM,1,1,,B,C6:b0Kh09b3t1K4ChsS2FK008NL>`2CT@2N000000000S4h8S400,0*50
```
and message groups. 

It also provides a number of components for building and maintaining an in memory state based upon the processed AIS data:

```elixir
%AIS.Data.AisState{
  vessels: %{},                   # A list of current vessels
  position_updates: [],           # The latest position updates
  trips: %{},                     # A list of current trips
  trip_updates: [],               # The latest trip updates
  index: QuadKeyTree.create(),    # A quad-tree geospatial index of vessel potions
  latest: %{}                     # The timestamps of the latest updates for each data provider
}
```

The `AIS.Processor` GenServer is the process for creating and maintaining this state.

It provides a number of callbacks for creating and querying state:

* `handle_call({:decoded, decoded}, _from, state)`: update state given a list of decoded messages
* `handle_call({:get_tile, x, y, z}, _from, state)`: get all vessels for a given web mercator map tile
* `handle_call({:get_entity, id}, _from, state)`: get the details for a given entity id

Decoded messages presented to `handle_call({:decoded, decoded}, _, _)` take the form:

```elixir
%{
  :mmsi => 636016337,
  :timestamp => ~U[2024-02-15 14:30:46Z],
  :ship_type => 70,
  :formatter => "VDM",
  "q" => "",
  "g" => "1-2-20395571",
  "c" => "1708007446",
  :padding => "0",
  :dimension_to_stern => 29,
  :destination => "PABLB",
  :repeat_indicator => 1,
  :position_fix_type => 1,
  :eta => %{month: 2, day: 14, minute: 0, hour: 20},
  :channel => "A",
  :sequential => "1",
  :name => "EVANGELIA D",
  "p" => "spire",
  :dte => 0,
  :dimension_to_starboard => 13,
  :current => "1",
  :msg_type => 5,
  :checksum => "16",
  "s" => "",
  :dimension_to_port => 19,
  :spare => 0,
  :imo_number => 9689184,
  :call_sign => "D5FQ3",
  :payload => "5INSFlH2Cn60CDI7>20EH4pLDhT60B2222222216EHMC=4WD0ND0@S0`888888888888880",
  :draught => 12.1,
  :ais_version_indicator => 2,
  :talker => "!AI",
  :dimension_to_bow => 171,
  :total => "1"
}
```