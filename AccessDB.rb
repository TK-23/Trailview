require 'pg'
require 'json'

class CreateTable

  attr_accessor :query, :dbname, :src_table, :where_field, :field_list
  attr_reader :connection

  def initialize(dbname, src_table, field_list = "*", where_field = nil, where_value = nil)
    @dbname = dbname
    @src_table = src_table
    @field_list = field_list
    @where_field = where_field
    @where_value = where_value
    format_where_value
    @connection = PG.connect(dbname: dbname)
  end

  def basic_query
    @basic_query = "SELECT #{field_list} FROM #{src_table} "
  end


  def attributes
    query = basic_query
    if !where_field.nil?
      query += " WHERE #{where_field} = $1"
    end

    query += ";"

    connection.exec_params(query,@where_value).to_a
  end

  def format_where_value
    if @where_value == nil
      w_value = []
    else
      w_value = []
      w_value << @where_value
    end
    @where_value = w_value
  end


  def geoms(properties_fields = "")
    if properties_fields != "" then properties_fields = "," + properties_fields end

    geoms_query = "SELECT ST_AsGeoJSON(geom) AS geometry #{properties_fields} from #{src_table}"

    if !where_field.nil?
       geoms_query += " WHERE #{where_field} = $1"
    end
    geoms_query += ";"

    geoms_json = connection.exec_params(geoms_query,@where_value).to_a

    to_geoJSON(geoms_json)

  end

  def to_geoJSON(query_result)
    @geoms = []

    query_result.each do |json|
      current_json = {}
      current_json["type"] = "Feature"
      properties_json = {}
      json.each do |key, value|
        if key == "geometry"
          current_json["geometry"] = JSON.parse(json["geometry"])
        else
          properties_json[key] = value
        end
      end
      current_json["properties"] = properties_json

      @geoms << current_json
    end
    @geoms.to_json
  end
end
