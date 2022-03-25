require 'sinatra'
require "sinatra/reloader" if development?
require 'yaml'
require 'date'

get '/' do
  shows = YAML.load_file("wnbf_events_2022.yaml", permitted_classes: [Date])
  erb :index, :locals => {shows: shows}
end

get '/about' do
  "<h1> TODO </h1>"
end
