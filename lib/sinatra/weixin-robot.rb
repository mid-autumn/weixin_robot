# encoding: utf-8

require 'sinatra/base'
require 'digest/sha1'

module Sinatra
  module WeiXinRobot
    module RobotHelpers
      def generate_signature(token=nil)
        weixin_token = token || settings.weixin_token
        timestamp, nonce = params[:timestamp], params[:nonce]
        weixin_sha1 = [weixin_token.to_s, timestamp.to_s, nonce.to_s].sort!.join
        Digest::SHA1.hexdigest(weixin_sha1)
      end

      def message_receiver(msg)
        Sinatra::WeiXinRobot::Receiver.message(msg)
      end
    end
    module MessageHelpers
      def text?
        @msg_type == "text"
      end

      def music?
        @msg_type == "music"
      end

      def news?
        @msg_type == "news"
      end

      def image?
        @msg_type == "image"
      end
      def location?
        @msg_type == "location"
      end
      def link?
        @msg_type == "link"
      end

      def event?
        @msg_type == "event"
      end
    end
    class Receiver
      include MessageHelpers
      attr_reader :robot, :user,
                  :create_time,
                  :raw_meesage,
                  :content,
                  :pic_url,
                  :title, :description, :url,
                  :location_y, :location_x, :scale, :label,
                  :event, :latitude, :precision, :foobar
      def initialize(raw_message)
        if raw_message.instance_of?(StringIO)
          @raw_message    = raw_message.string
        elsif raw_message.instance_of?(Tempfile)
          @raw_message    = raw_message.read
        else
          @raw_message    = raw_message.to_str
        end
        @robot            = @raw_message.scan(/<ToUserName><!\[CDATA\[(.*)\]\]><\/ToUserName>/).flatten.join
        @user             = @raw_message.scan(/<FromUserName><!\[CDATA\[(.*)\]\]><\/FromUserName>/).flatten.join
        @create_time      = @raw_message.scan(/<CreateTime>(\d+)<\/CreateTime>/).flatten.join
        @msg_type         = @raw_message.scan(/<MsgType><!\[CDATA\[(.*)\]\]><\/MsgType>/).flatten.join
        @msg_id           = @raw_message.scan(/<MsgId>(\d+)<\/MsgId>/).flatten.join
      end
      def self.message(raw_message)
        msg = new(raw_message)
        msg.handler
        msg
      end
      def handler
        if text?
          @content          = @raw_message.scan(/<Content><!\[CDATA\[(.*)\]\]><\/Content>/).flatten.join
        elsif image?
          @pic_url          = @raw_message.scan(/<PicUrl><!\[CDATA\[(.*)\]><\/PicUrl>/).flatten.join
        elsif location?
          @location_x       = @raw_message.scan(/<Location_X>(.*)<\/Location_X>/).flatten.join
          @location_y       = @raw_message.scan(/<Location_Y>(.*)<\/Location_Y>/).flatten.join
          @scale            = @raw_message.scan(/<Scale>(\d+)<\/Scale>/).flatten.join
          @label            = @raw_message.scan(/<Label><!\[CDATA\[(.*)\]\]><\/Label>/).flatten.join
        elsif link?
          @title            = @raw_message.scan(/<Title><!\[CDATA\[(.*)\]\]><\/Title>/).flatten.join
          @description      = @raw_message.scan(/<Description><!\[CDATA\[(.*)\]\]><\/Description>/).flatten.join
          @url              = @raw_message.scan(/<Url><!\[CDATA\[(.*)\]\]><\/Url>/).flatten.join
        elsif event?
          @event            = @raw_message.scan(/<Event><!\[CDATA\[(.*)\]\]><\/Event>/).flatten.join
          @latitude         = @raw_message.scan(/<Latitude>(.*)<\/Latitude>/).flatten.join
          @precision        = @raw_message.scan(/<Precision>(.*)<\/Precision>/).flatten.join
        else
          raise TypeError
        end
      end

      def sender(params={}, &block)
        options = {:robot => @robot, :user => @user, :msg_type => "text"}.merge!(params)
        if block_given?
          block.call(Reply.new(options))
        end
      end
    end # Receiver
    class Reply
      include MessageHelpers
      attr_accessor :content,
                    :create_time,
                    :msg_type,
                    :func_flag,
                    :music,
                    :articles

      attr_reader   :user, :robot
      def initialize(options={})
        @user               = options.delete(:user)
        @robot              = options.delete(:robot)
        @create_time        = options.delete(:create_time) || Time.now.to_i
        @msg_type           = options.delete(:msg_type)
        @func_flag          = options.delete(:func_flag) || 0
        @content            = options.delete(:content)
        @articles           = options.delete(:articles) || []
        @music              = options.delete(:music)
      end

      def articles=(hash)
        @articles.push(hash)
      end

      def text_message
        raise RuntimeError, "#{__LINE__} `@content` not defined" if @content.nil?
        "<Content><![CDATA[#{@content}]]></Content>"
      end

      def music_message
        raise RuntimeError, "#{__LINE__} `@music` not defined" if @music.nil?
        xml    =  "<Music>"
        xml   +=  "<Title><![CDATA[#{@music[:title]}]]></Title>"
        xml   +=  "<Description><![CDATA[#{@music[:description]}]]></Description>"
        xml   +=  "<MusicUrl><![CDATA[#{@music[:url]}]]></MusicUrl>\n"
        xml   +=  "<HQMusicUrl><![CDATA[#{@music[:hq_url]}]]></HQMusicUrl>"
        xml   +=  "</Music>"
      end

      def news_message
        raise RuntimeError, "#{__LINE__} `@news` not defined" if @articles.nil?
        xml   =   "<ArticleCount>#{@articles.length}</ArticleCount>"
        xml   +=  "<Articles>"
        @articles.each do |artcile|
          xml +=  "<item>"
          xml +=  "<Title><![CDATA[#{artcile[:title]}]]></Title>"
          xml +=  "<Description><![CDATA[#{artcile[:description]}]]></Description>"
          xml +=  "<PicUrl><![CDATA[#{artcile[:pic_url]}]]></PicUrl>"
          xml +=  "<Url><![CDATA[#{artcile[:url]}]]></Url>"
          xml +=  "</item>"
        end
        xml   +=  "</Articles>"
      end

      def to_xml
        xml  = "<xml>"
        xml += "<ToUserName><![CDATA[#{@user}]]></ToUserName>"
        xml += "<FromUserName><![CDATA[#{@robot}]]></FromUserName>"
        xml += "<CreateTime>#{@create_time}</CreateTime>"
        xml += "<MsgType><![CDATA[#{@msg_type}]]></MsgType>"
        xml += text_message if text?
        xml += music_message if music?
        xml += news_message if news?
        xml += "<FuncFlag>#{@func_flag}</FuncFlag>"
        xml += "</xml>"
      end

      def complete!
        to_xml
        self
      end
    end #Reply
    def self.registered(robot)
      robot.set     :weixin_token,    nil
      robot.set     :weixin_uri,      "http://wwww.your-weixin-bot-url.com/"
      robot.set     :weixin_path,     URI(robot.settings.weixin_uri).path.to_s
      robot.helpers  RobotHelpers
      robot.before "#{robot.settings.weixin_path}" do
        if request.request_method == "POST"
          content_type 'application/xml'
        end
      end
    end
  end # WeiXinRobot
  register WeiXinRobot
end # Sinatra



