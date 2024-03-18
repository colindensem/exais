defmodule AIS.Geo.Util do
  import Bitwise

  @doc """
  Get the Quadkey for a tile. A quadkey encodes a square region in lat/lon
  space organised by zoom levels. Each quadkey has a single digit code 0..3.
  The concatenation of quadkeys at each zoom level gives the complete quadkey
  for a lat/lon tile at the given zoom.

  For example: Galway is in Quadkey 0313102310 = Tile {486, 332} at zoom 10
  """
  def quadkey({x, y}, z) do
    Enum.to_list(z..1//-1)
    Enum.reduce(Enum.to_list(z..1//-1), "",
      fn z, acc ->
         mask = 1 <<< (z- 1)
         digit = if (x &&& mask) > 0, do: 1, else: 0
         digit = if (y &&& mask) > 0, do: digit + 2, else: digit
         acc <> "#{digit}"
      end)
  end

  @doc """
  Get the tile containing lat/lon point at given zoom
  """
  def tile(lon, lat, z) do
  {trunc(:math.floor(mercator_x(z, lon) / 256)), trunc(:math.floor(mercator_y(z, lat) / 256))}
  end

  def mercator_x(z, lon) do
    world_size(z) * ((lon/360) + 0.5)
  end

  def mercator_y(z, lat) do
    world_size(z) * (1 - (:math.log(:math.tan(:math.pi() * ((lat / 360) + 0.25))) / :math.pi())) / 2
  end

  defp world_size(z) do
    :math.pow(2, z) * 256
  end
end
