#!/usr/bin/env ruby

require 'sinatra'
require 'haml'
require 'cgi'
require 'net/https'
require 'RMagick'
require 'json'
require 'coffee-script'
require 'dalli'

# require 'sass/plugin/rack'
# use Sass::Plugin::Rack

set :cache, Dalli::Client.new # unless development?
set :enable_cache, true
set :protection, :except => :json_csrf

get '/' do
  haml :index
end

get '/waveform.js' do
  content_type "text/javascript"
  coffee :waveform
end

get '/application.js' do
  content_type "text/javascript"
  coffee :application
end

get '/w*' do
  content_type :json

  waveform = memcache_fetch params[:url] do
    waveform = []

    image = Magick::Image.read(params[:url]).first
    image.crop!(0, 0, image.columns, image.rows / 2)
    image.rotate!(90)

    columns = image.columns

    image.each_pixel do |pixel, c, r|
      if waveform.length <= r && (pixel.opacity == 0 || c == columns - 1)
        waveform << c / columns.to_f
      end
    end

    waveform
  end

  "#{ params[:callback] }(#{ waveform.to_json });"
end

def memcache_fetch(key)
  settings.cache.get(key) || begin
    value = yield
    settings.cache.set(key, value)
    value
  end
end
