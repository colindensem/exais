defmodule ExAis.Data.Decoders.WeatherReport do
  @moduledoc """
  Parses DAC 1, FI 31 (weather) AIS payload into raw numeric field values.
  """

  import Bitwise

  defstruct [
    :pos_accuracy,
    :lon_deg,
    :lat_deg,
    :utc_day,
    :utc_hour,
    :utc_minute,
    :wind_speed_knots,
    :wind_gust_knots,
    :wind_dir_deg,
    :gust_dir_deg,
    :air_temp_c,
    :humidity_percent,
    :dew_point_c,
    :pressure_hpa,
    :pressure_trend,
    :horizontal_visibility_nm,
    :horizontal_visibility_at_range,
    :horizontal_range,
    :water_level,
    :water_level_trend,
    :surface_current_speed,
    :surface_current_direction,
    :current_speed_2,
    :current_direction_2,
    :current_measuring_level_2,
    :current_speed_3,
    :current_direction_3,
    :current_measuring_level_3,
    :significant_wave_height,
    :wave_period,
    :wave_direction,
    :swell_height,
    :swell_period,
    :swell_direction,
    :sea_state,
    :water_temperature_c,
    :precipitation_type,
    :salinity,
    :ice
  ]

  def from_binary(<<
        pos_acc::1,
        lon::25,
        lat::24,
        utc_day::5,
        utc_hour::5,
        utc_min::6,
        wind_speed::7,
        wind_gust::7,
        wind_dir::9,
        gust_dir::9,
        air_temp::11,
        humidity::7,
        dew_point::10,
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
        water_temperature_c::10,
        precipitation_type::3,
        salinity::9,
        ice::2,
        _rest::bitstring
      >>) do
    %__MODULE__{
      pos_accuracy: pos_acc,
      lon_deg: decode_coord(lon, 25),
      lat_deg: decode_coord(lat, 24),
      utc_day: decode_simple(utc_day, 0),
      utc_hour: decode_simple(utc_hour, 24),
      utc_minute: decode_simple(utc_min, 60),
      wind_speed_knots: decode_simple(wind_speed, 127),
      wind_gust_knots: decode_simple(wind_gust, 127),
      wind_dir_deg: decode_angle(wind_dir),
      gust_dir_deg: decode_angle(gust_dir),
      air_temp_c: decode_signed_scaled(air_temp, 2047, -60, 0.1),
      humidity_percent: decode_simple(humidity, 101),
      dew_point_c: decode_signed_scaled(dew_point, 1023, -20, 0.1),
      pressure_hpa: decode_offset(pressure, 511, 800),
      pressure_trend: decode_list(:pressure, pressure_trend),
      water_level: decode_scaled(water_level, 511, 0.1),
      water_level_trend: decode_list(:water_level, water_level_trend),
      surface_current_speed: decode_scaled(surface_current_speed, 255, 0.1),
      surface_current_direction: decode_angle(surface_current_direction),
      current_speed_2: decode_scaled(current_speed_2, 255, 0.1),
      current_direction_2: decode_angle(current_direction_2),
      current_measuring_level_2: decode_simple(current_measuring_level_2, 31),
      current_speed_3: decode_scaled(current_speed_3, 255, 0.1),
      current_direction_3: decode_angle(current_direction_3),
      current_measuring_level_3: decode_simple(current_measuring_level_3, 31),
      significant_wave_height: decode_scaled(significant_wave_height, 255, 0.1),
      wave_period: decode_simple(wave_period, 63),
      wave_direction: decode_angle(wave_direction),
      swell_height: decode_scaled(swell_height, 255, 0.1),
      swell_period: decode_simple(swell_period, 63),
      swell_direction: decode_angle(swell_direction),
      sea_state: decode_simple(sea_state, 13),
      water_temperature_c: decode_signed_scaled(water_temperature_c, 1023, -10, 0.1),
      precipitation_type: decode_list(:precipitation, precipitation_type),
      salinity: decode_scaled(salinity, 255, 0.1),
      ice: decode_yes_no(ice)
    }
    |> Map.merge(decode_horizontal_visibility(horizontal_visibility))
  end

  defp decode_coord(val, bits) do
    max = 1 <<< (bits - 1)
    signed = if val >= max, do: val - (1 <<< bits), else: val
    signed * 0.0001 / 60.0
  end

  defp decode_angle(val) when is_integer(val) and val < 360,
    do: val

  defp decode_angle(_val), do: nil
  defp decode_simple(val, na), do: if(val == na, do: nil, else: val)

  defp decode_signed_scaled(val, na, offset, scale),
    do: if(val == na, do: nil, else: val * scale + offset)

  defp decode_scaled(val, na, scale),
    do: if(val == na, do: nil, else: val * scale)

  defp decode_offset(val, na, offset),
    do: if(val == na, do: nil, else: val + offset)

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
  defp decode_yes_no(0), do: :no
  defp decode_yes_no(1), do: :yes
  defp decode_yes_no(_), do: nil

  defp decode_horizontal_visibility(127),
    do: %{horizontal_visibility_nm: nil, horizontal_visibility_at_range: false}

  defp decode_horizontal_visibility(val) do
    %{
      horizontal_visibility_nm: band(val, 0b01111111) * 0.1,
      horizontal_visibility_at_range: val >>> 7 == 1
    }
  end
end
