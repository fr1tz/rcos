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
var mTestResult = null
var mTestResultSubmitted = false

func _init():
	add_user_signal("test_finished")

func _ready():
	get_node("death_timer").connect("timeout", self, "_die")
	mTcpConnection = get_node("tcp_connection")
	mTcpConnection.connect("connection_state_changed", self, "_connection_state_changed")

func _submit_test_result(result):
	mTestResult = result
	emit_signal("test_finished", mTestResult)
	mTestResultSubmitted = true

func _dbg(a1=null,a2=null,a3=null,a4=null,a5=null,a6=null,a7=null,a8=null,a9=null):
	prints("rfb_port_tester", mAddress, mPort, a1, a2, a3, a4, a5, a6, a7, a8, a9)

func _die():
	#_dbg("_die()")
	get_node("death_timer").stop()
	if !mTestResultSubmitted:
		_submit_test_result(null)
	queue_free()

func _connection_state_changed(new_state, old_state, reason):
	#dbg#var old_state_string = mTcpConnection.get_cs_string(old_state)
	#dbg#var new_state_string = mTcpConnection.get_cs_string(new_state)
	#dbg#var reason_string = mTcpConnection.get_rsn_string(reason)
	#dbg#prints(mAddress, mPort, old_state_string, "->", new_state_string, ":", reason_string)
	if new_state == mTcpConnection.CS_DISCONNECTED:
		_die()

func _process_data(data):
	#dbg#prints(mAddress, mPort, "have", data.size(), "bytes")
	if mTestResult == null && data.size() >= 12:
		var msg = data.get_string_from_ascii()
		var words = msg.split(" ", false)
		if words.size() != 2 || words[0] != "RFB":
			_die()
			return
		var version_tuple = words[1].split(".", false)
		if version_tuple.size() != 2:
			_die()
			return
		var major_version = int(version_tuple[0])
		var minor_version = int(version_tuple[1])
		var version = str(major_version)+"."+str(minor_version)
		#dbg#prints("mAddress, mPort, server version", mTestResult)
		_submit_test_result(version)
		_die()
		return 12
		var reply = "RFB 999.999\n".to_ascii()
		mTcpConnection.send_data(reply)
		#dbg#prints("mAddress, mPort, sent reply")
		return 12
	else:
		if mTestResult == "3.3":
			if data.size() < 4:
				return 0
			var buf = StreamPeerBuffer.new()
			buf.set_big_endian(true)
			buf.set_data_array(data)
			buf.seek(0)
			var security_type = buf.get_u32()
			#dbg#prints(mAddress, mPort, "security_type:", security_type)
			if security_type == 0: # Error
				var reason_length = buf.get_u32()
				#dbg#prints(mAddress, mPort, "reson_length", reason_length)
				var reason = buf.get_utf8_string(reason_length)
				#dbg#prints(mAddress, mPort, "reason:", reason)
				var msg_length = buf.get_pos()
				#dbg#prints(mAddress, mPort, "msg_length:", msg_length)
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
			#dbg#prints(mAddress, mPort, "num_security_types:", num_security_types)
			if num_security_types == 0:
				var reason_length = buf.get_u32()
				#dbg#prints(mAddress, mPort, "reson_length", reason_length)
				if buf.get_available_bytes() < reason_length:
					return 0
				var reason = buf.get_utf8_string(reason_length)
				#dbg#prints(mAddress, mPort, "reason:", reason)
				var msg_length = buf.get_pos()
				#dbg#prints(mAddress, mPort, "msg_length:", msg_length)
				_die()
				return msg_length
	return 0

func get_address():
	return mAddress

func get_port():
	return mPort

func test(address, port):
	set_name("rfb_port_tester ["+str(port)+"]")
	mAddress = address
	mPort = port
	#_dbg("starting test")
	mTcpConnection.set_poll_interval(3)
	if !mTcpConnection.connect_to_server(mAddress, mPort, funcref(self, "_process_data"), 10):
		_die()
		return
	get_node("death_timer").start()
