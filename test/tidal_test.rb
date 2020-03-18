require "test_helper"
require "json"

class TidalTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Tidal::VERSION
  end

  def test_get_data_by_search
    tidal_data = Tidal.for(latitude: 59.9128627, longitude: 10.7434443)

    assert_equal 6, tidal_data.count
  end

  def test_invalid_data
    tidal_data = Tidal.for(latitude: 58.44418, longitude: 5.99778)

    assert_equal 1, tidal_data.count
  end
end
