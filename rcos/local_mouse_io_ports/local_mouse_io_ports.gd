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

const PORT_POS = 0
const PORT_SPEED = 1
const PORT_BUTTON = 2
const PORT_CAPTURED = 3

var mMouseSpeed = Vector2(0, 0)
var mLastMouseMovementSpeed = Vector2(0, 0)

var mOutputPortsMeta = {}
var mInputPortsMeta = {}
var mOutputPorts = []
var mInputPorts = []

func _ready():
	_add_io_ports()
	set_fixed_process(true)

func _exit_tree():
	_remove_io_ports()

func _add_io_ports():
	var prefix = "local/mouse"
	_add_output_ports(prefix)
	_add_input_ports(prefix)

func _remove_io_ports():
	for port in mOutputPorts:
		data_router.remove_port(port)

func _add_output_ports(prefix):
	# Pointer Pos
	for port_name in ["x", "y", "xy"]:
		var port = data_router.add_output_port(prefix+"/pos/"+port_name)
		port.set_meta("data_type", "float")
		port.set_meta("port_type", PORT_POS)
		port.connect("data_access", self, "_output_port_data_access", [port])
		#port.connect("connections_changed", self, "_output_port_connections_changed", [port])
		mOutputPorts.push_back(port)
	var pos_node = data_router.get_output_port(prefix+"/pos")
	pos_node.set_meta("icon32", load("res://data_router/icons/32/pointer.png"))
	# Mouse Speed
	for port_name in ["x", "y", "xy"]:
		var port = data_router.add_output_port(prefix+"/speed/"+port_name)
		port.set_meta("data_type", "float")
		port.set_meta("port_type", PORT_SPEED)
		port.connect("data_access", self, "_output_port_data_access", [port])
		#port.connect("connections_changed", self, "_output_port_connections_changed", [port])
		mOutputPorts.push_back(port)
	var speed_node = data_router.get_output_port(prefix+"/speed")
	speed_node.set_meta("icon32", load("res://data_router/icons/32/speedometer.png"))
	# Mouse Buttons
	for button_index in range(1, 17):
		var port = data_router.add_output_port(prefix+"/buttons/"+str(button_index)+"/pressed")
		port.set_meta("data_type", "bool")
		port.set_meta("port_type", PORT_BUTTON)
		port.set_meta("button_index", button_index)
		port.connect("data_access", self, "_output_port_data_access", [port])
		#port.connect("connections_changed", self, "_output_port_connections_changed", [port])
		port.get_parent().set_meta("icon32", load("res://data_router/icons/32/button.png"))
		mOutputPorts.push_back(port)
	# Captured
	var port = data_router.add_output_port(prefix+"/captured")
	port.set_meta("data_type", "bool")
	port.set_meta("port_type", PORT_CAPTURED)
	port.connect("data_access", self, "_output_port_data_access", [port])

func _add_input_ports(prefix):
	mInputPortsMeta["captured"] = {
		"port_class": PORT_CAPTURED,
		"data_type": "bool"
	}
	for port_path in mInputPortsMeta.keys():
		var port = data_router.add_input_port(prefix+"/"+port_path)
		for meta_name in mInputPortsMeta[port_path].keys():
			var meta_value = mInputPortsMeta[port_path][meta_name]
			port.set_meta(meta_name, meta_value)
		port.connect("data_changed", self, "_input_port_data_changed", [port])
		mInputPorts.push_back(port)

func _update_output_port_data(port):
	if port.get_meta("port_type") == PORT_POS:
		var new_data
		var pos = get_viewport().get_mouse_pos()
		if port.get_name() == "xy":
			new_data = pos
		elif port.get_name() == "x":
			new_data = pos.x
		elif port.get_name() == "y":
			new_data = pos.y
		if port.mData != new_data:
			port.put_data(new_data)
	elif port.get_meta("port_type") == PORT_SPEED:
		var new_data
		var speed = mMouseSpeed
		if port.get_name() == "xy":
			new_data = speed
		elif port.get_name() == "x":
			new_data = speed.x
		elif port.get_name() == "y":
			new_data = speed.y
		if port.mData != new_data:
			port.put_data(new_data)
	elif port.get_meta("port_type") == PORT_BUTTON:
		var button_index = port.get_meta("button_index")
		var val = Input.is_mouse_button_pressed(button_index)
		if port.mData != val:
			port.put_data(val)
	elif port.get_meta("port_type") == PORT_CAPTURED:
		var captured = false
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			captured = true
		if port.mData != captured:
			port.put_data(captured)

func _output_port_data_access(port):
	_update_output_port_data(port)

func _input_port_data_changed(old_data, new_data, port):
	var port_class = port.get_meta("port_class")
	if port_class == PORT_CAPTURED:
		var captured = false
		if new_data != null:
			captured = bool(new_data)
		if captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _fixed_process(delta):
	var last_mouse_movement_speed = Input.get_mouse_speed()
	if last_mouse_movement_speed == mLastMouseMovementSpeed:
		mMouseSpeed = Vector2(0, 0)
	else:
		mMouseSpeed = last_mouse_movement_speed
	mLastMouseMovementSpeed = last_mouse_movement_speed
	for port in mOutputPorts:
		if port.is_connected():
			_update_output_port_data(port)
