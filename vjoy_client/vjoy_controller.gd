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

const INPUT_PORT_TYPE_AXIS = 0
const INPUT_PORT_TYPE_BUTTON = 1

var mVjoyClient = null
var mId = -1
var mDirty = false
var mState = {
	"axis_x": 0,
	"axis_y": 0,
	"axis_z": 0,
	"axis_x_rot": 0,
	"axis_y_rot": 0,
	"axis_z_rot": 0,
	"slider1": 0,
	"slider2": 0,
	"buttons": []
}
var mOutputPorts = {
	"status": null
}
var mInputPorts = {
	"axis_x": null,
	"axis_y": null,
	"axis_z": null,
	"axis_x_rot": null,
	"axis_y_rot": null,
	"axis_z_rot": null,
	"slider1": null,
	"slider2": null
}
var mButtonInputPorts = []

func _init():
	mState.buttons.resize(128)
	for i in range(0, 128):
		mState.buttons[i] = false

func _ready():
	pass

func _exit_tree():
	for port in mOutputPorts.values():
		data_router.remove_port(port)
	for port in mInputPorts.values():
		data_router.remove_port(port)
	for port in mButtonInputPorts:
		data_router.remove_port(port)

func _data2float(data):
	if data != null:
		return clamp(float(data), -1, 1)
	return float(0)

func _data2bool(data):
	if data != null:
		return bool(data)
	return false

func _input_port_data_changed(old_data, new_data, port):
	var input_port_type = port.get_meta("input_port_type")
	if input_port_type == INPUT_PORT_TYPE_AXIS:
		old_data = _data2float(old_data)
		new_data = _data2float(new_data)
		mState[port.get_name()] = new_data
		if new_data != old_data && (old_data == 0 || new_data == 0):
			mVjoyClient.send_update()
	elif input_port_type == INPUT_PORT_TYPE_BUTTON:
		old_data = _data2bool(old_data)
		new_data = _data2bool(new_data)
		var button_idx = port.get_meta("button_idx")
		mState.buttons[button_idx] = new_data
		if new_data != old_data:
			mVjoyClient.send_update() 

func initialize(vjoy_client, server_hostname, id):
	mVjoyClient = vjoy_client
	mId = id
	mDirty = false
	var prefix = server_hostname.to_lower()+"/vjoy_server/vjoy"+str(id)
	mOutputPorts.status = data_router.add_output_port(prefix+"/status")
	mInputPorts.axis_x = data_router.add_input_port(prefix+"/axis_x")
	mInputPorts.axis_y = data_router.add_input_port(prefix+"/axis_y")
	mInputPorts.axis_z = data_router.add_input_port(prefix+"/axis_z")
	mInputPorts.axis_x_rot = data_router.add_input_port(prefix+"/axis_x_rot")
	mInputPorts.axis_y_rot = data_router.add_input_port(prefix+"/axis_y_rot")
	mInputPorts.axis_z_rot = data_router.add_input_port(prefix+"/axis_z_rot")
	mInputPorts.slider1 = data_router.add_input_port(prefix+"/slider1")
	mInputPorts.slider2 = data_router.add_input_port(prefix+"/slider2")
	for port in mInputPorts.values():
		port.set_meta("input_port_type", INPUT_PORT_TYPE_AXIS)
		port.connect("data_changed", self, "_input_port_data_changed", [port])
	for i in range(0, 128):
		var port = data_router.add_input_port(prefix+"/button"+str(i+1))
		port.set_meta("input_port_type", INPUT_PORT_TYPE_BUTTON)
		port.set_meta("button_idx", i)
		port.connect("data_changed", self, "_input_port_data_changed", [port])
		mButtonInputPorts.push_back(port)

func get_id():
	return mId

func get_state():
	return mState
