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

extends ColorFrame

var mNetInterfaceActive = false
var mConnectionCount = 0

func _ready():
	set_fixed_process(true)

func _fixed_process(delta):
	var vrc_host = get_node("vrc_host")
	vrc_host.set_rot(vrc_host.get_rot() - delta*2.5)

func add_error():
	get_node("vrc_host/download_progress").add_error()
	get_node("vrc_host/unpacking_progress").add_error()

func set_connection_count(count):
	var connections = get_node("vrc_host/connections")
	for c in connections.get_children():
		connections.remove_child(c)
		c.queue_free()
	var packed_connection = load("res://vrc_host/status_screen/connection.tscn")
	for i in range(0, count):
		var connection = packed_connection.instance()
		var rot = i*(2*PI/count)
		connections.add_child(connection)
		connection.set_rot(rot)

func set_vrc_download_progress(progress):
	get_node("vrc_host/download_progress").set_progress(progress)

func set_vrc_unpacking_progress(progress):
	get_node("vrc_host/unpacking_progress").set_progress(progress)
