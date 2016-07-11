require 'sinatra/base'
require 'redis'
require 'puma'
ENV['RACK_ENV'] = 'production'

class ApiApplication < Sinatra::Base
  configure { set :server, :puma }

  get '/' do
    puts 'gtfo noob'
    redis = Redis.new
    redis.publish('chat-demo', 'fufufasdasd')
  end
end
