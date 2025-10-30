# ExAIS

ExAIS is an Elixir library for decoding AIS (Automatic Identification System) data transmitted by vessels via NMEA 0183 v4.0 format sentences.

## Features

- Decode standard NMEA 0183 v4.0 AIS sentences (AIVDM/AIVDO)
- Support for AIS tag blocks commonly used by satellite AIS providers (e.g., Spire)
- Handle multi-part message groups and fragmented messages
- GenServer-based decoder for concurrent message processing
- Telemetry integration for monitoring decoder performance
- Built-in checksum validation
- Support for filtering specific AIS message types

## Installation

Add `exais` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exais, "~> 0.2.1"}
  ]
end
```

## Usage

### Basic Decoding

Decode a single AIS message:

```elixir
# Simple NMEA sentence
ExAIS.Decoder.decode_nmea("!AIVDM,1,1,,B,15M67FC000G?ufbE`FepT@3n00Sa,0*5C", [1, 2, 3])

# With satellite AIS tag block
message = "\\c:1503079500*55\\!AIVDM,1,1,,B,C6:b0Kh09b3t1K4ChsS2FK008NL>`2CT@2N000000000S4h8S400,0*50"
ExAIS.Decoder.decode_message(message, %{groups: %{}, latest: DateTime.utc_now()}, ExAIS.Data.Ais.all_msg_types())
```

### Using the Decoder GenServer

The library provides a GenServer-based decoder for processing streams of AIS messages:

```elixir
# Start a decoder
decoder_opts = %{
  id: :my_decoder,
  module: ExAIS.Decoder,
  name: :my_decoder,
  batch_size: 10_000,
  processor: :my_processor,
  supervisor: MyApp.TaskSupervisor,
  msg_types: [1, 2, 3]  # Optional: filter specific message types
}

{:ok, pid} = ExAIS.Decoder.start_link(decoder_opts)

# Send messages for decoding
GenServer.cast(:my_decoder, {:decode, list_of_messages})
```

### Tag Block Support

ExAIS handles tag blocks commonly used in satellite AIS feeds:

```elixir
# Tag block format: \tag1:value1,tag2:value2*checksum\!AIVDM,...
# Supported tags:
# - c: Unix timestamp (seconds or microseconds)
# - s: Source (e.g., "terrestrial", "satellite")
# - p: Provider identifier
# - g: Group message identifier (format: "n-total-id")
# - q: Quality indicator
# - t: Text string
```

### Message Groups

ExAIS automatically handles grouped messages that span multiple sentences:

```elixir
# Multi-part messages are reassembled automatically
# Group tag format: g:1-2-12345 (message 1 of 2, group ID 12345)
```

## Supported AIS Message Types

The library supports decoding of various AIS message types. By default, all message types are processed, but you can filter to specific types when initializing a decoder.

## Development

```bash
# Install dependencies
mix deps.get

# Run tests
mix test

# Run tests with coverage
mix coveralls

# Format code
mix format

# Run static analysis
mix credo

# Generate documentation
mix docs
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. 