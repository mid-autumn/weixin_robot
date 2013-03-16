# encoding: utf-8

require 'sinatra/base'
require 'digest/sha1'

module Sinatra
  module WeiXinRobot
    module HelperMethods
      def generate_signature(token=nil)
        weixin_token = token || settings.wexin_token
        signature, timestamp, nonce = params[:signature], params[:timestamp], params[:nonce]
        weixin_sha1 = [token, timestamp.to_s, nonce.to_s].sort!.join
        Digest::SHA1.hexdigest(weixin_sha1)
      end
    end
    module RobotMethods

      def text?
        @type == "text"
      end

      def news?
        @type == "news"
      end

      def music?
        @type = "music"
      end

      def image?
        @type == "image"
      end

      def location?
        @type == "location"
      end

      def link?
        @type == "link"
      end

      def event?
        @type == "event"
      end
    end # BOTMethods
    class Message
      include RobotMethods
      attr_reader :user, :robot, :created_at, :type, :body,
                  :id, :pic_url, :location_x, :location_y, :scale,
                  :label, :title, :description, :url, :event,
                  :latitude, :longitude, :precision

      def initialize(raw)
        unless raw.instance_of?(Hash)
          raw          = raw.string
          @robot         = raw.scan(/<ToUserName><!\[CDATA\[(.*)\]\]><\/ToUserName>/).join
          @user        = raw.scan(/<FromUserName><!\[CDATA\[(.*)\]\]><\/FromUserName>/).join
          @created_at  = raw.scan(/<CreateTime>(\d+)<\/CreateTime>/).join
          @type        = raw.scan(/<MsgType><!\[CDATA\[(.*)\]\]><\/MsgType>/).join
          @body        = raw.scan(/<Content><!\[CDATA\[(.*)\]\]><\/Content>/).join
          @id          = raw.scan(/<MsgId>(\d+)<\/MsgId>/).join
          @pic_url     = raw.scan(/<PicUrl><!\[CDATA\[(.*)\]><\/PicUrl>/).join
          @location_x  = raw.scan(/<Location_X>(.*)<\/Location_X>/).join
          @location_y  = raw.scan(/<Location_Y>(.*)<\/Location_Y>/).join
          @scale       = raw.scan(/<Scale>(\d+)<\/Scale>/).join
          @label       = raw.scan(/<Label><!\[CDATA\[(.*)\]\]><\/Label>/).join
          @title       = raw.scan(/<Title><!\[CDATA\[(.*)\]\]><\/Title>/).join
          @description = raw.scan(/<Description><!\[CDATA\[(.*)\]\]><\/Description>/).join
          @url         = raw.scan(/<Url><!\[CDATA\[(.*)\]\]><\/Url>/).join
          @event       = raw.scan(/<Event><!\[CDATA\[(.*)\]\]><\/Event>/).join
          @latitude    = raw.scan(/<Latitude>(.*)<\/Latitude>/).join
          @longitude   = raw.scan(/<Longitude>(.*)<\/Longitude>/).join
          @precision   = raw.scan(/<Precision>(.*)<\/Precision>/).join
        end
      end

      def replied(params={})
        options = {:robot => @robot, :user => @user, :created_at => Time.now.to_i, :flag => 0}
        Reply.new(options.merge!(params))
      end
    end # Message

    class Reply < Message
      attr_reader :articles, :music, :created_at, :type, :bot, :user, :flag, :body

      def initialize(options={})
        @created_at   = options.delete(:created_at)
        @type         = options.delete(:type)
        @robot          = options.delete(:robot)
        @user         = options.delete(:user)
        @flag         = options.delete(:flag)
        if text?
          @body       = options.delete(:body)
        elsif music?
          @music      = options.delete(:music)
        elsif news?
          @articles   = options.delete(:articles)
        end
      end

      def to_xml
        xml   =   "<xml>\n"
        xml   +=  "<ToUserName><![CDATA[#{@user}]]></ToUserName>\n"
        xml   +=  "<FromUserName><![CDATA[#{@robot}]]></FromUserName>\n"
        xml   +=  "<CreateTime>#{@created_at}</CreateTime>\n"
        xml   +=  "<MsgType><![CDATA[#{@type}]]></MsgType>\n"
        if text?
          xml +=  "#{text_message}"
        elsif music?
          xml +=  "#{music_message}"
        elsif news?
          xml +=  "#{news_message}"
        end
        xml   +=  "<FuncFlag>#{@flag}</FuncFlag>\n"
        xml   +=  "</xml>\n"
      end

      def text_message
        "<Content><![CDATA[#{@body}]]></Content>\n"
      end

      def music_message
        xml   =   "<Music>\n"
        xml   +=  "<Title><![CDATA[#{@music[:title]}]]></Title>\n"
        xml   +=  "<Description><![CDATA[#{@music[:description]}]]></Description>\n"
        xml   +=  "<MusicUrl><![CDATA[#{@music[:url]}]]></MusicUrl>\n"
        xml   +=  "<HQMusicUrl><![CDATA[#{@music[:hq_url]}]]></HQMusicUrl>\n"
        xml   +=  "</Music>\n"
      end

      def news_message
        xml   =   "<ArticleCount>#{@articles.length}</ArticleCount>\n"
        xml   +=  "<Articles>\n"
        @articles.each do |artcile|
          xml +=  "<item>\n"
          xml +=  "<Title><![CDATA[#{artcile[:title]}]]></Title>\n"
          xml +=  "<Description><![CDATA[#{artcile[:description]}]]></Description>\n"
          xml +=  "<PicUrl><![CDATA[#{artcile[:pic_url]}]]></PicUrl>\n"
          xml +=  "<Url><![CDATA[#{artcile[:url]}]]></Url>\n"
          xml +=  "</item>\n"
        end
        xml   +=  "</Articles>\n"
      end
    end # Reply

    def self.registered(app)
      app.set :weixin_token,    "your-token"
      app.set :weixin_uri,      "http://wwww.your-weixin-bot-url.com/"
      app.set :weixin_path,     URI(app.settings.weixin_uri).path.to_s
      app.helpers HelperMethods

      app.before "#{app.settings.weixin_path}" do
        if request.request_method == "POST"
          content_type 'application/xml'
        elsif request.request_method == "GET"
          @echostr = params[:echostr]
        end
      end
    end
  end # WeiXinBot

  register WeiXinRobot
end # Sinatra




