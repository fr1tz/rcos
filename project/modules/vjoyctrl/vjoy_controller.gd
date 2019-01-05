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
const AXIS_NAMES = [
	"axis_x",
	"axis_y",
	"axis_z",
	"axis_x_rot",
	"axis_y_rot",
	"axis_z_rot",
	"slider1",
	"slider2",
]

var mVjoyClient = null
var mId = -1
var mDirty = false
var mPortPathsPrefix = ""
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
var mOutputPorts = {}
var mInputPorts = {}
var mButtonInputPorts = {}

func _init():
	mState.buttons.resize(128)
	for i in range(0, 128):
		mState.buttons[i] = false

func _ready():
	pass

func _exit_tree():
	for port in mOutputPorts.values():
		rcos_data_router.remove_port(port)
	for port in mInputPorts.values():
		rcos_data_router.remove_port(port)
	for port in mButtonInputPorts.values():
		rcos_data_router.remove_port(port)

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
	mPortPathsPrefix = server_hostname.to_lower()+"/vjoy_server/vjoy"+str(mId)
	mOutputPorts["status"] = rcos_data_router.add_output_port(mPortPathsPrefix+"/status")

func get_id():
	return mId

func get_state():
	return mState

func vjoy_config_changed(prop_name, prop_value):
	for axis_name in AXIS_NAMES:
		if prop_name == axis_name:
			var port_path = mPortPathsPrefix+"/"+axis_name
			if prop_value == "enabled":
				if !mInputPorts.has(axis_name):
					var port = rcos_data_router.add_input_port(port_path)
					port.set_meta("input_port_type", INPUT_PORT_TYPE_AXIS)
					port.connect("data_changed", self, "_input_port_data_changed", [port])
					mInputPorts[axis_name] = port
			else:
				if mInputPorts.has(axis_name):
					rcos_data_router.remove_port(mInputPorts[axis_name])
					mInputPorts.erase(axis_name)
				mState[axis_name] = 0
	if prop_name == "num_buttons":
		var num_buttons = int(prop_value)
		for button_idx in range(0, 128):
			var port_path = mPortPathsPrefix+"/button"+str(button_idx+1)
			if button_idx < num_buttons:
				if !mButtonInputPorts.has(button_idx):
					var port = rcos_data_router.add_input_port(port_path)
					port.set_meta("input_port_type", INPUT_PORT_TYPE_BUTTON)
					port.set_meta("button_idx", button_idx)
					port.connect("data_changed", self, "_input_port_data_changed", [port])
					mButtonInputPorts[button_idx] = port
			else:
				if mButtonInputPorts.has(button_idx):
					rcos_data_router.remove_port(mButtonInputPorts[button_idx])
					mButtonInputPorts.erase(button_idx)
				mState.buttons[button_idx] = false
