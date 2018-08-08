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

const PROTOCOL_VERSION_3_3 = 0
const PROTOCOL_VERSION_3_7 = 1
const PROTOCOL_VERSION_3_8 = 2

# Client -> server msg types
const MSG_TYPE_SET_PIXEL_FORMAT = 0
const MSG_TYPE_SET_ENCODINGS = 2
const MSG_TYPE_FRAMEBUFFER_UPDATE_REQUEST = 3
const MSG_TYPE_KEY_EVENT = 4
const MSG_TYPE_POINTER_EVENT = 5
const MSG_TYPE_CLIENT_CUT_TEXT = 6

# Server -> client msg types
const MSG_TYPE_FRAMEBUFFER_UPDATE = 0
const MSG_TYPE_SET_COLOUR_MAP_ENTRIES = 1
const MSG_TYPE_BELL = 2
const MSG_TYPE_SERVER_CUT_TEXT = 3

# Connection state
const CS_ERROR = -1
const CS_NOT_CONNECTED = 0
const CS_RECEIVE_PROTOCOL_VERSION = 1
const CS_RECEIVE_SECURITY_MSG = 2
const CS_RECEIVE_SECURITY_RESULT_MSG = 3
const CS_RECEIVE_SERVER_INIT_MSG = 4
const CS_RECEIVE_SERVER_MESSAGES = 5

const PADDING_BYTE = 0

var mStream = null
var mRemoteAddress = ""
var mRemotePort = -1
var mReceiveBuffer = RawArray()
var mSendBuffer = RawArray()
var mConnectionState = CS_NOT_CONNECTED
var mProtocolVersion = -1
var mDesktopName = ""
var mFramebufferWidth = 0
var mFramebufferHeight = 0
var mPointer = {
	"fpos_x": 0,
	"fpos_y": 0,
	"ipos_x": -1,
	"ipos_y": -1,
	"speed_x": 0,
	"speed_y": 0,
	"speed_multiplier": 20,
	"button_mask": 0,
	"dirty": false
}

func _init():
	add_user_signal("connection_established")
	add_user_signal("connection_error")
	add_user_signal("server_cut_text_msg_received")
	add_user_signal("bell_msg_received")

func _ready():
	get_node("read_data_timer").connect("timeout", self, "_read_data")
	get_node("send_data_timer").connect("timeout", self, "_send_data")
	get_node("update_pointer_timer").connect("timeout", self, "_update_pointer")

func _decode_uint16(b1, b2):
	var value = b2
	value |= (b1 << 8)
	return value

func _decode_uint32(b1, b2, b3, b4):
	var value = b4
	value |= (b3 << 8)
	value |= (b2 << 16)
	value |= (b1 << 24)
	return value

func _encode_uint16(value):
	value = int(value)
	var bytes = RawArray()
	bytes.append((value & 0xFF00) >> 8)
	bytes.append((value & 0x00FF))
	return bytes

func _encode_uint32(value):
	value = int(value)
	var bytes = RawArray()
	bytes.append((value & 0xFF000000) >> 24)
	bytes.append((value & 0x00FF0000) >> 16)
	bytes.append((value & 0x0000FF00) >> 8)
	bytes.append((value & 0x000000FF))
	return bytes

func _read_data():
	var status = mStream.get_status()
	if status == StreamPeerTCP.STATUS_CONNECTING:
		rcos.log_debug(self, "connecting")
	elif status == StreamPeerTCP.STATUS_CONNECTED:
		if mConnectionState == CS_NOT_CONNECTED:
			mConnectionState = CS_RECEIVE_PROTOCOL_VERSION
		_receive_data()
		_process_data()
	else:
		rcos.log_debug(self, ["error:", status])
		emit_signal("connection_error", status)

func _send_data():
	if mSendBuffer.size() == 0:
		return
	var r = mStream.put_partial_data(mSendBuffer)
	var error = r[0]
	var nbytes = r[1]
	if error:
		rcos.log_debug(self, ["_send_data() ERROR:", error])
		return
	mSendBuffer.invert()
	mSendBuffer.resize(mSendBuffer.size()-nbytes)
	mSendBuffer.invert()
	if mSendBuffer.size() == 0:
		get_node("send_data_timer").stop()

func _receive_data():
	if mStream.get_available_bytes() == 0:
		return
	#rcos.log_debug(self, ["bytes available:", mStream.get_available_bytes())
	var r = mStream.get_partial_data(mStream.get_available_bytes())
	var error = r[0]
	var data = r[1]
	if error:
		rcos.log_debug(self, ["_receive_data() ERROR:", error])
		return
	mReceiveBuffer.append_array(data)

