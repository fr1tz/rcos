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

func _on_input_data_changed(data, port):
	set_dirty()

func initialize(server_hostname, id):
	var prefix = server_hostname.to_lower()+"/vjoy_server/vjoy"+str(id)
	mId = id
	mDirty = false
	mOutputPorts.status = data_router.add_output_port(prefix+"/status")
	mInputPorts.axis_x = data_router.add_input_port(prefix+"/axis_x")
	mInputPorts.axis_y = data_router.add_input_port(prefix+"/axis_y")
	mInputPorts.axis_z = data_router.add_input_port(prefix+"/axis_z")
	mInputPorts.axis_x_rot = data_router.add_input_port(prefix+"/axis_x_rot")
	mInputPorts.axis_y_rot = data_router.add_input_port(prefix+"/axis_y_rot")
	mInputPorts.axis_z_rot = data_router.add_input_port(prefix+"/axis_z_rot")
	mInputPorts.slider1 = data_router.add_input_port(prefix+"/slider1")
	mInputPorts.slider2 = data_router.add_input_port(prefix+"/slider2")
	for i in range(0, 128):
		var button_input_port = data_router.add_input_port(prefix+"/button"+str(i+1))
		mButtonInputPorts.push_back(button_input_port)
	for port in mInputPorts.values():
		port.connect("data_changed", self, "_on_input_data_changed", [port])
	for port in mButtonInputPorts:
		port.connect("data_changed", self, "_on_input_data_changed", [port])

func get_id():
	return mId

func set_dirty():
	mDirty = true

func clear_dirty():
	mDirty = false

func is_dirty():
	return mDirty

func _data2float(data):
	if data != null:
		return clamp(float(data), -1, 1)
	return float(0)

func _data2bool(data):
	if data != null:
		return bool(data)
	return false

func get_state():
	mState.axis_x = _data2float(mInputPorts.axis_x.get_data())
	mState.axis_y = _data2float(mInputPorts.axis_y.get_data())
	mState.axis_z = _data2float(mInputPorts.axis_z.get_data())
	mState.axis_x_rot = _data2float(mInputPorts.axis_x_rot.get_data())
	mState.axis_y_rot = _data2float(mInputPorts.axis_y_rot.get_data())
	mState.axis_z_rot = _data2float(mInputPorts.axis_z_rot.get_data())
	mState.slider1 = _data2float(mInputPorts.slider1.get_data())
	mState.slider2 = _data2float(mInputPorts.slider2.get_data())
	for i in range(0, 128):
		mState.buttons[i] = _data2bool(mButtonInputPorts[i].get_data())
	return mState
