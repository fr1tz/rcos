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
const MSG_TYPE_change_pixel_format = 0
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
const CS_READY_TO_CONNECT = 0
const CS_CONNECTING = 1
const CS_RECEIVE_PROTOCOL_VERSION = 2
const CS_RECEIVE_SECURITY_MSG = 3
const CS_WAITING_FOR_PASSWORD = 4
const CS_RECEIVE_VNC_AUTH_CHALLENGE = 5
const CS_RECEIVE_SECURITY_RESULT_MSG = 6
const CS_RECEIVE_SERVER_INIT_MSG = 7
const CS_RECEIVE_SERVER_MESSAGES = 8
const CS_RECEIVE_FRAMEBUFFER_RECT = 9

const PADDING_BYTE = 0

onready var mIOPorts = get_node("io_ports")
onready var mReadDataTimer = get_node("read_data_timer")
onready var mSendDataTimer = get_node("send_data_timer")
onready var mUpdatePointerTimer = get_node("update_pointer_timer")

var mScancode2Keysym = load("res://rfb/rfb_client/scancode2keysym.gd").new()
var mError = ""
var mStream = null
var mRemoteAddress = ""
var mRemotePort = -1
var mPassword = null
var mReceiveBuffer = RawArray()
var mSendBuffer = RawArray()
var mConnectionState = CS_READY_TO_CONNECT
var mConnectionStateData = {}
var mProtocolVersion = -1
var mDesktopName = ""
var mRFBUtil = RFBUtil.new()
var mFramebuffer = RFBFramebuffer.new()
var mFramebufferImage = null
var mFramebufferWidth = 0
var mFramebufferHeight = 0
var mNaturalPixelFormat = {} # server's natural pixel format
var mPixelFormat = {
	"bits_per_pixel": 32,
	"depth": 32,
	"big_endian_flag": 0,
	"true_color_flag": 1,
	"red_max": 255,
	"green_max": 255,
	"blue_max": 255,
	"red_shift": 16,
	"green_shift": 8,
	"blue_shift": 0
}
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
	add_user_signal("connection_state_changed")
	add_user_signal("connection_established")
	add_user_signal("connection_error")
	add_user_signal("server_cut_text_msg_received")
	add_user_signal("bell_msg_received")
	add_user_signal("framebuffer_changed")

func _ready():
	mIOPorts.initialize(self)
	mReadDataTimer.connect("timeout", self, "_read_data")
	mSendDataTimer.connect("timeout", self, "_send_data")
	mUpdatePointerTimer.connect("timeout", self, "_update_pointer")

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

func _error(msg):
	mError = msg
	rcos.log_error(self, msg)

func _set_connection_state(state):
	mConnectionState = state
	emit_signal("connection_state_changed", state)

func _read_data():
	var status = mStream.get_status()
	if status == StreamPeerTCP.STATUS_CONNECTING:
		rcos.log_debug(self, "connecting")
	elif status == StreamPeerTCP.STATUS_CONNECTED:
		if mConnectionState == CS_CONNECTING:
			_set_connection_state(CS_RECEIVE_PROTOCOL_VERSION)
		_receive_data()
		var n = 50
		while n > 0:
			if _process_receive_buffer() == 0:
				break
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
		mSendDataTimer.stop()

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

