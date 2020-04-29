require "tidal/version"
require "date"
require "net/http"
require "nokogiri"
require "time"

module Tidal
  class << self
    def for(options)
      options = merge_default_params(options)

      res = get_tidal_data(options)
      return unless res.is_a?(Net::HTTPSuccess)

      retval = parse_tidal_data(res)

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
          date: DateTime.now,
          datatype: "all",
          refcode: "cd",
          place: '',
          file: '',
          lang: 'en',
          interval: 60,
          days: 2,
          dst: '0',
          tzone: '',
          tide_request: 'locationdata'
        }.merge(options)
      end

      def get_tidal_data(options)
        uri = URI("http://api.sehavniva.no" + "/tideapi.php")

        params = {
          lat: options[:latitude],
          lon: options[:longitude],
          fromtime: options[:date].strftime("%Y-%m-%dT00:00"),
          totime: (options[:date] + options[:days]).strftime("%Y-%m-%dT00:00"),
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

      def xml_row_to_h(row)
        row.attributes.map {|name, attr|
          if attr.value.match(/\dT\d/)
            [name, Time.parse(attr.value).to_datetime]
          elsif attr.value.match(/\d\.\d/)
            [name, attr.value.to_f]
          elsif attr.value.match(/\d/)
            [name, attr.value.to_i]
          else
            [name, attr.value]
          end
        }.to_h
      end

      def parse_tidal_data(res)
        retval = {}

        doc = Nokogiri::XML(res.body)
        doc.css("location").each do |row|
          retval["location"] = xml_row_to_h(row)
        end

        doc.css("waterlevel").each do |row|
          row_data = xml_row_to_h(row)

          unless row_data["flag"]
            row_data_flag = row.parent.attributes["type"].value
            row_data["flag"] = row_data_flag
          end

          if retval[row_data["flag"]]
            retval[row_data["flag"]] << row_data
          else
            retval[row_data["flag"]] = [row_data]
          end
        end
        retval
      end

      def get_high_low_data(options)
        uri = URI("https://www.kartverket.no" + "/Sehavniva/Service/Portvakten/Tidevann/")

        params = {
          lat: options[:latitude],
          lon: options[:longitude],
          from: options[:date].strftime("%-m/%d/%Y"),
          to: (options[:date] + 1).strftime("%-m/%d/%Y"),
          lang: options[:lang],
          interval: 'hoylav',
          place: '',
          reflevel: 'CD'
        }

        uri.query = URI.encode_www_form(params)

        Net::HTTP.get_response(uri)
      end

      def json_obj_to_h(obj)
        obj.map {|key, value|
          if value.nil?
            [key, value]
          elsif value.is_a?(Integer)
            [key, value]
          elsif value.match(/\dT\d/)
            [key, Time.parse(value).to_datetime]
          elsif value.match(/\d\.\d/)
            [key, value.to_f]
          elsif value.match(/\d/)
            [key, value.to_i]
          else
            [key, value]
          end
        }.to_h
      end

      def parse_high_low_data(res)
        parsed = JSON.parse(res.body)

        return [] unless parsed["days"].count > 1

        dayone = parsed["days"][0]["data"].map {|obj| json_obj_to_h(obj) }
        daytwo = parsed["days"][1]["data"].map {|obj| json_obj_to_h(obj) }
        dayone + daytwo
      end
  end
end
