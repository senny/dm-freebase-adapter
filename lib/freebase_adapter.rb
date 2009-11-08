require 'json'
require 'net/http'

module DataMapper
  module Adapters
    class FreebaseAdapter < AbstractAdapter

      FREEBASE_HOST = "www.freebase.com"
      FREEBASE_PATH = "/api/service/mqlread"

      UNIQUE_PROPERTIES = {}

      def read(query)
        model = query.model
        metaweb_reflect_properties(model) unless UNIQUE_PROPERTIES.has_key?(model)
        metaweb_query = {}
        fields = query.fields
        order_by_fields = query.order.collect(&:target)
        query.conditions.each do |condition|
          metaweb_query[build_metaweb_condition_key(condition)] = build_metaweb_condition(condition)
          looking_for = fields.reject {|field| metaweb_query.include?(field.name)}
          looking_for.each do |field|
            if UNIQUE_PROPERTIES[model][field]
              metaweb_query[field.name] = nil
            else
              metaweb_query[field.name] = []
            end
          end
        end
        order_by = build_metaweb_sort_directive(query.order)
        metaweb_query["sort"] = order_by if order_by.size > 0
        metaweb_query["type"] = query.model.storage_name
        result = metaweb_query_result([metaweb_query])
        convert_metaweb_result(result)
      end

      private

      def build_metaweb_condition_key(condition)
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
          "#{condition.operands.first.subject.name}!="
        else
          condition.subject.name
        end
      end

      def query_url
        host = (options[:host] && !options[:host].empty?) ? options[:host] : FREEBASE_HOST
        path = (options[:path] && !options[:path].empty?) ? options[:path] : FREEBASE_PATH
        "http://#{ host }#{ path }"
      end

      def build_metaweb_sort_directive(directions)
        directions.reject { |order| order.target.name.to_s == "id" }.collect do |direction|
          sort = direction.target.name
          sort = "-#{sort}" if direction.operator == :desc
          sort
        end
      end

      def build_metaweb_condition(condition)
        case condition.subject
        when DataMapper::Associations::ManyToOne::Relationship
          {:id => condition.value.id}
        else
          condition.value
        end
      end

      def convert_metaweb_result(results)
        return {} unless results
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

      def metaweb_query_result(query)
        JSON.parse(metaweb_read(query))["result"]
      end

      def metaweb_read(query)
        # puts "QUERY:"
        # puts "#{JSON.dump(query)}"
        metaweb_query = "?query={\"query\": #{JSON.dump(query)}}"
        url = "#{query_url}#{URI.escape(metaweb_query)}"
        response = Net::HTTP.get_response(URI.parse(url))
        response.body
      end

      def metaweb_reflect_properties(model)
        # TODO: perform only one query
        UNIQUE_PROPERTIES[model] = {}
        properties = {}
        model.properties.each {|property| properties["#{model.storage_name}/#{property.name}"] = property}
        results = metaweb_query_result([{"id|=" => properties.keys, "id" => nil, "type" => "/type/property", "unique" => nil}])
        if results
          results.each do |result|
            id = result["id"]
            UNIQUE_PROPERTIES[model][properties[id]] = result["unique"]
          end
        end
      end

    end # class FreebaseAdapter
  end # module Adapters
end # module DataMapper

