require 'exifr'
require 'pg'

module Geo

  def self.transform_pt(db, lat, long, input_srid, output_srid)
    result = db.exec("SELECT ST_AsText(ST_Transform(ST_GeomFromText('POINT(#{long} #{lat})',#{input_srid}),#{output_srid}))").to_a
    coords = result[0]["st_astext"][6..-2]
    output = coords.split(" ")
    output
  end

  def self.txt_from_astext(array_hash, add_m)
    i = 0
    line_coords = ""

    array_hash.each do |photo|
      if !photo["st_astext"].nil?
         coord = "#{photo["st_astext"].split("(")[1][0..-2]}"
         if add_m == true
           coord = coord + " #{i}"
         end
         coord = coord + ","
         line_coords << coord
      end
      i+=1
    end

    line_coords = line_coords[0...-1]
  end

  def self.txt_to_array(input)
    output = []
    input.split(",").each do |elem|
      full_coord = []
      elem.split(" ").each do |coord|
        full_coord << coord.to_f
      end
      output << full_coord
    end
    output
  end

  def self.array_to_txt(input)
    output = ""
    i = 0
    input.each do |item|
      current_item = ""
      ii = 0
      item.each do |sub_item|
        if ii == 0
          current_item = current_item + sub_item.to_s
        else
          current_item = current_item + " " + sub_item.to_s
        end
      end
      if i == 0
        output = output + current_item
      else
        output = output + "," + current_item
      end
    end
    output
  end

end

class Photo

  attr_accessor :lat, :long, :alt, :att, :build_viewer, :db, :track_id, :file_path, :file_name, :viewer_coords, :degree

  def initialize(db = nil, lat = nil, long = nil, alt = 0, file_name = nil, attributes = nil )
    @lat = lat
    @long = long
    @alt = alt
    @file_name = file_name
    @att = attributes
    @db = db
    @viewer_coords = nil
  end

  def build_viewer
    photo_albers = Geo.transform_pt(db, lat, long, 4326, 932619)
    viewer_albers = calc_viewer_coords(photo_albers[0].to_f,photo_albers[1].to_f, 200, 20, 1)
    viewer_wgs = db.exec("SELECT ST_AsText(ST_Transform(ST_GeomFromText('POLYGON((#{viewer_albers}))', 932619),4326))").to_a

    geom = viewer_wgs.first["st_astext"]
    output = Geo.txt_to_array(geom.split("((")[1][0..-3])

    output_reverse = []
    output.each do |item|
      output_reverse << item.reverse
    end
    # db.exec("INSERT INTO viewers (track_id,photo_id, geom) VALUES (#{track_id},#{track_id}, ST_GeomFromText(ST_AsText(ST_Transform(ST_GeomFromText('POLYGON((#{viewer_coords}))', 102243),4326)),4326));")
    output_reverse
  end

  def radian(degree)
    (degree / 360)  * ( 2*  Math::PI )
  end


  def calc_viewer_coords(long_albers, lat_albers, width, degree_buffer, degree_increment )

    current_degree = degree - degree_buffer
    if current_degree < 0
      current_degree = 360 + current_degree
    end

    output = "#{long_albers} #{lat_albers}"

    iterations = (( degree_buffer * 2 ) / degree_increment ).to_i

    iterations.times do

      if current_degree > 360
        current_degree = current_degree - 360
      end

      if current_degree <= 90
        d = radian(current_degree)
        y = width *  Math.sin(d)
        x = width * Math.cos(d)
      elsif current_degree > 90 && current_degree <=180
        d = radian(current_degree - 90)
        y = width *  Math.cos(d)
        x = -1 * width * Math.sin(d)
      elsif current_degree > 180 && current_degree <= 270
        d = radian(current_degree - 180)
        y = -1 * width *  Math.sin(d)
        x = -1 * width * Math.cos(d)

      elsif current_degree > 270 && current_degree <= 360
        d = radian(current_degree - 270)
        y = -1 * width *  Math.cos(d)
        x = width * Math.sin(d)
      end

      if x < width && y < width
        x+= lat_albers
        y+= long_albers

        output += ",#{y} #{x}"
      end

      current_degree += degree_increment
    end
    output += ",#{long_albers} #{lat_albers}"
    output
  end

  def degree
    (att[:gps_img_direction].to_f)
  end

  def write_to_db

    geom_query = "ST_GeomFromText('POINT(#{long} #{lat} #{alt})',4326)"

    fields = "viewer_coords,geom,track_id,created,file_name,file_path,"
    values = "'#{build_viewer}',#{geom_query},'#{track_id}', NOW(),'#{file_name}','#{file_path}',"

    att.each do |key,value|
      if ( value.nil? || value == "\x00")
        value = 0
      end
      fields += "#{key},"
      values += "'#{value}',"
    end

    fields = fields[0...-1]
    values = values[0...-1]

    db.exec("INSERT INTO photos (#{fields} ) VALUES (#{values})")
  end

  def self.load_from_db(db, id)

    output = {}

    attributes = db.exec("SELECT * FROM photos WHERE id = #{id}").to_a[0]
    geom = db.exec("SELECT ST_AsText(geom) FROM photos WHERE id = #{id}").to_a

    geom_as_array = Geo.txt_from_astext(geom, false).split(" ")
    attributes["geom"] = geom_as_array

    output["long"] = geom_as_array[0]
    output["lat"] = geom_as_array[1]
    output["alt"] = geom_as_array [2]
    output["file_path"] = attributes["file_path"]
    output["file_name"] = attributes["file_name"]
    output["viewer_coords"] = attributes["viewer_coords"]
    output["direction"] = attributes["gps_img_direction"]

    output
  end

end

class Track

  attr_reader :db, :attributes, :photos, :albers_coords, :wgs_coords, :projection, :track_id
  attr_accessor  :generate_geoJSON


  def initialize(db, track_id, photos = nil, attributes = nil)
    @db = db
    @track_id = track_id
    @photos = photos
    @projection = 4326
    @attributes = attributes
  end

  def wgs_coords
    @wgs_coords = @db.exec("SELECT ST_AsText(geom),id FROM photos WHERE track_id = #{track_id}").to_a
  end

  def albers_coords
    @albers_coords = @db.exec("SELECT ST_AsText(ST_Transform(geom,932619)) as st_astext, id FROM photos WHERE track_id = #{track_id}").to_a
  end

  def update_geom
    c = Geo.txt_from_astext(wgs_coords, true)
    db.exec("UPDATE tracks SET geom = ST_GeomFromText('LINESTRING(#{c})',4326) WHERE id = #{track_id};")
  end

  def to_geoJSON
    output = {}
    output["type"] = "Feature"
    properties_json = {}
    attributes.each do |key, value|
      if key == "geometry"
        output["geometry"] = JSON.parse(attributes["geometry"])
      else
        properties_json[key] = value
      end
    end
    output["properties"] = properties_json

    output
  end

  def load_photo_set(directory)

    all_photos = []

    Dir.foreach(directory) do |f|

      photo = Photo.new(db)
      photo.file_name = f

      if f[-3..-1] == 'jpg'

        gen_metadata = EXIFR::JPEG.new(directory+"/"+f)

        metadata = gen_metadata.to_hash

        photo.track_id = track_id
        photo.file_name = f
        photo.file_path = directory
        photo.att = metadata
        photo.lat = gen_metadata.gps.latitude
        photo.long = gen_metadata.gps.longitude
        photo.alt = gen_metadata.gps.altitude.round(2)

        photo.write_to_db

        all_photos << photo
      end
    end

    update_geom

  end

  def self.create(db, user_id, name, description)

    query = "INSERT INTO tracks (user_id, name, description) values ($1,$2,$3) RETURNING id;"
    track_id = db.exec_params(query,[user_id, name, description]).to_a[0]["id"]

    attributes = db.exec_params('SELECT id, ST_AsGeoJSON(geom) as geometry, user_id, name, description, import_date from tracks WHERE id = $1', [track_id.to_i]).to_a[0]

    Track.new(db, track_id.to_i, nil)

  end

  def self.load_single(db, track_id)
    attributes = db.exec_params('SELECT id, ST_AsGeoJSON(geom) as geometry, user_id, name, description, import_date from tracks WHERE id = $1', [track_id]).to_a[0]
    photos = db.exec_params('SELECT id FROM photos WHERE track_id = $1', [track_id]).to_a
    photo_set = []
    photos.each do |photo|
      photo_set << Photo.load_from_db(db, photo["id"].to_i)
    end

    track = Track.new(db, track_id, photo_set,attributes)
  end

  def self.load_all_by_user(db, user_id)
    tracks = db.exec_params('SELECT id, ST_AsGeoJSON(geom) as geometry, user_id, name, description, import_date from tracks WHERE user_id = $1', [user_id.to_i]).to_a
    output = []
    tracks.each do |track|
      output << Track.new(db, track["id"],nil, track)
    end
    output
  end

end

