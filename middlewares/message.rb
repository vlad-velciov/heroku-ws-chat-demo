require 'json'

module ChatDemo
  class Message
    def initialize(message)
      @hash_message = JSON.parse(message)
      p @hash_message
    end

    def serial_number
      @hash_message['serial_number'].to_sym
    end

    def data
      @hash_message['data']
    end



  end
end
