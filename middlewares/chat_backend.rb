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
      @redis = redis_connection(uri)
      puts 'initialize'
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
        @clients.delete(ws)
        @number_of_connections = @number_of_connections - 1
        ws = nil
      end
      ws
    end

    def message_event(ws)
      ws.on :message do |event|
        @redis.publish(CHANNEL + ws.object_id.to_s, event.data)
      end
    end

    def open_event(ws)
      ws.on :open do |event|
        p [:open, ws.object_id]
        @number_of_connections = @number_of_connections + 1
        @clients << ws
        subscribe_to_channel ws.object_id.to_s, ws
      end
    end

    def subscribe_to_channel(channel_index = '0', ws)
      Thread.new do
        redis_sub = redis_connection(nil)
        redis_sub.subscribe(computed_channel channel_index) do |on|
          on.message do |channel, msg|
            ws.send msg
          end
        end
      end
    end

    def computed_channel(index)
      CHANNEL + index
    end
  end
end
