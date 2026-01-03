# test_send_jt808.rb
require 'socket'
host = '127.0.0.1'   # or your server IP
port = 6808
# payload hex: message_id 0002 + properties 0000 + phone BCD 012345678901 + serial 0001
payload = "000200000123456789010001"
cs = payload.scan(/../).map{|b| b.to_i(16)}.reduce(0){|a,v| a ^ v}
frame_hex = "7e" + payload + ("%02x" % cs) + "7e"
s = TCPSocket.new(host, port)
s.write([frame_hex].pack("H*"))
puts "sent #{frame_hex}"
sleep 1
s.close
