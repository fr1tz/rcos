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
var mServerUdpPort = -1
var mServerHostname = null
var mClientId = -1
var mControllers = null
var mConnection = null
var mUDP = PacketPeerUDP.new()
var mSendUpdateCountdown = SEND_UPDATE_INTERVAL

func _ready():
	mControllers = get_node("controllers")
	mConnection = get_node("connection")
	mConnection.connect("message_received", self, "_process_message")
	var task_properties = {
		"name": "vJoy Client",
		"icon": get_node("icon").get_texture(),
		"canvas": get_node("canvas"),
	}
	mTaskId = rcos.add_task(task_properties)

func _fixed_process(delta):
	mSendUpdateCountdown -= delta
	if mSendUpdateCountdown <= 0:
		send_update()

func _process_message(msg):
	prints("vjoy_client: _process_message():", msg)
	var type = rlib.hd(msg)
	var args = rlib.tl(msg)
	if type == "init":
		mServerHostname = rlib.hd(args); args = rlib.tl(args)
		mServerUdpPort = int(rlib.hd(args)); args = rlib.tl(args)
		mClientId = int(rlib.hd(args))
		for id in range(1, 17):
			var ctrl = rlib.instance_scene("res://vjoy_client/vjoy_controller.tscn")
			ctrl.set_name("vjoy_controller"+str(id))
			ctrl.initialize(self, mServerHostname, id)
			mControllers.add_child(ctrl)
		set_fixed_process(true)
	elif type == "vjoy_status":
		var id = rlib.hd(args)
		args = rlib.tl(args)
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
	mSendUpdateCountdown = SEND_UPDATE_INTERVAL

func send_update():
	if mSendUpdateCountdown == 0:
		return
	mSendUpdateCountdown = 0
	call_deferred("_send_update")

func send_packet(data, addr, port):
	mUDP.set_send_address(addr, port)
	mUDP.put_packet(data)

func connect_to_server(address, port):
	mServerAddress = address
	mServerTcpPort = port
	if !mConnection.connect_to_server(address, port):
		rcos.log_error(self, "Failed to initialize connection")
