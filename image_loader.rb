require 'exifr'
require 'pg'

def load_photos(directory, track_id )
  connection = PG.connect(dbname: 'trailview')

  Dir.foreach(directory) do |f|
    if f[-3..-1] == 'jpg'

      gen_metadata = EXIFR::JPEG.new(directory+"/"+f)

      metadata = gen_metadata.to_hash

      lat = gen_metadata.exif.gps.latitude
      long = gen_metadata.gps.longitude
      alt = gen_metadata.gps.altitude.round(2)

      geom_query = "ST_GeomFromText('POINT(#{long} #{lat} #{alt})',4326)"

      puts geom_query

      fields = "geom,track_id,created,file_name,file_path,"
      values = "#{geom_query},'#{track_id}', NOW(),'#{f}','#{directory}',"

      metadata.each do |key,value|
        if ( value.nil? || value == "\x00")
          value = 0
        end
        fields += "#{key},"
        values += "'#{value}',"

      end

      fields = fields[0...-1]
      values = values[0...-1]

      connection.exec("INSERT INTO photos (#{fields} ) VALUES (#{values})")

    end
  end
end

def update_line_geometry_from_photos
  connection = PG.connect(dbname: 'trailview')
  photos = connection.exec("SELECT ST_AsText(geom) FROM photos WHERE track_id = 1").to_a

  i = 0
  coords = ""
  photos.each do |photo|
    if !photo["st_astext"].nil?
       coord = "#{photo["st_astext"].to_s[9..-2]} #{i},"
       coords << coord
    end
    i+=1
  end

  coords = coords[0...-1]

  connection.exec("UPDATE tracks SET geom = ST_GeomFromText('LINESTRING(#{coords})',4326) WHERE id = 1;")

end

load_photos("public/images2/",1)
create_line_geometry_from_photos




