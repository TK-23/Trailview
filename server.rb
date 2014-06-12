require 'sinatra'
require 'pg'
require 'json'
require 'pry'
require 'sinatra/flash'

require_relative 'config/application'
require_relative 'image_loader'
require_relative 'log_in'

db = PG.connect(dbname: 'trailview')


get "/" do

  erb :home
end

post "/log_in" do
  if valid_user?  params[:username], params[:password]
    user_id = get_user_id(params[:username])
    set_user(user_id)
    redirect "/home"
  else
    redirect "/"
  end
end

post "/create_user" do
  create_user
  session[:user_id] = get_user_id(params[:username])
  redirect "/home"
end

post "/create_track" do
  Track.create(db,session[:user_id], params[:name],params[:description])
  redirect "/home"
end


get "/home" do
  authenticate
  @tracks = Track.load_all_by_user(db, session[:user_id])
  erb :user_home
end


get "/tracks/:track_id" do
  authenticate

  @track = Track.load_single(db, [params[:track_id]])

  track_owner = @track.attributes["user_id"]

  if !matches_owner?(track_owner) then ( redirect "/" ) end

  @photos = []
  @track.photos.each do |photo|
    @photos << photo.to_json
  end

 # @track_geoJSON = @track.generate_geoJSON

  erb :track_page
end

