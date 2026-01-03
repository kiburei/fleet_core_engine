require "minitest/autorun"
require_relative "../lib/jt808/parser"

class Jt808ParserTest < Minitest::Test
  def test_parse_heartbeat_frame
    # Construct a minimal JT808 heartbeat frame:
    # message_id (0x0002), properties (0x0000), terminal phone (BCD, 6 bytes), serial (0x0001)
    payload = "00020000" + "012345678901" + "0001"

    # Compute checksum (XOR of all payload bytes)
    cs = payload.scan(/../).map { |b| b.to_i(16) }.reduce(0) { |a, v| a ^ v }
    cs_hex = "%02x" % cs

    frame_hex = "7e" + payload + cs_hex + "7e"
    raw = [ frame_hex ].pack("H*")

    pkt = Jt808::Parser.parse(raw)

    assert pkt, "Parser returned nil for valid frame"
    assert_equal 0x0002, pkt[:message_id]
    assert_equal "12345678901", pkt[:phone]
    assert_equal 1, pkt[:serial]
    assert_equal "", pkt[:body_hex]
  end
end
