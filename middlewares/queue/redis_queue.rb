require 'redis'
module ChatDemo
  class RedisQueue
    CHANNEL = 'chat-demo'
    attr_writer :connection

    def subscribe(channel_index = '0', ws)
      connection_stub.subscribe(computed_channel channel_index) do |on|
        on.message do |channel, msg|
          ws.send msg
        end
      end
    end

    def add_channel(index)
      separator = @registered_channels.empty? ? '' : ' '
      @registered_channels = @registered_channels + separator + computed_channel(index)
    end

    def connection_stub
      @connect ||= Redis.new
    end

    def computed_channel(index)
      CHANNEL + index
    end
  end
end
