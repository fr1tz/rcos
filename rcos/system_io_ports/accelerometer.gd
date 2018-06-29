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

var mOutputPorts = {}
var mInputPorts = {}

func _ready():
	var port_path_prefix = "localhost/sys"
	mOutputPorts["accelerometer_x"] = data_router.add_output_port(port_path_prefix+"/accelerometer_x")
	mOutputPorts["accelerometer_y"] = data_router.add_output_port(port_path_prefix+"/accelerometer_y")
	mOutputPorts["accelerometer_z"] = data_router.add_output_port(port_path_prefix+"/accelerometer_z")
	set_fixed_process(true)

func _exit_tree():
	for port in mOutputPorts.values():
		data_router.remove_port(port)
	for port in mInputPorts.values():
		data_router.remove_port(port)

func _fixed_process(delta):
	var accel = Input.get_accelerometer()
	mOutputPorts["accelerometer_x"].put_data(accel.x)
	mOutputPorts["accelerometer_y"].put_data(accel.y)
	mOutputPorts["accelerometer_z"].put_data(accel.z)
