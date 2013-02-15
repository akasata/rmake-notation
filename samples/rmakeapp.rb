# encoding: utf-8

require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'thin'
require 'rmake-notation'

Rack::Handler.register 'Thin', 'Rack::Handler::Thin'

helpers do
  def generate_contents(content)
    @notation ||= Object.new.extend Rmake::Notation
    @notation.generate_contents content
  end
end  

get "/" do
  @text = ""
  open("./sample.txt") do |f|
    @text += f.read
  end
  
  erb :index
end





