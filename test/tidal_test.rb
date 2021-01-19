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
      tidal_data = Tidal.for(latitude: 59.9128627, longitude: 10.7434443)
      assert_equal 6, tidal_data.count
    end
  end

  def test_get_data_by_search_2
    VCR.use_cassette("test_get_data_by_search_2") do
      tidal_data = Tidal.for(latitude: 58.973981, longitude: 5.731113)
      assert_equal 6, tidal_data.count
    end
  end

  def test_invalid_data
    VCR.use_cassette("test_invalid_data") do
      tidal_data = Tidal.for(latitude: 58.44418, longitude: 5.99778)
      assert_equal 1, tidal_data.count
    end
  end
end
