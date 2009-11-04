require 'json'
require 'net/http'

module DataMapper
  module Adapters
    class FreebaseAdapter < AbstractAdapter

      FREEBASE_HOST = "www.freebase.com"
      FREEBASE_PATH = "/api/service/mqlread"

      def query_url
        host = (options[:host] && !options[:host].empty?) ? options[:host] : FREEBASE_HOST
        path = (options[:path] && !options[:path].empty?) ? options[:path] : FREEBASE_PATH
        "http://#{ host }#{ path }"
      end

      def read(query)
        metaweb_query = {}
        fields = query.fields
        query.conditions.each do |condition|
          metaweb_query[condition.subject.name] = condition.value
        end
        looking_for = fields.reject {|field| metaweb_query.include?(field.name)}
        looking_for.each do |field|
          metaweb_query[field.name] = []
        end
        metaweb_query["type"] = query.model.storage_name
        metaweb_read(metaweb_query)["result"]
      end

      private

      def metaweb_read(query)
        metaweb_query = "?query={\"query\": [#{JSON.dump(query)}]}"
        url = "#{query_url}#{URI.escape(metaweb_query)}"
        response = Net::HTTP.get_response(URI.parse(url))
        data = response.body

        result = JSON.parse(data)

        if result['code'] == '/api/status/error'
          raise "web service error #{url}"
        end
        return result
      end


    end # class FreebaseAdapter
  end # module Adapters
end # module DataMapper

