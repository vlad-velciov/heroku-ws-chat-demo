require 'faye/websocket'
require 'redis'
require 'json'

module ChatDemo
  class ChatBackend
    KEEP_ALIVE_TIME = 15
    CHANNEL = 'chat-demo'
    WS_LIMIT = 900

    def initialize(app)
      @app = app
      @clients = []
      @clients_hash = {}
      @number_of_connections = 0
      uri = nil
      # uri = URI.parse ENV['REDISCLOUD_URL']
      @redis = redis_connection(uri)
      # create_threads
      thread_for_all(uri)
    end

    def thread_for_all(uri)
      # Thread.new do
      #   subscribe_to_channel 0
      # end
    end

    def create_threads
      # @clients.each do |client|
      #   Thread.new do
      #     subscribe_to_channel 0
      #   end
      # end
    end

    def redis_connection(uri)
      Redis.new
    end

    def notify_client(client, message)
      client.send message
    end

    def call(env)
      if Faye::WebSocket.websocket? env
        ws = Faye::WebSocket.new(env, nil, {ping: KEEP_ALIVE_TIME})
        open_event(ws)
        message_event(ws)
        ws = close_event(ws)

        ws.rack_response
      else
        @app.call(env)
      end
    end

    def reached_limit?
      @clients.count >= WS_LIMIT
    end

    def close_event(ws)
      ws.on :close do |event|
        p [:close, event.data]

        # p [:close, ws.object_id, event.code, event.reason]
        @clients.delete(ws)
        @clients_hash.delete ws.object_id
        @number_of_connections = @number_of_connections - 1
        ws = nil
      end
      ws
    end

    def message_event(ws)
      ws.on :message do |event|
        p [:message, event.data]
        @redis.publish(CHANNEL + '0', event.data)
      end
    end

    def open_event(ws)
      ws.on :open do |event|
        p 'open'
        @number_of_connections = @number_of_connections + 1
        p @number_of_connections
        # @clients_hash[ws.object_id] = ws
        @clients << ws
        p ws.object_id

        subscribe_to_channel ws.object_id.to_s

        p @number_of_connections
      end
    end

    def subscribe_to_channel(channel_index = '0')
      redis_sub = redis_connection(nil)
      redis_sub.subscribe(CHANNEL + channel_index) do |on|
        p 'adadsdad'
        on.message do |channel, msg|
          @clients_hash[channel_index].send msg
        end
      end
    end
  end
end
