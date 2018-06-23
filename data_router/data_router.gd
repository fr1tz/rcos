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

const PORT_TYPE_INPUT = 0
const PORT_TYPE_OUTPUT = 1

onready var mInputPorts = get_node("input_ports")
onready var mOutputPorts = get_node("output_ports")

func _init():
	add_user_signal("input_port_added")
	add_user_signal("output_port_added")
	add_user_signal("connection_added")
	add_user_signal("connection_removed")

func _add_port(port_path, port_type):
	var parent_node = null
	if port_type == PORT_TYPE_INPUT:
		parent_node = mInputPorts
	elif port_type == PORT_TYPE_OUTPUT:
		parent_node =  mOutputPorts
	if parent_node.has_node(port_path):
		return false
	var node_names = port_path.split("/", false)
	for i in range(0, node_names.size()):
		var node_name = node_names[i]
		if i == node_names.size() - 1:
			var new_node = null
			if port_type == PORT_TYPE_INPUT:
				new_node = rlib.instance_scene("res://data_router/input_port.tscn")
				new_node.add_to_group("data_router_input_ports")
			elif port_type == PORT_TYPE_OUTPUT:
				new_node = rlib.instance_scene("res://data_router/output_port.tscn")
				new_node.add_to_group("data_router_output_ports")
			new_node.set_name(node_name)
			parent_node.add_child(new_node)
			if port_type == PORT_TYPE_INPUT:
				emit_signal("input_port_added", new_node)
			elif port_type == PORT_TYPE_OUTPUT:
				emit_signal("output_port_added", new_node)
			return new_node
		if !parent_node.has_node(node_name):
			var new_node = Node.new()
			new_node.set_name(node_name)
			parent_node.add_child(new_node)
		parent_node = parent_node.get_node(node_name)

func add_input_port(port_path):
	return _add_port(port_path, PORT_TYPE_INPUT)

func add_output_port(port_path):
	return _add_port(port_path, PORT_TYPE_OUTPUT)

func has_input_port(port_path):
	return mInputPorts.has_node(port_path)

func has_output_port(port_path):
	return mOutputPorts.has_node(port_path)

func has_connection(output_port_path, input_port_path):
	var output_port = mOutputPorts.get_node(output_port_path)
	var input_port = mInputPorts.get_node(input_port_path)
	if output_port == null || input_port == null:
		return false
	return output_port.get_connections().has(input_port)

func get_input_ports():
	return get_tree().get_nodes_in_group("data_router_input_ports")

func get_output_ports():
	return get_tree().get_nodes_in_group("data_router_output_ports")

func get_connections():
	var connections = []
	var output_ports = get_output_ports()
	for output_port in output_ports:
		var output_port_path = output_port.get_port_path()
		for input_port in output_port.get_connections():
			var input_port_path = input_port.get_port_path()
			var connection = {
				"output": output_port_path,
				"input": input_port_path
			}
			connections.push_back(connection)
	return connections

func output_node_to_port_path(node):
	return str(get_node("output_ports").get_path_to(node))

func input_node_to_port_path(node):
	return str(get_node("input_ports").get_path_to(node))

func add_connection(output, input):
	#prints("data_router: add connection: ", output, "->", input)
	var output_port_node = null
	var input_port_node = null
	if typeof(output) == TYPE_STRING:
		output_port_node = mOutputPorts.get_node(output)
	elif typeof(output) == TYPE_OBJECT:
		output_port_node = output
	else:
		return false
	if typeof(input) == TYPE_STRING:
		input_port_node = mInputPorts.get_node(input)
	elif typeof(input) == TYPE_OBJECT:
		input_port_node = input
	else:
		return false
	if output_port_node == null || input_port_node == null:
		return false
	var success = output_port_node.add_connection(input_port_node)
	if success:
		emit_signal("connection_added", output_port_node, input_port_node)
	return success

func remove_connection(output, input):
	#prints("data_router: remove connection: ", output, "->", input)
	var output_port_node = null
	var input_port_node = null
	if typeof(output) == TYPE_STRING:
		output_port_node = mOutputPorts.get_node(output)
	elif typeof(output) == TYPE_OBJECT:
		output_port_node = output
	else:
		return false
	if typeof(input) == TYPE_STRING:
		input_port_node = mInputPorts.get_node(input)
	elif typeof(output) == TYPE_OBJECT:
		input_port_node = input
	else:
		return false
	if output_port_node == null || input_port_node == null:
		return false
	var success = output_port_node.remove_connection(input_port_node)
	if success:
		emit_signal("connection_removed", output_port_node, input_port_node)
	return success
