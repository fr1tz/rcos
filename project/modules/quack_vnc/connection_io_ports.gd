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

enum PortClass {
	BELL,
	CLIPBOARD_TEXT,
	KB_TYPE_TEXT,
	KB_PRESS_KEY,
	KB_RELEASE_KEY,
	PTR_POS,
	PTR_POS_X,
	PTR_POS_Y,
	PTR_POS_DELTA,
	PTR_POS_X_DELTA,
	PTR_POS_Y_DELTA,
	PTR_SPEED,
	PTR_SPEED_X,
	PTR_SPEED_Y,
	PTR_BUTTON,
	FB_IMAGE,
	FB_WIDTH,
	FB_HEIGHT,
	FB_SIZE
}

var mConnection = null
var mOutputPortsMeta = {}
var mInputPortsMeta = {}
var mOutputPorts = []
var mInputPorts = []

var mDesktop = {
	"image": null,
	"dirty": false
}
var mCursor = {
	"image": null,
	"dirty": false
}

func _exit_tree():
	_remove_io_ports()

func _add_io_ports():
	var host_addr = mConnection.get_remote_address()
	var host = host_addr
	if rcos.has_node("services/host_info_service"):
		var host_info_service = rcos.get_node("services/host_info_service")
		var host_info = host_info_service.get_host_info_from_address(host_addr)
		if host_info != null:
			host = host_info.get_host_name()
	if host == host_addr:
		var words = mConnection.get_desktop_name().split(" ", false)
		if words[0] != "":
			host = words[0]
			var sep_pos = words[0].find(":")
			if sep_pos > 0:
				host = words[0].left(sep_pos)
	var server_id
	var server_port = mConnection.get_remote_port()
	if server_port >= 5900 && server_port <= 5999:
		server_id = "_"+str(server_port-5900)
	else:
		server_id = "__"+str(server_port)
	var prefix = host.to_lower()+"/rfb"+str(server_id)
	_add_output_ports(prefix)
	_add_input_ports(prefix)
	var icon = load("res://modules/quack_vnc/graphics/icon.server.png")
	var node1 = data_router.get_output_port(prefix)
	var node2 = data_router.get_input_port(prefix)
	for node in [node1, node2]:
		node.set_meta("icon32", icon)
		node.set_meta("icon_label", server_id.replace("_", ":"))

func _remove_io_ports():
	for port in mOutputPorts:
		data_router.remove_port(port)
	for port in mInputPorts:
		data_router.remove_port(port)

func _add_output_ports(prefix):
	mOutputPortsMeta["bell"] = {
		"port_class": BELL,
		"data_type": "bool",
		"icon32": load("res://modules/quack_vnc/graphics/icon.bell.png")
	}
	mOutputPortsMeta["clipboard/text"] = {
		"port_class": CLIPBOARD_TEXT,
		"data_type": "string",
		"icon32": load("res://rcos_sys/data_router/icons/32/clipboard.png")
	}
	mOutputPortsMeta["framebuffer/image"] = {
		"port_class": FB_IMAGE,
		"data_type": "image"
	}
	mOutputPortsMeta["framebuffer/width"] = {
		"port_class": FB_WIDTH,
		"data_type": "int"
	}
	mOutputPortsMeta["framebuffer/height"] = {
		"port_class": FB_HEIGHT,
		"data_type": "int"
	}
	mOutputPortsMeta["framebuffer/size"] = {
		"port_class": FB_SIZE,
		"data_type": "vector2"
	}
	for port_path in mOutputPortsMeta.keys():
		var port = data_router.add_output_port(prefix+"/"+port_path, "")
		mOutputPortsMeta[port_path]["port"] = port
		for meta_name in mOutputPortsMeta[port_path].keys():
			var meta_value = mOutputPortsMeta[port_path][meta_name]
			port.set_meta(meta_name, meta_value)
		mOutputPorts.push_back(port)
	var node_meta = {}
	node_meta["framebuffer"] = {
		"icon32": load("res://modules/quack_vnc/graphics/icon.fb.png")
	}
	for node_path in node_meta.keys():
		var node = data_router.get_output_port(prefix+"/"+node_path)
		for meta_name in node_meta[node_path].keys():
			var meta_value = node_meta[node_path][meta_name]
			node.set_meta(meta_name, meta_value)

