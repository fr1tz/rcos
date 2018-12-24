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

const CS_DISCONNECTED = 0
const CS_CONNECTING = 1
const CS_CONNECTED = 2

const RSN_OTHER_ERROR = 0
const RSN_READ_ERROR = 1
const RSN_USER_REQUEST = 2
const RSN_CONNECT_TIMED_OUT = 3
const RSN_CONNECT_FAILED = 4
const RSN_CONNECTION_ACCEPTED = 5
const RSN_CONNECTION_LOST = 6

onready var mConnectTimeoutTimer = get_node("timers/connect_timeout")
onready var mPollTimer = get_node("timers/poll")
onready var mSendDataTimer = get_node("timers/send_data")

var mStream = null
var mRemoteAddress = ""
var mRemotePort = -1
var mReceiveBuffer = RawArray()
var mSendBuffer = RawArray()
var mConnectionState = CS_DISCONNECTED
var mProcessReceiveBufferFunc = null

func _init():
	add_user_signal("connection_state_changed")

func _ready():
	mConnectTimeoutTimer.connect("timeout", self, "_connect_timed_out")
	mPollTimer.connect("timeout", self, "_poll")
	mSendDataTimer.connect("timeout", self, "_send_data")

func _set_connection_state(new_state, reason):
	if mConnectionState == new_state:
		return
	var old_state = mConnectionState
	mConnectionState = new_state
	if mConnectionState == CS_DISCONNECTED:
		for timer in get_node("timers").get_children():
			timer.stop()
	elif mConnectionState == CS_CONNECTED:
		mConnectTimeoutTimer.stop()
	emit_signal("connection_state_changed", new_state, old_state, reason)

func _connect_timed_out():
	_set_connection_state(CS_DISCONNECTED, RSN_CONNECT_TIMED_OUT)
	mStream.disconnect()

func _poll():
	var status = mStream.get_status()
	if status == StreamPeerTCP.STATUS_CONNECTED \
	|| mStream.get_available_bytes() > 0:
		if mConnectionState == CS_CONNECTING:
			_set_connection_state(CS_CONNECTED, RSN_CONNECTION_ACCEPTED)
		var error = 0
		if mStream.get_available_bytes() > 0:
			var r = mStream.get_partial_data(mStream.get_available_bytes())
			var read_error = r[0]
			var data = r[1]
			if !read_error:
				mReceiveBuffer.append_array(data)
			else:
				error = read_error
		if mReceiveBuffer.size() > 0:
			var nbytes = mProcessReceiveBufferFunc.call_func(mReceiveBuffer)
			if nbytes > 0:
				mReceiveBuffer.invert()
				mReceiveBuffer.resize(mReceiveBuffer.size()-nbytes)
				mReceiveBuffer.invert()
		if error:
			_set_connection_state(CS_DISCONNECTED, RSN_READ_ERROR)
			mStream.disconnect()
	elif status != StreamPeerTCP.STATUS_CONNECTING:
		if mConnectionState == CS_CONNECTING:
			_set_connection_state(CS_DISCONNECTED, RSN_CONNECT_FAILED)
		elif mConnectionState == CS_CONNECTED:
			_set_connection_state(CS_DISCONNECTED, RSN_CONNECTION_LOST)

func _send_data():
	if mSendBuffer.size() == 0:
		return
	mStream.set_nodelay(true)
	var r = mStream.put_partial_data(mSendBuffer)
	var error = r[0]
	var nbytes = r[1]
	if error:
		_set_connection_state(CS_DISCONNECTED)
		return
	mSendBuffer.invert()
	mSendBuffer.resize(mSendBuffer.size()-nbytes)
	mSendBuffer.invert()
	if mSendBuffer.size() == 0:
		mSendDataTimer.stop()

func get_cs_string(cs):
	if cs == CS_DISCONNECTED:
		return "disconnected"
	elif cs == CS_CONNECTING:
		return "connecting"
	elif cs == CS_CONNECTED:
		return "connected"
	else:
		return ""

func get_rsn_string(cs):
	if cs == RSN_OTHER_ERROR:
		return "other error"
	elif cs == RSN_READ_ERROR:
		return "error while trying to read data from stream"
	elif cs == RSN_USER_REQUEST:
		return "requested by user"
	elif cs == RSN_CONNECT_TIMED_OUT:
		return "connection-attempt timed out"
	elif cs == RSN_CONNECT_FAILED:
		return "connection-attempt failed"
	elif cs == RSN_CONNECTION_ACCEPTED:
		return "remote host accepted connection"
	elif cs == RSN_CONNECTION_LOST:
		return "lost connection to remote host"
	else:
		return ""

func send_data(data):
	if mConnectionState == CS_DISCONNECTED:
		return
	mSendDataTimer.start()
	mSendBuffer.append_array(data)
	if mStream.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		_send_data()

func set_poll_interval(interval):
	mPollTimer.set_wait_time(interval)

func disconnect_from_server():
	if mStream != null:
		mStream.disconnect()
		mStream = null
	_set_connection_state(CS_DISCONNECTED, RSN_USER_REQUEST)

func connect_to_server(address, port, process_receive_buffer_func, timeout = 3):
	disconnect_from_server()
	mRemoteAddress = address
	mRemotePort = port
	mProcessReceiveBufferFunc = process_receive_buffer_func
	mReceiveBuffer.resize(0)
	mSendBuffer.resize(0)
	mStream = StreamPeerTCP.new()
	if mStream.connect(mRemoteAddress, mRemotePort) != OK:
		return false
	_set_connection_state(CS_CONNECTING, RSN_USER_REQUEST)
	mConnectTimeoutTimer.set_wait_time(timeout)
	mConnectTimeoutTimer.start()
	mPollTimer.start()
	return true
