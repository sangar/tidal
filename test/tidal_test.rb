require "test_helper"
require "json"

class TidalTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Tidal::VERSION
  end

  def test_get_data_by_search
    tidal_data = Tidal.for(latitude: 59.9128627, longitude: 10.7434443)

    assert_equal 5, tidal_data.count
  end
end