func _process_data():
	var num_processed_bytes = 0
	if mConnectionState == CS_RECEIVE_PROTOCOL_VERSION:
		num_processed_bytes = _process_protocol_version(mReceiveBuffer)
	elif mConnectionState == CS_RECEIVE_SECURITY_MSG:
		num_processed_bytes = _process_security_msg(mReceiveBuffer)
	elif mConnectionState == CS_RECEIVE_SECURITY_RESULT_MSG:
		num_processed_bytes = _process_security_result_msg(mReceiveBuffer)
	elif mConnectionState == CS_RECEIVE_SERVER_INIT_MSG:
		num_processed_bytes = _process_server_init_msg(mReceiveBuffer)
	elif mConnectionState == CS_RECEIVE_SERVER_MESSAGES:
		num_processed_bytes = _process_server_msg(mReceiveBuffer)
	if num_processed_bytes == -1:
		mConnectionState = CS_ERROR
	elif num_processed_bytes > 0:
		mReceiveBuffer.invert()
		mReceiveBuffer.resize(mReceiveBuffer.size()-num_processed_bytes)
		mReceiveBuffer.invert()

func _process_protocol_version(data):
	rcos.log_debug(self, "_process_protocol_version()")
	var s = ""
	for i in range(0, data.size()):
		s += str(data[i]) + " "
	rcos.log_debug(self, s)
	if data.size() < 12:
		return 0
	data.resize(12)
	var msg = data.get_string_from_ascii()
	rcos.log_debug(self, ["protocol version msg:", msg])
	var words = msg.split(" ", false)
	if words.size() != 2 || words[0] != "RFB":
		return -1
	var version_tuple = words[1].split(".", false)
	if version_tuple.size() != 2:
		return -1
	var major_version = int(version_tuple[0])
	var minor_version = int(version_tuple[1])
	rcos.log_debug(self, ["version:", major_version, minor_version])
	if major_version != 3 || minor_version > 8:
		return -1
	var protocol_version_msg
	if minor_version == 8:
		mProtocolVersion = PROTOCOL_VERSION_3_8
		protocol_version_msg = "RFB 003.008\n".to_ascii()
	elif minor_version == 7:
		mProtocolVersion = PROTOCOL_VERSION_3_7
		protocol_version_msg = "RFB 003.007\n".to_ascii()
	else:
		mProtocolVersion = PROTOCOL_VERSION_3_3
		protocol_version_msg = "RFB 003.003\n".to_ascii()
	send_data(protocol_version_msg)
	mConnectionState = CS_RECEIVE_SECURITY_MSG
	return 12

func _process_security_msg(data):
	rcos.log_debug(self, "_process_security_msg()")
	var s = ""
	for i in range(0, data.size()):
		s += str(data[i]) + " "
	rcos.log_debug(self, s)
	if mProtocolVersion == PROTOCOL_VERSION_3_3:
		if data.size() < 4:
			return -1
		var security_type = data[3]
		rcos.log_debug(self, ["security_type:", security_type])
		if security_type == 0: # Error
			var reason_length = _decode_uint32(data[4], data[5], data[6], data[7])
			var msg_length = 8 + reason_length
			if data.size() < msg_length:
				return 0
			var reason_data = RawArray()
			reason_data.append_array(data)
			reason_data.invert()
			reason_data.resize(reason_data.size()-8)
			reason_data.invert()
			var reason = reason_data.get_string_from_ascii()
			rcos.log_error(self, ["error:", reason])
			return -1
		elif security_type == 1: # No Authentication
			var client_init_msg = RawArray()
			client_init_msg.append(1) # request shared session	
			send_data(client_init_msg)
			mConnectionState = CS_RECEIVE_SERVER_INIT_MSG
			return 4
		elif security_type == 2: # VNC Authentication 
			rcos.log_error(self, ["error: vnc auth not implemented (TODO: implement vnc_client using libvnc)"])
			return -1
	else:
		var num_security_types = data[0]
		rcos.log_debug(self, ["num_security_types:", num_security_types])
		if num_security_types == 0:
			if data.size() < 5:
				return 0
			var reason_length = _decode_uint32(data[1], data[2], data[3], data[4])
			var msg_length = 5 + reason_length
			if data.size() < msg_length:
				return 0
			var reason_data = RawArray()
			reason_data.append_array(data)
			reason_data.invert()
			reason_data.resize(reason_data.size()-5)
			reason_data.invert()
			var reason = reason_data.get_string_from_ascii()
			rcos.log_error(self, ["error:", reason])
			return -1
		var msg_length = 1 + num_security_types
		if data.size() < msg_length:
			return 0
		var available_security_types = []
		for i in range(1, msg_length):
			var security_type = data[i]
			rcos.log_debug(self, ["available security type:", security_type])
			available_security_types.push_back(security_type)
		if !available_security_types.has(1):
			rcos.log_debug(self, ["error: server requires authentication"])
			return -1
		var security_type_msg = RawArray()
		security_type_msg.append(1)
		send_data(security_type_msg)
		if mProtocolVersion == PROTOCOL_VERSION_3_8:
			mConnectionState = CS_RECEIVE_SECURITY_RESULT_MSG
		elif mProtocolVersion == PROTOCOL_VERSION_3_7:
			mConnectionState = CS_RECEIVE_SERVER_INIT_MSG
		return msg_length

