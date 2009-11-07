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
          metaweb_query[build_metaweb_condition_key(condition)] = build_metaweb_condition(condition)
          looking_for = fields.reject {|field| metaweb_query.include?(field.name)}
          looking_for.each do |field|
            metaweb_query[field.name] = [{}]
          end
        end
        metaweb_query["type"] = query.model.storage_name
        result = metaweb_read(metaweb_query)["result"]
        convert_metaweb_result(result)
      end

      private

      def build_metaweb_condition_key(condition)
        puts condition.class
        case condition
        when DataMapper::Query::Conditions::LikeComparison
          "#{condition.subject.name}~="
        when DataMapper::Query::Conditions::InclusionComparison
          "#{condition.subject.name}|="
        when DataMapper::Query::Conditions::LessThanComparison
          "#{condition.subject.name}<"
        when DataMapper::Query::Conditions::GreaterThanComparison
          "#{condition.subject.name}>"
        when DataMapper::Query::Conditions::LessThanOrEqualToComparison
          "#{condition.subject.name}<="
        when DataMapper::Query::Conditions::GreaterThanOrEqualToComparison
          "#{condition.subject.name}>="
        when DataMapper::Query::Conditions::NotOperation
          "#{condition.subject.name}!="
        else
          condition.subject.name
        end
      end

      def build_metaweb_condition(condition)
        case condition.subject
        when DataMapper::Associations::ManyToOne::Relationship
          {:id => condition.value.id}
          break
        else
          condition.value
        end
      end

      def convert_metaweb_result(results)
        # puts result.inspect
        results.each do |element|
          element.each do |key, value|
            element[key] = extract_value(value)
          end
        end
      end

      def extract_value(property)
        case property
        when Array
          values = property.collect {|element| extract_value(element)}
          values.size == 1 ? values.first : values
        when Hash
          if property.has_key?("type")
            extract_typed_value(property)
          else
            property
          end
        else
          property
        end
      end

      def extract_typed_value(property)
        case property["type"]
        when "/type/text", "/type/id"
          property["value"]
        else
          property["name"]
        end
      end

      def metaweb_read(query)
        puts JSON.dump(query)
        puts ""
        metaweb_query = "?query={\"query\": [#{JSON.dump(query)}]}"
        url = "#{query_url}#{URI.escape(metaweb_query)}"
        response = Net::HTTP.get_response(URI.parse(url))
        data = response.body

        result = JSON.parse(data)

        if result['code'] == '/api/status/error'
          puts result.inspect
          raise "web service error #{url}"
        end
        return result
      end


    end # class FreebaseAdapter
  end # module Adapters
end # module DataMapper

