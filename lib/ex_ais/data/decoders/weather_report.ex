defmodule ExAis.Data.Decoders.WeatherReport do
  @moduledoc """
  Parses DAC 1, FI 31 (weather) AIS payload into raw numeric field values.
  """

  import Bitwise

  defstruct [
    :air_pressure_hpa,
    :air_pressure_trend,
    :air_temp_c,
    :current_direction_2,
    :current_direction_3,
    :current_measuring_level_2,
    :current_measuring_level_3,
    :current_speed_2,
    :current_speed_3,
    :dew_point_c,
    :horizontal_range,
    :horizontal_visibility_at_range,
    :horizontal_visibility_nm,
    :humidity_percent,
    :ice,
    :lat_deg,
    :lon_deg,
    :pos_accuracy,
    :precipitation_type,
    :salinity,
    :sea_state,
    :significant_wave_height,
    :surface_current_direction,
    :surface_current_speed,
    :swell_direction,
    :swell_height,
    :swell_period,
    :utc_day,
    :utc_hour,
    :utc_minute,
    :water_level_trend,
    :water_level,
    :water_temperature_c,
    :wave_direction,
    :wave_period,
    :wind_dir_deg,
    :wind_gust_dir_deg,
    :wind_gust_knots,
    :wind_speed_knots
  ]

  @doc """
  Decode the *application payload* (already past the 56-bit Type 8 header).
  """
  def from_binary(<<
        lon::signed-25,
        lat::signed-24,
        pos_accuracy::1,
        utc_day::5,
        utc_hour::5,
        utc_min::6,
        wind_speed::7,
        wind_gust::7,
        wind_dir::9,
        gust_dir::9,
        air_temp::signed-11,
        humidity::7,
        dew_point::signed-10,
        pressure::9,
        pressure_trend::2,
        horizontal_visibility::8,
        water_level::12,
        water_level_trend::2,
        surface_current_speed::8,
        surface_current_direction::9,
        current_speed_2::8,
        current_direction_2::9,
        current_measuring_level_2::5,
        current_speed_3::8,
        current_direction_3::9,
        current_measuring_level_3::5,
        significant_wave_height::8,
        wave_period::6,
        wave_direction::9,
        swell_height::8,
        swell_period::6,
        swell_direction::9,
        sea_state::4,
        water_temperature_c::signed-10,
        precipitation_type::3,
        salinity::9,
        ice::2,
        _rest::bitstring
      >>) do
    %__MODULE__{
      air_pressure_hpa: decode_offset(pressure, 511, 800),
      air_pressure_trend: decode_list(:pressure, pressure_trend),
      air_temp_c: decode_div10(air_temp, 2047),
      current_direction_2: decode_angle(current_direction_2),
      current_direction_3: decode_angle(current_direction_3),
      current_measuring_level_2: decode_simple(current_measuring_level_2, 31),
      current_measuring_level_3: decode_simple(current_measuring_level_3, 31),
      current_speed_2: decode_scaled(current_speed_2, 255, 0.1),
      current_speed_3: decode_scaled(current_speed_3, 255, 0.1),
      dew_point_c: decode_div10(dew_point, 1023),
      humidity_percent: decode_simple(humidity, 100),
      ice: decode_yes_no(ice),
      lat_deg: decode_coord(lat),
      lon_deg: decode_coord(lon),
      pos_accuracy: if(pos_accuracy == 1, do: :high, else: :low),
      precipitation_type: decode_list(:precipitation, precipitation_type),
      salinity: decode_scaled(salinity, 511, 0.1),
      sea_state: decode_simple(sea_state, 13),
      significant_wave_height: decode_scaled(significant_wave_height, 255, 0.1),
      surface_current_direction: decode_angle(surface_current_direction),
      surface_current_speed: decode_scaled(surface_current_speed, 255, 0.1),
      swell_direction: decode_angle(swell_direction),
      swell_height: decode_scaled(swell_height, 255, 0.1),
      swell_period: decode_simple(swell_period, 63),
      utc_day: decode_simple(utc_day, 0),
      utc_hour: decode_simple(utc_hour, 24),
      utc_minute: decode_simple(utc_min, 60),
      water_level_trend: decode_list(:water_level, water_level_trend),
      water_level: decode_scaled(water_level, 4001, 1.0),
      water_temperature_c: decode_div10(water_temperature_c, 1023),
      wave_direction: decode_angle(wave_direction),
      wave_period: decode_simple(wave_period, 63),
      wind_dir_deg: decode_angle(wind_dir),
      wind_gust_dir_deg: decode_angle(gust_dir),
      wind_gust_knots: decode_simple(wind_gust, 127),
      wind_speed_knots: decode_simple(wind_speed, 127)
    }
    |> Map.merge(decode_horizontal_visibility(horizontal_visibility))
  end

  defp decode_angle(val) when is_integer(val) and val < 360, do: val
  defp decode_angle(_val), do: nil

  defp decode_coord(val), do: val / 60_000.0

  defp decode_div10(na, na), do: nil
  defp decode_div10(val, _na), do: val / 10.0

  defp decode_horizontal_visibility(127),
    do: %{horizontal_visibility_nm: nil, horizontal_visibility_at_range: false}

  defp decode_horizontal_visibility(val) do
    %{
      horizontal_visibility_nm: band(val, 0b01111111) * 0.1,
      horizontal_visibility_at_range: val >>> 7 == 1
    }
  end

  defp decode_list(:pressure, 0), do: :steady
  defp decode_list(:pressure, 1), do: :increasing
  defp decode_list(:pressure, 2), do: :decreasing
  defp decode_list(:pressure, _), do: nil
  defp decode_list(:water_level, 0), do: :steady
  defp decode_list(:water_level, 1), do: :increasing
  defp decode_list(:water_level, 2), do: :decreasing
  defp decode_list(:water_level, _), do: nil
  defp decode_list(:precipitation, 1), do: :rain
  defp decode_list(:precipitation, 2), do: :thunderstorm
  defp decode_list(:precipitation, 3), do: :freezing_rain
  defp decode_list(:precipitation, 4), do: :mixed_ice
  defp decode_list(:precipitation, 5), do: :snow
  defp decode_list(:precipitation, _), do: nil

  defp decode_offset(na, na, _offset), do: nil
  defp decode_offset(val, _na, offset), do: val + offset

  defp decode_scaled(na, na, _scale), do: nil
  defp decode_scaled(val, _na, scale), do: val * scale

  defp decode_simple(na, na), do: nil
  defp decode_simple(val, _na), do: val

  defp decode_yes_no(0), do: :no
  defp decode_yes_no(1), do: :yes
  defp decode_yes_no(_), do: nil
end
