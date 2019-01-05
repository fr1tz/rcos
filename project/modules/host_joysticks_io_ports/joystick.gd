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

const PORT_TYPE_AXIS = 0
const PORT_TYPE_BUTTON = 1

var mDevice = -1
var mOutputPorts = []

func _ready():
	pass

func _exit_tree():
	_remove_io_ports()

func _add_io_ports():
	var joystick_name = Input.get_joy_name(mDevice)
	if joystick_name == "":
		queue_free()
		return
	var os_name = OS.get_name().to_lower().replace(" ", "_")
	var prefix = "localhost/joysticks/"+joystick_name+"["+str(mDevice)+"]"
	add_output_ports(prefix)

func add_output_ports(prefix):
	for axis_index in range(0, 8):
		var port = data_router.add_output_port(prefix+"/axis"+str(axis_index+1))
		port.set_meta("port_type", PORT_TYPE_AXIS)
		port.set_meta("axis_index", axis_index)
		port.set_meta("icon32", load("res://rcos_sys/data_router/icons/32/axis1.png"))
		port.connect("data_access", self, "_output_port_data_access", [port])
		port.connect("connections_changed", self, "_output_port_connections_changed", [port])
		mOutputPorts.push_back(port)
	for button_index in range(0, 16):
		var port = data_router.add_output_port(prefix+"/button"+str(button_index+1))
		port.set_meta("port_type", PORT_TYPE_BUTTON)
		port.set_meta("button_index", button_index)
		port.set_meta("icon32", load("res://rcos_sys/data_router/icons/32/button.png"))
		port.connect("data_access", self, "_output_port_data_access", [port])
		port.connect("connections_changed", self, "_output_port_connections_changed", [port])
		mOutputPorts.push_back(port)

func _remove_io_ports():
	for port in mOutputPorts:
		data_router.remove_port(port)

func _update_output_port_data(port):
	if port.get_meta("port_type") == PORT_TYPE_BUTTON:
		var button_index = port.get_meta("button_index")
		var val = Input.is_joy_button_pressed(mDevice, button_index)
		if port.mData != val:
			port.put_data(val)
	elif port.get_meta("port_type") == PORT_TYPE_AXIS:
		var axis_index = port.get_meta("axis_index")
		var val = Input.get_joy_axis(mDevice, axis_index)
		if port.mData != val:
			port.put_data(val)

func _output_port_data_access(port):
	_update_output_port_data(port)

func _output_port_connections_changed(port):
	set_fixed_process(false)
	for port in mOutputPorts:
		if port.is_connected():
			set_fixed_process(true)

func _fixed_process(delta):
	for port in mOutputPorts:
		if port.is_connected():
			_update_output_port_data(port)

func init(device):
	mDevice = device
	_add_io_ports()
