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

# Port IDs
const TEXT = 0

var mOutputPorts = {}
var mInputPorts = {}

func _ready():
	_add_io_ports()

func _exit_tree():
	_remove_io_ports()

func _add_io_ports():
	var port_path_prefix = "localhost/sys/clipboard"
	var input_port_names = {
		TEXT: "text"
	}
	for port_id in input_port_names.keys():
		var port_name = input_port_names[port_id]
		var port_path = port_path_prefix+"/"+port_name
		var port = data_router.add_input_port(port_path)
		port.set_meta("data_type", "string")
		port.set_meta("port_id", port_id)
		port.connect("data_changed", self, "_on_input_port_data_changed", [port])
		mInputPorts[port_id] = port
	var output_port_names = {
		TEXT: "text"
	}
	for port_id in output_port_names.keys():
		var port_name = output_port_names[port_id]
		var port_path = port_path_prefix+"/"+port_name
		var port = data_router.add_output_port(port_path)
		port.set_meta("data_type", "string")
		port.set_meta("port_id", port_id)
		port.connect("data_accessed", self, "_output_port_data_accessed", [port])
		port.connect("connections_changed", self, "_output_port_connections_changed", [port])
		mOutputPorts[port_id] = port

func _remove_io_ports():
	for port in mOutputPorts.values():
		data_router.remove_port(port)
	for port in mInputPorts.values():
		data_router.remove_port(port)

func _fixed_process(delta):
	if mOutputPorts[TEXT].mData != OS.get_clipboard():
		mOutputPorts[TEXT].put_data(OS.get_clipboard())

func _output_port_data_accessed(port):
	var port_id = port.get_meta("port_id")
	if port_id == TEXT:
		port.put_data(OS.get_clipboard())

func _output_port_connections_changed(port):
	set_fixed_process(false)
	for port_id in mOutputPorts.keys():
		if mOutputPorts[port_id].is_connected():
			set_fixed_process(true)

func _on_input_port_data_changed(old_data, new_data, port):
	var port_id = port.get_meta("port_id")
	if port_id == TEXT:
		var text = ""
		if new_data != null:
			text = str(new_data)
		OS.set_clipboard(text)
		if mOutputPorts[TEXT].is_connected():
			mOutputPorts[TEXT].put_data(text)
