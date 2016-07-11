module ChatDemo
  class Terminal
    attr_accessor :connection, :serial_number

    def initialize(serial_number)
      @serial_number = serial_number
    end

    def send(message)
      @connection.send message
    end
  end
end
