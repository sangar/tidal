require "tidal/version"
require "date"
require "net/http"
require "nokogiri"

module Tidal
  class << self
    def for(options)
      res = get_tidal_data(options)
      return unless res.is_a?(Net::HTTPSuccess)

      parse_tidal_data(res)
    end

    private
      def get_tidal_data(options)
        options = {
          latitude: nil,
          longitude: nil,
          date: DateTime.now,
          datatype: "all",
          refcode: "cd",
          place: '',
          file: '',
          lang: '',
          interval: 60,
          dst: '0',
          tzone: '',
          tide_request: 'locationdata'
        }.merge(options)

        uri = URI("http://api.sehavniva.no" + "/tideapi.php")

        params = {
          lat: options[:latitude],
          lon: options[:longitude],
          fromtime: options[:date].strftime("%Y-%m-%dT00:00"),
          totime: (options[:date] + 1).strftime("%Y-%m-%dT00:00"),
          datatype: options[:datatype],
          refcode: options[:refcode],
          place: options[:place],
          file: options[:file],
          lang: options[:lang],
          interval: options[:interval],
          dst: options[:dst],
          tzone: options[:tzone],
          tide_request: options[:tide_request]
        }
        uri.query = URI.encode_www_form(params)

        Net::HTTP.get_response(uri)
      end

      def row_to_h(row)
        row.attributes.map {|name, attr| [name, attr.value] }.to_h
      end

      def parse_tidal_data(res)
        retval = {}

        doc = Nokogiri::XML(res.body)
        doc.css("location").each do |row|
          retval["location"] = row_to_h(row)
        end

        doc.css("waterlevel").each do |row|
          row_data = row_to_h(row)

          unless row_data["flag"]
            row_data["flag"] = row.parent.attributes["type"]
          end

          if retval[row_data["flag"]]
            retval[row_data["flag"]] << row_data
          else
            retval[row_data["flag"]] = [row_data]
          end
        end
        retval
      end
  end
end
