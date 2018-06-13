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

var gui = null

var mTaskId = -1
var mHostname = null
var mConnection = null
var mUDP = PacketPeerUDP.new()
var mVjoyStatusOutputs = []

func _ready():
	mConnection = get_node("connection")
	mConnection.connect("message_received", self, "_process_message")
	var task_properties = {
		"name": "vJoy Client",
		"icon": get_node("icon").get_texture(),
		"canvas": get_node("canvas"),
	}
	mTaskId = rcos.add_task(task_properties)

func _process_message(msg):
	prints("vjoy_client: _process_message():", msg)
	var type = rlib.hd(msg)
	var args = rlib.tl(msg)
	if type == "hostname":
		mHostname = rlib.hd(args)
		for i in range(0, 16):
			var port_name = mHostname+"/vjoy_server/vjoy"+str(i+1)+"/status"
			var port = data_router.add_output_port(port_name)
			mVjoyStatusOutputs.push_back(port)
	elif type == "vjoy_status":
		var id = rlib.hd(args)
		args = rlib.tl(args)
		var state = rlib.hd(args)
		prints("vjoy", id, "state:", state)
		var idx = int(id)-1
		mVjoyStatusOutputs[idx].put_data(state)

func send_packet(data, addr, port):
	mUDP.set_send_address(addr, port)
	mUDP.put_packet(data)

func connect_to_server(address, port):
	mHostname = address
	if !mConnection.connect_to_server(address, port):
		rcos.log_error(self, "Failed to initialize connection")

