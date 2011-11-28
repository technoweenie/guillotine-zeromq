require 'guillotine'
require 'ffi-rzmq'
require 'yajl'

module Guillotine
  module Zeromq
    class App
      def initialize(adapter, socket)
        @adapter = adapter
        @socket = socket
      end

      def run
        msg = gets
        method, *params = msg.split ' '
        res = send "call_#{method}", *params
        @socket.send_string res.to_s
      end

      def call_find(code)
        @adapter.find(code)
      end

      def call_add(url, code = nil)
        @adapter.add url, code
      end

      def gets
        string = ''
        result = @socket.recv_string(string)
        if ZMQ::Util.resultcode_ok?(result)
          string
        else
          raise result.inspect
        end
      end
    end
  end
end

