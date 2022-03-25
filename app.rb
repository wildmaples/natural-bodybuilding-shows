require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require "sinatra/reloader" if development?

require_relative 'app/shows'

shows ||= Shows.new

get '/' do
  erb :index, :locals => { shows: shows.get }
end

get '/about' do
  erb :about
end
