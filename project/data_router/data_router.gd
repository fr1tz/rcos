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

var mIconByNodeName = {
	"clipboard": load("res://data_router/icons/32/clipboard.png"),
	"mouse": load("res://data_router/icons/32/mouse.png"),
	"keyboard": load("res://data_router/icons/32/keyboard.png"),
	"pointer": load("res://data_router/icons/32/pointer.png"),
	"button": load("res://data_router/icons/32/button.png"),
	"buttons": load("res://data_router/icons/32/buttons.png"),
	"joystick": load("res://data_router/icons/32/joystick.png"),
	"joysticks": load("res://data_router/icons/32/joysticks.png"),
	"text": load("res://data_router/icons/32/data_type_string.png"),
	"pressed": load("res://data_router/icons/32/data_type_bool.png")
}

var mIconByParentNodeName = {
	"buttons": load("res://data_router/icons/32/button.png"),
	"joysticks": load("res://data_router/icons/32/joystick.png")
}

var mIconByPortDataType = {
	"string": load("res://data_router/icons/32/data_type_string.png"),
	"bool": load("res://data_router/icons/32/data_type_bool.png"),
	"image": load("res://data_router/icons/32/data_type_image.png")
}

const PORT_TYPE_INPUT = 0
const PORT_TYPE_OUTPUT = 1

onready var mInputPorts = get_node("input_ports")
onready var mOutputPorts = get_node("output_ports")

var mInputPortCreationNoticeRequests = {}
var mOutputPortCreationNoticeRequests = {}

var mNodeIcons = {}
var mNodeIconsKeys = []

func _init():
	add_user_signal("input_port_added")
	add_user_signal("output_port_added")
	add_user_signal("input_port_removed")
	add_user_signal("output_port_removed")
	add_user_signal("connection_added")
	add_user_signal("connection_removed")

func _add_port(port_path, port_type, initial_data = null):
	port_path = port_path.replace(":", "_")
	var parent_node = null
	if port_type == PORT_TYPE_INPUT:
		parent_node = mInputPorts
	elif port_type == PORT_TYPE_OUTPUT:
		parent_node =  mOutputPorts
	if parent_node.has_node(port_path):
		return null
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
			new_node.put_data(initial_data)
			parent_node.add_child(new_node)
			var requests
			if port_type == PORT_TYPE_INPUT:
				requests = mInputPortCreationNoticeRequests
				emit_signal("input_port_added", new_node)
			elif port_type == PORT_TYPE_OUTPUT:
				requests = mOutputPortCreationNoticeRequests
				emit_signal("output_port_added", new_node)
			if requests.has(port_path):
				for func_ref in requests[port_path]:
					func_ref.call_func(new_node)
				requests.erase(port_path)
			return new_node
		if !parent_node.has_node(node_name):
			var new_node = Node.new()
			new_node.set_name(node_name)
			parent_node.add_child(new_node)
		parent_node = parent_node.get_node(node_name)

func remove_port(port_node):
	if port_node == null:
		return
	var port_type = null
	var port_path = null
	var root_node = null
	if port_node extends load("res://data_router/input_port.gd"):
		port_type = PORT_TYPE_INPUT
		port_path = input_node_to_port_path(port_node)
		root_node = mInputPorts
	elif port_node extends load("res://data_router/output_port.gd"):
		port_type = PORT_TYPE_OUTPUT
		port_path = output_node_to_port_path(port_node)
		root_node = mOutputPorts
	var node = port_node
	while node != root_node:
		if node.get_child_count() == 0:
			var parent = node.get_parent()
			node.get_parent().remove_child(node)
			node.queue_free()
			node = parent
		else:
			break
	if port_type == PORT_TYPE_INPUT:
		emit_signal("input_port_removed", port_path)
	elif port_type == PORT_TYPE_OUTPUT:
		emit_signal("output_port_removed", port_path)

func add_input_port(port_path, initial_data = null):
	return _add_port(port_path, PORT_TYPE_INPUT, initial_data)

func add_output_port(port_path, initial_data = null):
	return _add_port(port_path, PORT_TYPE_OUTPUT, initial_data)

func get_input_port(port_path):
	if mInputPorts.has_node(port_path):
		return mInputPorts.get_node(port_path)
	return null

func get_output_port(port_path):
	if mOutputPorts.has_node(port_path):
		return mOutputPorts.get_node(port_path)
	return null

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
	if typeof(output) == TYPE_STRING && mOutputPorts.has_node(output):
		output_port_node = mOutputPorts.get_node(output)
	elif typeof(output) == TYPE_OBJECT:
		output_port_node = output
	else:
		return false
	if typeof(input) == TYPE_STRING && mInputPorts.has_node(input):
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
	if typeof(output) == TYPE_STRING && mOutputPorts.has_node(output):
		output_port_node = mOutputPorts.get_node(output)
	elif typeof(output) == TYPE_OBJECT:
		output_port_node = output
	else:
		return false
	if typeof(input) == TYPE_STRING && mInputPorts.has_node(input):
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

func request_port_creation_notice(port_type, port_path, callback):
	var requests
	if port_type == PORT_TYPE_INPUT:
		requests = mInputPortCreationNoticeRequests;
	elif port_type == PORT_TYPE_OUTPUT:
		requests = mOutputPortCreationNoticeRequests;
	else:
		return
	if requests.has(port_path):
		requests[port_path].push_back(callback)
	else:
		requests[port_path] = [callback]

func set_node_icon(path, texture, icon_size):
	if !mNodeIcons.has(path):
		mNodeIcons[path] = {}
	mNodeIcons[path][icon_size] = texture
	mNodeIconsKeys = mNodeIcons.keys()
	mNodeIconsKeys.sort()
	mNodeIconsKeys.invert()

func get_node_icon(node, icon_size):
	# Has node a custom icon?
	if node.has_meta("icon"+str(icon_size)):
		return node.get_meta("icon"+str(icon_size))
	var node_path 
	if mOutputPorts.is_a_parent_of(node):
		node_path = str(mOutputPorts.get_path_to(node))
	elif mInputPorts.is_a_parent_of(node):
		node_path = str(mInputPorts.get_path_to(node))
	else:
		return load("res://data_router/icons/32/node.png")
	# Has a custom icon been set for this node via data_router.set_node_icon()?
	if mNodeIcons.has(node_path):
		if mNodeIcons[node_path].has(icon_size):
				return mNodeIcons[node_path][icon_size] 
	# Try to find an appropriate icon
	if icon_size != 32:
		return null
	if node.has_method("put_data"): # Is node an i/o port?
		# Icon based on i/o port data type.
		if node.has_meta("data_type"):
			var data_type = node.get_meta("data_type")
			if mIconByPortDataType.has(data_type):
				return mIconByPortDataType[data_type]
		# Icon based on i/o port name.
		var node_name = node.get_name()
		if mIconByNodeName.has(node_name):
			return mIconByNodeName[node_name]
		return load("res://data_router/icons/32/io_port.png")
	# Node is not an i/o port.
	var node_name = node.get_name()
	if mIconByNodeName.has(node_name):
		return mIconByNodeName[node_name]
	var parent_node_name = node.get_parent().get_name()
	if mIconByParentNodeName.has(parent_node_name):
		return mIconByParentNodeName[parent_node_name]
	# If all else fails, return default node icon.
	return load("res://data_router/icons/32/node.png")
