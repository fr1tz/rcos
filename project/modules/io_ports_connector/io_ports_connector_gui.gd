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

extends Panel

onready var mMenuBar = get_node("vsplit/menu_bar")
onready var mConnectionItems = get_node("vsplit/items_panel/scroller/items")

var mConnectionItemsById = {}
var mSelectedOutputPort = null
var mSelectedInputPort = null

func _ready():
	for connection in rcos_data_router.get_connections():
		_add_connection_item(connection)
	rcos_data_router.connect("connection_added", self, "_connection_added")
	rcos_data_router.connect("connection_removed", self, "_connection_removed")
	rcos_data_router.connect("connection_changed", self, "_connection_changed")
	mMenuBar.get_node("buttons/add_connection_button").connect("pressed", self, "_show_output_port_selector")
	get_node("output_port_selector").connect("canceled", self, "_show_connections")
	get_node("output_port_selector").connect("node_selected", self, "_output_port_selected")
	get_node("input_port_selector").connect("canceled", self, "_show_connections")
	get_node("input_port_selector").connect("node_selected", self, "_input_port_selected")
	var isquare = Vector2(rcos.get_isquare_size(), rcos.get_isquare_size())
	#mMenuBar.set_custom_minimum_size(isquare)
	for c in mMenuBar.get_node("buttons").get_children():
		c.set_custom_minimum_size(isquare)

func _connection_added(connection):
	_add_connection_item(connection)

func _connection_removed(connection):
	_remove_connection_item(connection)

func _connection_changed(connection):
	mConnectionItemsById[connection.get_id()].update_markings()

func _add_connection_item(connection):
	var item = rlib.instance_scene("res://modules/io_ports_connector/connection_item.tscn")
	mConnectionItems.add_child(item)
	item.initialize(connection)
	#item.connect("pressed", self, "_connection_item_selected", [item])
	var isquare = Vector2(rcos.get_isquare_size(), rcos.get_isquare_size())
	item.set_custom_minimum_size(isquare)
	mConnectionItemsById[connection.get_id()] = item
	return item

func _remove_connection_item(connection):
	var item = mConnectionItemsById[connection.get_id()]
	mConnectionItems.remove_child(item)
	item.queue_free()

func _show_connections():
	get_node("output_port_selector").set_hidden(true)
	get_node("input_port_selector").set_hidden(true)

func _show_output_port_selector():
	mSelectedOutputPort = null
	mSelectedInputPort = null
	get_node("output_port_selector").set_hidden(false)
	get_node("input_port_selector").set_hidden(true)

func _output_port_selected(node):
	mSelectedOutputPort = node
	get_node("output_port_selector").set_hidden(true)
	get_node("input_port_selector").set_hidden(false)

func _input_port_selected(node):
	mSelectedInputPort = node
	get_node("output_port_selector").set_hidden(true)
	get_node("input_port_selector").set_hidden(true)
	if mSelectedOutputPort == null || mSelectedInputPort == null:
		return
	rcos_data_router.add_connection(mSelectedOutputPort, mSelectedInputPort)
