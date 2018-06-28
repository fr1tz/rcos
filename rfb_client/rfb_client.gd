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

func _exit_tree():
	if mTaskId != -1:
		rcos.remove_task(mTaskId)

func connect_to_server(address, port):
	rcos.log_notice(self, "Opening connection to "+address+":"+str(port))
	mServerAddress = address
	mServerTcpPort = port
	if !mConnection.connect_to_server(address, port):
		rcos.log_error(self, "Failed to initialize connection")
	gui.get_open_connection_dialog().set_hidden(true)

func kill():
	queue_free()
