CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;
CREATE EXTENSION fuzzystrmatch;
CREATE EXTENSION postgis_tiger_geocoder;

CREATE TABLE users (
  id serial PRIMARY KEY NOT NULL,
  username varchar(20),
  email varchar(100),
  password varchar(1000),
  salt varchar(100),
  last_login date,
  number_of_logins integer
);

CREATE TABLE tracks (
  id serial PRIMARY KEY NOT NULL,
  user_id integer REFERENCES users(id),
  name varchar(100),
  description varchar(1000),
  import_date date
);

SELECT AddGeometryColumn('tracks','geom',4326,'LINESTRING',4);

CREATE INDEX tracks_gix
  ON tracks
  USING GIST (geom);

CREATE TABLE photos (
  id serial PRIMARY KEY,
  track_id integer REFERENCES tracks(id),
  file_name varchar(1000),
  file_path varchar(1000),
  name varchar(100),
  description text,
  width integer,
  height integer,
  bits integer,
  comment text,
  make varchar(100),
  model varchar(100),
  orientation text,
  x_resolution varchar(10),
  y_resolution varchar(10),
  resolution_unit integer,
  software varchar(50),
  date_time date,
  ycb_cr_positioning varchar(50),
  exposure_time varchar(50),
  f_number varchar(50),
  exposure_program varchar(50),
  iso_speed_ratings varchar(50),
  date_time_original date,
  date_time_digitized date,
  shutter_speed_value varchar(50),
  aperture_value double precision,
  brightness_value varchar(50),
  metering_mode integer,
  flash integer,
  focal_length varchar(50),
  subject_area varchar(50),
  subsec_time_orginal integer,
  subsec_time_digitized integer,
  color_space integer,
  pixel_x_dimension integer,
  pixel_y_dimension integer,
  sensing_method integer,
  custom_rendered varchar(50),
  exposure_mode integer,
  white_balance integer,
  focal_length_in_35mm_film integer,
  scene_capture_type integer,
  gps_latitude_ref varchar(1),
  gps_latitude varchar(50),
  gps_longitude_ref varchar(1),
  gps_longitude varchar(50),
  gps_altitude_ref varchar(50),
  gps_altitude varchar(50),
  gps_time_stamp varchar(50),
  gps_img_direction_ref varchar(1),
  gps_img_direction varchar(50),
  viewer_coords text,
  created date
);

SELECT AddGeometryColumn('photos','geom',4326,'POINT',3);

CREATE INDEX photo_gix
  ON photos
  USING GIST (geom);

INSERT into spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext) values ( 932619, 'epsg', 32619, '+proj=utm +zone=19 +ellps=WGS84 +datum=WGS84 +units=m +no_defs ', 'PROJCS["WGS 84 / UTM zone 19N",GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563,AUTHORITY["EPSG","7030"]],AUTHORITY["EPSG","6326"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.01745329251994328,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4326"]],UNIT["metre",1,AUTHORITY["EPSG","9001"]],PROJECTION["Transverse_Mercator"],PARAMETER["latitude_of_origin",0],PARAMETER["central_meridian",-69],PARAMETER["scale_factor",0.9996],PARAMETER["false_easting",500000],PARAMETER["false_northing",0],AUTHORITY["EPSG","32619"],AXIS["Easting",EAST],AXIS["Northing",NORTH]]');