func _process_security_result_msg(data):
	rcos.log_debug(self, "_process_security_result_msg()")
	var s = ""
	for i in range(0, data.size()):
		s += str(data[i]) + " "
	rcos.log_debug(self, s)
	if data.size() < 4:
		return 0
	if data[3] == 0: # SUCCESS
		var client_init_msg = RawArray()
		client_init_msg.append(1) # request shared session
		send_data(client_init_msg)
		mConnectionState = CS_RECEIVE_SERVER_INIT_MSG
		return 4
	# FAILURE
	if data.size() < 8:
		return 0
	var reason_length = _decode_uint32(data[1], data[2], data[3], data[4])
	var msg_length = 8 + reason_length
	if data.size() < msg_length:
		return 0
	var reason_data = RawArray()
	reason_data.append_array(data)
	reason_data.invert()
	reason_data.resize(reason_data.size()-8)
	reason_data.invert()
	var reason = reason_data.get_string_from_ascii()
	rcos.log_debug(self, ["error:", reason])
	return -1

func _process_server_init_msg(data):
	rcos.log_debug(self, "_process_server_init_msg()")
	if data.size() < 24:
		return 0
	mFramebufferWidth = _decode_uint16(data[0], data[1])
	mFramebufferHeight = _decode_uint16(data[2], data[3])
	var name_length= _decode_uint32(data[20], data[21], data[22], data[23])
	var msg_length = 24 + name_length
	if data.size() < msg_length:
		return 0
	var name_data = RawArray()
	name_data.append_array(data)
	name_data.invert()
	name_data.resize(name_data.size()-24)
	name_data.invert()
	mDesktopName = name_data.get_string_from_ascii()
	rcos.log_debug(self, ["desktop name:", mDesktopName])
	rcos.log_debug(self, ["width:", mFramebufferWidth])
	rcos.log_debug(self, ["height:", mFramebufferHeight])
	mConnectionState = CS_RECEIVE_SERVER_MESSAGES
	emit_signal("connection_established")
	set_fixed_process(true)
	get_node("update_pointer_timer").start()
	return msg_length

func _process_server_msg(data):
	if data.size() == 0:
		return 0
	var s = ""
	for i in range(0, mReceiveBuffer.size()):
		#s += ("%2o " % data[i])
		s += str(mReceiveBuffer[i]) + " "
	rcos.log_debug(self, [data.size(), ":", s])
	if data[0] == MSG_TYPE_FRAMEBUFFER_UPDATE:
		return data.size()
	elif data[0] == MSG_TYPE_SET_COLOUR_MAP_ENTRIES:
		return data.size()
	elif data[0] == MSG_TYPE_BELL:
		rcos.log_debug(self, "got bell msg")
		emit_signal("bell_msg_received")
		return 1
	elif data[0] == MSG_TYPE_SERVER_CUT_TEXT:
		var text_length = _decode_uint32(data[4], data[5], data[6], data[7])
		var msg_length = 8 + text_length
		var text_data = RawArray()
		text_data.append_array(data)
		text_data.invert()
		text_data.resize(text_data.size()-8)
		text_data.invert()
		var text = text_data.get_string_from_ascii()
		rcos.log_debug(self, "got server_cut_text msg: " + text)
		emit_signal("server_cut_text_msg_received", text)
		return data.size()
	return data.size()

