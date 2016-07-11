require 'faye/websocket'
require 'redis'
require 'json'
require 'middlewares/queue/redis_queue'

module ChatDemo
  class ChatBackend
    KEEP_ALIVE_TIME = 15
    CHANNEL = 'chat-demo'
    WS_LIMIT = 900

    def initialize(app, queue = RedisQueue.new)
      @app = app
      @clients = []
      @clients_hash = {}
      @number_of_connections = 0
      @queue = queue
      uri = nil
      @publisher =redis_connection(uri)
      @queue.connection = redis_connection(uri)
      puts 'initialize'
    end

    def redis_connection(uri)
      Redis.new
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
        decrement_connection_number
        ws = nil
      end
      ws
    end

    def message_event(ws)
      ws.on :message do |event|
        @publisher.publish(CHANNEL + ws.object_id.to_s, event.data)
      end
    end

    def open_event(ws)
      ws.on :open do |event|
        p [:open, ws.object_id]
        increment_connection_number
        @clients << ws

        subscribe_to_channel ws.object_id.to_s, ws
      end
    end

    def subscribe_to_channel(identifier, ws)
      Thread.new do
        @queue.subscribe identifier, ws
      end
    end

    def decrement_connection_number
      @number_of_connections = @number_of_connections - 1
    end

    def increment_connection_number
      @number_of_connections = @number_of_connections + 1
    end
  end
end
