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

const SEND_UPDATE_INTERVAL = 0.05

var gui = null

enum PortClass {
	BELL,
	CLIPBOARD_TEXT,
	KB_TYPE_TEXT,
	KB_PRESS_KEY,
	KB_RELEASE_KEY,
	PTR_POS,
	PTR_POS_X,
	PTR_POS_Y,
	PTR_SPEED,
	PTR_SPEED_X,
	PTR_SPEED_Y,
	PTR_BUTTON
}

var mTaskId = -1
var mServerAddress = null
var mServerTcpPort = -1
var mServerHostname = null
var mConnection = null
var mOutputPortsMeta = {}
var mInputPortsMeta = {}
var mOutputPorts = []
var mInputPorts = []

func _ready():
	gui = get_node("canvas/rfb_client_gui")
	gui.get_open_connection_dialog().connect("cancel_button_pressed", self, "kill")
	gui.get_open_connection_dialog().connect("connect_button_pressed", self, "connect_to_server")
	var logger = rcos.spawn_module("logger")
	logger.set_filter(str(rcos.get_path_to(self)))
	var task_properties = {
		"name": "RFB Client",
		"icon": get_node("icon").get_texture(),
		"canvas": get_node("canvas"),
	}
	mTaskId = rcos.add_task(task_properties)
	mConnection = get_node("connection")
	mConnection.connect("connection_established", self, "_connection_established")
	mConnection.connect("connection_error", self, "_connection_error")
	mConnection.connect("bell_msg_received", self, "_bell_msg_received")
	mConnection.connect("server_cut_text_msg_received", self, "server_cut_text_msg_received")
	gui.get_node("pointer_speed_multiplier").connect("text_entered", mConnection, "set_pointer_speed_multiplier")

func _exit_tree():
	if mTaskId != -1:
		rcos.remove_task(mTaskId)
	_remove_io_ports()

func _add_io_ports():
	var hostname = mServerAddress
	var words = mConnection.get_desktop_name().split(" ", false)
	if words[0] != "":
		hostname = words[0]
		var sep_pos = words[0].find(":")
		if sep_pos > 0:
			hostname = words[0].left(sep_pos)
	var prefix 
	if mServerTcpPort >= 5900 && mServerTcpPort <= 5999:
		prefix = hostname.to_lower()+"/rfb:"+str(mServerTcpPort-5900)
	else:
		prefix = hostname.to_lower()+"/rfb::"+str(mServerTcpPort)
	_add_output_ports(prefix)
	_add_input_ports(prefix)

func _add_output_ports(prefix):
	mOutputPortsMeta["bell"] = {
		"port_class": BELL,
		"data_type": "bool"
	}
	mOutputPortsMeta["clipboard/text"] = {
		"port_class": CLIPBOARD_TEXT,
		"data_type": "string"
	}
	for port_path in mOutputPortsMeta.keys():
		var port = data_router.add_output_port(prefix+"/"+port_path, "")
		for meta_name in mOutputPortsMeta[port_path].keys():
			var meta_value = mOutputPortsMeta[port_path][meta_name]
			port.set_meta(meta_name, meta_value)
		mOutputPorts.push_back(port)

func _add_input_ports(prefix):
	mInputPortsMeta["clipboard/text"] = {
		"port_class": CLIPBOARD_TEXT,
		"data_type": "string"
	}
	mInputPortsMeta["keyboard/type_text(text)"] = {
		"port_class": KB_TYPE_TEXT,
		"data_type": "string"
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
		"data_type": "vec2"
	}
	mInputPortsMeta["pointer/pos/x"] = {
		"port_class": PTR_POS_X,
		"data_type": "number"
	}
	mInputPortsMeta["pointer/pos/y"] = {
		"port_class": PTR_POS_Y,
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
		for meta_name in mInputPortsMeta[port_path].keys():
			var meta_value = mInputPortsMeta[port_path][meta_name]
			port.set_meta(meta_name, meta_value)
		port.connect("data_changed", self, "_input_port_data_changed", [port])
		mInputPorts.push_back(port)

func _remove_io_ports():
	for port in mOutputPorts:
		data_router.remove_port(port)
	for port in mInputPorts:
		data_router.remove_port(port)

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
			var words = new_data.split(" ")
			if words.size() > 0: x = words[0]
			if words.size() > 1: y = words[1]
		mConnection.set_pointer_pos_x(x)
		mConnection.set_pointer_pos_y(y)
	elif port_class == PTR_POS_X:
		mConnection.set_pointer_pos_x(new_data)
	elif port_class == PTR_POS_Y:
		mConnection.set_pointer_pos_y(new_data)
	elif port_class == PTR_SPEED:
		var x = 0
		var y = 0
		if typeof(new_data) == TYPE_VECTOR2 || typeof(new_data) == TYPE_VECTOR3:
			x = new_data.x
			y = new_data.y
		elif typeof(new_data) == TYPE_STRING:
			var words = new_data.split(" ", false)
			if words.size() > 0: x = words[0]
			if words.size() > 1: y = words[1]
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
	mOutputPorts[0].put_data(true)
	mOutputPorts[0].put_data(false)

func server_cut_text_msg_received(text):
	mOutputPorts[1].put_data(text)

func _connection_established():
	_add_io_ports()

func _connection_error(status):
	_remove_io_ports()

func connect_to_server(address, port):
	rcos.log_notice(self, "Opening connection to "+address+":"+str(port))
	mServerAddress = address
	mServerTcpPort = port
	if !mConnection.connect_to_server(address, port):
		rcos.log_error(self, "Failed to initialize connection")
	gui.get_open_connection_dialog().set_hidden(true)

func kill():
	queue_free()
