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
			elif port_type == PORT_TYPE_OUTPUT:
				new_node = rlib.instance_scene("res://data_router/output_port.tscn")
			new_node.set_name(node_name)
			parent_node.add_child(new_node)
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

func add_connection(output_port_path, input_port_path):
	#prints("data_router: add connection: ", output_port_path, "->", input_port_path)
	if !mOutputPorts.has_node(output_port_path) \
	|| !mInputPorts.has_node(input_port_path):
		return false
	var output_port_node = mOutputPorts.get_node(output_port_path)
	var input_port_node = mInputPorts.get_node(input_port_path)
	return output_port_node.add_connection(input_port_node)

func remove_connection(output_port_path, input_port_path):
	#prints("data_router: remove connection: ", output_port_path, "->", input_port_path)
	if !mOutputPorts.has_node(output_port_path) \
	|| !mInputPorts.has_node(input_port_path):
		return false
	var output_port_node = mOutputPorts.get_node(output_port_path)
	var input_port_node = mInputPorts.get_node(input_port_path)
	return output_port_node.remove_connection(input_port_node)
