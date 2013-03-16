# encoding: utf-8

require 'rubygems'
require 'bundler'
Bundler.require

require 'sinatra/base'
require './weixin_bot'



class App < Sinatra::Base
  register Sinatra::WeiXinBOT

  configure do
    enable  :logging
    set :weixin_token,  "your-token"
    set :weixin_uri,    "your-uri"
  end

  get '/' do
    @echostr
  end

  post '/' do
    if generate_signature settings.weixin_token == params[:signature]
      Sinatra::WeiXinBOT::Reply.new()
    end
  end

end