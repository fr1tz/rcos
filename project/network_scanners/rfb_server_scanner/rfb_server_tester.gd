# Copyright © 2018 Michael Goldener <mg@wasted.ch>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

extends Node

var mAddress = ""
var mPort = -1
var mTcpConnection = null
var mServerVersion = null
var mTestFinished = false

func _init():
	add_user_signal("test_finished")

func _ready():
	get_node("abort_test_timer").connect("timeout", self, "_die")
	mTcpConnection = get_node("tcp_connection")
	mTcpConnection.connect("connection_state_changed", self, "_connection_state_changed")

func _die():
	if !mTestFinished:
		emit_signal("test_finished", mServerVersion)
	queue_free()

func _connection_state_changed(new_state, old_state, reason):
	#dbg#var old_state_string = mTcpConnection.get_cs_string(old_state)
	#dbg#var new_state_string = mTcpConnection.get_cs_string(new_state)
	#dbg#var reason_string = mTcpConnection.get_cs_string(reason)
	#dbg#prints(old_state_string, "->", new_state_string, ":", reason_string)
	if new_state == mTcpConnection.CS_DISCONNECTED:
		_die()

func _process_data(data):
	#dbg#prints("have", data.size(), "bytes")
	if mServerVersion == null && data.size() >= 12:
		var msg = data.get_string_from_ascii()
		var words = msg.split(" ", false)
		if words.size() != 2 || words[0] != "RFB":
			emit_signal("test_finished", null)
			return
		var version_tuple = words[1].split(".", false)
		if version_tuple.size() != 2:
			emit_signal("test_finished", null)
			return
		var major_version = int(version_tuple[0])
		var minor_version = int(version_tuple[1])
		mServerVersion = str(major_version)+"."+str(minor_version)
		#dbg#prints("server version", mServerVersion)
		emit_signal("test_finished", mServerVersion)
		var reply = "RFB 999.999\n".to_ascii()
		mTcpConnection.send_data(reply)
		#dbg#prints("sent reply")
		return 12
	else:
		if mServerVersion == "3.3":
			if data.size() < 4:
				return 0
			var buf = StreamPeerBuffer.new()
			buf.set_big_endian(true)
			buf.set_data_array(data)
			buf.seek(0)
			var security_type = buf.get_u32()
			#dbg#prints("security_type:", security_type)
			if security_type == 0: # Error
				var reason_length = buf.get_u32()
				#dbg#prints("reson_length", reason_length)
				var reason = buf.get_utf8_string(reason_length)
				#dbg#prints("reason:", reason)
				var msg_length = buf.get_pos()
				#dbg#prints("msg_length:", msg_length)
				_die()
				return msg_length
		else:
			if data.size() < 1:
				return 0
			var buf = StreamPeerBuffer.new()
			buf.set_big_endian(true)
			buf.set_data_array(data)
			buf.seek(0)
			var num_security_types = buf.get_u8()
			#dbg#prints("num_security_types:", num_security_types)
			if num_security_types == 0:
				var reason_length = buf.get_u32()
				#dbg#prints("reson_length", reason_length)
				if buf.get_available_bytes() < reason_length:
					return 0
				var reason = buf.get_utf8_string(reason_length)
				#dbg#prints("reason:", reason)
				var msg_length = buf.get_pos()
				#dbg#prints("msg_length:", msg_length)
				_die()
				return msg_length
	return 0

func get_address():
	return mAddress

func get_port():
	return mPort

func test(address, port):
	set_name("rfb_server_tester [port "+str(port)+"]")
	mAddress = address
	mPort = port
	if !mTcpConnection.connect_to_server(mAddress, mPort, funcref(self, "_process_data"), 3):
		queue_free()
		return
	get_node("abort_test_timer").start()
