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

const SEND_UPDATE_INTERVAL = 0.02

var gui = null

var mTaskId = -1
var mServerAddress = null
var mServerTcpPort = -1
var mServerUdpPort = -1
var mServerHostname = null
var mClientId = -1
var mControllers = null
var mConnection = null
var mUDP = PacketPeerUDP.new()
var mSendUpdateQueued = false

func _ready():
	gui = get_node("canvas/vjoy_client_gui")
	gui.get_open_connection_dialog().connect("cancel_button_pressed", self, "kill")
	gui.get_open_connection_dialog().connect("connect_button_pressed", self, "connect_to_server")
	var logger = rcos_modules.spawn_module("logger")
	logger.set_filter(str(rcos.get_path_to(self)))
	get_node("send_update_timer").connect("timeout", self, "send_update")
	mControllers = get_node("controllers")
	mConnection = get_node("connection")
	mConnection.connect("message_received", self, "_process_message")
	var task_properties = {
		"name": "vJoy Client",
		"icon": get_node("icon").get_texture(),
		"canvas": get_node("canvas"),
	}
	mTaskId = rcos_tasks.add_task(task_properties)

func _process_message(msg):
	rcos_log.debug(self, ["vjoy_client: _process_message():", msg])
	var type = rlib.hd(msg)
	var args = rlib.tl(msg)
	if type == "init":
		mServerHostname = rlib.hd(args); args = rlib.tl(args)
		mServerUdpPort = int(rlib.hd(args)); args = rlib.tl(args)
		mClientId = int(rlib.hd(args))
		for id in range(1, 17):
			var ctrl = rlib.instance_scene("res://modules/vjoyctrl/vjoy_controller.tscn")
			ctrl.set_name("vjoy_controller"+str(id))
			ctrl.initialize(self, mServerHostname, id)
			mControllers.add_child(ctrl)
		get_node("send_update_timer").start()
	elif type == "vjoy_config":
		var id = rlib.hd(args); args = rlib.tl(args)
		var prop_name = rlib.hd(args); args = rlib.tl(args)
		var prop_value = rlib.hd(args);
		var ctrl = mControllers.get_node("vjoy_controller"+str(id))
		if ctrl:
			ctrl.vjoy_config_changed(prop_name, prop_value)
	elif type == "vjoy_status":
		var id = rlib.hd(args); args = rlib.tl(args)
		var state = rlib.hd(args)
		var ctrl = mControllers.get_node("vjoy_controller"+str(id))
		if ctrl == null:
			return
		ctrl.mOutputPorts.status.put_data(state)

func _send_update():
	var data = get_node("update_packet").create_packet(mClientId, mControllers)
#	var s = ""
#	for i in range(0, data.size()):
#		#s += ("%2o " % data[i])
#		s += str(data[i]) + " "
#	print(s)
	send_packet(data, mServerAddress, mServerUdpPort)
	mSendUpdateQueued = false

func send_update():
	if mSendUpdateQueued:
		return
	call_deferred("_send_update")

func send_packet(data, addr, port):
	mUDP.set_send_address(addr, port)
	mUDP.put_packet(data)

func connect_to_server(address, port):
	mServerAddress = address
	mServerTcpPort = port
	if !mConnection.connect_to_server(address, port):
		rcos_log.error(self, "Failed to initialize connection")
	gui.get_open_connection_dialog().set_hidden(true)

func kill():
	queue_free()