func _process_receive_buffer():
	var nbytes = 0
	if mConnectionState == CS_RECEIVE_PROTOCOL_VERSION:
		nbytes = _process_protocol_version(mReceiveBuffer)
	elif mConnectionState == CS_RECEIVE_SECURITY_MSG:
		nbytes = _process_security_msg(mReceiveBuffer)
	elif mConnectionState == CS_RECEIVE_VNC_AUTH_CHALLENGE:
		nbytes = _process_vnc_auth_challenge(mReceiveBuffer)
	elif mConnectionState == CS_RECEIVE_SECURITY_RESULT_MSG:
		nbytes = _process_security_result_msg(mReceiveBuffer)
	elif mConnectionState == CS_RECEIVE_SERVER_INIT_MSG:
		nbytes = _process_server_init_msg(mReceiveBuffer)
	elif mConnectionState == CS_RECEIVE_SERVER_MESSAGES:
		nbytes = _process_server_msg(mReceiveBuffer)
	elif mConnectionState == CS_RECEIVE_FRAMEBUFFER_RECT:
		nbytes = _process_framebuffer_rect(mReceiveBuffer)
	if nbytes == -1:
		_set_connection_state(CS_ERROR)
	elif nbytes > 0:
		mReceiveBuffer.invert()
		mReceiveBuffer.resize(mReceiveBuffer.size()-nbytes)
		mReceiveBuffer.invert()
	return nbytes

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
	_set_connection_state(CS_RECEIVE_SECURITY_MSG)
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
			_error(reason)
			return -1
		elif security_type == 1: # No Authentication
			var client_init_msg = RawArray()
			client_init_msg.append(1) # request shared session	
			send_data(client_init_msg)
			_set_connection_state(CS_RECEIVE_SERVER_INIT_MSG)
			return 4
		elif security_type == 2: # VNC Authentication 
			_error("VNC auth not implemented for protocol version 3.3")
			return -1
	else:
		if data.size() < 1:
			return 0
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
			_error(reason)
			return -1
		var msg_length = 1 + num_security_types
		if data.size() < msg_length:
			return 0
		var available_security_types = []
		for i in range(1, msg_length):
			var security_type = data[i]
			rcos.log_debug(self, ["available security type:", security_type])
			available_security_types.push_back(security_type)
		var security_type
		if available_security_types.has(1):
			security_type = 1
		elif available_security_types.has(2):
			security_type = 2
		else:
			_error("No supported security type available")
			return -1
		var security_type_msg = RawArray()
		security_type_msg.append(security_type)
		send_data(security_type_msg)
		if security_type == 2:
			if mPassword == null:
				_set_connection_state(CS_WAITING_FOR_PASSWORD)
			else:
				_set_connection_state(CS_RECEIVE_VNC_AUTH_CHALLENGE)
		else:
			if mProtocolVersion == PROTOCOL_VERSION_3_8:
				_set_connection_state(CS_RECEIVE_SECURITY_RESULT_MSG)
			elif mProtocolVersion == PROTOCOL_VERSION_3_7:
				_set_connection_state(CS_RECEIVE_SERVER_INIT_MSG)
		return msg_length

func _process_vnc_auth_challenge(data):
	rcos.log_debug(self, "_process_vnc_auth_challenge()")
	if data.size() < 16:
		return 0
	var password = mPassword.to_ascii()
	var key = RawArray()
	for i in range(0, 8):
		if i < password.size():
			key.append(password[i])
		else:
			key.append(0)
	var challenge = RawArray()
	challenge.append_array(data)
	challenge.resize(16)
	var response = mRFBUtil.des_encrypt(challenge, key)
	send_data(response)
	_set_connection_state(CS_RECEIVE_SECURITY_RESULT_MSG)
	return 16

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
		_set_connection_state(CS_RECEIVE_SERVER_INIT_MSG)
		return 4
	# FAILURE
	if data.size() < 8:
		return 0
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
	rcos.log_debug(self, ["error:", reason])
	return -1

