require 'socket'

class UdpConnector

  def initialize(host, port)
    @socket = UDPSocket.new
    @socket.connect(host, port)
  end

  def send_message(message)
    @socket.send(message, 0)
  end

  def receive_message
    msg, sender = @socket.recvfrom(10000)
    msg
  end
end