func _update_pointer():
	mPointer.fpos_x += mPointer.speed_x * mPointer.speed_multiplier
	mPointer.fpos_y += mPointer.speed_y * mPointer.speed_multiplier
	mPointer.fpos_x = clamp(mPointer.fpos_x, 0, mFramebufferWidth)
	mPointer.fpos_y = clamp(mPointer.fpos_y, 0, mFramebufferHeight)
	if int(mPointer.fpos_x) != mPointer.ipos_x \
	|| int(mPointer.fpos_y) != mPointer.ipos_y:
		mPointer.dirty = true
	if !mPointer.dirty:
		return
	rcos.log_debug(self, ["sending poiner event", mPointer.fpos_x, mPointer.fpos_y, mPointer.button_mask])
	var pointer_event_msg = RawArray()
	pointer_event_msg.append(MSG_TYPE_POINTER_EVENT)
	pointer_event_msg.append(mPointer.button_mask)
	pointer_event_msg.append_array(_encode_uint16(mPointer.fpos_x))
	pointer_event_msg.append_array(_encode_uint16(mPointer.fpos_y))
	send_data(pointer_event_msg)
	mPointer.ipos_x = int(mPointer.fpos_x)
	mPointer.ipos_y = int(mPointer.fpos_y)
	mPointer.dirty = false

func connect_to_server(address, port):
	mConnectionState = CS_NOT_CONNECTED
	mStream = StreamPeerTCP.new()
	if mStream.connect(address, port) != OK:
		return false
	get_node("read_data_timer").start()
	return true

func get_desktop_name():
	return mDesktopName

func send_data(data):
	get_node("send_data_timer").start()
	mSendBuffer.append_array(data)
	_send_data()

func send_clipboard(text):
	var client_cut_text_msg = RawArray()
	client_cut_text_msg.append(MSG_TYPE_CLIENT_CUT_TEXT)
	client_cut_text_msg.append(PADDING_BYTE)
	client_cut_text_msg.append(PADDING_BYTE)
	client_cut_text_msg.append(PADDING_BYTE)
	client_cut_text_msg.append_array(_encode_uint32(text.length()))
	client_cut_text_msg.append_array(text.to_ascii())
	send_data(client_cut_text_msg)

func set_key_pressed(keysym, pressed = true):
	var key_event_msg = RawArray()
	key_event_msg.append(MSG_TYPE_KEY_EVENT)
	key_event_msg.append(pressed)
	key_event_msg.append(PADDING_BYTE)
	key_event_msg.append(PADDING_BYTE)
	key_event_msg.append_array(_encode_uint32(keysym))
	send_data(key_event_msg)

func send_char(c):
	if c == null || c.length() != 1:
		return
	var keysym = c.to_ascii()[0]
	var key_event_msg = RawArray()
	key_event_msg.append(MSG_TYPE_KEY_EVENT)
	key_event_msg.append(1)
	key_event_msg.append(PADDING_BYTE)
	key_event_msg.append(PADDING_BYTE)
	key_event_msg.append_array(_encode_uint32(keysym))
	send_data(key_event_msg)
	key_event_msg.set(1, 0)
	send_data(key_event_msg)

func send_text(text):
	for c in text:
		send_char(c)

func set_pointer_pos_x(val):
	if typeof(val) == TYPE_INT:
		val = val
	elif typeof(val) == TYPE_REAL:
		val = val*mFramebufferWidth
	elif typeof(val) == TYPE_VECTOR2 || typeof(val) == TYPE_VECTOR3:
		val = val.x
	elif typeof(val) == TYPE_STRING:
		if val.find(".") >= 0:
			val = float(val)*mFramebufferWidth
		else:
			val = int(val)
	else:
		val = 0
	mPointer.fpos_x = clamp(val, 0, mFramebufferWidth)

func set_pointer_pos_y(val):
	if typeof(val) == TYPE_INT:
		val = val
	elif typeof(val) == TYPE_REAL:
		val = val*mFramebufferHeight
	elif typeof(val) == TYPE_VECTOR2 || typeof(val) == TYPE_VECTOR3:
		val = val.x
	elif typeof(val) == TYPE_STRING:
		if val.find(".") >= 0:
			val = float(val)*mFramebufferHeight
		else:
			val = int(val)
	else:
		val = 0
	mPointer.fpos_y = clamp(val, 0, mFramebufferHeight)

func set_pointer_speed_x(val):
	if val == null:
		val = 0
	else:
		val = float(val)
	mPointer.speed_x = clamp(val, -10, 10)

func set_pointer_speed_y(val):
	if val == null:
		val = 0
	else:
		val = float(val)
	mPointer.speed_y = clamp(val, -10, 10)

func set_pointer_speed_multiplier(val):
	if val == null:
		val = 10
	else:
		val = float(val)
	mPointer.speed_multiplier = clamp(val, 1, 100)

func set_button_pressed(button_num, val):
	var pressed = false
	if val != null:
		pressed = bool(val)
	if pressed:
		mPointer.button_mask |= (1 << (button_num-1))
	else:
		mPointer.button_mask &= ~(1 << (button_num-1))
	mPointer.dirty = true
