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

func _ready():
	var logger = rcos.spawn_module("logger")
	logger.set_filter(str(rcos.get_path_to(self)))
	var task_properties = {
		"name": "RFB Client",
		"icon": get_node("icon").get_texture(),
		"canvas": get_node("canvas"),
	}
	mTaskId = rcos.add_task(task_properties)
	mConnection = get_node("connection")
	mConnection.connect("connection_state_changed", self, "_connection_state_changed")
	mConnection.connect("connection_established", self, "_connection_established")
	mConnection.connect("connection_error", self, "_connection_error")
	gui = get_node("canvas/rfb_client_gui")
	gui.initialize(self, mConnection)

func _exit_tree():
	if mTaskId != -1:
		rcos.remove_task(mTaskId)

func _connection_state_changed(new_state):
	pass

func _connection_established():
	pass

func _connection_error(status):
	pass

func connect_to_server(address, port):
	rcos.log_notice(self, "Opening connection to "+address+":"+str(port))
	mServerAddress = address
	mServerTcpPort = port
	mConnection.connect_to_server(address, port)

func kill():
	queue_free()
