defmodule ExAIS.UtilTest do
  use ExUnit.Case

  alias ExAIS.Data.Country

  describe "country flags" do
    test "get flag" do
      flag = Country.get_flag("775")
      assert flag == "VE"
    end
  end
end
