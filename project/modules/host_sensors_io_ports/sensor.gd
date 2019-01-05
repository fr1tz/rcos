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

export(int, "Accelerometer", "Gravity", "Gyroscope", "Magnetometer") var sensor

enum Sensors {
	ACCELEROMETER,
	GRAVITY,
	GYROSCOPE,
	MAGNETOMETER
}

var mSensor = -1
var mOutputPorts = []

func _ready():
	_add_io_ports()

func _exit_tree():
	_remove_io_ports()

func _add_io_ports():
	var os_name = OS.get_name().to_lower().replace(" ", "_")
	var port_path_prefix = "localhost/sensors"
	var icon = null
	if sensor == ACCELEROMETER:
		port_path_prefix += "/accelerometer"
		icon = load("res://rcos_sys/data_router/icons/32/accelerometer.png")
	elif sensor == GRAVITY:
		port_path_prefix += "/gravity"
		icon = load("res://rcos_sys/data_router/icons/32/gravity.png")
	elif sensor == GYROSCOPE:
		port_path_prefix += "/gyroscope"
		icon = load("res://rcos_sys/data_router/icons/32/gyroscope.png")
	elif sensor == MAGNETOMETER:
		port_path_prefix += "/magnetometer"
		icon = load("res://rcos_sys/data_router/icons/32/magnetometer.png")
	var output_port_names = ["x", "y", "z"]
	for port_name in output_port_names:
		var port_path = port_path_prefix+"/"+port_name
		var port = data_router.add_output_port(port_path)
		port.connect("data_access", self, "_output_port_data_access", [port])
		port.connect("connections_changed", self, "_output_port_connections_changed", [port])
		mOutputPorts.push_back(port)
	data_router.get_output_port(port_path_prefix).set_meta("icon32", icon)

func _remove_io_ports():
	for port in mOutputPorts:
		data_router.remove_port(port)

func _update_output_port_data(port):
	var vec = Vector3(0, 0, 0)
	if sensor == ACCELEROMETER:
		vec = Input.get_accelerometer()
	elif sensor == GRAVITY:
		vec = Input.get_gravity()
	elif sensor == GYROSCOPE:
		vec = Input.get_gyroscope()
	elif sensor == MAGNETOMETER:
		vec = Input.get_magnetometer()
	var data = null
	if port.get_name() == "x":
		data = vec.x
	elif port.get_name() == "y":
		data = vec.y
	elif port.get_name() == "z":
		data = vec.z
	if port.mData != data:
		port.put_data(data)

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
