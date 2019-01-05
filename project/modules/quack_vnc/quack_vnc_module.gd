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
#	var logger = rcos_modules.spawn_module("logger")
#	logger.set_filter(str(rcos.get_path_to(self)))
	var task_properties = {
		"name": "Quack VNC",
		"canvas": get_node("canvas"),
		"icon": load("res://modules/quack_vnc/graphics/icon.png")
	}
	mTaskId = rcos_tasks.add_task(task_properties)
	mConnection = get_node("connection")
	mConnection.connect("connection_state_changed", self, "_connection_state_changed")
	gui = get_node("canvas/rfb_client_gui")
	gui.initialize(self, mConnection)

func _exit_tree():
	if mTaskId != -1:
		rcos_tasks.remove_task(mTaskId)

func _connection_state_changed(new_state):
	if new_state == mConnection.CS_ERROR:
		var task_properties = {
			"icon": load("res://modules/quack_vnc/graphics/icon.png"),
			"icon_spin_speed": 0
		}
		rcos_tasks.change_task(mTaskId, task_properties)
	elif new_state == mConnection.CS_READY_TO_CONNECT:
		var task_properties = {
			"icon": load("res://modules/quack_vnc/graphics/icon.png"),
			"icon_spin_speed": 0
		}
		rcos_tasks.change_task(mTaskId, task_properties)
	elif new_state == mConnection.CS_CONNECTING:
		var task_properties = {
			"icon": load("res://modules/quack_vnc/graphics/spinner.png"),
			"icon_spin_speed": 5
		}
		rcos_tasks.change_task(mTaskId, task_properties)
	elif new_state == mConnection.CS_SERVER_INIT_MSG_RECEIVED:
		var server_id
		var server_port = mConnection.get_remote_port()
		if server_port >= 5900 && server_port <= 5999:
			server_id = ":"+str(server_port-5900)
		else:
			server_id = "::"+str(server_port)
		var task_properties = {
			"icon": load("res://modules/quack_vnc/graphics/icon.server.png"),
			"icon_label": server_id,
			"icon_spin_speed": 0
		}
		rcos_tasks.change_task(mTaskId, task_properties)

func connect_to_server(address, port):
	rcos_log.notice(self, "Opening connection to "+address+":"+str(port))
	mServerAddress = address
	mServerTcpPort = port
	if rcos.has_node("services/host_info_service"):
		var host_info_service = rcos.get_node("services/host_info_service")
		var host_info = host_info_service.get_host_info_from_address(mServerAddress)
		if host_info != null:
			var color = host_info.get_host_color()
			var task_properties = {
				"task_color": color
			}
			rcos_tasks.change_task(mTaskId, task_properties)
	mConnection.connect_to_server(address, port)

func kill():
	queue_free()
