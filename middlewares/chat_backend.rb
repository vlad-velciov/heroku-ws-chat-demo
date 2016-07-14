require 'faye/websocket'
require 'redis'
require 'json'
require 'middlewares/message'
require 'em-hiredis'
require 'profile_helper/profiler'

module ChatDemo
  class ChatBackend

    include ChatDemo::Profiler

    KEEP_ALIVE_TIME = 15
    CHANNEL = 'chat-demo'

    def initialize(app)
      @app = app
      initialize_clients
      start_eventmachine
      listen_all
      @publisher =redis_connection(nil)
    end

    def initialize_clients
      @clients = []
      @clients_hash = {}
      @number_of_connections = 0
    end

    def start_eventmachine
      Thread.new { EM.run } unless EM.reactor_running?
      Thread.pass until EM.reactor_running?
    end

    def listen_all
      EM.next_tick do
        pubsub = redis_connection nil
        pubsub.subscribe(CHANNEL)
        pubsub.on(:message) { |channel, message|
          send_to_terminal(message)
        }
      end
    end

    def send_to_terminal(message)
      parsed_message = Message.new(message)
      @clients_hash[parsed_message.serial_number].send(parsed_message.data) if @clients_hash.has_key? parsed_message.serial_number
    end

    def redis_connection(uri)
      redis = EM::Hiredis.connect uri
      redis.pubsub
    end

    def call(env)
      if Faye::WebSocket.websocket? env
        ws = Faye::WebSocket.new(env, nil, {ping: KEEP_ALIVE_TIME, tls: true})
        open_event(ws)
        message_event(ws)
        ws = close_event(ws)

        ws.rack_response
      else
        @app.call(env)
      end
    end

    def close_event(ws)
      ws.on :close do |event|
        p [:close]
        forget_connection ws
        ws = nil
      end
      ws
    end

    def forget_connection(ws)
      @clients.delete(ws)
      @clients_hash.delete(ws)
      decrement_connection_number
    end

    def message_event(ws)
      ws.on :message do |event|
        @publisher.publish(CHANNEL, event.data)
      end
    end

    def open_event(ws)
      ws.on :open do |event|
        p [:open]
        @clients_hash[ws.object_id.to_s.to_sym] = ws
        increment_connection_number
        @clients << ws
        send_connection_id(ws)
      end
    end

    def send_connection_id(ws)
      ws.send ws.object_id.to_s
    end

    def decrement_connection_number
      @number_of_connections = @number_of_connections - 1
    end

    def increment_connection_number
      @number_of_connections = @number_of_connections + 1
    end
  end
end
