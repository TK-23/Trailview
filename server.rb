require 'sinatra'
require 'pg'
require 'json'

require 'sinatra/flash'

require_relative 'config/application'
require_relative 'image_loader'
require_relative 'log_in'

db = PG.connect(dbname: 'trailview')

get "/" do
  if params[:signout] == "y"
    session["user_id"] = nil
    redirect "/"
  end
  if logged_in? then redirect "/home" end
  @logInState = 0
  erb :home
end

get "/create_user" do
  @logInState = 1
  erb :home
end

post "/log_in" do
  if valid_user?  params[:username], params[:password]
    user_id = get_user_id(params[:username])
    set_user(user_id)
    redirect "/home"
  else
    flash[:notice] = "Invalid username or password"
    redirect "/"
  end
end

post "/create_user" do
  if form_incomplete?
    flash[:notice] = "Please fill out all inputs"
    redirect "/create_user"
  elsif username_taken?
    flash[:notice] = "Please choose a different username"
    redirect "/create_user"
  else
    create_user
    session[:user_id] = get_user_id(params[:username])
    redirect "/home"
  end
end

get "/home" do
  authenticate
  @tracks = Track.load_all_by_user(db, session[:user_id])

  @tracks_geoJSON = []
  @tracks.each do |track|
    @tracks_geoJSON << track.to_geoJSON
  end
  @tracks_geoJSON = @tracks_geoJSON.to_json

  erb :user_home
end


post "/create_track" do

  current_track = Track.create(db,session[:user_id], params[:name],params[:description])
  track_directory = "public/UserPhotos/#{session[:user_id]}/#{current_track.track_id}"

  Dir.mkdir(track_directory)
  params["images"].each do |image|
    File.open("#{track_directory}/" + image[:filename], "wb") do |f|
      f.write(image[:tempfile].read)
    end
  end

  current_track.load_photo_set(track_directory)

  redirect "/home"
end


get "/tracks/:track_id" do
  authenticate

  @track = Track.load_single(db, params[:track_id].to_i)

  if !matches_owner?(@track.attributes["user_id"]) then ( redirect "/" ) end

  @photos = []
  @track.photos.each do |photo|
    @photos << photo.to_json
  end

  @track_geoJSON = @track.to_geoJSON.to_json

  erb :track_page
end

