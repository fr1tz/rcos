# Copyright © 2017, 2018 Michael Goldener <mg@wasted.ch>
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

var mStream = null
var mRemoteAddress = ""
var mRemotePort = -1
var mReceiveBuffer = RawArray()
var mSendBuffer = RawArray()

func _init():
	add_user_signal("message_received")

func _ready():
	get_node("io_timer").connect("timeout", self, "_process_io")

func _process_io():
	var status = mStream.get_status()
	if status == StreamPeerTCP.STATUS_CONNECTING:
		print("connecting")
	elif status == StreamPeerTCP.STATUS_CONNECTED:
		_receive_data()
		_process_data()
	else:
		prints("error:", status)

func _receive_data():
	if mStream.get_available_bytes() == 0:
		return
	#prints("bytes available:", mStream.get_available_bytes())
	var r = mStream.get_partial_data(mStream.get_available_bytes())
	var error = r[0]
	var data = r[1]
	if error:
		rcos.log_debug(self, ["_receive_data() ERROR:", error])
		return
	mReceiveBuffer.append_array(data)

func _process_data():
	var n = 10
	while n > 0:
		if mReceiveBuffer.size() == 0:
			return
		n -= 1
		var msg_size = -1
		for i in range(0, mReceiveBuffer.size()):
			if mReceiveBuffer[i] == 10: # Line feed
				msg_size = i
				break
		if msg_size == -1:
			break
		if msg_size > 0:
			var msg_data = RawArray(mReceiveBuffer)
			msg_data.resize(msg_size);
			var msg = msg_data.get_string_from_utf8()
			emit_signal("message_received", msg)
		mReceiveBuffer.invert()
		mReceiveBuffer.resize(mReceiveBuffer.size()-msg_size-1)
		mReceiveBuffer.invert()

func connect_to_server(address, port):
	mStream = StreamPeerTCP.new()
	if mStream.connect(address, port) != OK:
		return false
	get_node("io_timer").start()