func _add_input_ports(prefix):
	mInputPortsMeta["clipboard/text"] = {
		"port_class": CLIPBOARD_TEXT,
		"data_type": "string"
	}
	mInputPortsMeta["keyboard/type_text(text)"] = {
		"port_class": KB_TYPE_TEXT,
		"data_type": "string",
		"icon32": load("res://rcos_sys/data_router/icons/32/keyboard.png")
	}
	mInputPortsMeta["keyboard/press_key(x11_keysym)"] = {
		"port_class": KB_PRESS_KEY,
		"data_type": "string"
	}
	mInputPortsMeta["keyboard/release_key(x11_keysym)"] = {
		"port_class": KB_RELEASE_KEY,
		"data_type": "string"
	}
	mInputPortsMeta["pointer/pos/xy"] = {
		"port_class": PTR_POS,
		"percent": false,
		"move": false,
		"data_type": "vec2"
	}
	mInputPortsMeta["pointer/pos/x"] = {
		"port_class": PTR_POS_X,
		"percent": false,
		"move": false,
		"data_type": "number"
	}
	mInputPortsMeta["pointer/pos/y"] = {
		"port_class": PTR_POS_Y,
		"percent": false,
		"move": false,
		"data_type": "number"
	}
	mInputPortsMeta["pointer/pos/xy%"] = {
		"port_class": PTR_POS,
		"percent": true,
		"move": false,
		"data_type": "vec2"
	}
	mInputPortsMeta["pointer/pos/x%"] = {
		"port_class": PTR_POS_X,
		"percent": true,
		"move": false,
		"data_type": "number"
	}
	mInputPortsMeta["pointer/pos/y%"] = {
		"port_class": PTR_POS_Y,
		"percent": true,
		"move": false,
		"data_type": "number"
	}
	mInputPortsMeta["pointer/move/xy"] = {
		"port_class": PTR_POS,
		"percent": false,
		"move": true,
		"data_type": "vec2"
	}
	mInputPortsMeta["pointer/move/x"] = {
		"port_class": PTR_POS_X,
		"percent": false,
		"move": true,
		"data_type": "number"
	}
	mInputPortsMeta["pointer/move/y"] = {
		"port_class": PTR_POS_Y,
		"percent": false,
		"move": true,
		"data_type": "number"
	}
	mInputPortsMeta["pointer/move/xy%"] = {
		"port_class": PTR_POS,
		"percent": true,
		"move": true,
		"data_type": "vec2"
	}
	mInputPortsMeta["pointer/move/x%"] = {
		"port_class": PTR_POS_X,
		"percent": true,
		"move": true,
		"data_type": "number"
	}
	mInputPortsMeta["pointer/move/y%"] = {
		"port_class": PTR_POS_Y,
		"percent": true,
		"move": true,
		"data_type": "number"
	}
	mInputPortsMeta["pointer/speed/xy"] = {
		"port_class": PTR_SPEED,
		"data_type": "vec2"
	}
	mInputPortsMeta["pointer/speed/x"] = {
		"port_class": PTR_SPEED_X,
		"data_type": "number"
	}
	mInputPortsMeta["pointer/speed/y"] = {
		"port_class": PTR_SPEED_Y,
		"data_type": "number"
	}
	for i in range(1, 9):
		mInputPortsMeta["pointer/buttons/"+str(i)+"/pressed"] = {
			"port_class": PTR_BUTTON,
			"data_type": "bool",
			"button_num": i
		}
	for port_path in mInputPortsMeta.keys():
		var port = data_router.add_input_port(prefix+"/"+port_path)
		mInputPortsMeta[port_path]["port"] = port
		for meta_name in mInputPortsMeta[port_path].keys():
			var meta_value = mInputPortsMeta[port_path][meta_name]
			port.set_meta(meta_name, meta_value)
		port.connect("data_changed", self, "_input_port_data_changed", [port])
		mInputPorts.push_back(port)

