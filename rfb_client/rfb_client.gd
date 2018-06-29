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

var mTaskId = -1
var mServerAddress = null
var mServerTcpPort = -1
var mServerHostname = null
var mConnection = null
var mOutputPorts = {}
var mInputPorts = {}

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
	mOutputPorts["bell"] = data_router.add_output_port(prefix+"/bell", false)
	mOutputPorts["clipboard"] = data_router.add_output_port(prefix+"/clipboard", "")
	for port_name in ["clipboard", "send_text"]:
		var port_path = prefix+"/"+port_name
		var port = data_router.add_input_port(port_path)
		port.connect("data_changed", self, "_input_port_data_changed", [port])
		mInputPorts[port_name] = port

func _remove_io_ports():
	for port in mOutputPorts.values():
		data_router.remove_port(port)
	for port in mInputPorts.values():
		data_router.remove_port(port)

func _input_port_data_changed(old_data, new_data, port):
	var port_name = port.get_name()
	if port_name == "clipboard":
		var text = ""
		if new_data != null:
			text = str(new_data)
		mConnection.send_clipboard(text)
	elif port_name == "send_text":
		var text = ""
		if new_data != null:
			text = str(new_data)
		mConnection.send_text(text)

func _bell_msg_received():
	mOutputPorts["bell"].put_data(true)
	mOutputPorts["bell"].put_data(false)

func server_cut_text_msg_received(text):
	mOutputPorts["clipboard"].put_data(text)

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
