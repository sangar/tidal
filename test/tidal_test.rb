require "test_helper"
require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
end

class TidalTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Tidal::VERSION
  end

  def test_get_data_by_search
    VCR.use_cassette("test_get_data_by_search") do
      tidal_data = Tidal.for(
          latitude: 59.9128627,
          longitude: 10.7434443,
          date: DateTime.parse("2025-01-29T09:33:37+01:00")
        )

      assert_equal 6, tidal_data.count

      location = tidal_data["location"]
      assert_equal "Oslo", location["name"]
      assert_equal "OSL", location["code"]
      assert_equal 59.912863, location["latitude"]
      assert_equal 10.743444, location["longitude"]
      assert_equal 0, location["delay"]
      assert_equal 1.0, location["factor"]
      assert_equal "Oslo", location["obsname"]
      assert_equal "OSL", location["obscode"]
      assert_equal "Tides and observed water level from Oslo", location["descr"]

      obs = tidal_data["obs"]
      assert_equal 57, obs.count
      assert_equal 74.2, obs[0]["value"]
      assert_equal 75.1, obs[1]["value"]

      pre = tidal_data["pre"]
      assert_equal 433, pre.count
      assert_equal 60.9, pre[0]["value"]
      assert_equal 61.9, pre[1]["value"]

      weathereffect = tidal_data["weathereffect"]
      assert_equal 57, weathereffect.count
      assert_equal 13.3, weathereffect[0]["value"]
      assert_equal 13.1, weathereffect[1]["value"]

      forecast = tidal_data["forecast"]
      assert_equal 433, forecast.count
      assert_equal 61.9, forecast[0]["value"]
      assert_equal 59.9, forecast[1]["value"]

      highlow = tidal_data["highlow"]
      assert_equal 23, highlow.count
      assert_equal 85.5, highlow[0]["value"]
      assert_equal Time.parse("2025-01-29T05:24:00+01:00").to_datetime, highlow[0]["time"]
      assert_equal 53.0, highlow[1]["value"]
      assert_equal Time.parse("2025-01-29T10:33:00+01:00").to_datetime, highlow[1]["time"]
    end
  end

  def test_get_data_by_search_2
    VCR.use_cassette("test_get_data_by_search_2") do
      tidal_data = Tidal.for(
          latitude: 58.973981,
          longitude: 5.731113,
          date: DateTime.parse("2021-02-19T19:33:37+01:00")
        )
      assert_equal 6, tidal_data.count
    end
  end

  def test_invalid_data
    assert_raises "No station data available!" do
      VCR.use_cassette("test_invalid_data") do
        tidal_data = Tidal.for(
            latitude: 58.44418,
            longitude: 5.99778,
            date: DateTime.parse("2021-02-19T19:33:37+01:00")
          )
        assert_equal 6, tidal_data.count
      end
    end
  end
end