func _process_server_init_msg(data):
	rcos.log_debug(self, "_process_server_init_msg()")
	if data.size() < 24:
		return 0
	var name_length= _decode_uint32(data[20], data[21], data[22], data[23])
	var msg_length = 24 + name_length
	if data.size() < msg_length:
		return 0
	mFramebufferWidth = _decode_uint16(data[0], data[1])
	mFramebufferHeight = _decode_uint16(data[2], data[3])
	mNaturalPixelFormat["bits_per_pixel"] = data[4]
	mNaturalPixelFormat["depth"] = data[5]
	mNaturalPixelFormat["big_endian_flag"] = data[6]
	mNaturalPixelFormat["true_color_flag"] = data[7]
	mNaturalPixelFormat["red_max"] = _decode_uint16(data[8], data[9])
	mNaturalPixelFormat["green_max"] = _decode_uint16(data[10], data[11])
	mNaturalPixelFormat["blue_max"] = _decode_uint16(data[12], data[13])
	mNaturalPixelFormat["red_shift"] = data[14]
	mNaturalPixelFormat["green_shift"] = data[15]
	mNaturalPixelFormat["blue_shift"] = data[16]
	#mPixelFormat = mNaturalPixelFormat
	mFramebuffer = RFBFramebuffer.new()
	mFramebuffer.set_size(Vector2(mFramebufferWidth, mFramebufferHeight))
	mFramebuffer.set_pixel_format_bits_per_pixel(mPixelFormat.bits_per_pixel)
	mFramebuffer.set_pixel_format_depth(mPixelFormat.depth)
	mFramebuffer.set_pixel_format_big_endian_flag(mPixelFormat.big_endian_flag)
	mFramebuffer.set_pixel_format_true_color_flag(mPixelFormat.true_color_flag)
	mFramebuffer.set_pixel_format_red_max(mPixelFormat.red_max)
	mFramebuffer.set_pixel_format_green_max(mPixelFormat.green_max)
	mFramebuffer.set_pixel_format_blue_max(mPixelFormat.blue_max)
	mFramebuffer.set_pixel_format_red_shift(mPixelFormat.red_shift)
	mFramebuffer.set_pixel_format_green_shift(mPixelFormat.green_shift)
	mFramebuffer.set_pixel_format_blue_shift(mPixelFormat.blue_shift)
	mFramebufferImage = Image(mFramebufferWidth, mFramebufferHeight, false, Image.FORMAT_RGB)
	mFramebufferImage.fill(Color(0, 1, 0))
	var name_data = RawArray()
	name_data.append_array(data)
	name_data.invert()
	name_data.resize(name_data.size()-24)
	name_data.invert()
	mDesktopName = name_data.get_string_from_ascii()
	rcos.log_debug(self, ["desktop name:", mDesktopName])
	rcos.log_debug(self, ["width:", mFramebufferWidth])
	rcos.log_debug(self, ["height:", mFramebufferHeight])
	rcos.log_debug(self, ["natural pixel format:", mNaturalPixelFormat])
	rcos.log_debug(self, ["new pixel format:", mPixelFormat])
	_set_connection_state(CS_RECEIVE_SERVER_MESSAGES)
	emit_signal("connection_established")
	mUpdatePointerTimer.start()
	_change_pixel_format(mPixelFormat)
	_send_framebuffer_update_request(0, 0, mFramebufferWidth, mFramebufferHeight, 0)
	return msg_length

func _process_server_msg(data):
	if data.size() == 0:
		return 0
	if data[0] == MSG_TYPE_FRAMEBUFFER_UPDATE:
		if data.size() < 4:
			return 0
		mConnectionStateData["num_rects"] = _decode_uint16(data[2], data[3])
		_set_connection_state(CS_RECEIVE_FRAMEBUFFER_RECT)
		return 4
	elif data[0] == MSG_TYPE_SET_COLOUR_MAP_ENTRIES:
		_error("Colour map currently not implemented")
		return -1
	elif data[0] == MSG_TYPE_BELL:
		rcos.log_debug(self, "got bell msg")
		emit_signal("bell_msg_received")
		return 1
	elif data[0] == MSG_TYPE_SERVER_CUT_TEXT:
		if data.size() < 8:
			return 0
		var text_length = _decode_uint32(data[4], data[5], data[6], data[7])
		var msg_length = 8 + text_length
		if data.size() < msg_length:
			return 0
		var text_data = RawArray()
		text_data.append_array(data)
		text_data.invert()
		text_data.resize(text_data.size()-8)
		text_data.invert()
		var text = text_data.get_string_from_ascii()
		rcos.log_debug(self, "got server_cut_text msg: " + text)
		emit_signal("server_cut_text_msg_received", text)
		return msg_length
	return data.size()

