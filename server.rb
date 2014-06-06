require 'sinatra'
require 'exifr'
require 'pg'
require_relative 'AccessDB'


get "/" do
  @photos_geo = CreateTable.new('trailview','tracks','*',).geoms

  erb :main
end

post "/" do

  redirect "/tracks/1"
end

get "/tracks/:track_id" do

  @tracks = CreateTable.new('trailview','tracks','*','id',params[:track_id]).attributes
  @tracks_geo = CreateTable.new('trailview','tracks','*','id',params[:track_id]).geoms
  @photos_geo = CreateTable.new('trailview','photos','*','track_id',params[:track_id]).geoms('file_name,file_path')
  erb :track_page
end

