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

extends Panel

onready var mConnectionItems = get_node("items_container/items")

var mConnectionItemsByKey = {}
var mConnectionItemsByOutput = {}
var mConnectionItemsByInput = {}
var mSelectedConnectionItem = null
var mSelectedOutputPort = null
var mSelectedInputPort = null

func _ready():
	_load()
	data_router.connect("output_port_added", self, "_output_port_added")
	data_router.connect("input_port_added", self, "_input_port_added")
	data_router.connect("connection_added", self, "_connection_added")
	data_router.connect("connection_removed", self, "_connection_removed")
	get_node("buttons/add_connection_button").connect("pressed", self, "_show_output_port_selector")
	get_node("buttons/toggle_connection_button").connect("pressed", self, "_toggle_selected_connection_item")
	get_node("buttons/remove_connection_button").connect("pressed", self, "_remove_selected_connection_item")
	get_node("buttons/save_button").connect("pressed", self, "_save")
	get_node("output_port_selector").connect("canceled", self, "_show_connections")
	get_node("output_port_selector").connect("node_selected", self, "_output_port_selected")
	get_node("input_port_selector").connect("canceled", self, "_show_connections")
	get_node("input_port_selector").connect("node_selected", self, "_input_port_selected")

func _output_port_added(output_port_node):
	var output_path = data_router.output_node_to_port_path(output_port_node)
	if !mConnectionItemsByOutput.has(output_path):
		return
	for item in mConnectionItemsByOutput[output_path]:
		item.activate_connection()

func _input_port_added(input_port_node):
	var input_path = data_router.input_node_to_port_path(input_port_node)
	if !mConnectionItemsByInput.has(input_path):
		return
	for item in mConnectionItemsByInput[input_path]:
		item.activate_connection()

func _connection_added(output_port_node, input_port_node):
	_add_connection_item(output_port_node, input_port_node, false)

func _connection_removed(output_port_node, input_port_node):
	var output_path = data_router.output_node_to_port_path(output_port_node)
	var input_path = data_router.input_node_to_port_path(input_port_node)
	var key = output_path+"->"+input_path
	if mConnectionItemsByKey.has(key):
		mConnectionItemsByKey[key].update_markings()

func _connections_changed():
	for c in mConnectionItems.get_children():
		mConnectionItems.remove_child(c)
		c.queue_free()
	var connections = data_router.get_connections()
	for connection in connections:
		var item = rlib.instance_scene("res://rcos/data_connector/connection_item.tscn")
		item.initialize(connection.output, connection.input)
		mConnectionItems.add_child(item)

func _add_connection_item(output, input, disabled):
	var output_path = null
	var input_path = null
	if typeof(output) == TYPE_STRING:
		output_path = output
	elif typeof(output) == TYPE_OBJECT:
		output_path = data_router.output_node_to_port_path(output)
	if typeof(input) == TYPE_STRING:
		input_path = input
	elif typeof(input) == TYPE_OBJECT:
		input_path = data_router.input_node_to_port_path(input)
	var key = output_path+"->"+input_path
	if mConnectionItemsByKey.has(key):
		return mConnectionItemsByKey[key]
	var item = rlib.instance_scene("res://rcos/data_connector/connection_item.tscn")
	item.initialize(output_path, input_path, disabled)
	item.connect("pressed", self, "_connection_item_selected", [item])
	get_node("items_container/items").add_child(item)
	mConnectionItemsByKey[key] = item
	if mConnectionItemsByOutput.has(output_path):
		mConnectionItemsByOutput[output_path].push_back(item)
	else:
		mConnectionItemsByOutput[output_path] = [item]
	if mConnectionItemsByInput.has(input_path):
		mConnectionItemsByInput[input_path].push_back(item)
	else:
		mConnectionItemsByInput[input_path] = [item]
	return item

func _remove_selected_connection_item():
	if mSelectedConnectionItem == null:
		return
	var output_path = mSelectedConnectionItem.get_output_port_path()
	var input_path = mSelectedConnectionItem.get_input_port_path()
	var key = output_path+"->"+input_path
	mConnectionItemsByKey.erase(key)
	if mConnectionItemsByOutput.has(output_path):
		mConnectionItemsByOutput[output_path].erase(mSelectedConnectionItem)
	if mConnectionItemsByInput.has(input_path):
		mConnectionItemsByOutput[input_path].erase(mSelectedConnectionItem)
	mConnectionItems.remove_child(mSelectedConnectionItem)
	mSelectedConnectionItem.deactivate_connection()
	mSelectedConnectionItem.queue_free()
	mSelectedConnectionItem = null

func _toggle_selected_connection_item():
	if mSelectedConnectionItem == null:
		return
	mSelectedConnectionItem.toggle_connection_disabled()

func _connection_item_selected(item):
	if mSelectedConnectionItem != null:
		mSelectedConnectionItem.set_pressed(false)
	mSelectedConnectionItem = item

func _save():
	var dir = Directory.new()
	if !dir.dir_exists("user://etc"):
		dir.make_dir_recursive("user://etc")
	var connections = []
	for item in mConnectionItems.get_children():
		var connection = {
			"output": item.get_output_port_path(),
			"input": item.get_input_port_path(),
			"disabled": item.is_connection_disabled()
		}
		connections.push_back(connection)
	var file = File.new()
	if file.open("user://etc/data_router_conf.json", File.WRITE) != OK:
		return
	var config = {
		"version": 0,
		"connections": connections
	}
	file.store_buffer(config.to_json().to_utf8())
	file.close()

func _load():
	var file = File.new()
	if file.open("user://etc/data_router_conf.json", File.READ) != OK:
		return
	var text = file.get_buffer(file.get_len()).get_string_from_utf8()
	file.close()
	var config = {}
	if config.parse_json(text) != OK:
		return
	if config.version == 0:
		for c in config.connections:
			var item = _add_connection_item(c.output, c.input, c.disabled)
			item.activate_connection()

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
	var item = _add_connection_item(mSelectedOutputPort, mSelectedInputPort)
	item.activate_connection()
