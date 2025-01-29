require "tidal/version"
require "date"
require "net/http"
require "time"

module Tidal
  class << self
    def for(options)
      options = merge_default_params(options)

      retval = {}

      res = get_position_data(options)
      return unless res.is_a?(Net::HTTPSuccess)
      retval["location"] = parse_position_data(res)

      res = get_tidal_data(options)
      return unless res.is_a?(Net::HTTPSuccess)
      retval.merge!(parse_tidal_data(res))

      res = get_high_low_data(options)
      return unless res.is_a?(Net::HTTPSuccess)
      retval["highlow"] = parse_high_low_data(res)

      retval
    end

    private
      def merge_default_params(options)
        {
          latitude: nil,
          longitude: nil,
          language: 'en',
          interval: 10,
          date: DateTime.now,
          referenceCode: "CD",
          place: '',
          days: 2,
        }.merge(options)
      end

      def get_position_data(options)
        uri = URI("https://www.kartverket.no" + "/api/vsl/position/")

        params = {
          latitude: options[:latitude],
          longitude: options[:longitude],
          language: options[:language],
        }
        uri.query = URI.encode_www_form(params)

        Net::HTTP.get_response(uri)
      end

      def parse_position_data(res)
        data = JSON.parse(res.body)
        result = data["result"]
        station_data = result["stationData"]

        raise "No station data available!" if station_data.nil?

        {
          "name" => station_data["name"],
          "code" => station_data["code"],
          "latitude" => station_data["latitude"].to_f,
          "longitude" => station_data["longitude"].to_f,
          "delay" => station_data["delay"],
          "factor" => station_data["factor"],
          "obsname" => station_data["obsName"],
          "obscode" => station_data["obsCode"],
          "descr" => station_data["description"],
        }
      end

      def get_tidal_data(options)
        uri = URI("https://www.kartverket.no" + "/api/vsl/waterLevels/")

        params = {
          latitude: options[:latitude],
          longitude: options[:longitude],
          language: options[:language],
          interval: options[:interval],
          fromTime: options[:date].strftime("%Y-%m-%dT00:00"),
          toTime: (options[:date] + options[:days]).strftime("%Y-%m-%dT00:00"),
          referenceCode: options[:referenceCode],
          place: options[:place],
        }
        uri.query = URI.encode_www_form(params)

        Net::HTTP.get_response(uri)
      end

      def parse_tidal_data(res)
        retval = {
          "obs" => [],
          "pre" => [],
          "weathereffect" => [],
          "forecast" => [],
        }

        data = JSON.parse(res.body)

        result = data["result"]
        result["observations"].each do |obs|
          next if obs["measurement"].nil?

          retval["obs"].push({
            "value" => obs["measurement"]["value"],
            "time" => Time.parse(obs["dateTime"]).to_datetime,
            "flag" => "obs"
          })
        end
        result["predictions"].each do |pre|
          retval["pre"].push({
            "value" => pre["measurement"]["value"],
            "time" => Time.parse(pre["dateTime"]).to_datetime,
            "flag" => "pre"
          })
        end
        result["weatherEffects"].each do |we|
          next if we["measurement"].nil?

          retval["weathereffect"].push({
            "value" => we["measurement"]["value"],
            "time" => Time.parse(we["dateTime"]).to_datetime,
            "flag" => "weathereffect"
          })
        end
        result["forecasts"].each do |forecast|
          retval["forecast"].push({
            "value" => forecast["measurement"]["value"],
            "time" => Time.parse(forecast["dateTime"]).to_datetime,
            "flag" => "forecast"
          })
        end

        retval
      end

      def get_high_low_data(options)
        uri = URI("https://www.kartverket.no" + "/api/vsl/tideforecast")

        params = {
          latitude: options[:latitude],
          longitude: options[:longitude],
          language: options[:language]
        }

        uri.query = URI.encode_www_form(params)

        Net::HTTP.get_response(uri)
      end

      def parse_high_low_data(res)
        parsed = JSON.parse(res.body)
        result = parsed["result"]["forecasts"]

        result.map {|elem|
          {
            "value" => elem["measurement"]["value"],
            "time" => Time.parse(elem["dateTime"]).to_datetime
          }
        }
      end
  end
end
