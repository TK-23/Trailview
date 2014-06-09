require 'sinatra'
require 'exifr'
require 'pg'
require 'json'
require_relative 'image_loader'


get "/" do

  erb :main
end

post "/" do

  redirect "/tracks/1"
end

get "/tracks/:track_id" do

  @track = Track.load_from_db(PG.connect(dbname: 'trailview'), [params[:track_id]])
  @photos = []
  @track.photos.each do |photo|
    @photos << photo.to_json
  end

  erb :track_page
end

