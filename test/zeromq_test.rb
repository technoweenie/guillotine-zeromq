require 'test/unit'
require File.expand_path('../../lib/guillotine-zeromq', __FILE__)

class ZeroMQTest < Test::Unit::TestCase
  def setup
    @adapter = Guillotine::Adapters::MemoryAdapter.new

    @context = ZMQ::Context.new
    @rep = @context.socket ZMQ::REP
    @req = @context.socket ZMQ::REQ

    [@req, @rep].each do |socket|
      socket.setsockopt ZMQ::LINGER, 0
    end

    @app = Guillotine::Zeromq::App.new(@adapter, @rep)
    @rep.bind 'inproc://guillotine'
    @req.connect 'inproc://guillotine'
  end

  def teardown
    [@req, @rep].each { |socket| socket.close }
    @context.terminate
  end

  def test_gets_full_url
    code = @adapter.add url='http://example.com'

    request :find, code

    @app.run

    assert_equal url, response
  end

  def test_add_url
    request :add, url='http://foobar.com'

    @app.run

    code = response

    assert_equal url, @adapter.find(code)
  end

  def request(method, query)
    @req.send_string "#{method} #{query}"
  end

  def response
    res = @req.recv_string resp=''
    assert ZMQ::Util.resultcode_ok?(res), "ZMQ Error: #{res.inspect}" 
    resp
  end
end

