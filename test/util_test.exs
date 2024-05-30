defmodule ExAIS.UtilTest do
  use ExUnit.Case

  describe "country flags" do

    test "get flag" do
      flag = ExAIS.Data.Country.get_flag("775")
      assert flag == "VE"
    end
  end
end
