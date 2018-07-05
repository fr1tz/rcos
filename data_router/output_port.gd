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

var mData = null
var mConnections = []

func _init():
	add_user_signal("data_access")
	add_user_signal("connections_changed")

func _ready():
	pass

func add_connection(input_node):
	if mConnections.has(input_node):
		return true
	mConnections.push_back(input_node)
	emit_signal("connections_changed")
	if mData != null:
		put_data(mData)
	return true

func remove_connection(input_node):
	if !mConnections.has(input_node):
		return true
	mConnections.erase(input_node)
	emit_signal("connections_changed")
	return true

func get_connections():
	return mConnections

func is_connected():
	return mConnections.size() > 0

func get_port_path():
	return data_router.get_node("output_ports").get_path_to(self)

func access_data():
	emit_signal("data_access")
	return mData

func put_data(data):
	mData = data
	for input_node in mConnections:
		input_node.put_data(mData)