func _input_port_data_changed(old_data, new_data, port):
	var port_class = port.get_meta("port_class")
	if port_class == CLIPBOARD_TEXT:
		var text = ""
		if new_data != null:
			text = str(new_data)
		mConnection.send_clipboard(text)
	elif port_class == KB_TYPE_TEXT:
		var text = ""
		if new_data != null:
			text = str(new_data)
		mConnection.send_text(text) 
	elif port_class == KB_PRESS_KEY:
		if new_data != null:
			var keysym = int(new_data)
			mConnection.set_key_pressed(keysym, true)
	elif port_class == KB_RELEASE_KEY:
		if new_data != null:
			var keysym = int(new_data)
			mConnection.set_key_pressed(keysym, false)
	elif port_class == PTR_POS:
		var x = 0
		var y = 0
		if typeof(new_data) == TYPE_VECTOR2 || typeof(new_data) == TYPE_VECTOR3:
			x = new_data.x
			y = new_data.y
		elif typeof(new_data) == TYPE_STRING:
			var numbers = rlib.extract_numbers(new_data)
			if numbers.size() >= 1: x = numbers[0]
			if numbers.size() >= 2: y = numbers[1]
		var percent = port.get_meta("percent")
		var move = port.get_meta("move")
		mConnection.set_pointer_pos_x(x, percent, move)
		mConnection.set_pointer_pos_y(y, percent, move)
	elif port_class == PTR_POS_X:
		var percent = port.get_meta("percent")
		var move = port.get_meta("move")
		mConnection.set_pointer_pos_x(new_data, percent, move)
	elif port_class == PTR_POS_Y:
		var percent = port.get_meta("percent")
		var move = port.get_meta("move")
		mConnection.set_pointer_pos_y(new_data, percent, move)
	elif port_class == PTR_SPEED:
		var x = 0
		var y = 0
		if typeof(new_data) == TYPE_VECTOR2 || typeof(new_data) == TYPE_VECTOR3:
			x = new_data.x
			y = new_data.y
		elif typeof(new_data) == TYPE_STRING:
			var numbers = rlib.extract_numbers(new_data)
			if numbers.size() >= 1: x = numbers[0]
			if numbers.size() >= 2: y = numbers[1]
		mConnection.set_pointer_speed_x(x)
		mConnection.set_pointer_speed_y(y)
	elif port_class == PTR_SPEED_X:
		mConnection.set_pointer_speed_x(new_data)
	elif port_class == PTR_SPEED_Y:
		mConnection.set_pointer_speed_y(new_data)
	elif port_class == PTR_BUTTON:
		var button_num = port.get_meta("button_num")
		mConnection.set_button_pressed(button_num, new_data)

func _bell_msg_received():
	mOutputPortsMeta["bell"].port.put_data(true)
	mOutputPortsMeta["bell"].port.put_data(false)

func _server_cut_text_msg_received(text):
	mOutputPortsMeta["clipboard/text"].port.put_data(text)

func _update_fb_image_output_port():
	if !mDesktop.dirty && !mCursor.dirty:
		return
	if mDesktop.dirty:
		mDesktop.image = mConnection.get_desktop_fb().get_image()
		mDesktop.dirty = false
	if mCursor.dirty:
		mCursor.image = mConnection.get_cursor_fb().get_image()
		mCursor.dirty = false
	var image = mDesktop.image
	if mCursor.image != null:
		var pointer_pos = mConnection.get_pointer_pos()
		var cursor_hotspot = mConnection.get_cursor_hotspot()
		image.blend_rect(mCursor.image, \
		                 mCursor.image.get_used_rect(), \
		                 pointer_pos - cursor_hotspot)
	var port = mOutputPortsMeta["framebuffer/image"].port
	port.put_data(image)

func _desktop_fb_changed(fb):
	mDesktop.dirty = true
	var fb_image_output_port = mOutputPortsMeta["framebuffer/image"].port
	if fb_image_output_port.get_connections().size() > 0:
		_update_fb_image_output_port()

func _cursor_fb_changed(fb):
	mCursor.dirty = true
	var fb_image_output_port = mOutputPortsMeta["framebuffer/image"].port
	if fb_image_output_port.get_connections().size() > 0:
		_update_fb_image_output_port()

func _fb_image_output_port_data_access(port):
	_update_fb_image_output_port()

func _connection_state_changed(new_state):
	if new_state == mConnection.CS_ERROR:
		_remove_io_ports()
	elif new_state == mConnection.CS_SERVER_INIT_MSG_RECEIVED:
		_add_io_ports()
		var fb_size = mConnection.get_desktop_size()
		mOutputPortsMeta["framebuffer/width"].port.put_data(fb_size.x)
		mOutputPortsMeta["framebuffer/height"].port.put_data(fb_size.y)
		mOutputPortsMeta["framebuffer/size"].port.put_data(fb_size)
		var port = mOutputPortsMeta["framebuffer/image"].port
		port.connect("data_access", self, "_fb_image_output_port_data_access", [port])

func initialize(connection):
	mConnection = connection
	mConnection.connect("connection_state_changed", self, "_connection_state_changed")
	mConnection.connect("bell_msg_received", self, "_bell_msg_received")
	mConnection.connect("server_cut_text_msg_received", self, "_server_cut_text_msg_received")
	mConnection.connect("desktop_fb_changed", self, "_desktop_fb_changed")
	mConnection.connect("cursor_fb_changed", self, "_cursor_fb_changed")

func get_output_port(port_name):
	return mOutputPortsMeta[port_name].port