func _process_framebuffer_rect(data):
	if data.size() < 12:
		return 0
	var encoding = data[11]
	if encoding != 0:
		return -1
	var rect_width = _decode_uint16(data[4], data[5])
	var rect_height = _decode_uint16(data[6], data[7])
	var rect_data_size = rect_width * rect_height * mPixelFormat.bits_per_pixel/8
	var msg_size = 12 + rect_data_size
	if data.size() < msg_size:
		return 0
	var rect_pos_x = _decode_uint16(data[0], data[1])
	var rect_pos_y = _decode_uint16(data[2], data[3])
	var bytes_per_pixel = mPixelFormat.bits_per_pixel / 8
	var rect = Rect2(rect_pos_x, rect_pos_y, rect_width, rect_height)
	mFramebuffer.put_rect_raw(rect, data, 12)
	mConnectionStateData["num_rects"] -= 1
	if mConnectionStateData["num_rects"] == 0:
		emit_signal("framebuffer_changed", mFramebuffer.get_image())
		_set_connection_state(CS_RECEIVE_SERVER_MESSAGES)
		_send_framebuffer_update_request(0, 0, mFramebufferWidth, mFramebufferHeight, 1)
	return msg_size

func _change_pixel_format(new_pixel_format):
	mPixelFormat = new_pixel_format
	rcos.log_debug(self, ["sending set pixel format message", new_pixel_format])
	var msg = RawArray()
	msg.append(MSG_TYPE_change_pixel_format)
	msg.append(PADDING_BYTE)
	msg.append(PADDING_BYTE)
	msg.append(PADDING_BYTE)
	msg.append(mPixelFormat.bits_per_pixel)
	msg.append(mPixelFormat.depth)
	msg.append(mPixelFormat.big_endian_flag)
	msg.append(mPixelFormat.true_color_flag)
	msg.append_array(_encode_uint16(mPixelFormat.red_max))
	msg.append_array(_encode_uint16(mPixelFormat.green_max))
	msg.append_array(_encode_uint16(mPixelFormat.blue_max))
	msg.append(mPixelFormat.red_shift)
	msg.append(mPixelFormat.green_shift)
	msg.append(mPixelFormat.blue_shift)
	msg.append(PADDING_BYTE)
	msg.append(PADDING_BYTE)
	msg.append(PADDING_BYTE)
	send_data(msg)

func _send_framebuffer_update_request(x, y, width, height, incremental):
	#prints("sending framebuffer update request", 0, 0, mFramebufferWidth, mFramebufferHeight)
	rcos.log_debug(self, ["sending framebuffer update request", 0, 0, mFramebufferWidth, mFramebufferHeight])
	var msg = RawArray()
	msg.append(MSG_TYPE_FRAMEBUFFER_UPDATE_REQUEST)
	msg.append(incremental)
	msg.append_array(_encode_uint16(x))
	msg.append_array(_encode_uint16(y))
	msg.append_array(_encode_uint16(width))
	msg.append_array(_encode_uint16(height))
	send_data(msg)
	
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

func set_password(password):
	mPassword = password
	if mConnectionState == CS_WAITING_FOR_PASSWORD:
		_set_connection_state(CS_RECEIVE_VNC_AUTH_CHALLENGE)

func connect_to_server(address, port):
	mRemoteAddress = address
	mRemotePort = port
	_set_connection_state(CS_CONNECTING)
	mStream = StreamPeerTCP.new()
	if mStream.connect(mRemoteAddress, mRemotePort) != OK:
		_error("Failed to initialize connection")
		_set_connection_state(CS_ERROR)
		return false
	mReadDataTimer.start()
	return true

func get_error():
	return mError

func get_remote_address():
	return mRemoteAddress

func get_remote_port():
	return mRemotePort

func get_desktop_name():
	return mDesktopName

func send_data(data):
	mSendDataTimer.start()
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

func process_key_event(event):
	var keysym = null
	rcos.log_debug(self, event)
	if event.unicode > 0 && event.unicode < 256:
		keysym = event.unicode
	elif mScancode2Keysym.map.has(event.scancode):
		keysym = mScancode2Keysym.map[event.scancode]
	if keysym == null:
		return
	set_key_pressed(keysym, event.pressed)
