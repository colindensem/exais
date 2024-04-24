defmodule AIS.UtilTest do
  use ExUnit.Case

  describe "geo utils" do

    test "get quakey for tile" do
      quad = AIS.Geo.Util.quadkey({486, 332}, 10)
      assert quad == "0313102310"
    end

    test "get tile containing lon, lat at zoom" do
      tile = AIS.Geo.Util.tile(-1.0, 52.0, 10)
      assert tile == {509, 338}
    end

    test "get mercator x, y at for lon, lat at zoom" do
      x = AIS.Geo.Util.mercator_x(10, -1.0)
      y = AIS.Geo.Util.mercator_y(10, 52.0)
      assert {x, y} == {130343.82222222222, 86590.11990239238}
    end
  end

  describe "country flags" do

    test "get flag" do
      flag = AIS.Data.Country.get_flag("775")
      assert flag == "VE"
    end
  end
end
