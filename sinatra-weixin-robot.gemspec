require './lib/sinatra-weixin-robot'
spec = Gem::Specification.new do |s|
  s.name = 'sinatra-weixin-robot'
  s.version = Sinatra::WeiXinRobot::VERSION
  s.summary = 'WeiXin Robot'
  s.description = 'WeiXin Robot for sinatra'
  s.platform = Gem::Platform::RUBY
  s.authors = ["KennX"]
  s.email = ["kennx9@gmail.com"]
  s.date = ["2013-03-18"]
  s.required_ruby_version = '>= 1.9.2'
  s.homepage = 'https://github.com/kennx/weixin_robot'
  s.files = Dir['lib/**/*']
end